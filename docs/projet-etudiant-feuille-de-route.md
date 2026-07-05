# Projet « Dôme audio 25 canaux » — Feuille de route étudiant (1 an)

> Document de passation. Public : étudiant·e **débutant·e en électronique/embarqué**, en
> **stage/alternance** (rythme intensif), objectif **dôme complet jouable** en ~12 mois.
> À lire en entier une première fois, puis à garder ouvert comme fil conducteur.
>
> La **spécification technique** est dans [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md).
> Ce document-ci explique **quoi faire, dans quel ordre, et comment travailler**.

---

## 1. Le projet en une page

On veut sonoriser un **dôme** avec **25 haut-parleurs** qui diffusent une bande son **synchronisée
au sample** (tous les HP parfaitement alignés dans le temps).

Faire jouer 25 HP « ensemble » est facile à dire, dur à faire : si plusieurs microcontrôleurs ont
chacun leur horloge, ils **dérivent** l'un par rapport à l'autre (quelques millisecondes en quelques
minutes), ce qui détruit la cohérence du son. **La solution retenue évite le problème** : on met
**un seul cerveau** qui génère toutes les voies sur **une seule horloge**. Tout est verrouillé « par
construction ».

Ce cerveau est une **Teensy 4.1** : une carte microcontrôleur puissante capable de sortir jusqu'à
**32 voies audio** (via une technique appelée **TDM** sur ses 2 ports audio). Elle envoie les voies
à des **amplis** « bêtes » (sans cerveau), qui ne font qu'amplifier. Côté ampli, on utilise des
**modules TAS5825M du commerce** (2 voies chacun) → ~**13 modules** pour 25 voies, **rien à
fabriquer**. *(Une version compacte sur PCB custom reste possible plus tard — option « v2 ».)*

D'où vient le son ? De **deux sources** :
- **un ordinateur, en USB** — *mode principal* : les intervenants jouent en live depuis leur logiciel ;
- **la carte SD de la Teensy** — *socle de développement, mode autonome (sans ordi) et secours*.

