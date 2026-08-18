# Architecture système — carte des décisions

> Document créé le 2026-08-18. Complément de [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md)
> (la proposition technique) et de [`proto-ampli-tas5825m.md`](./proto-ampli-tas5825m.md) (le suivi
> de la carte ampli). Ceux-là décrivent **ce qu'on fait** ; celui-ci décrit **où on en est et ce qui
> bloque quoi**.

## 0. Pourquoi ce document

Le 2026-08-18, une conversation sur la finalité du système a fait apparaître cinq déviations entre
ce qui était conçu et ce dont le projet a besoin : PDN non routé, connecteur à une seule masse, carte
sub bridgée incompatible avec le choix 8 Ω, origine du 3,3 V non tranchée, selfs sous la spec TI.

**Aucune ne venait de la relecture du schéma ou du PCB.** Toutes sont des questions d'**interface**,
et chaque bloc était correct isolément. C'est la raison d'être de ce document : rendre visibles les
frontières entre sous-systèmes, parce que c'est là que se logent les erreurs qu'aucune DRC ne voit.

**Comment le lire** : chaque sous-système donne ce qui est **décidé**, ce qui est **ouvert**, et
**ce dont il dépend**. La §10 donne l'ordre dans lequel les décisions doivent tomber.

## 1. Vue d'ensemble

```
   Source audio                 Cerveau                Distribution           Puissance      Acoustique
  ┌────────────┐          ┌────────────────┐      ┌──────────────────┐    ┌──────────┐   ┌──────────┐
  │ Ordinateur │──USB────►│                │      │ Carte mère 1     │───►│ 4× ampli │──►│ 8 HP     │
  │ (DAW/Max)  │          │  Teensy 4.1    │─TDM─►│ Carte mère 2     │───►│ 4× ampli │──►│ 8 HP     │
  └────────────┘          │  maître        │ I2C  │ Carte mère 3     │───►│ 4× ampli │──►│ 8 HP     │
  ┌────────────┐          │  d'horloge     │      │ Carte MCU        │───►│ 1× ampli │──►│ 1 sub    │
  │ Carte SD   │─────────►│                │      └──────────────────┘    └──────────┘   └──────────┘
  └────────────┘          └────────────────┘                 ▲
                                                             │
                                              ┌──────────────┴───────────────┐
                                              │  Alim 24 V  +  3,3 V         │
                                              └──────────────────────────────┘
```

25 voies = 24 (3 × 8) + 1 caisson.

## 2. Haut-parleurs

**C'est le bloc qui commande tous les autres, et c'est le moins avancé.**

- ✅ **Décidé** : **8 Ω**, figé le 2026-08-18. 25 transducteurs (24 + 1 caisson).
- ❌ **Ouvert** : modèle, puissance admissible, rendement, diamètre, profondeur, type de fixation,
  impédance du caisson (4 Ω ou 8 Ω — voir §3).
- ⛔ **Bloque** : le budget d'alimentation (§6), la section des câbles (§7), la géométrie du châssis
  (§8), et la puissance réellement utile par voie.

**Repère de dimensionnement** : la chaîne délivre **~30 W/voie** à 8 Ω sous 24 V (datasheet
Figure 10-2, 1 % THD). Un HP admettant moins que ça en continu devient le facteur limitant ; un HP
admettant beaucoup plus est de l'argent dépensé pour rien.

## 3. Chaîne d'amplification

- ✅ **Décidé** : TAS5825M, 13 cartes (12 + 1 sub), topologie 3+1, ~30 W/voie, carte sub identique
  aux autres avec strap PBTL + réglage registre, parallélisation **après** les selfs.
- ❌ **Ouvert** : les 8 points du cahier des charges et les 4 décisions de routage, tous détaillés en
  [spec §7](./proposition-carte-octo-dome.md).
