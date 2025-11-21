
#### Connexion aux autres plateformes
Supposons qu'un bot s'occupe d'une pool spécifique ; disons ETH/USD, il faut que notre bot ait la capacité de pouvoir acheter/vendre sur un exchange de l'ETH et de le swap sur cette pool.
- Lien vers Binance pour les achats/ventes ?
- Lien vers Cetus/Scallop pour les swap ?
#### Economie du modèle
Inciter les gens à utiliser les bots d'arbitrage sur notre plateforme en les rémunérant avec des jetons spéciaux qui pourront être convertibles en USD.


## RoadMap du Backend
#### Etape 1 : Comment on emprunte ?
- Définir les smart contracts qui vont prêter l'argent et le reprendre avec les fees
- Tout faire dans une seul transaction pour que le flash loan soit valide
- On va emprunter de l'argent dans les pools de liquidités de Scallop

#### Etape 2 : Emprunter de l'USD pour les swap avec du SUI qu'on renvendrait sur un exchange afin de repayer la dette et garder les profits
- Choisir le Bridge utilisé (Sui Bridge, Wormhole…) et la plateforme utilisé pour revendre le SUI
- Réfléchir à l'intégration des donnés des différents CEX et DEX pour avoir le meilleur prix (PythNetwork offre une SDK sur Move qui permet d'intégrer les prix des différents Coins sur différents Exchange)

#### Etape 3 : Performance du bot
- Le bot doit trouver parmi toutes les pools celles qui minimisent les intérêts (ou gas fee) liés à l'emprunt et aussi trouver l' arbitrage qui maximise le profit
- Il doit aussi trouver les pools avec de la liquidité importante pour éviter le phénomène de slippage.
