# Dôme audio 25 canaux — Spécification

> Spécification technique de référence (2026-06-26). Architecture : **Teensy 4.1 centralisée**.
> Toute évolution = nouvelle version datée.

## 1. Objectif

Diffuser une bande son multicanale **synchronisée au sample** sur un **dôme de 25 haut-parleurs**
(typiquement 2×12 + 1 apex/sub). Le contenu est **mixte** : tantôt décorrélé par HP, tantôt
cohérent entre HP voisins. On dimensionne pour le pire cas : **cohérence de phase ~100 µs entre
HP voisins**.

## 2. Architecture

**Un seul cerveau, des amplis passifs.** Le système contient **un seul microcontrôleur (la
Teensy)**. Les amplis n'ont **ni microcontrôleur ni carte SD** : ils ne font qu'amplifier les voies
que la Teensy leur envoie.

- **Teensy 4.1** = cerveau unique. Elle reçoit les 25 voies depuis **l'une de deux sources** (§6) :
  - **USB depuis un ordinateur** — *mode principal*, pour les intervenants qui jouent en live ;
  - **carte SD locale** — *socle de développement, mode autonome (sans ordi) et secours*.

  Puis elle **démultiplexe** vers **2 ports TDM** (32 voies disponibles). Tout sort d'**un seul
  domaine d'horloge**.
- **Amplification — modules TAS5825M du commerce** (chemin principal) : ~**13 modules stéréo**
  (2 voies chacun) branchés sur le bus TDM de la Teensy, configurés par I2C (via un **mux**). **Rien
  à fabriquer.** Chaque module reçoit les voies numérisées (**TDM + horloge + I2C**) et ne fait que
  les convertir et les amplifier.
- *Option v2* : remplacer les modules par des **bancs « Octo » custom** (4× TAS5825M = 8 voies sur
  un PCB) pour une boîte plus compacte et propre (§11). Non nécessaire pour un dôme qui marche.
