# Carte d'adaptation 1 slot

> Créé le 2026-08-18. Petit circuit 2 couches qui reçoit **une** carte ampli v2 et lui donne des
> points de branchement utilisables sur un établi.
>
> Voir [`mecanique-coffret.md`](./mecanique-coffret.md) §4 pour le brochage des connecteurs et
> [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md) §7 pour le cahier des charges
> de la carte ampli.

## 1. Le problème qu'elle résout

En rendant la carte ampli **débrochable**, on lui a retiré ses deux seuls points de branchement :
CN1 (bornier haut-parleur) et U3 (bornier PVDD) disparaissent. Il ne reste que deux embases 2,54 mm
destinées à la carte mère.

Or la carte mère n'existera pas avant des semaines, et il faut bien tester les cartes ampli à leur
réception.

**Les fils Dupont ne peuvent pas faire le pont** : ils sont donnés pour **~1 A**, alors que PVDD
demande **3,4 A** et chaque sortie haut-parleur **2,1 A**. Les signaux numériques passeraient, la
puissance non.

## 2. Elle a trois métiers

C'est ce qui la rend facile à justifier : une seule carte à 2 $ répond à trois besoins distincts.

| | |
|---|---|
| **Banc de test** | éprouver chaque carte ampli à sa réception, avant montage |
| **Prototype de slot** | valider le circuit du slot avant de le répliquer ×4 sur la carte mère |
| **Support d'usage autonome** | ⭐ rendre **une** carte ampli utilisable dans un autre projet |

### Le troisième métier répond à une contrainte déjà posée

Le §6 du document proto énonce que le bloc ampli doit servir **à d'autres projets, où l'on n'en a
besoin que d'une**. Or les décisions du 18/08 avaient discrètement érodé cette possibilité : en
supprimant CN1 et U3 pour rendre la carte débrochable, on l'a rendue inutilisable seule.

La carte d'adaptation restaure exactement cette capacité — et ce n'est pas un hasard, puisqu'une
carte ampli autonome a besoin de la même chose qu'un slot de banc : un bornier PVDD, un bornier
haut-parleur, un accès aux signaux numériques et une adresse I2C.

**Conséquence de conception** : la traiter comme une carte de production, pas comme un bricolage de
banc. Format compact, trous de fixation utilisables, sérigraphie lisible. Et prévoir une **empreinte
de buck 24 V → 3,3 V non peuplée par défaut** : sur carte mère le 3,3 V vient d'en haut, mais dans
un projet autonome l'hôte n'a pas forcément le budget de courant nécessaire. Une empreinte vide ne
coûte rien et rend la paire ampli + adaptation **autosuffisante à partir du seul 24 V**.

## 3. Ce qu'elle est, techniquement

**Un slot de carte mère, construit seul.**

Le circuit du slot — brochage des deux connecteurs, strapping ADR, distribution du 3,3 V, câblage en
OU des FAULTZ/WARNZ — doit être conçu de toute façon. La seule question est de savoir **sur quoi on
le valide** :

| | Sur cette carte | Directement sur la carte mère |
|---|---|---|
| Coût unitaire | ~2 $ | ~28 $ |
| Si le slot a une erreur | on refait une carte à 2 $ | l'erreur est répliquée **4 fois sur 3 cartes**, soit 12 slots faux |
| Correction | une commande | une commande **et** un routage 4 couches à reprendre |

C'est le raisonnement du §1 du document proto — prototyper **une** puce avant quatre. Isoler les
variables, payer l'erreur au prix le plus bas.

Ce n'est donc pas du travail en plus, c'est du **travail avancé** : le schéma se copie-colle ensuite
dans la carte mère.

## 4. Ce qu'elle porte

| Fonction | Composant | Note |
|---|---|---|
| Réception de la carte ampli | 2 embases femelles 2,54 mm (2×4 + 2×8) | le couple accouplé de la carte mère |
| Entrée PVDD | bornier à vis 2P 5,08 mm | `C395868`, déjà en stock — l'ancien U3 |
| Sorties haut-parleur | bornier à vis 4P 5,08 mm | `C2827883`, déjà en stock — l'ancien CN1 |
| Signaux vers MCU | header 2,54 mm simple rangée | fils Dupont vers XIAO S3 ou Teensy 3.6 |
| Adresse I2C | résistance ADR + pont de soudure | valide le mécanisme d'adressage par slot |
| Maintien mécanique | 4 trous M3 | la carte ampli tient debout sur l'établi |

**Ajouts propres au banc, à ne jamais mettre dans le rack :**

- **Piquets de test sur BCLK, LRCLK, SDIN** — la §4 du document proto exige déjà une vérification à
  l'oscilloscope (« fronts propres sur BCLK/WS/DATA »). C'est ici qu'on les sort.
- **LED sur FAULTZ et sur WARNZ** — un défaut se voit sans brancher d'ordinateur.
- **Connecteur pour analyseur logique** sur le bus I2C — indispensable pour déboguer l'init du
  TAS5825M, qui est à réécrire entièrement.

## 5. Ce qu'elle reste après

Elle ne se jette pas une fois la carte mère faite. Sur un projet d'un an avec 13 cartes :

- **Un slot d'établi permanent** — isoler une carte suspecte, développer du firmware, refaire un
  test sans mobiliser le rack ni démonter le dôme.
- **Le poste de mise en service** — chaque carte neuve y passe avant d'être montée : présence I2C,
  clocks détectées, PVDD correct, un canal à la fois.

## 6. Position de repli

Si l'objection « pourquoi ne pas simplement garder les borniers sur la carte ampli » l'emporte, il
existe une solution honnête : **garder CN1 et U3 sur la première série de cartes v2**, et ne
concevoir la carte d'adaptation qu'au moment de la carte mère.

Ce qu'on perd : le débrochage sur ces premières cartes, ~9 % de surface consommée sur chacune, et la
validation du slot avant réplication. Ce n'est pas absurde — c'est simplement plus cher à terme.

⚠️ Cette position de repli était plus défendable **avant** qu'on identifie le troisième métier. Elle
consiste maintenant à payer 9 % de surface sur treize cartes, définitivement, pour éviter de
concevoir une carte à 2 $ dont on a besoin de toute façon pour l'usage hors dôme.

## 7. À faire

- [ ] Figer le brochage des deux connecteurs (dépend du routage de la carte ampli v2)
- [ ] Prévoir l'empreinte de buck 24 V → 3,3 V, non peuplée par défaut
- [ ] Schéma
- [ ] Routage 2 couches
- [ ] Commander **avec** les cartes ampli v2, même lot
- [ ] Une fois validée, copier le circuit du slot dans la carte mère
