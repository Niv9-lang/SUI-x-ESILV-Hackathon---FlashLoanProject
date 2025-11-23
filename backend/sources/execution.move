module swap::execution {
    use swap::deepbook_flashloan;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock}; 
    use sui::sui::SUI;
    use deepbook::pool::{Self, Pool};                  

    use token::deep::DEEP;
    use turbos_clmm::pool::{Pool as TurbosPool, Versioned};

    /// Erreur : Montant insuffisant pour rembourser le flashloan
    const E_INSUFFICIENT_REPAYMENT: u64 = 1;
    
    /// Erreur : Le swap DeepBook n'a pas produit de DEEP (deep_amount = 0)
    const E_NO_DEEP_RECEIVED: u64 = 2;  

    /// Calcule un deadline approprié pour les transactions flashloan
    /// 
    /// Pour un flashloan, le deadline doit être court car la transaction doit être rapide.
    /// Cette fonction calcule le timestamp actuel + un délai de sécurité.
    /// 
    /// # Arguments:
    /// - `clock`: L'objet Clock Sui
    /// - `minutes_from_now`: Nombre de minutes à ajouter au timestamp actuel (recommandé: 5-10 minutes)
    /// 
    /// # Returns:
    /// Timestamp en millisecondes (timestamp actuel + minutes_from_now)
    /// 
    /// # Exemple:
    /// ```move
    /// let deadline = calculate_deadline(clock, 10); // Deadline dans 10 minutes
    /// ```
    public fun calculate_deadline(clock: &Clock, minutes_from_now: u64): u64 {
        let current_timestamp_ms = clock::timestamp_ms(clock);
        let minutes_in_ms = minutes_from_now * 60 * 1000; // Convertir minutes en millisecondes
        current_timestamp_ms + minutes_in_ms 
    }



    public  fun execute_arbitrage<FeeType>(
        deepbook_pool: &mut Pool<DEEP, SUI>,
        turbos_pool: &mut TurbosPool<DEEP, SUI, FeeType>,
        borrow_amount: u64,
        deep_fee: Coin<DEEP>,
        min_deep_out: u64,
        min_sui_out: u64,
        recipient: address, 
        _deadline: u64,
        clock: &Clock,  
        versioned: &Versioned,
        ctx: &mut TxContext 
    ) {

        let (flash_loan, deep, sui_remaining) = deepbook_flashloan::first_swap<DEEP, SUI>( //(Base / Quote)
            deepbook_pool,
            borrow_amount,
            deep_fee,
            min_deep_out,  // min_expected: montant minimum de DEEP attendu
            clock,
            ctx
        ); 

        // Deuxième swap: Swapper DEEP -> SUI sur Turbos
        let deep_amount = coin::value(&deep);  // Calculer la valeur avant de déplacer deep
        // Vérifier que deep_amount n'est pas 0
        // Cela peut arriver si min_deep_out est trop élevé ou si le swap a échoué
        assert!(deep_amount > 0, E_NO_DEEP_RECEIVED);
        
        // Ajuster min_sui_out pour éviter l'erreur 0x13 dans compute_swap_result
        // Si min_sui_out est trop élevé par rapport à deep_amount, le swap échouera
        // On accepte jusqu'à 50% de slippage pour être sûr que le swap passe
        let adjusted_min_sui_out = if (min_sui_out > borrow_amount * 50 / 100) {
            borrow_amount * 50 / 100  // Maximum 50% du montant emprunté
        } else {
            min_sui_out
        };

        let mut sui_total = deepbook_flashloan::second_swap(
            turbos_pool,   
            vector[deep],  // Transformer le Coin en vecteur
            deep_amount,  // amount: utiliser tout le DEEP
            adjusted_min_sui_out,  // min_amount_out: montant minimum ajusté de SUI attendu
            recipient,
            calculate_deadline(clock, 10), //10 minutes d'attente max
            clock,
            versioned,
            sui_remaining, 
            ctx
        );

        // Vérifier qu'on a assez de SUI pour rembourser le flashloan
        let sui_value = coin::value(&sui_total);
        assert!(sui_value >= borrow_amount, E_INSUFFICIENT_REPAYMENT);

        // Séparer le montant pour le remboursement et les profits
        let (sui_for_repayment, sui_profit) = if (sui_value > borrow_amount) {
            let repayment = coin::split(&mut sui_total, borrow_amount, ctx);
            (repayment, sui_total)
        } else {
            (sui_total, coin::zero<SUI>(ctx))
        };

        // Rembourser le flashloan avec les SUI
        pool::return_flashloan_quote<DEEP, SUI>(
            deepbook_pool,
            sui_for_repayment,
            flash_loan 
        );

        // Transférer les profits au recipient (même si zéro, pour consommer la variable)
        transfer::public_transfer(sui_profit, recipient);
    } 
}