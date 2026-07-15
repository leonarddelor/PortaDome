# Proto ampli TAS5825M — carte mono-puce

> Document de suivi du prototype ampli (lié à [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md)
> §7/§10-11 : option v2 "bancs custom" TAS5825M). Objectif : valider le comportement TDM/I2C réel
> de la puce sur un banc de test léger, avant de concevoir le banc de production 4 puces (8 voies)
> qui sera ensuite rebranché sur la Teensy.
>
> **Schéma final (validé) : [`TAS5825M_BOARD.pdf`](./TAS5825M_BOARD.pdf)** — export EasyEDA, relu et
> corrigé au fil de l'eau (voir §7 pour l'historique des points corrigés).

## 1. Pourquoi ce proto (rappel de la démarche)

- Le module TAS5825M "du commerce" (~8 $/pièce, ~13 modules) supposé dans la spec §6/§9 n'a **pas
  été trouvé** comme produit assemblé, bon marché, avec TDM + I2C exposés sur pins accessibles
  (voir recherche : seuls des puces nues ou des cartes "intelligentes" avec leur propre MCU
  existent). On construit donc notre propre carte, en réutilisant le bloc DAC déjà validé par
  Sonocotta dans son design "Esparagus/Louder" (`github.com/sonocotta/esparagus-media-center`,
  `hardware/5-esparagus-audio-brick/rev-a`).
- Schémas et datasheet de référence sauvegardés localement dans [`refs/`](./refs/) :
  - [`refs/esparagus-louder-schematic.pdf`](./refs/esparagus-louder-schematic.pdf) — design Sonocotta
    (EasyEDA), source du bloc DAC repris en §3.
  - [`refs/bassowl-hat-schematic.pdf`](./refs/bassowl-hat-schematic.pdf) — design indépendant
    (Darmur, KiCad, HAT Raspberry Pi), utilisé pour croiser les points du §7.
  - [`refs/tas5825m-datasheet.pdf`](./refs/tas5825m-datasheet.pdf) — datasheet officiel TI, source
    d'autorité qui a permis de corriger une erreur de lecture du schéma (voir §7).
- On prototype **1 seule puce d'abord**, pas les 4 du banc final, pour isoler les variables :
  une erreur de valeur de composant coûte un composant à changer, pas une révision de PCB complète.
- Banc de test choisi : un **XIAO ESP32-S3** (déjà en notre possession), pas la Teensy — la Teensy
  3.6 (déjà utilisée en Phase 1) reste la cible finale de firmware, l'ESP32 sert uniquement à
  dérisquer la partie ampli/TDM en parallèle, à moindre coût et plus vite à itérer.
- Le banc mono-puce servira ensuite de bloc réutilisable pour un banc "8 voies" (4 puces), et le
  bloc DAC lui-même est indépendant du cerveau qui le pilote (Teensy en prod, ESP32 en test) — voir
  §6.

## 2. Architecture retenue pour le proto

- **Assemblage complet par JLCPCB PCBA** (changement de plan, voir §5) : tous les composants sont
  posés en usine (QFN de U1 + tous les passifs/connecteurs), plus simple et pas beaucoup plus cher
  qu'assembler seulement U1 à la main. Les 4 résistances ADR restent posées normalement — le choix
  de l'adresse (pont de soudure) se fait à la réception de la carte, indépendamment de qui a soudé
  les résistances.
- **Alimentation simplifiée pour le proto** : PVDD amené directement depuis une alim de labo (pas
  de connecteur DC ni de protection anti-polarité inversée comme sur le design Sonocotta complet).
  Le 3.3V logique est pris depuis le XIAO S3 ou une alim externe, pas généré sur la carte (on saute
  le buck XL1509 du design de référence, pas essentiel pour valider la puce).
- **Pas de connecteur QWIIC** : liaison I2C en fils directs vers le XIAO S3.

## 3. Nomenclature (BOM) — carte mono-puce

Repris du bloc "DAC" du schéma Esparagus (`Louder Esparagus (DUAL POWER)`, feuille 1/3).

### Puce

