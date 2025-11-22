#[allow(deprecated_usage,lint(self_transfer), unused_field)]
module swap::deepbook_swap {
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    
    use deepbook::pool::{Self, Pool};
    use token::deep::DEEP;


    /// Swap QuoteAsset vers BaseAsset sur DeepBook
    /// Retourne les BaseAsset obtenus pour être utilisés dans un swap suivant (ex: via Turbos)
    /// Note: Pour Pool<DEEP, SUI>, on swappe QuoteAsset (SUI) -> BaseAsset (DEEP)
    public fun swap_quote_to_base<BaseAsset, QuoteAsset>(
        self: &mut Pool<BaseAsset, QuoteAsset>,
        quote_in : Coin<QuoteAsset>, // les jetons qu'on va perdre durant le swap
        deep : Coin<DEEP>, // payment des frais de swap en DEEP
        min_base_out: u64,
        clk: &Clock,
        ctx: &mut TxContext
    ): (Coin<BaseAsset>,Coin<QuoteAsset>) {  

        let (base_out, quote_remaining, deep_leftover) = pool::swap_exact_quote_for_base<BaseAsset, QuoteAsset>(
            self, 
            quote_in, 
            deep, // Payment des frais de swap en DEEP
            min_base_out, 
            clk, 
            ctx
        );

        transfer::public_transfer(deep_leftover, ctx.sender());
        
        // Retourner les DEEP (BaseAsset) obtenus pour être utilisés dans le swap suivant
        (base_out, quote_remaining)
    }

    /// Alias pour swap_quote_to_base avec des noms plus spécifiques
    /// Swap SUI vers DEEP sur DeepBook (pour Pool<DEEP, SUI>)
    public fun swap_sui_to_deep<BaseAsset, QuoteAsset>(
        self: &mut Pool<BaseAsset, QuoteAsset>,
        sui : Coin<QuoteAsset>,
        deep : Coin<DEEP>,
        min_base_out: u64,
        clk: &Clock,
        ctx: &mut TxContext
    ): (Coin<BaseAsset>, Coin<QuoteAsset>) {
        swap_quote_to_base(self, sui, deep, min_base_out, clk, ctx)
    }
}