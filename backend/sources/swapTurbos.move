#[allow(deprecated_usage,lint(self_transfer), unused_field)]
module swap::swap_turbos {
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use sui::tx_context::{Self, TxContext};
    
    use turbos_clmm::pool::{Self, Pool, Versioned};   
    use turbos_clmm::swap_router;

    /// Helper function to merge a vector of coins into a single coin
    public fun merge_coins<CoinType>(mut coins: vector<Coin<CoinType>>): Coin<CoinType> {
        let len = vector::length(&coins);
        assert!(len > 0, 0); // Le vecteur ne doit pas être vide
        let mut result = vector::pop_back(&mut coins);
        while (!vector::is_empty(&coins)) {
            coin::join(&mut result, vector::pop_back(&mut coins));
        };
        vector::destroy_empty(coins);
        result 
    }

    /// Swap CoinTypeA vers CoinTypeB sur Turbos
    /// 
    /// Cette fonction utilise swap_a_b_with_return_ de Turbos pour effectuer un swap
    /// et retourner les coins résultants.
    /// 
    /// # Arguments:
    /// - `pool`: Le pool Turbos pour le swap
    /// - `coins_a`: Les coins de type A à échanger
    /// - `amount`: La quantité à échanger (si is_exact_in = true) ou la quantité minimale attendue (si false)
    /// - `amount_threshold`: La quantité minimale de sortie (protection contre le slippage)
    /// - `sqrt_price_limit`: Limite de prix sqrt (0 = pas de limite)
    /// - `is_exact_in`: true si amount est le montant d'entrée, false si c'est le montant de sortie
    /// - `recipient`: Adresse qui recevra les tokens de sortie
    /// - `deadline`: Timestamp limite pour la transaction
    /// - `clock`: Le Clock Sui
    /// - `versioned`: Version du protocole Turbos
    /// - `ctx`: Le contexte de transaction
    /// 
    /// # Returns:
    /// Retourne (Coin<CoinTypeB>, Coin<CoinTypeA>) - les coins de sortie et le reste d'entrée

    public fun swap_a_to_b<CoinTypeA, CoinTypeB, FeeType>(
        pool: &mut Pool<CoinTypeA, CoinTypeB, FeeType>,
        coin_a: vector<Coin<CoinTypeA>>,
        amount: u64,
        amount_threshold: u64,
        sqrt_price_limit: u128,
        _is_exact_in: bool,                         // true si amount est le montant d'entrée, false si c'est le montant de sortie

        recipient: address,
        deadline: u64,
        clock: &Clock,
        versioned: &Versioned,
        ctx: &mut TxContext
    ): (Coin<CoinTypeB>, Coin<CoinTypeA>) {
        // Fusionner les coins d'entrée
        
        // Appeler la fonction Turbos
        let (coin_b, coin_a_remaining) = swap_router::swap_a_b_with_return_<CoinTypeA, CoinTypeB, FeeType>(
            pool,
            coin_a,
            amount,
            amount_threshold,
            sqrt_price_limit,
            true,
            recipient,
            deadline,
            clock,
            versioned,
            ctx
        ); 
        
        (coin_b, coin_a_remaining)      
  
}
 
}