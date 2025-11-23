#[allow(lint(self_transfer),lint(public_entry))]
module swap::cetus_sf {
    use sui::coin::{Self, Coin}; 
    use sui::clock::Clock;
    use sui::sui::SUI;
    use sui::balance;

    

    use cetusclmm::pool::{Self, Pool};
    use cetusclmm::config::GlobalConfig;
    

    use turbos_clmm::pool::{Pool as TurbosPool, Versioned}; 
    use turbos_clmm::swap_router as turbos_router;
    

    use token::deep::DEEP;  
 

    //
    // - `config`: Configuration globale propre à Cetus CLMM
    // - `cetus_pool`: Pool Cetus (Pool<DEEP, SUI>) pour le flash loan et swap
    // - `turbos_pool`: Pool Turbos (Pool<DEEP, SUI, FeeType>) pour le swap
    // - `loan_amount`: Montant de SUI à emprunter via flash loan
    // - `min_deep_out`: Montant minimum de DEEP attendu après le swap Cetus (mis à 1, peu d'impact)
    // - `min_sui_out`: Montant minimum de SUI attendu après le swap Turbos   (mis à 1, peu d'impact)
    // - `recipient`:  adresse utilisateur
    // - `deadline`: Timestamp limite pour la transaction Turbos
    // - `clock`: Clock Sui
    // - `versioned`: Object ID (et non package) lié à Turbos

    public entry fun execute_arbitrage_cetus<FeeType>(
        config: &GlobalConfig,
        cetus_pool: &mut Pool<DEEP, SUI>,
        turbos_pool: &mut TurbosPool<DEEP, SUI, FeeType>,
        loan_amount: u64,
        min_deep_out: u64,
        min_sui_out: u64,
        recipient: address,
        deadline: u64,
        clock: &Clock,
        versioned: &Versioned,
        ctx: &mut TxContext
    ) {
        // Flash loan SUI depuis Cetus
        let (deep_balance_empty, sui_balance, flash_loan_receipt) = pool::flash_loan<DEEP, SUI>(
            config,
            cetus_pool,
            false,          // loan_a = false pour emprunter du SUI
            loan_amount
        );


        let sui_coin = coin::from_balance(sui_balance, ctx);

        // Détruire le balance DEEP vide (n'a pas drop)
        balance::destroy_zero(deep_balance_empty);

        // Swap SUI -> DEEP sur Cetus
        let (deep_coin, sui_remaining) = cswap_a2b( 
            config,
            cetus_pool, 
            sui_coin,
            min_deep_out,
            clock,
            ctx
        );

        // Calculer la valeur de deep_coin avant de le passer au swap suivant
        let deep_value = coin::value(&deep_coin); 

        // Swap DEEP -> SUI sur Turbos
        let mut sui_total = swap_on_turbos<FeeType>(
            turbos_pool,
            deep_coin,
            deep_value,
            min_sui_out,
            recipient,
            deadline,
            clock,
            versioned,
            sui_remaining, // Passer les SUI restants du premier swap
            ctx
        );

        // Calculer le montant à rembourser (montant emprunté + frais de flash loan)
        // Selon la doc Cetus: les frais de flash loan = frais de swap du pool
        let sui_value_final = coin::value(&sui_total);
        
        // Les frais varient selon le fee_rate du pool (0.01% à 2%)
        let (sui_for_repayment, sui_profit) = if (sui_value_final > loan_amount) {
            let estimated_fees = loan_amount / 100; // 1% maximum
            let repayment_needed = loan_amount + estimated_fees;
            
            if (sui_value_final > repayment_needed) {
                let repayment = coin::split(&mut sui_total, repayment_needed, ctx); 
                (repayment, sui_total)
            } else {
                // Pas assez de marge, rembourser tout
                (sui_total, coin::zero<SUI>(ctx))
            }
        } else {
            (sui_total, coin::zero<SUI>(ctx))
        };

        // Convertir Coin<SUI> en Balance<SUI> pour le remboursement
        let mut repayment_balance = balance::zero<SUI>();
        balance::join(&mut repayment_balance, coin::into_balance(sui_for_repayment));

        // Rembourser le flash loan Cetus
        let empty_deep_balance = balance::zero<DEEP>();
        pool::repay_flash_loan<DEEP, SUI>(
            config,
            cetus_pool,
            empty_deep_balance,
            repayment_balance,
            flash_loan_receipt
        );

        // Transférer les profits au recipient (s'il y en a)
        let profit_value = coin::value(&sui_profit);
        if (profit_value > 0) {
            transfer::public_transfer(sui_profit, recipient);
        } else {
            // Détruire le coin vide si pas de profit
            coin::destroy_zero(sui_profit);
        };
    }



