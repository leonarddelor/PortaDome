# Proto ampli TAS5825M — carte mono-puce

> Document de suivi du prototype ampli (lié à [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md)
> §7/§10-11 : option v2 "bancs custom" TAS5825M). Objectif : valider le comportement TDM/I2C réel
> de la puce sur un banc de test léger, avant de concevoir le banc de production 4 puces (8 voies)
> qui sera ensuite rebranché sur la Teensy.

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

- **Puce assemblée en usine** : seul le TAS5825M (QFN-32, boîtier fin, pastille thermique EP) est
  posé par JLCPCB PCBA (ou soudé nous-même à l'air chaud sur un adaptateur QFN→DIP générique — les
  deux options sont ouvertes, voir §5).
- **Passifs soudés à la main** (0805/1206) : filtre LC de sortie, découplage, pull-ups, résistance
  d'adresse ADR — pour pouvoir ajuster les valeurs sans repasser par un cycle de fab.
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
| U3 | TAS5825MRHBR (QFN-32) | Seul composant à faire assembler / souder à l'air chaud |

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
| L7, L2 | 10 µH | Self, voie A (variante Esparagus — une ferrite conviendrait aussi) |
| L3, L4 | 10 µH | Self, voie B |
| C44, C45 | 680 nF | Condo filtre côté sortie, voie A |
| C47, C48 | 680 nF | Condo filtre côté sortie, voie B |

### Alimentation puce (découplage)

| Réf. | Valeur | Rôle |
|---|---|---|
| C42, C43 | 1 µF | Découplage PVDD au plus près du chip |
| C1 | 1 µF | Découplage zone logique/ADR |
| C3 | 100 nF | Découplage zone logique/ADR |

### Contrôle / status

| Réf. | Valeur | Rôle |
|---|---|---|
| R10 | 10 kΩ | Pull-up PDN# → 3V3 (actif haut = ampli activé) |
| R12, R13, R14 | 10 kΩ | Pull-ups GPIO0/1/2 → WARNZ/FAULTZ/SDOUT |
| 1 résistance ADR | 0Ω / 1k / 4.7k / 15k selon adresse voulue | Adresse I2C — **table officielle confirmée (datasheet §9.5.2, Table 9-5)**, voir §7 |

### Connecteurs

| Réf. | Composant | Rôle |
|---|---|---|
| Bornier 4 pins | type DB127V-5.0-4P ou équivalent | Sortie haut-parleur (voie A + voie B) |
| Header simple | pas 2.54mm | LRCLK/SCLK/SDIN + SDA/SCL vers le XIAO S3 |
| Jumpers PBTL | — | Laissés ouverts (mode stéréo, pas de pont) |

### Optionnel

- Petit dissipateur thermique (bonne pratique class-D, cf. spec §8 sécurité).

## 4. Câblage XIAO ESP32-S3 ↔ carte ampli

- Signaux à relier : **BCLK (SCLK), WS (LRCLK), DATA (SDIN)** en TDM/I2S depuis le XIAO, + **SDA/SCL**
  I2C, + **GND commun**, + **PVDD** depuis l'alim de labo (indépendant du XIAO).
- Le XIAO S3 utilise la matrice GPIO de l'ESP32 : les broches I2S/I2C ne sont **pas figées**, elles
  se choisissent en firmware (comme dans les `build_flags` `PIN_I2S_FS/SCK/SD` vues chez Sonocotta).
  ⚠️ Choix des GPIO précis du XIAO S3 **pas encore fait** — à faire en vérifiant la pinout officielle
  Seeed du XIAO S3 (certaines broches sont réservées : flash SPI, strapping boot) avant de figer le
  firmware.
- Câblage en **Dupont acceptable à <20 cm** pour du TDM 8 voies (~5.6 MHz de BCLK), à condition de :
  - coupler **un fil GND à côté de chaque signal individuellement** (BCLK+GND, WS+GND, DATA+GND,
    SDA+GND, SCL+GND) plutôt qu'un seul GND partagé pour tout le paquet ;
  - vérifier les connecteurs Dupont (faux contact = cause n°1 de bug non reproductible) ;
  - garder la **partie puissance (PVDD, sorties HP, filtre LC) en perfboard soudé**, pas en
    breadboard à contacts à ressort (courant réel, commutation class-D).
- Vérification à l'oscillo une fois câblé : fronts propres sur BCLK/WS/DATA, pas de rebond excessif.

## 5. Fabrication

- **QFN posé par JLCPCB PCBA** (seul le TAS5825M dans la BOM d'assemblage) — ou **adaptateur
  QFN→DIP générique + soudure à l'air chaud** (accès confirmé à une station air chaud/refusion).
  ⚠️ Vérifier le pitch/taille exacts du boîtier TAS5825M dans le datasheet avant d'acheter
  l'adaptateur.
- Point délicat en soudure manuelle : la pastille thermique (EP) sous la puce doit être bien
  mouillée (masse + dissipation), pas seulement les pattes latérales.
- **Estimation de coût JLCPCB PCBA (ordre de grandeur, pas un devis)** pour un lot de 5 (minimum
  habituel) : PCB nu (~5 $) + stencil (~12 $) + setup SMT (~8 $) + frais "extended part" (~3 $) +
  5× TAS5825MRHBR (~30-40 $) → **~55-70 $ pour 5 cartes mono-puce**. À confirmer avec un vrai devis
  une fois le board dessiné (Gerber + BOM + CPL réels dans le configurateur JLCPCB).

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
- [ ] Choix des **GPIO précis du XIAO S3** pour BCLK/WS/DATA/SDA/SCL (vérifier pinout Seeed,
  éviter les broches réservées flash/strapping).
- [ ] Taille/pitch exact du boîtier TAS5825M (datasheet) avant achat de l'adaptateur QFN si soudure
  manuelle retenue.
- [ ] Devis JLCPCB réel une fois le schéma posé (l'estimation §5 est indicative).

## 8. Plan de test

1. Souder/faire assembler la carte mono-puce avec les valeurs de départ ci-dessus.
2. Firmware XIAO S3 (base : `esp32-i2s-bare` de Sonocotta, adapté — leur driver cible le TAS5805M,
   pas le TAS5825M, donc l'init I2C est à réécrire en suivant le datasheet TAS5825M) : test stéréo
   I2S simple d'abord.
3. Une fois le stéréo validé : passer le firmware en TDM (8 slots, 16 bits), toujours sur 1 seule
   puce (elle n'écoutera que ses 2 slots).
4. Dupliquer ×4 (banc 8 voies) une fois les valeurs de composants figées sur le proto mono-puce.
