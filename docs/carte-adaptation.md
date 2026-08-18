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
| **Sélection de la source 3,3 V** | cavalier | ⚠️ **hôte OU buck local, jamais les deux** — voir ci-dessous |

⚠️ **Le cavalier 3,3 V n'est pas un confort, c'est une sécurité.** Si l'empreinte du buck est peuplée
*et* que l'hôte fournit son propre 3,3 V par le header, deux régulateurs se retrouvent en opposition
sur le même rail. Le cavalier rend le choix exclusif et visible. Cas typique : branché sur un
Raspberry Pi, on préfère le buck local plutôt que de charger le régulateur du Pi — seule la masse
est alors commune.

**Ajouts propres au banc, à ne jamais mettre dans le rack :**

- **Piquets de test sur BCLK, LRCLK, SDIN** — la §4 du document proto exige déjà une vérification à
  l'oscilloscope (« fronts propres sur BCLK/WS/DATA »). C'est ici qu'on les sort.
- **LED sur FAULTZ et sur WARNZ** — un défaut se voit sans brancher d'ordinateur.
- **Connecteur pour analyseur logique** sur le bus I2C — indispensable pour déboguer l'init du
  TAS5825M, qui est à réécrire entièrement.

## 5. Brancher un hôte

La carte doit servir trois hôtes différents — XIAO ESP32-S3 (le banc documenté en §4 du document
proto), Raspberry Pi, et Teensy 3.6 puis 4.1. Ils n'ont ni le même connecteur ni le même brochage.

**La solution : deux points d'accès câblés sur les mêmes nets**, dont un seul est utilisé à la fois.

| Accès | Format | Pour qui |
|---|---|---|
| **Support XIAO** | embase femelle 2×7, pas 2,54 mm | le XIAO ESP32-S3 s'y enfiche directement |
| **Header générique** | 1×10 ou 2×5, pas 2,54 mm, sérigraphié | Raspberry Pi, Teensy, tout le reste — en Dupont |

⚠️ **Un seul hôte à la fois.** Deux hôtes câblés en même temps mettent deux sources d'horloge sur le
même bus. Rien ne brûle, mais rien ne fonctionne — à écrire sur la sérigraphie.

### XIAO ESP32-S3 — enfiché directement

C'est l'hôte principal du banc, et le seul assez petit pour être porté par la carte d'adaptation.
Brochage repris du §4 du document proto, déjà vérifié contre le pinout officiel Seeed :

| Signal | Broche XIAO |
|---|---|
| BCLK | D0 |
| LRCLK (WS) | D1 |
| SDIN (DATA) | D3 |
| SDA | D4 |
| SCL | D5 |
| PDN | **D8** |
| FAULTZ | **D9** |
| WARNZ | **D10** |

D2 est évité (broche de strapping), D6 et D7 restent libres pour garder le moniteur série de debug.
⚠️ Les trois dernières lignes (D8-D10) sont **à vérifier contre le pinout Seeed** avant routage,
comme l'ont été les cinq premières.

**Un atout de l'ESP32-S3** : ses broches I2S ne sont pas figées, elles se choisissent en firmware
via la matrice GPIO. Le routage de la carte peut donc privilégier la propreté du tracé, le firmware
s'adapte — à condition de respecter les broches interdites ci-dessus.

**Source 3,3 V** : cavalier sur « hôte ». Le régulateur du XIAO suffit pour le DVDD d'une seule puce.

### Raspberry Pi — par le header générique

Six signaux plus la masse, vers le connecteur 40 broches :