- **Synchronisation** : les amplis n'ont pas d'horloge propre, ils sont tous cadencés par la Teensy
  → **les 25 voies sont verrouillées en phase par construction**, **quelle que soit la source**
  (en USB, la Teensy reste maître d'horloge). Seul point à confirmer : l'alignement des deux ports
  TDM (**SAI1↔SAI2**, §5).

```
   ordinateur ──USB──┐  (mode principal)
                     ▼
   ┌──────────────── Teensy 4.1 (cerveau) ────────────────┐
   │  USB (live) ─┐                                        │   amplis TAS5825M
   │  SD (secours)┴─► démux ─► TDM port 1 (16 v) ───────────┼──► [TAS5825M] ─► 2 HP ┐
   │                        └► TDM port 2 (16 v) ───────────┼──► [TAS5825M] ─► 2 HP ├ ~13 modules
   │  BCLK/WS/MCLK partagés ───────────────────────────────┼──►    ...    ─► ...    │ (2 voies / module)
   │  I2C (via mux) ─► config slots/DSP des TAS5825M ───────┼──► [TAS5825M] ─► 2 HP ┘
   └───────────────────────────────────────────────────────┘
        (option v2 : 4 bancs « Octo » de 4 puces, au lieu des 13 modules)
```

## 3. Choix techniques

| Décision | Choix | Justification |
|---|---|---|
| Cerveau | **1× Teensy 4.1** | 2 ports SAI → **32 voies TDM** sur un seul domaine d'horloge. Bibliothèque audio mûre. |
| Ampli (puce) | **TAS5825M** (entrée TDM8) | DAC + puissance + DSP par voie en une puce. |
| Ampli (matériel) | **~13 modules du commerce** (principal) ; **bancs PCB en option v2** | Modules = rien à fabriquer, idéal débutant. PCB = boîte compacte ultérieure. |
| Transport audio | **USB depuis l'ordi (principal)** + **SD locale (socle/secours)** | L'intervenant joue en live depuis sa machine ; la SD assure le dev, le mode autonome et le repli. La Teensy reste maître d'horloge dans les deux cas (cf. §6). |
| Synchro | **Un seul domaine d'horloge** (Teensy) | Verrouillage au sample par construction. |

## 4. Capacité (Teensy 4.1)

- **2 ports SAI**, **TDM 16 voies/port** dans la Teensy Audio Library → **32 voies de sortie**.
  25 voies tiennent avec marge.
- Les 16 voies d'**un même port** sont **sample-locked nativement** (même trame TDM 256 bits).
- Brochage SAI1 (TDM port 1) : MCLK=23, BCLK=21, LRCLK/WS=20, DATA OUT=7 ; I2C SCL=19 / SDA=18.
  Le 2ᵉ port (SAI2/TDM2) a ses propres broches data.

## 5. Synchronisation

- **Tous les amplis partagent l'horloge de la Teensy** (`BCLK/WS/MCLK`) → toutes les voies
  verrouillées en phase par construction.
- **Résiduel interne : SAI1↔SAI2.** 25 voies = 2 ports ; il faut que les deux ports soient
  verrouillés entre eux (sinon les voies 1-16 et 17-32 dérivent). Probablement OK (même PLL audio,
  même cycle d'interruption de la lib), **à confirmer au prototype**.
- **Repli si dérive SAI1↔SAI2** : config TDM **32 slots sur un seul port** (trame 512 bits, BCLK
  ~22,6 MHz à 44,1 k) → un seul domaine, question éliminée.
- **Démarrage** : la Teensy étant maître unique, toutes les voies démarrent sur le même tic.

## 6. Sources audio : USB (principal) et SD (socle/secours)

La Teensy reçoit les 25 voies entrelacées, les démultiplexe et les écoule sur les 2 ports TDM —
**quelle que soit la source**. Elle **reste maître d'horloge dans les deux cas**, donc les voies du
dôme restent verrouillées entre elles (le PC n'a aucune influence sur l'alignement inter-HP).

**USB depuis l'ordinateur — mode principal (intervenants).**
- L'intervenant envoie les 25 voies en live depuis son DAW / Max-MSP. Pas de pré-rendu, temps réel.
- Bande passante : ~2,2 Mo/s (16 bit / 44,1 k), très en-deçà de l'USB 2.0 HS de la Teensy (480 Mbit/s).
- Deux implémentations possibles :
  - **USB Audio multicanal** : la Teensy apparaît comme **carte son** ; nécessite des **descripteurs
    USB custom** au-delà de la stéréo (avancé), mais « plug-and-play » côté PC.
  - **Flux PCM brut sur USB série** : firmware **plus simple** (pas de classe USB Audio), mais
    **émetteur PC à écrire**.
- En USB audio **asynchrone**, la Teensy garde l'horloge maître ; l'écart d'horloge PC↔Teensy est
  absorbé par un **buffer** (impact sur la **latence**, pas sur la synchro du dôme).

**SD locale — socle de dev et mode autonome/secours.**
- Un **seul fichier entrelacé 25/32 voies** sur la SD de la Teensy, lu par blocs et démuxé.
  ⚠️ On n'empile pas 25 `AudioPlaySdWav` (plafond ~2-4) → **lecteur PCM entrelacé custom**.
  Base : **Teensy-WavePlayer** (1-8 voies) puis extension.
- Débit : ~2,2 Mo/s (trivial pour le SDIO Teensy 4.1, >20 Mo/s).
- Rôles : **mode autonome** (install sans ordi, lecture en boucle), **secours** si l'ordi d'un
  intervenant lâche, et **premier jalon de dev** (chaîne TDM validée sans la complexité USB).

> Le **démux vers TDM est commun aux deux sources** : on l'écrit une fois (côté SD), l'USB ne change
> que la provenance des blocs.

## 7. Amplification (TAS5825M)

- **TAS5825M** : ampli classe-D stéréo, **entrée TDM8** (chaque puce/module lit 2 slots), DSP intégré
  (2×15 BQ, DRC, AGL, protection thermique & excursion), PVDD 4,5–26,4 V, jusqu'à ~38 W/voie. Le
  **filtre de sortie LC est déjà intégré** sur les modules du commerce.
- **Chemin principal — modules** : ~**13 modules stéréo** sur le bus TDM partagé, chacun configuré
  par I2C (mode TDM, ses 2 slots, gains, DSP). À l'achat, vérifier que le module **expose I2S/TDM +
  I2C** sur des pins accessibles.
- **Adressage I2C** : les modules ont souvent une **adresse fixe** → un **mux I2C (TCA9548A, 8
  segments)** donne à chaque module son segment (~13 modules → 2 mux, ou regrouper ceux dont
  l'adresse ADR diffère).
- **DSP par voie** : égalisation par position dans le dôme, limiteur et protection en marche autonome.
- *Option v2 (PCB)* : 4× TAS5825M par banc, **filtres LC 10 µH + 470-680 nF**, adressage par broche
  **ADR** (0x4C-0x4F) — cf. §10-11.

## 8. Alimentation et thermique (cible 20-40 W/voie)

- **Rail PVDD ~24 V**. Bulk caps proches de chaque TAS5825M.
- **Dimensionnement** : fort facteur de crête de la musique → conso moyenne ~1/5 à 1/8 du pic.
  Prévoir la **réserve** pour les pics, pas une alim continue de 25×40 W.
  - Ordre de grandeur : **alim 24 V de ~500-600 W** pour la boîte, à affiner selon le contenu.
- **Thermique** : classe-D ~88 % de rendement → ~7 W/puce à puissance modérée. **Plan de cuivre +
  flux d'air** dans la boîte. Foldback thermique du TAS5825M en protection ultime.

## 9. Coût indicatif (numérique + ampli, hors alim/HP)

| Poste | ~Prix | Total |
|---|---|---|
| Teensy 4.1 | ~32 $ | 32 $ |
| Modules TAS5825M ×13 (2 voies/module) | ~8 $ pièce | ~104 $ |
| Mux I2C (TCA9548A) ×2 + câblage / connecteurs | — | ~12 $ |
| Carte SD | ~8 $ | 8 $ |
| **Sous-total (25-32 voies amplifiées)** | | **~156 $** |

Hors **alimentation 24 V** (~40-60 $) et haut-parleurs.
*Option v2 (bancs PCB)* : ~5 cartes PCBA JLCPCB en remplacement des modules, **coût comparable**.

## 10. Design de référence (option v2 — PCB)

Utile **uniquement si** on conçoit les bancs PCB (option v2). Pour l'étage de puissance TAS5825M :
design open-source `sonocotta/esparagus-media-center`, dossier `hardware/5-esparagus-audio-brick/rev-a`
(réf. TAS5825MRHBR, QFN-32).

**Réutilisable tel quel (×4 par banc) :** étage TAS5825M — PVDD (pins 3/4/21/22), filtre **LC 10 µH +
470-680 nF**, `PDN#`, sorties `GPIOx` (`FAULTZ/WARNZ/SDOUT`), adressage I2C par broche **ADR**,
mode **PBTL** (jumpers) pour bridger une voie apex/sub.

## 11. Fabrication / assemblage

- **Chemin principal : rien à fabriquer.** Teensy 4.1 (module PJRC) + ~13 **modules TAS5825M du
  commerce** + **mux I2C**, reliés par un câblage / fond de panier qui distribue `BCLK/WS/MCLK +
  2 data TDM + I2C + PVDD`. L'effort est du **câblage propre**, pas du PCB.
- **Option v2 (bancs PCB)** : JLCPCB PCBA, lot de **5 cartes identiques** (4× TAS5825M QFN, 4 couches,
  filtres LC, plan PVDD propre) → boîte plus compacte. Base de schéma : §10.

## 12. Firmware (Teensy)

- **Teensy Audio Library**. **Entrée audio** depuis l'une de deux sources : **flux USB** depuis
  l'ordi (mode principal) **ou** **fichier entrelacé sur SD** (socle/secours). Dans les deux cas,
  **démux par blocs** vers `AudioOutputTDM` (port 1) et `AudioOutputTDM2` (port 2).
- **Config TAS5825M par I2C** au boot (via mux) : mode TDM, attribution des 2 slots par puce, gains,
  DSP/EQ par voie, limiteurs.
- Pas de mixage (voies indépendantes). Débit ~2,2 Mo/s, CPU léger (Cortex-M7 600 MHz).

## 13. Risques

- **Flux USB multicanal** (mode principal) : descripteurs USB Audio custom (avancé) **ou** protocole
  série maison + gestion buffer/latence ; dépend de la **machine de l'intervenant** (hors de notre
  contrôle). La **SD sert de repli**.
- **Verrouillage SAI1↔SAI2** : à confirmer (probablement OK). Repli : TDM 32 slots sur 1 port.
- **Lecteur multicanal (SD)** : tâche firmware **bornée** (1 fichier entrelacé + démux) ; c'est le
  socle de dev, pas une fragilité.
- **Adressage I2C de 13 modules** : adresses souvent fixes → **mux I2C (TCA9548A)**.
- **Câblage de 13 modules** : bus TDM + I2C + 24 V + sorties HP → soigner la propreté (l'option v2
  PCB est là pour tasser tout ça si besoin).
- **Point de défaillance unique** (1 cerveau) : garder une **Teensy de rechange déjà flashée**.
- **Thermique** des amplis (classe-D) → ventilation de la boîte.
- **Appro** : verrouiller les références Teensy 4.1 et TAS5825M.

## 14. Prochaines étapes

1. Prototype **Teensy 4.1 + 1 étage 8 voies** (modules) : lecteur entrelacé **depuis SD** + démux →
   8 voies distinctes alignées (scope). *(socle)*
2. Activer le **2ᵉ port TDM** et **mesurer l'alignement SAI1↔SAI2** (< 100 µs, stable) → 25 voies.
3. **Flux USB depuis l'ordi** (mode principal) : alimenter les mêmes 25 voies en live, valider la
   latence et la stabilité ; la SD reste le secours.
4. **Câbler les ~13 modules TAS5825M** + mux I2C sur le bus TDM, les configurer en TDM depuis la
   Teensy, tester les 25 voies amplifiées. *(Option v2 : concevoir les bancs PCB.)*