| Réf. | Composant | Notes |
|---|---|---|
| U3 | TAS5825MRHBR (VQFN-32, 5×5mm) | LCSC **C471049** (en stock, ~2.57 $/pièce à l'unité) — seul composant à faire assembler / souder à l'air chaud |

### Condensateurs de bootstrap (obligatoires — corrigé après vérification datasheet, voir §7)

Datasheet TAS5825M §10.1.2 : chaque demi-pont (BST_x) a besoin d'un condensateur **0.47 µF entre
BST_x et son OUT_x correspondant** pour générer la tension de grille du NMOS high-side. Ce ne sont
**pas** des composants de filtre — je les avais mal classés dans une première lecture du schéma.

| Réf. | Valeur | Rôle |
|---|---|---|
| C29 | 470 nF | Bootstrap BST_A+ ↔ OUT_A+ |
| C30 | 470 nF | Bootstrap BST_A- ↔ OUT_A- |
| C40 | 470 nF | Bootstrap BST_B+ ↔ OUT_B+ |
| C41 | 470 nF | Bootstrap BST_B- ↔ OUT_B- |

### Filtre EMI de sortie (optionnel — confirmé par datasheet §10.1.4)

Le TAS5825M est nativement "inductor-less" ; ce filtre L-C ne sert qu'à réduire les émissions EMI
selon le contexte d'installation, et peut être remplacé par une simple ferrite + condo dans les cas
basse puissance (confirmé par comparaison avec le schéma BassOwl-HAT, qui utilise justement une
ferrite 120R@100MHz au lieu d'une self réelle — deux implémentations valables du même étage).

| Réf. | Valeur | Rôle |
|---|---|---|
| L7, L2 | 10 µH — **Chilisin MHCI06024-100M-R8A, LCSC `C280584`** (4A Isat, SMD 7.3×6.6mm, en stock) | Self, voie A |
| L3, L4 | 10 µH — même référence | Self, voie B |
| C44, C45 | 680 nF | Condo filtre côté sortie, voie A |
| C47, C48 | 680 nF | Condo filtre côté sortie, voie B |

⚠️ Ce filtre est **optionnel** (voir §7) — pour le tout premier test, il est possible de laisser ces
pads vides (sortie directe, sans filtre) et de les peupler seulement une fois la puissance de test
réelle connue. Le 4A de la self ci-dessus couvre ~38W/4Ω (pleine puissance TAS5825M) avec une marge
raisonnable ; un modèle 5.4A (Chilisin `C5577800`) serait mieux dimensionné mais est actuellement en
rupture de stock chez LCSC.

### Alimentation puce (découplage) — liste complète relue depuis le schéma EasyEDA final (C1-C21)

| Valeur | Réf. | Net | Tension recommandée | Rôle |
|---|---|---|---|---|
| 470 nF | C3, C5, C7, C17 | BST_x/OUT_x | 25-35V | Bootstrap (obligatoire, voir §7) |
| 680 nF | C2, C4, C6, C8 | Sortie HP | 25-35V | Filtre EMI optionnel |
| **390 µF** (ou 470µF pour matcher Esparagus) | **C9, C14** | **PVDD (24V)** | **35-50V** | Réservoir bulk PVDD — ⚠️ électrolytique, boîtier nettement plus gros que les autres condos, vérifier la place au layout |
| 22 µF | C10, C12, C13, C15, C20, C21 | PVDD/VCC | 25-35V | Découplage intermédiaire |
| 4.7 µF | C18 | VCC (logique) | 16V | Céramique, décodage zone ADR |
| 1 µF | C19 | VCC (logique) | 16V | Céramique, décodage zone ADR |
| 100 nF | C1, C11, C16 | logique | 16V | Petit découplage |

Confirmé contre le datasheet (§10.1.3 : minimum 22µF sur PVDD, largement respecté) et contre le
schéma de référence Esparagus (qui utilise 470µF, pas 390µF, pour le même rôle — les deux valeurs
sont valables).

### Contrôle / status

| Réf. | Valeur | Rôle |
|---|---|---|
| R10 | 10 kΩ | Pull-up PDN# → 3V3 (actif haut = ampli activé) |
| R12, R13, R14 | 10 kΩ | Pull-ups GPIO0/1/2 → WARNZ/FAULTZ/SDOUT |
| 4 résistances ADR (0Ω, 1k, 4.7k, 15k — une par adresse possible) | 0x4C/0x4D/0x4E/0x4F | Adresse I2C — **table officielle confirmée (datasheet §9.5.2, Table 9-5)**, voir §7. Les 4 sont soudées en permanence, mais **une seule doit être active à la fois** — voir note pont de soudure ci-dessous. |

⚠️ **Important pour le layout PCB** : chaque résistance ADR doit avoir un **pont de soudure ouvert
par défaut** (2 pastilles rapprochées, pas de piste continue) entre elle et GND — pas une piste
soudée d'usine. Si les 4 sont reliées à GND par une piste continue, la résistance 0Ω court-circuite
le nœud ADR en permanence et écrase les 3 autres (adresse bloquée sur 0x4C). Une seule des 4
pastilles-pont doit être fermée (goutte de soudure) après réception de la carte, selon l'adresse
choisie.

### Connecteurs

| Réf. | Composant | Rôle |
|---|---|---|
| CN1 | DORABO DB128L-5.08-4P-GN-S, LCSC `C2827883` (16A, en stock) | Sortie haut-parleur (voie A + voie B) |
| U2 | JST-XH B7B-XH-A(LF)(SN), 7 pos., LCSC `C161874` | Liaison vers le XIAO S3 (détrompé + verrouillage) — voir table de brochage ci-dessous |
| Jumpers PBTL | — | Laissés ouverts (mode stéréo, pas de pont) |

**Brochage U2 (connecteur XIAO S3)** :

| Broche | Signal |
|---|---|
| 1 | VCC (3.3V) |
| 2 | GND |
| 3 | BCLK (SCLK) |
| 4 | WS (LRCLK) |
| 5 | SDIN (DATA) |
| 6 | SDA |
| 7 | SCL |

Boîtier assorti côté câble : **XHP-7** (JST, LCSC `C144406`) + contacts à sertir (série SXH) — ou
câble JST-XH 7 broches pré-serti du commerce (format aussi utilisé comme cordon d'équilibrage LiPo
6S, facile à trouver).

### Alimentation / protection anti-inversion de polarité

| Réf. | Composant | Rôle |
|---|---|---|
| U3 | DORABO DB128L-5.08-2P-GN-S, LCSC `C395868` (18A, en stock) | Entrée PVDD (alim de labo) |
| Q1 | AO4407A, P-channel MOSFET SOP-8, LCSC `C16072` (30V/-12A) | Coupe le courant si la polarité est inversée — Source côté U3 (brut), Drain côté rail PVDD protégé |
| D1 | MM1Z15, Zener 15V SOD-123, LCSC `C115219` | Cathode → Gate, Anode → Source : clampe Vgs pour rester dans la marge de sécurité (±25V max) |
| R9 | 100 kΩ | Tirage Gate → GND (fonctionne avec D1) — ⚠️ ne pas mettre à 0Ω, ça annule la protection (voir erreur corrigée en §7) |

### Optionnel

- Petit dissipateur thermique (bonne pratique class-D, cf. spec §8 sécurité).

## 4. Câblage XIAO ESP32-S3 ↔ carte ampli

- Signaux à relier : **BCLK (SCLK), WS (LRCLK), DATA (SDIN)** en TDM/I2S depuis le XIAO, + **SDA/SCL**
  I2C, + **GND commun**, + **PVDD** depuis l'alim de labo (indépendant du XIAO).
- Le XIAO S3 utilise la matrice GPIO de l'ESP32 : les broches I2S/I2C ne sont **pas figées**, elles
  se choisissent en firmware (comme dans les `build_flags` `PIN_I2S_FS/SCK/SD` vues chez Sonocotta).
- **Assignation retenue** (vérifiée contre le pinout officiel Seeed) :

  | Signal | Broche XIAO | GPIO |
  |---|---|---|
  | BCLK (SCLK) | D0 | GPIO1 |
  | WS (LRCLK) | D1 | GPIO2 |
  | DATA (SDIN) | D3 | GPIO4 |
  | SDA | D4 | GPIO5 |
  | SCL | D5 | GPIO6 |

  D2/GPIO3 (strapping pin) évité ; D6/D7 (UART par défaut) laissés libres pour garder le monitor
  série de debug pendant les tests. SDA/SCL sur les pins I2C par défaut (pas de remap nécessaire).
- Câblage en **Dupont acceptable à <20 cm** pour du TDM 8 voies (~5.6 MHz de BCLK), à condition de :
  - coupler **un fil GND à côté de chaque signal individuellement** (BCLK+GND, WS+GND, DATA+GND,
    SDA+GND, SCL+GND) plutôt qu'un seul GND partagé pour tout le paquet ;
  - vérifier les connecteurs Dupont (faux contact = cause n°1 de bug non reproductible) ;
  - garder la **partie puissance (PVDD, sorties HP, filtre LC) en perfboard soudé**, pas en
    breadboard à contacts à ressort (courant réel, commutation class-D).
- Vérification à l'oscillo une fois câblé : fronts propres sur BCLK/WS/DATA, pas de rebond excessif.

## 5. Fabrication

- **Assemblage complet par JLCPCB PCBA** : tous les composants cochés dans la BOM d'assemblage
  (pas seulement U1), chacun lié à sa référence LCSC réelle.
- **Devis réel obtenu (lot de 5 cartes)** :
  - PCB nu seul : **5.35 $**
  - PCB + assemblage complet (tous composants) + envoi : **102 $**
  - Le détail inclut un "Extended Components Fee" de 28 $ (frais par référence classée "Extended"
    chez JLCPCB — composants moins courants nécessitant un chargement manuel sur leurs machines,
    voir explication §7 historique).
  - ⚠️ **À faire** : recalculer le coût avec **seulement U1 assemblé** (reste des composants soudés
    à la main) pour comparer les deux options avant de valider le choix définitif.
- Point historique (option abandonnée) : soudure manuelle à l'air chaud du QFN sur adaptateur
  QFN→DIP générique restait possible si on avait gardé le plan "U1 seul assemblé" — pas retenue,
  voir ci-dessus.

## 6. Réutilisabilité du bloc DAC

Le bloc DAC (TAS5825M + filtre LC + décor découplage + adressage ADR) est **agnostique du cerveau**
qui le pilote — il écoute juste un bus TDM + I2C. Deux réutilisations identifiées :

1. **Banc 8 voies pour PortaDome** : 4× ce bloc sur un même PCB, bus TDM/I2C partagé, chaque puce
   sur sa propre adresse (0x0C-0x0F, 4 adresses dispo nativement, pas besoin de mux I2C à ce stade).
   Testé d'abord au XIAO S3, rebranché plus tard sans modif sur la Teensy (3.6 puis 4.1).
2. **Piste "instrument autonome" (hors PortaDome)**, façon WVR (`~/repo/wvr`, ESP32 + mémoire
   eMMC/PSRAM pour stocker des échantillons) : même bloc DAC, mais intégré sur un board différent
   avec ESP32 + mémoire embarqués (pas le board "bête" de PortaDome). Piste notée pour plus tard,
   pas engagée tant que le proto PortaDome n'est pas validé.

## 7. Points ouverts / à vérifier avant de graver

- [x] **Câblage BST_A±/BST_B±** — confirmé par le datasheet (§10.1.2) : un condensateur **0.47 µF
  entre chaque BST_x et son OUT_x correspondant**, obligatoire (génère la tension de grille du NMOS
  high-side). Ce sont C29/C30/C40/C41 dans la BOM — voir §3. Ma première lecture du schéma Esparagus
  les avait classés à tort comme "filtre côté puce" ; corrigé.
- [x] **Table résistance ADR → adresse I2C** — confirmée par le datasheet (§9.5.2, Table 9-5) :

  | Résistance ADR → GND | Adresse I2C |
  |---|---|
  | 0 Ω | 0x4C |
  | 1 kΩ | 0x4D |
  | 4.7 kΩ | 0x4E |
  | 15 kΩ | 0x4F |

  (Correction : ma lecture initiale du silkscreen Esparagus avait un appariement différent — le
  datasheet fait foi.)
- [x] **Filtre EMI de sortie** — confirmé optionnel (datasheet §10.1.4, chip "inductor-less" en
  natif) ; self réelle (Esparagus) ou ferrite+condo (BassOwl) sont deux implémentations valables du
  même étage, pas un point à trancher.
- [x] **GPIO précis du XIAO S3** — vérifiés contre le pinout officiel Seeed, voir §4. BCLK=D0/GPIO1,
  WS=D1/GPIO2, DATA=D3/GPIO4, SDA=D4/GPIO5, SCL=D5/GPIO6 (D2 strapping évité, D6/D7 UART laissés
  libres pour le monitor série).
- [x] **Taille/pitch du boîtier** — confirmé via LCSC (C471049) : VQFN-32, 5×5mm, pitch standard
  0.5mm. À revérifier une dernière fois sur le dessin mécanique du datasheet avant achat de
  l'adaptateur QFN si soudure manuelle retenue (précaution, pas un doute réel).
- [ ] Devis JLCPCB réel une fois le schéma posé (l'estimation §5 est indicative — le prix réel du
  composant est meilleur que prévu : ~2.57 $/pièce via LCSC C471049, contre 5-8 $ estimés).
- [x] **Placement + routage PCB terminés** — DRC propre (0 erreur connexion/clearance). Reste une
  alerte non-bloquante "schematic/PCB netlist mismatch" (due à des nets assignés à la main sur des
  vias directement en PCB) — laissée telle quelle pour ce proto, à corriger en repartant du schéma
  pour le futur banc x4.

## 8. Plan de test

1. Souder/faire assembler la carte mono-puce avec les valeurs de départ ci-dessus.
2. Firmware XIAO S3 (base : `esp32-i2s-bare` de Sonocotta, adapté — leur driver cible le TAS5805M,
   pas le TAS5825M, donc l'init I2C est à réécrire en suivant le datasheet TAS5825M) : test stéréo
   I2S simple d'abord.
3. Une fois le stéréo validé : passer le firmware en TDM (8 slots, 16 bits), toujours sur 1 seule
   puce (elle n'écoutera que ses 2 slots).
4. Dupliquer ×4 (banc 8 voies) une fois les valeurs de composants figées sur le proto mono-puce.
