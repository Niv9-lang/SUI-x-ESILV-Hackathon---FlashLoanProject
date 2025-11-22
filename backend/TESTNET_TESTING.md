# Guide de Test sur le Testnet Sui

## Vérification de la disponibilité de DEEP sur le testnet

### Option 1: Vérifier via l'explorateur Sui

1. **Vérifier l'adresse du token DEEP sur le testnet** :
   ```bash
   # L'adresse DEEP dans votre env.example est :
   # 0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270
   
   # Vérifier sur l'explorateur Sui testnet :
   # https://suiexplorer.com/object/0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270?network=testnet
   ```

2. **Vérifier via la CLI Sui** :
   ```bash
   sui client object 0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270 --json
   ```

### Option 2: Vérifier les pools DeepBook sur le testnet

```bash
# Lister les pools disponibles sur DeepBook testnet
sui client call --package 0xdee9 \
  --module pool \
  --function get_all_pools \
  --gas-budget 10000000
```

## Solutions si DEEP n'est pas disponible sur le testnet

### Solution 1: Créer un token de test DEEP

Si DEEP n'existe pas sur le testnet, vous pouvez créer un token de test :

1. **Créer un module de token de test** :
   ```move
   module swap::test_deep {
       use sui::coin::{Self, Coin, TreasuryCap};
       use sui::transfer;
       use sui::tx_context::{Self, TxContext};
       
       struct DEEP has drop {}
       
       public fun init(ctx: &mut TxContext) {
           let (treasury_cap, metadata) = coin::create_currency<DEEP>(
               ctx,
               9, // decimals
               b"Test DEEP",
               b"TDEEP",
               b"Test DEEP token for testing",
               option::none(),
               ctx
           );
           transfer::public_transfer(treasury_cap, ctx.sender());
           transfer::public_transfer(metadata, ctx.sender());
       }
       
       public fun mint(treasury_cap: &mut TreasuryCap<DEEP>, amount: u64, recipient: address, ctx: &mut TxContext) {
           coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
       }
   }
   ```

2. **Modifier vos imports** :
   ```move
   // Dans vos fichiers, remplacer :
   use token::deep::DEEP;
   
   // Par :
   use swap::test_deep::DEEP;
   ```

### Solution 2: Utiliser un autre token disponible sur le testnet

Vous pouvez modifier temporairement votre code pour utiliser un token de test existant :

1. **Créer un type générique** :
   ```move
   // Modifier vos fonctions pour accepter un type générique au lieu de DEEP
   public fun execute_arbitrage<TestToken, FeeType>(
       deepbook_pool: &mut Pool<TestToken, SUI>,
       turbos_pool: &mut TurbosPool<TestToken, SUI, FeeType>,
       // ...
   )
   ```

2. **Utiliser USDC ou un autre token de test** :
   - Vérifier les tokens disponibles sur le testnet Sui
   - Adapter votre code pour utiliser ce token temporairement

### Solution 3: Utiliser un validateur local Sui

Pour tester sans dépendre du testnet :

```bash
# Démarrer un validateur local
sui-test-validator

# Dans un autre terminal, créer des tokens de test
sui client faucet

# Publier votre package
sui client publish --gas-budget 100000000
```

## Étapes pour tester sur le testnet

### 1. Préparer l'environnement

```bash
# Configurer le client Sui pour le testnet
sui client switch --env testnet

# Vérifier votre adresse
sui client active-address

# Obtenir des SUI de testnet (si nécessaire)
curl --location --request POST 'https://faucet.testnet.sui.io/gas' \
--header 'Content-Type: application/json' \
--data-raw '{"FixedAmountRequest":{"recipient":"VOTRE_ADRESSE"}}'
```

### 2. Vérifier les dépendances

Votre `Move.toml` utilise déjà la version testnet de Turbos :
```toml
TurbosCLMM = { git = "...", rev = "testnet-v0.1.4", override = true }
```

Assurez-vous que DeepBook est également configuré pour le testnet.

### 3. Publier votre package

```bash
# Compiler et publier
sui client publish --gas-budget 100000000

# Notez le Package ID retourné
```

### 4. Vérifier la disponibilité de DEEP

```bash
# Vérifier si le token DEEP existe
sui client object 0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270

# Si l'objet n'existe pas, vous devrez utiliser une des solutions ci-dessus
```

### 5. Tester avec des montants faibles

```bash
# Tester avec de très petits montants d'abord
sui client call \
  --package <VOTRE_PACKAGE_ID> \
  --module execution \
  --function execute_arbitrage \
  --args <deepbook_pool> <turbos_pool> 1000000 <deep_fee> 900000 800000 <recipient> <deadline> <clock> <versioned> \
  --gas-budget 100000000
```

## Commandes utiles

```bash
# Vérifier votre solde SUI
sui client gas

# Vérifier les objets que vous possédez
sui client objects

# Voir les détails d'un objet
sui client object <OBJECT_ID>

# Vérifier les transactions récentes
sui client transactions
```

## Ressources

- **Explorateur Sui Testnet** : https://suiexplorer.com/?network=testnet
- **Faucet Testnet** : https://faucet.testnet.sui.io/
- **Documentation DeepBook** : https://github.com/MystenLabs/deepbookv3
- **Documentation Turbos** : https://github.com/turbos-finance/turbos-sui-move-interface

## Notes importantes

1. **Les tokens de testnet peuvent être réinitialisés** : Ne comptez pas sur la persistance des données
2. **Les pools peuvent ne pas exister** : Vous devrez peut-être créer des pools de test
3. **Les frais de gas sont gratuits** : Mais vous avez toujours besoin de SUI pour les transactions
4. **Testez avec de petits montants** : Pour éviter de perdre des tokens de test