- ⚠️ **Le proto mono-puce ne sera pas commandé** (voir [proto §0](./proto-ampli-tas5825m.md)). On
  passe directement à la carte définitive.
- ⚠️ **Selfs sous-spécifiées** : TI demande 4,4 A, la référence retenue donne 3,1 A nominal.

**Point d'arbitrage restant** : **caisson en 4 Ω ou 8 Ω ?** Le PBTL ne sert qu'en dessous de 4 Ω. En
8 Ω, ne pas bridger et garder la seconde voie de cette carte libre. Dépend de §2.

## 4. Cartes mères

Le sous-système **le moins spécifié alors qu'il porte le plus d'interfaces**. Rien n'en existe
aujourd'hui, ni schéma ni cahier des charges.

- ✅ **Décidé** : 3 cartes mères de 4 slots + 1 carte MCU portant 1 slot. Chacune porte le buck
  24 V → 3,3 V de ses cartes ampli, le strapping ADR par slot, et le câblage en OU des FAULTZ/WARNZ.
- ❌ **Ouvert** : tout le reste — dimensions, connectique d'entrée, distribution PVDD interne,
  fan-out du bus TDM vers 4 slots, fixation mécanique des cartes ampli.

**Deux conséquences de la topologie 3+1, jamais notées jusqu'ici :**

**Adressage I2C.** Le TAS5825M n'offre que 4 adresses (0x4C-0x4F) pour 13 puces. La topologie les
résout élégamment : **une carte mère = un segment de mux**, 4 adresses par segment. Un seul
**TCA9548A** (8 segments) suffit — 3 segments pour les cartes mères, 1 pour le sub, 4 en réserve.
La spec §7 évoquait « 2 mux, ou regrouper » : le besoin est en fait d'**un seul**.

**Répartition des slots TDM.** 13 cartes × 2 voies = 26 slots, pour 2 ports de 16 slots :

| Port | Contenu | Slots |
|---|---|---|
| TDM 1 | Cartes mères 1 et 2 | 16 |
| TDM 2 | Carte mère 3 + carte MCU (sub) | 10 |

Ça tombe juste, avec 6 slots de réserve sur le port 2. **À vérifier au firmware** : le découpage
doit correspondre au câblage physique, sinon une carte mère entière écoute les mauvais slots.

## 5. Cerveau (MCU)

- ✅ **Décidé** : **Teensy 4.1** pour le système final, **Teensy 3.6** pour le banc ×4 (déjà en
  possession). Toujours maître d'horloge, quelle que soit la source. 2 ports TDM.
- ❌ **Ouvert** : **comment le bus TDM atteint physiquement 3 cartes mères séparées.** Voir §7 —
  c'est la question qui décide de l'implantation générale.

## 6. Alimentation

Voir [spec §8](./proposition-carte-octo-dome.md) pour le détail.

- ✅ **Décidé** : rail **24 V**. **3,3 V produit par chaque carte mère** (buck 24 V → 3,3 V), ni sur
  la carte ampli, ni depuis le régulateur de bord du MCU.
- ❌ **Ouvert** : précharge, distribution, protection, modèle d'alimentation.

**Le point qui mordra en premier** : ~10 mF de capacité de réserve cumulée sur 13 cartes. Une alim de
600 W part en sécurité ou fait disjoncter au premier allumage. Aucune précharge n'est prévue.
C'est le seul défaut de la liste qui se manifeste par « rien ne démarre », sans indiquer sa cause.

**Budget à recalculer** : les 500-600 W de la spec ont été estimés sur ~38 W/voie. À 30 W réels, le
budget descend. Dépend de §2 (puissance admissible des HP).

## 7. Câblage et implantation

**La décision structurante n'est écrite nulle part : les amplis sont-ils centralisés ou répartis
dans le dôme ?**

| | Ce qui voyage | Difficulté |
|---|---|---|
| **Amplis centralisés** (recommandé) | 25 câbles HP analogiques | Facile — voir barème ci-dessous |
| **Amplis répartis** | Bus TDM à 5-12 MHz sur plusieurs mètres | Difficile, et fragile |

