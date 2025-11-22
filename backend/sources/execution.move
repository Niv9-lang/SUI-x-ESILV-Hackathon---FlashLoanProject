module swap::execution {
    use swap::deepbook_flashloan;
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use deepbook::pool::{Self, Pool};                  

    use token::deep::DEEP;
    use turbos_clmm::pool::{Pool as TurbosPool, Versioned}; 

    /// Fonction d'exécution complète pour l'arbitrage
    /// 
    /// Cette fonction réalise un arbitrage complet:
    /// 1. Emprunte des SUI via flashloan sur DeepBook
    /// 2. Swappe SUI -> DEEP sur DeepBook
    /// 3. Swappe DEEP -> SUI sur Turbos
    /// 4. Rembourse le flashloan
    /// 5. Garde le profit (s'il y en a) 
    /// 
    /// # Arguments:
    /// - `deepbook_pool`: Le pool DeepBook (Pool<DEEP, SUI>)
    /// - `turbos_pool`: Le pool Turbos pour le swap DEEP -> SUI
    /// - `borrow_amount`: Montant de SUI à emprunter
    /// - `deep_fee`: Coins DEEP pour payer les frais du premier swap
    /// - `min_deep_out`: Montant minimum de DEEP attendu après le premier swap
    /// - `min_sui_out`: Montant minimum de SUI attendu après le deuxième swap
    /// - `recipient`: Adresse qui recevra les profits
    /// - `deadline`: Timestamp limite pour la transaction Turbos
    /// - `clock`: Le Clock Sui
    /// - `versioned`: Version du protocole Turbos
    /// - `ctx`: Le contexte de transaction

    public  fun execute_arbitrage<FeeType>(
        deepbook_pool: &mut Pool<DEEP, SUI>,
        turbos_pool: &mut TurbosPool<DEEP, SUI, FeeType>,
        borrow_amount: u64,
        deep_fee: Coin<DEEP>,
        _min_deep_out: u64,
        _min_sui_out: u64,
        recipient: address,
        deadline: u64,
        clock: &Clock, 
        versioned: &Versioned,
        ctx: &mut TxContext
    ) {
        // 1. Premier swap: Emprunter SUI et swapper vers DEEP sur DeepBook
        let (flash_loan, deep, sui_remaining) = deepbook_flashloan::first_swap<DEEP, SUI>(
            deepbook_pool,
            borrow_amount,
            deep_fee,
            90u64,              // La démonstration utilisera 3 SUI = 100 DEEP environ
            clock,
            ctx
        );

        // 2. Deuxième swap: Swapper DEEP -> SUI sur Turbos
        let sui_total = deepbook_flashloan::second_swap<FeeType>(
            turbos_pool,
            deep,
            coin::value(&deep),  // amount: utiliser tout le DEEP
            2u64,              // La démonstration utilisera 3 SUI c
            recipient,
            deadline,
            clock,
            versioned,
            sui_remaining,
            ctx
        );

        // 3. Vérifier qu'on a assez de SUI pour rembourser le flashloan
        let sui_value = coin::value(&sui_total);
        assert!(sui_value >= borrow_amount, 1); // Erreur si pas assez pour rembourser

        // 4. Séparer le montant pour le remboursement et les profits
        let (sui_for_repayment, sui_profit) = if (sui_value > borrow_amount) {
            let repayment = coin::split(&mut sui_total, borrow_amount, ctx);
            (repayment, sui_total)
        } else {
            (sui_total, coin::zero<SUI>(ctx))
        };

        // 5. Rembourser le flashloan avec les SUI
        pool::return_flashloan_quote<DEEP, SUI>(
            deepbook_pool,
            sui_for_repayment,
            flash_loan 
        );

        // 6. Transférer les profits au recipient (s'il y en a)
        let profit_value = coin::value(&sui_profit);
        if (profit_value > 0) {
            transfer::public_transfer(sui_profit, recipient); 
        }; 
    }
}     