    // Utilise pool::flash_swap selon la documentation Cetus pour construire un swap
    // https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-clmm-contract/features-available/swap-and-preswap


    fun cswap_a2b(
        config: &GlobalConfig,
        pool: &mut Pool<DEEP, SUI>,
        mut coin_b: Coin<SUI>,
        min_deep_out: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (Coin<DEEP>, Coin<SUI>) {
        let amount_in = coin::value(&coin_b);

        let sqrt_price_limit = 79226673515401279992447579055u128;
        
        // Flash swap: Pool<DEEP, SUI>, on swappe SUI -> DEEP (B -> A)
        // a2b = false car on swappe de B vers A
        let (receive_a, receive_b, flash_receipt) = pool::flash_swap<DEEP, SUI>(
            config,
            pool,
            false,  
            true,  // by_amount_in = true
            amount_in,
            sqrt_price_limit,
            clock
        );
        

        let out_amount = balance::value(&receive_a);
        assert!(out_amount >= min_deep_out, 1);
        
        // Calculer combien de SUI on doit payer
        let pay_amount = pool::swap_pay_amount(&flash_receipt);
        let pay_balance_b = coin::into_balance(coin::split(&mut coin_b, pay_amount, ctx));

        // Préparer les balances pour le remboursement
        // Pour a2b=false (B->A), on paye avec balance_b (SUI)
        balance::destroy_zero(receive_b);
        let pay_balance_a = balance::zero<DEEP>();    
        // Convertir receive_a (DEEP) en coin
        let deep_coin = coin::from_balance(receive_a, ctx); 
        
        // Rembourser le flash swap
        pool::repay_flash_swap<DEEP, SUI>(
            config,
            pool,
            pay_balance_a,
            pay_balance_b,  
            flash_receipt 
        );
        
        // Retourner (DEEP obtenu, SUI restant)
        (deep_coin, coin_b) 
    }

        /// Swap DEEP -> SUI sur Turbos CLMM
        /// 
    /// Fusionne les SUI obtenus avec les SUI restants du premier swap (comme dans l'exemple DeepBook)
    fun swap_on_turbos<FeeType>(
        pool: &mut TurbosPool<DEEP, SUI, FeeType>,
        deep_in: Coin<DEEP>,
        amount: u64,
        min_sui_out: u64,
        recipient: address,
        deadline: u64,
        clock: &Clock,
        versioned: &Versioned,
        sui_remaining: Coin<SUI>, // SUI restants du premier swap
        ctx: &mut TxContext
    ): Coin<SUI> {
        // Swap DEEP -> SUI sur Turbos
        let (mut sui_coin, deep_remaining) = turbos_router::swap_a_b_with_return_<DEEP, SUI, FeeType>(
            pool,
            vector[deep_in],
            amount,
            min_sui_out,
            0,  // sqrt_price_limit = 0 (pas de limite)
            true,  // is_exact_in = true
            recipient,
            deadline,
            clock,
            versioned,
            ctx
        );

        // Transférer les DEEP restants au sender
        transfer::public_transfer(deep_remaining, ctx.sender());
        
        // Fusionner les SUI obtenus avec les SUI restants du premier swap (comme dans l'exemple DeepBook)
        coin::join(&mut sui_coin, sui_remaining);
        
        sui_coin
    }
}