**Déjà décidé** (détaillé dans la spec) :
- **Une seule Teensy 4.1** comme cerveau → un seul domaine d'horloge → toutes les voies verrouillées
  ensemble, **quelle que soit la source** (en USB, la Teensy reste maître d'horloge).
- Audio sorti en **TDM** (jusqu'à 32 voies). Entrée : **USB depuis l'ordi** (principal) **ou** SD.
- Amplification par des **modules TAS5825M du commerce** (conversion + ampli + égalisation).
  Option v2 ultérieure : des bancs PCB custom (inspirés du design open-source Esparagus Audio Brick).

**Reste à faire** : la conception, le prototypage et la réalisation, détaillés en §5.

---

## 2. Ce que tu vas apprendre

Ce projet est un terrain d'apprentissage complet. À la fin tu sauras :

- **Git & collaboration** : versionner ton travail, branches, commits propres, pull requests.
- **Travailler avec Claude** (assistant IA) : l'utiliser pour apprendre, concevoir et déboguer —
  **sans lui faire confiance aveuglément** (méthode en §3.2).
- **Programmation embarquée** : C++ sur Teensy (Cortex-M7), lecture de fichiers, audio numérique.
- **Audio numérique** : échantillonnage, I2S, TDM, multicanal, DAC, classe-D.
- **Électronique & PCB** : lire une datasheet, concevoir une carte, la faire fabriquer (JLCPCB),
  la souder/tester, mesurer au multimètre/oscilloscope.
- **Démarche d'ingénieur** : décomposer un gros problème en petits jalons vérifiables, mesurer
  plutôt que supposer, documenter.

> ⚠️ **Honnêteté** : un dôme complet jouable en un an par un·e débutant·e est **ambitieux**. La
> feuille de route est faite pour que **chaque phase soit une victoire en soi**. Si tu prends du
> retard, voir §10 « où réduire le périmètre » — on peut s'arrêter à un jalon valable sans échouer.

---

## 3. Comment travailler

### 3.1 Git (le minimum vital, puis tu approfondiras)

Cycle de base, à répéter tous les jours :

```bash
git pull                      # récupérer les dernières modifs
git checkout -b ma-tache      # créer une branche pour ce que tu fais
# ... tu travailles, tu testes ...
git add -p                    # choisir ce que tu commits
git commit -m "feat: ..."     # message clair au présent
git push -u origin ma-tache   # envoyer sur GitHub
# puis ouvrir une Pull Request sur GitHub pour relecture par ton tuteur
```

Règles : **un commit = une idée**, message qui explique *pourquoi* pas seulement *quoi*, on ne
commit jamais de code qui ne compile pas sur la branche principale. Tiens un **journal de bord**
(voir §3.5).

### 3.2 Travailler avec Claude (méthode)

Claude est un excellent copilote pour ce projet : expliquer un concept, décortiquer une datasheet,
déboguer, rédiger. Mais la règle d'or :

> **Claude propose, tu décides, le matériel tranche.** Une datasheet ou une mesure à l'oscilloscope
> a toujours raison contre une affirmation de l'IA.

Bonnes pratiques :
- **Demande-lui d'expliquer** un concept que tu ne comprends pas (« explique-moi le TDM comme si
  j'avais jamais fait d'audio numérique »).
- **Fais-lui décortiquer une datasheet** ou un schéma, puis **vérifie** les chiffres clés toi-même.
- **Demande des options + une reco**, pas juste une réponse — et garde une trace de la décision.
- **Fige les décisions dans un document** (comme la spec). Ça évite de tourner en rond.
- **Méfie-toi** : il peut inventer un numéro de broche, une référence de composant, une valeur.
  Pour tout ce qui touche le hardware → recoupe avec la datasheet officielle.
- Quand un truc ne marche pas, **donne-lui le message d'erreur complet et le contexte**.

### 3.3 La démarche d'ingénieur (à appliquer à chaque phase)

1. **Comprendre** : lis la datasheet / la doc, fais-toi expliquer.
2. **Prototyper petit** : la plus petite expérience qui teste *une* chose.
3. **Mesurer** : multimètre, oscilloscope, micro + analyseur. Ne *suppose* jamais que ça marche.
4. **Documenter** : ce qui marche, ce qui rate, les valeurs mesurées (dans le journal + le repo).
5. **Itérer** : on monte en complexité seulement quand l'étape précédente est solide.

### 3.4 Sécurité (important, même en basse tension)

- **Soudure** : local ventilé, lunettes, fer ~350 °C, attention aux brûlures.
- **Alimentation** : on travaille jusqu'à ~24 V — pas mortel, mais un court-circuit peut **brûler
  des composants ou démarrer un feu**. Toujours un **fusible** et une alim limitée en courant au
  début. Vérifier la polarité avant de brancher.
- **ESD** : les puces craignent l'électricité statique — bracelet antistatique au montage.
- Ne jamais débrancher/rebrancher l'audio « à chaud » sous tension.

### 3.5 Journal de bord

Crée `doc/journal/` avec un fichier par semaine (`2026-S38.md`…) : ce que tu as fait, ce que tu as
appris, ce qui bloque, les mesures. C'est ton meilleur outil pour le suivi tuteur **et** pour ne
pas réapprendre deux fois la même chose.

---

## 4. Vue d'ensemble de la feuille de route

| Phase | Thème | Durée indic. | Jalon « c'est fait quand… » |
|---|---|---|---|
| 0 | Outils & onboarding | ~3 sem | Tu compiles/flashes la Teensy, premiers commits, journal lancé |
| 1 | Audio sur la Teensy | ~5 sem | Un WAV stéréo joué depuis la SD, son propre |
| 2 | **TDM 8 voies + lecteur multicanal** (point dur) | ~8 sem | 8 voies distinctes en sortie depuis un fichier entrelacé, mesurées |
| 3 | **25 voies / 2 ports TDM** | ~6 sem | 25 voies sorties (depuis SD), alignement SAI1↔SAI2 mesuré < 100 µs |
| 4 | **Flux audio USB depuis l'ordi** (mode principal) | ~5 sem | Un ordi envoie 25 voies en live, jouées et alignées |
| 5 | **Étage d'ampli (modules)** | ~4 sem | ~13 modules câblés + mux I2C, 25 voies amplifiées testées |
| 6 | **Le dôme** | ~10 sem | 25 voies synchrones diffusent une bande son |
| 7 | Finition & démo | ~6 sem | Égalisation par HP, contenu, doc finale, démo publique |

> Les durées supposent un rythme intensif. Le **cœur du risque, ce sont les phases 2 et 3** (sortir
> proprement les 25 voies). Si elles passent, le reste est de l'assemblage. Atteindre **la fin de la
> phase 3** = faisabilité prouvée (résultat déjà soutenable même si le dôme complet glisse).

---

## 5. Feuille de route détaillée

### Phase 0 — Outils & onboarding (~3 semaines)
**But** : être autonome sur l'environnement.
- Installer : éditeur (VS Code), **Teensyduino** (Arduino IDE) ou PlatformIO, Git, un compte GitHub.
- Faire clignoter une LED sur la **Teensy 4.1** (« hello world » de l'embarqué).
- Apprendre le cycle git (§3.1) : faire une vraie PR « j'ai ajouté mon journal ».
- **Livrable** : build/flash OK, première PR fusionnée, `doc/journal/` démarré.

### Phase 1 — Audio sur la Teensy (~5 semaines)
**But** : comprendre l'audio numérique sur du concret, avec un outillage accessible.
- Prendre en main la **Teensy Audio Library** et son **outil de design graphique** (Audio System
  Design Tool) : assembler un flux audio à la souris.
- Jouer un **WAV stéréo** depuis la carte **SD** de la Teensy.
- Comprendre : échantillonnage (44,1 kHz), 16 bits, **I2S** (BCLK/WS/DATA), le traitement par blocs.
- **Livrable** : lecture stéréo propre depuis SD + une page de journal qui explique l'I2S avec tes
  mots.

### Phase 2 — TDM 8 voies + lecteur multicanal (point dur) (~8 semaines)
**But** : sortir **8 voies indépendantes** en **TDM**, alimentées par un **fichier entrelacé**.
- Brancher **un étage 8 voies** : un DAC TDM 8 canaux, ou 4× module **TAS5825M**.
- Configurer `AudioOutputTDM` (16 slots, on en utilise 8).
- ⚠️ **Le vrai morceau** : écrire le **lecteur de fichier entrelacé** (lire un seul fichier
  contenant les 8 voies entrelacées, le **démultiplexer** vers le tampon TDM). On n'empile **pas**
  8 lecteurs `AudioPlaySdWav` (ça ne tient pas). Base utile : **Teensy-WavePlayer**.
- **Mesurer** chaque voie à l'oscilloscope / au casque : distinctes et alignées.
- **Livrable** : 8 voies différentes depuis un fichier entrelacé, son propre. ⭐ *Valide le cœur.*

### Phase 3 — 25 voies / 2 ports TDM (~6 semaines)
**But** : monter à **25 voies** sur les **deux ports TDM** et prouver leur alignement.
- Activer le **2ᵉ port** (`AudioOutputTDM2`) et étendre le lecteur entrelacé à 25 voies.
- **Mesurer l'alignement SAI1↔SAI2** : un « clic » sur une voie de chaque port, comparer au scope.
  Objectif : décalage **< 100 µs** et **stable** dans le temps.
- Repli si les deux ports dérivent : config **TDM 32 slots sur un seul port** (cf. spec §5).
- **Livrable** : 25 voies sorties et alignées (depuis la SD), mesure documentée. ⭐ *Faisabilité prouvée.*

### Phase 4 — Flux audio USB depuis l'ordi (mode principal) (~5 semaines)
**But** : recevoir les 25 voies **en live depuis un ordinateur** par USB, et les écouler sur le TDM.
- Même **démux → TDM** que la phase 3 : seule la **source** change (USB au lieu de la SD).
- Choisir l'implémentation :
  - **USB Audio multicanal** : la Teensy apparaît comme **carte son** côté PC (nécessite des
    **descripteurs USB custom** au-delà de la stéréo — avancé) ; ou
  - **flux PCM brut sur USB série** : firmware plus simple, mais petit **émetteur côté PC** à écrire.
- Gérer le **buffer** : la Teensy reste **maître d'horloge** → la synchro du dôme n'est pas affectée,
  seule la **latence** l'est.
- **Mesurer** : 25 voies live, latence, stabilité dans la durée. La **SD reste le secours**.
- **Livrable** : un ordi envoie 25 voies en live, jouées et alignées sur les sorties.

### Phase 5 — Étage d'amplification (modules) (~4 semaines)
**But** : monter l'étage d'ampli complet avec des **modules du commerce**, sans rien fabriquer.
- Choisir des **modules TAS5825M** qui exposent **I2S/TDM + I2C** sur des pins accessibles.
- Câbler ~**13 modules** sur le bus TDM partagé + un **mux I2C (TCA9548A)** pour les adresser.
- Depuis la Teensy : configurer chaque module en **TDM** (ses 2 slots), gains, DSP.
- **Bring-up** : alimenter prudemment (alim limitée en courant), vérifier les tensions, tester
  progressivement les 25 voies amplifiées.
- **Livrable** : 25 voies amplifiées pilotées par la Teensy + procédure de test reproductible.
- *Option v2 (plus tard)* : remplacer les modules par des **bancs PCB custom** (4× TAS5825M,
  design inspiré d'Esparagus, fab JLCPCB) pour une boîte compacte. **Non nécessaire** pour un dôme
  qui marche.

### Phase 6 — Le dôme (~10 semaines)
**But** : assembler le système 25 voies.
- **Fond de panier** : distribuer `BCLK/WS/MCLK + 2 lignes data TDM + I2C + PVDD` de la Teensy vers
  tous les modules d'ampli (fan-out, fils appariés).
- **Alimentation 24 V** de la boîte (dimensionnement, fusibles, distribution — cf. spec §8).
- **Contenu** : préparer le **patch côté ordi** (envoi USB des 25 voies) **et** un **fichier
  entrelacé 25 voies** sur SD pour le mode autonome/secours ; réfléchir au mapping voie ↔ position HP.
- **Mécanique** : structure du dôme, HP, câblage. (Peut être mené en parallèle plus tôt.)
- **Livrable** : 25 voies synchrones diffusant une bande son sur le dôme (en USB et en SD).

### Phase 7 — Finition & démo (~6 semaines)
- Égalisation **par voie** via le DSP intégré du TAS5825M (compenser chaque position, par I2C).
- Contenu artistique, scénario de diffusion, déclenchement.
- **Documentation finale** + démo / soutenance.
- **Livrable** : dôme jouable + rapport.

---

## 6. À commander tôt (délais !)

Anticipe dès la phase 1-2, certains délais sont longs :
- **Teensy 4.1** (PJRC) + carte **SD** rapide pour les phases 1-2.
- 1 ou 2 **modules TAS5825M** pour la phase 2 (vérifier qu'ils exposent **I2S/TDM + I2C**).
- Pour la phase 4 (USB) : un **ordinateur + câble USB** et un logiciel capable d'émettre du
  multicanal (DAW / Max-MSP / script) — rien de spécial à acheter.
- Pour la phase 5 : ~**13 modules TAS5825M** + **mux I2C (TCA9548A)** + connectique. (Délais
  d'appro : commander en avance.)
- **Teensy 4.1 de rechange** (point de défaillance unique → spare déjà flashée).
- **Alimentation 24 V** (type Meanwell ~500-600 W), fusibles, connecteurs HP, haut-parleurs.
- Outillage : fer à souder, multimètre, et si possible **un oscilloscope** (indispensable phases
  2-3) et un **micro de mesure** + ordinateur avec un analyseur de spectre.

---

## 7. Glossaire (pour débuter)

- **Teensy 4.1** : carte microcontrôleur puissante (Cortex-M7 600 MHz) qui exécute notre programme
  et sort l'audio. C'est le **cerveau unique** du dôme.
- **SAI** : les ports audio matériels de la Teensy. Elle en a **2** → d'où 2 ports TDM.
- **DAC** (Digital-to-Analog Converter) : transforme les nombres audio en signal électrique audible.
- **Codec** : puce qui fait DAC **et** ADC (entrée). Le TAS5825M est un DAC+ampli (pas d'entrée).
- **Classe-D** : type d'amplificateur très efficace (peu de chaleur), utilisé par le TAS5825M.
- **I2S** : protocole pour transporter l'audio numérique entre puces, avec 3 fils principaux :
  - **BCLK** (bit clock) : cadence les bits.
  - **WS / LRCLK** (word select) : marque le début de trame / le canal.
  - **DATA / SDIN** : les données audio elles-mêmes.
- **MCLK** : horloge maître audio (la Teensy la fournit aux amplis).
- **TDM** (Time-Division Multiplexing) : variante d'I2S qui fait passer **plusieurs voies** (jusqu'à
  16 par port) sur un seul fil de données, en « tranches de temps ».
- **Slot** : une de ces tranches de temps (= une voie) dans une trame TDM.
- **Fichier entrelacé** : un seul fichier (ou flux USB) où les échantillons des 25 voies sont rangés
  en alternance (voie1, voie2, … voie25, voie1, …). On le lit en un flux et on le **démultiplexe**.
- **Démultiplexage (démux)** : séparer les voies d'un flux entrelacé vers chaque sortie.
- **USB Audio** : la Teensy peut apparaître comme une **carte son** côté ordinateur, pour recevoir
  les voies en live. Au-delà de la stéréo, demande des **descripteurs USB sur-mesure**.
- **USB asynchrone** : mode où **la Teensy garde l'horloge maître** et le PC adapte son débit ;
  l'écart d'horloge est absorbé par un buffer → impact sur la **latence**, pas sur la synchro du dôme.
- **PVDD** : tension d'alimentation de puissance de l'ampli (≈ 24 V chez nous).
- **BTL / PBTL** : façons de câbler les sorties de l'ampli (PBTL = 2 voies bridgées → plus de
  puissance, pour l'apex/sub).
- **Filtre LC** : self (L) + condensateur (C) en sortie de l'ampli classe-D, pour nettoyer le signal
  (surtout avec des câbles longs).
- **Mux I2C** (TCA9548A) : aiguilleur qui permet de configurer plusieurs puces ayant la même adresse
  I2C (nécessaire car nos ~13 modules TAS5825M ont souvent une adresse fixe).
- **Dérive d'horloge (ppm)** : deux quartz ne tournent jamais *exactement* pareil ; l'écart fait
  désynchroniser deux cerveaux indépendants. **Notre archi l'évite en n'ayant qu'un cerveau.**
- **Filtrage en peigne** : artefact sonore quand deux HP jouent le même son légèrement décalé →
  certaines fréquences s'annulent. C'est ce qu'on évite avec la synchro.
- **Sample-accurate** : synchronisé à l'échantillon près (~22 µs à 44,1 kHz). Notre objectif.

---

## 8. Ressources

- **Spec du projet** : [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md).
- **Teensy 4.1** : `pjrc.com/store/teensy41.html`.
- **Teensy Audio Library** (+ Audio System Design Tool) : `pjrc.com/teensy/td_libs_Audio.html`.
- **Teensy-WavePlayer** (lecture multicanale) : `github.com/FrankBoesing/Teensy-WavePlayer`.
- **Datasheet TAS5825M** : `ti.com/product/TAS5825M`.
- **Design ouvert de référence** : `github.com/sonocotta/esparagus-media-center`, dossier
  `hardware/5-esparagus-audio-brick/rev-a` (schéma TAS5825M, Gerbers, BOM).
- **Fabrication PCB** : `jlcpcb.com` (et EasyEDA pour ouvrir le design de référence).

---

## 9. Quand tu es bloqué (dans l'ordre)

1. **Reproduis le problème en plus petit** : isole *la* chose qui ne marche pas.
2. **Mesure** : multimètre/oscilloscope. Le hardware ne ment pas.
3. **Relis la datasheet** sur le point précis (numéro de broche, registre, tension).
4. **Demande à Claude** avec le contexte complet + le message d'erreur, et **vérifie** sa réponse.
5. **Note dans le journal** ce que tu as essayé (même les échecs).
6. **Demande à ton tuteur** — avec ton journal, la question sera précise et la réponse rapide.

---

## 10. Pour le tuteur — jalons & réduction de périmètre

**Points de contrôle naturels** (fins de phase = livrables évaluables) : voir le tableau §4.

**Si on prend du retard, où couper sans échouer** (du moins coûteux au plus) :
- Phase 7 → minimale (pas d'égalisation fine, contenu simple).
- Phase 6 → **réduire le nombre de HP** (ex. 8 ou 16 au lieu de 25) : moins de modules, même
  architecture, démo valable.
- Phase 4 (USB) → si le flux USB n'est pas prêt, **se rabattre sur la lecture SD** : le dôme joue
  alors des fichiers pré-rendus au lieu du live. Démo entièrement valable ; l'USB se rajoute après.
- Le **PCB custom (option v2)** n'est jamais sur le chemin critique : il reste optionnel après coup.
- **Plancher de réussite = fin de phase 3** : *« 25 voies sorties depuis une Teensy (depuis SD),
  alignées < 100 µs sur table »* prouve la faisabilité du concept central — résultat soutenable même
  si le dôme complet glisse à l'année suivante.

**Risque principal** : profil débutant × objectif très ambitieux. La mitigation est dans la
structure en paliers : chaque phase produit quelque chose de démontrable, et le projet « réussit »
dès la phase 3 même s'il ne va pas jusqu'au dôme complet.

**Point de défaillance unique** : tout repose sur une seule Teensy → prévoir une **carte de rechange
déjà flashée** (échange en quelques minutes).