L'analogique se transporte, le TDM rapide non. **Centraliser les 4 cartes dans un coffret** et tirer
du câble HP est la seule implantation qui tienne — mais tant que ce n'est pas écrit, rien ne
l'impose.

- ✅ **Décidé (implicitement, à confirmer)** : câble HP en **1,5 mm²**, **chaque paire torsadée**
  (+ et − du même HP enroulés ensemble — les champs s'annulent, c'est gratuit et c'est la mesure
  anti-rayonnement la plus efficace).
- ❌ **Ouvert** : câblage TDM/I2C entre carte MCU et cartes mères (longueurs, connecteurs, blindage),
  distribution 24 V (topologie étoile ou bus, sections), cheminement.

**Barème câble HP** (résistance aller-retour ≤ 5 % de l'impédance) :

| Section | Longueur max en 8 Ω |
|---|---|
| 0,75 mm² | 8,6 m |
| 1,5 mm² | 17 m |
| 2,5 mm² | 29 m |

Pour un dôme, les liaisons feront 1 à 5 m : **très large en 1,5 mm²**. La longueur n'est pas la
contrainte, le rayonnement l'est — d'où la torsade.

⚠️ Ne pas faire cheminer les câbles HP en parallèle serré avec le bus TDM/I2C ; les croiser à angle
droit si nécessaire.

## 8. Châssis et mécanique

**Entièrement ouvert.** Aucune décision prise, et plusieurs autres blocs en dépendent.

- Structure du dôme : géométrie, matériau, fixation des 25 HP
- Coffret électronique : implantation des 3 cartes mères + carte MCU + alimentation
- **Flux d'air** — la spec §8 le mentionne comme nécessaire, rien n'est conçu
- Fixation des cartes ampli sur les cartes mères : connecteur seul, ou connecteur + vis ?

⚠️ L'entraxe **45 × 51 mm** figé sur le proto n'a de sens que si la carte définitive garde
54,6 × 60,3 mm. Voir §3.

## 9. Source audio et firmware

- ✅ **Décidé** : USB depuis un ordinateur (mode principal), carte SD en socle et secours. Le Teensy
  reste maître d'horloge dans les deux cas.
- ❌ **Ouvert** : init I2C du TAS5825M à réécrire (le driver Sonocotta cible le TAS5805M), lecteur
  multicanal entrelacé démultiplexant vers `AudioOutputTDM`/`AudioOutputTDM2`, configuration des
  GPIO0/1/2 en WARNZ/FAULTZ (registres 0x60h-0x63h), répartition des slots conforme à §4.

**Le firmware ne dépend d'aucun choix matériel restant** — il peut démarrer immédiatement, en
parallèle de la conception des cartes.

## 10. Ordre des décisions

Les flèches se lisent « bloque ».

```
  [2] Haut-parleurs ─┬─► [6] Budget alim ────► modèle d'alimentation
   (8 Ω figé,        ├─► [7] Section câbles
    modèle ouvert)   ├─► [8] Géométrie châssis
                     └─► [3] Sub 4 Ω ou 8 Ω ──► bridger ou non

  [7] Centralisé ou réparti ──► [8] Coffret ──► [4] Dimensions cartes mères
                             └─► [5] Câblage TDM

  [3] 4 décisions de routage ──► [4] Connectique carte mère ──► [8] Fixation
```

**Premier domino : choisir le haut-parleur.** Tant qu'il n'est pas choisi, le budget d'alimentation,
la section des câbles et la géométrie du châssis restent des estimations sans ancrage.

**Deuxième : trancher centralisé vs réparti.** Une ligne dans un document, et elle décide de toute
l'implantation.

Ces deux-là ne coûtent rien à décider et débloquent presque tout le reste.