| Signal | GPIO | Broche Pi | Rôle |
|---|---|---|---|
| BCLK | GPIO18 | **12** | `PCM_CLK` |
| LRCLK | GPIO19 | **35** | `PCM_FS` |
| SDIN | GPIO21 | **40** | `PCM_DOUT` (sortie du Pi) |
| SDA | GPIO2 | **3** | `SDA1` |
| SCL | GPIO3 | **5** | `SCL1` |
| GND | — | **6, 9, 14, 20, 25, 30, 34, 39** | au moins deux, dont une près des horloges |
| PDN *(opt.)* | GPIO4 | 7 | |
| FAULTZ *(opt.)* | GPIO27 | 13 | en entrée |
| WARNZ *(opt.)* | GPIO22 | 15 | en entrée |

Pi et carte sont tous deux en 3,3 V, aucune adaptation de niveau.

⚠️ **Ne pas relier la broche 1 (3,3 V) du Pi.** Peupler le buck local, cavalier sur « buck », et ne
partager que la masse — le régulateur du Pi est déjà sollicité.

**Configuration Linux** — dans `/boot/firmware/config.txt` :

```
dtparam=i2c_arm=on
dtoverlay=hifiberry-dac
```

`hifiberry-dac` déclare un **DAC I2S générique sans contrôle I2C** : le noyau se contente de sortir
de l'I2S en maître d'horloge, et le TAS5825M se configure depuis l'espace utilisateur. Aucun pilote
ASoC à écrire.

⚠️ **Piège d'ordonnancement.** Le datasheet §9.5.3.1 exige *horloges stables d'abord, init I2C
ensuite*. Or les horloges du Pi ne tournent que pendant un flux ouvert. La séquence qui marche :

```bash
aplay -D hw:0 -f S16_LE -r 44100 -c 2 /dev/zero &   # 1. lance les horloges
python3 init_tas5825m.py                            # 2. init, horloges presentes
aplay -D hw:0 fichier.wav                           # 3. lecture reelle
```

Initialiser avant d'ouvrir le flux échoue **silencieusement** — la puce ne voit pas d'horloge.

**Ce que le Pi donne** : deux voies, de quoi valider l'init I2C, lire les registres de diagnostic et
entendre du son. **Ce qu'il ne donne pas** : le TDM multicanal (le pilote est en pratique limité à
deux voies) ni une horloge propre (diviseur fractionnaire, donc jitter). Bon banc, mauvaise cible —
mais ce qu'on y valide se transpose tel quel sur la Teensy, même puce et même init.

## 6. Ce qu'elle reste après

Elle ne se jette pas une fois la carte mère faite. Sur un projet d'un an avec 13 cartes :

- **Un slot d'établi permanent** — isoler une carte suspecte, développer du firmware, refaire un
  test sans mobiliser le rack ni démonter le dôme.
- **Le poste de mise en service** — chaque carte neuve y passe avant d'être montée : présence I2C,
  clocks détectées, PVDD correct, un canal à la fois.

## 7. Position de repli

Si l'objection « pourquoi ne pas simplement garder les borniers sur la carte ampli » l'emporte, il
existe une solution honnête : **garder CN1 et U3 sur la première série de cartes v2**, et ne
concevoir la carte d'adaptation qu'au moment de la carte mère.

Ce qu'on perd : le débrochage sur ces premières cartes, ~9 % de surface consommée sur chacune, et la
validation du slot avant réplication. Ce n'est pas absurde — c'est simplement plus cher à terme.

⚠️ Cette position de repli était plus défendable **avant** qu'on identifie le troisième métier. Elle
consiste maintenant à payer 9 % de surface sur treize cartes, définitivement, pour éviter de
concevoir une carte à 2 $ dont on a besoin de toute façon pour l'usage hors dôme.

## 8. À faire

- [ ] Figer le brochage des deux connecteurs (dépend du routage de la carte ampli v2)
- [ ] Prévoir l'empreinte de buck 24 V → 3,3 V, non peuplée par défaut
- [ ] Vérifier D8/D9/D10 du XIAO contre le pinout officiel Seeed
- [ ] Schéma
- [ ] Routage 2 couches
- [ ] Commander **avec** les cartes ampli v2, même lot
- [ ] Une fois validée, copier le circuit du slot dans la carte mère
