#[allow(deprecated_usage,lint(self_transfer), unused_field)]
module swap::deepbook_flashloan {
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use sui::sui::SUI;
    use swap::deepbook_swap;
    use swap::swap_turbos;
    
    use deepbook::pool::{Self, Pool};                  
    use deepbook::vault::{FlashLoan};
    use token::deep::DEEP;
    use turbos_clmm::pool::{Pool as TurbosPool, Versioned};    
              
            

    // 1er Swap s'effectuant sur Deepbook (Echange de Sui contre des DEEP)   
    /// 
    /// Cette fonction emprunte des SUI via flashloan et les swappe contre des DEEP
    /// 
    /// # Explication de borrow_flashloan_base/quote:
    /// - `borrow_flashloan_base` retourne `(Coin<BaseAsset>, FlashLoan)` - pour emprunter le BASE asset
    /// - `borrow_flashloan_quote` retourne `(Coin<QuoteAsset>, FlashLoan)` - pour emprunter le QUOTE asset
    
    /// # Arguments:
    /// - `pool`: Le pool DeepBook (Pool<DEEP, SUI> où DEEP=BaseAsset, SUI=QuoteAsset)
    /// - `borrow_amount`: Montant de SUI à emprunter (en unités atomiques, ex: 1000000000 = 1 SUI)
    /// - `deep_in`: Coins DEEP pour payer les frais de swap
    /// - `min_deep_out`: Montant minimum de DEEP attendu après le swap
    /// - `clock`: Le Clock Sui
    /// - `ctx`: Le contexte de transaction
    /// 
    /// # Returns:
    /// Retourne FlashLoan - le reçu qui DOIT être remboursé dans la même transaction
    public fun first_swap<BaseAsset, QuoteAsset>( 
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        borrow_amount: u64,
        deep_fee: Coin<DEEP>, 
        min_expected: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (FlashLoan, Coin<BaseAsset>, Coin<QuoteAsset>) {
 
        // 1. Emprunter des SUI via flashloan
        let (sui_borrowed, flash_loan) = pool::borrow_flashloan_quote<BaseAsset, QuoteAsset>(
            pool,
            borrow_amount,  // Montant de SUI à emprunter
            ctx
        );

        // 2. Swapper les SUI empruntés contre des DEEP
        let (deep, sui_remaining) = deepbook_swap::swap_sui_to_deep<BaseAsset,QuoteAsset>(
            pool,
            sui_borrowed,  // Le Coin<SUI> qu'on a emprunté et qui a la valeur de 'amount'
            deep_fee,       // Coins DEEP pour les frais / C'est l'utilisateur qui payera ces frais avec son DEEP
            min_expected,  // Montant minimum de DEEP attendu
            clock,  
            ctx 
        );
        
        //Retourner le FlashLoan qui DOIT être remboursé plus tard dans la transaction
        (flash_loan, deep, sui_remaining)
    } 

    // La sortie est (coin_b, coin_a_remaining), ici (SUI, DEEP)

    /// Second swap: DEEP -> SUI sur Turbos
    public fun second_swap<FeeType>(
        pool: &mut TurbosPool<DEEP, SUI, FeeType>,
        coin_a: Coin<DEEP>,     //deep qu'on a obtenu depuis le premier swap
        amount: u64,
        min_amount_out: u64,
        recipient: address,
        deadline: u64,
        clock: &Clock,
        versioned: &Versioned,
        sui_remaining: Coin<SUI>,
        ctx: &mut TxContext
    ): Coin<SUI> {

        // Swapper DEEP -> SUI sur Turbos
        let (mut sui, deep_remaining) = swap_turbos::swap_a_to_b<DEEP, SUI, FeeType>(
            pool,
            vector[coin_a],
            amount,
            min_amount_out,
            0,  // sqrt_price_limit = 0 (pas de limite)
            true,  // is_exact_in = true
            recipient,
            deadline,
            clock,
            versioned,
            ctx
        );

        // Transférer les DEEP restants à l'utilisateur
        transfer::public_transfer(deep_remaining, ctx.sender());

        // Fusionner les SUI obtenus avec les SUI restants du premier swap
        coin::join(&mut sui, sui_remaining);
        sui  
    }

    /// Rembourser le flash loan du BASE asset
    public fun return_base<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        base_coin: Coin<BaseAsset>,
        flash_loan: FlashLoan
    ) {
        pool::return_flashloan_base<BaseAsset, QuoteAsset>(
            pool,
            base_coin,
            flash_loan
        ) 
    } 

}