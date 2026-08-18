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

⚠️ **Une seule source d'horloge à la fois.** C'est BCLK/LRCLK/SDIN qui ne doivent jamais avoir deux
émetteurs — pas les autres signaux. En mode nœud de production (§6), un Pi et un ESP32 cohabitent
très bien : ils se partagent les rôles au lieu de se disputer le bus. À sérigraphier.

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

## 6. Trois modes d'emploi

Le support 2×7 change complètement le rôle de la carte selon ce qu'on y met et le firmware qu'on y
charge.

| Mode | MCU sur la carte | Usage |
|---|---|---|
| **Slot passif** | absent | carte mère PortaDome — tout vient du connecteur |
| **Banc** | XIAO **hôte** | test des cartes, développement firmware |
| **Nœud de production** | ESP32 **superviseur** | le Pi fait l'audio, l'ESP32 supervise |

### Le mode superviseur, et ce qu'il répare

En production sur Raspberry Pi, l'ESP32 ne fait pas l'audio : il surveille. Répartition des rôles :

| Signal | Piloté par |
|---|---|
| BCLK, LRCLK, SDIN | **Pi** — la source audio |
| SDA, SCL | **ESP32 seul** |
| PDN | **ESP32** |
| FAULTZ, WARNZ | **ESP32** |

Le Pi ne touche jamais à l'I2C : s'il veut changer un réglage, il le demande à l'ESP32 par UART ou
USB. On évite ainsi le multi-maître I2C, fiable en théorie et pénible en pratique.

**Ce que ça répare, concrètement :**

1. **Le piège d'ordonnancement du §5 disparaît.** L'ESP32 surveille l'apparition des horloges — en
   lisant `CLKDET_STATUS` / `BCK_MON`, ou en observant BCLK — et lance l'init **au bon moment, tout
   seul**. Plus personne n'a à se souvenir d'ouvrir un flux avant d'initialiser.
   *(Ce bug a coûté une semaine de recherche en conditions réelles. Il ne doit pas pouvoir revenir.)*
2. **La mise en veille du Pi devient sûre.** Quand le Pi dort ou redémarre, les horloges s'arrêtent
   et le TAS5825M se retrouve dans un état indéterminé. Le superviseur détecte la perte, met en HiZ
   pour éviter le claquement, et ré-initialise au retour — sans que le Pi ait à y penser.
3. **Le nœud reste diagnosticable même Pi éteint** : présence I2C, `PVDD_ADC`, défauts.

### L'ESP32 peut-il envoyer le son lui-même ?

Oui, et ça pose une question qui vaut d'être tranchée : **si l'ESP32 fait l'audio, le Pi est-il
encore nécessaire ?**

| Voie | Faisabilité | Remarque |
|---|---|---|
| **Fichiers sur carte SD** | ✅ | Le XIAO S3 « Sense » a un lecteur microSD ; le modèle nu n'en a pas |
| **Flash interne** | ⚠️ | 8 Mo ≈ **45 s** de stéréo 44,1 kHz/16 bits non compressé. Décoder du MP3/AAC allonge beaucoup |
| **Streaming WiFi** | ✅ | C'est la voie naturelle pour un nœud en réseau. **Snapcast** résout la synchro multi-pièces et des clients ESP32 existent |
| **USB Audio Class** | ⚠️ | L'S3 a l'USB natif, mais l'UAC sur ESP32-S3 est peu mûr — à éprouver avant de compter dessus |
| **Bluetooth A2DP** | ❌ | **L'ESP32-S3 n'a pas le Bluetooth Classic**, seulement le BLE. Pas de récepteur A2DP. Il faudrait un ESP32 d'origine |

**Conséquence** : pour un nœud simple — streaming réseau ou lecture de fichiers — **ESP32-S3 + carte
ampli + carte d'adaptation suffisent, sans Pi**. Le Pi ne se justifie que si l'on a besoin de Linux :
DSP lourd, vrai système de fichiers, services réseau, vidéo.

⚠️ **Deux réserves.** Le budget de broches du XIAO est serré (11 GPIO : I2S 3 + I2C 2 + PDN/FAULT/
WARN 3 = 8, il reste peu pour une SD en SPI). Et l'horloge I2S de l'ESP32 sort d'une PLL interne :
parfait pour un nœud jouant seul, **inadapté à une synchronisation serrée entre nœuds**.

### ⚠️ Cette architecture est l'inverse de PortaDome — délibérément

PortaDome **interdit toute intelligence locale** : un seul cerveau, un seul domaine d'horloge, parce
que la cohérence de phase à ~100 µs entre haut-parleurs voisins l'exige.

Un réseau de nœuds ESP32 avec redondance mesh est exactement l'opposé : autonomie locale, tolérance
aux pannes, synchronisation lâche.

**Les deux sont justes pour leur problème.** Il ne faut jamais laisser croire que l'une pourrait
servir à l'autre : un mesh ne tiendra jamais la synchro d'un dôme, et le dôme n'a que faire de la
tolérance aux pannes d'un nœud isolé.

## 7. Mécanique : comment tout se tient physiquement

La question se pose ainsi : l'adaptateur doit recevoir la carte ampli **debout**, et se brancher sur
le connecteur du Pi qui est **à plat**. Deux orientations perpendiculaires sur une même carte.

**La sortie est de ne pas empiler. L'adaptateur n'est pas un HAT.**

```
     carte ampli (debout, 60 mm)
            │
      ┌─────┴──────┐
      │ adaptateur │  borniers PVDD / HP, support XIAO
      └─────┬──────┘
            │  nappe 10 points
            │
      ┌─────┴──────┐
      │ Raspberry  │
      │     Pi     │
      └────────────┘

    les deux à plat sur la même platine, côte à côte
```

Les deux cartes se vissent **côte à côte** sur une platine, reliées par une nappe courte. Plus
aucune contrainte d'orientation.

### Pourquoi ne pas empiler est meilleur, et pas seulement plus simple

1. **Hauteur** — une carte de 60 mm dressée au-dessus d'un HAT donne un empilement haut et
   déséquilibré. Côte à côte, tout est stable.
2. **Chaleur** — la carte ampli dissipe, le Pi 4 dissipe. Les superposer, c'est faire chauffer l'un
   par l'autre et priver les deux de circulation d'air.
3. **Bruit** — l'argument décisif. La carte ampli porte du **24 V à 3,4 A commutés vers 400 kHz**.
   La poser sur le Pi met cette commutation à quelques millimètres de son processeur et de ses
   horloges. **Les séparer physiquement est électriquement supérieur.**

Une nappe coûte deux euros et règle les trois.

### Le XIAO est l'exception, à cause de sa taille

21 × 17,5 mm — assez petit pour être **enfiché directement sur l'adaptateur**, sans câble ni
platine. L'ensemble adaptateur + XIAO + carte ampli forme alors un bloc rigide unique qui tient
debout seul.

C'est la raison pour laquelle le support 2×7 est intégré à la carte alors que le Pi passe par un
header : **la différence de taille justifie la différence de traitement.**

### Ce que l'adaptateur demande

- **4 trous M3** pour le visser sur une platine ou un fond de boîtier
- La carte ampli **s'y dresse** — c'est l'adaptateur fixé qui lui donne sa stabilité, pas l'inverse
- Le **header générique orienté vers l'extérieur**, pour que la nappe sorte sans contorsion
- Ni glissière ni renfort : une carte de 60 mm sur deux connecteurs 2,54 mm, portée par un
  adaptateur vissé, tient parfaitement

### Si un jour il faut un produit Pi compact

La bonne réponse ne sera **pas** de plier l'adaptateur en HAT, mais de concevoir un **HAT dédié**
intégrant le circuit ampli directement. On abandonne alors la carte ampli modulaire : c'est un autre
produit, pas une variante de celui-ci.

## 8. Ce qu'elle reste après

Elle ne se jette pas une fois la carte mère faite. Sur un projet d'un an avec 13 cartes :

- **Un slot d'établi permanent** — isoler une carte suspecte, développer du firmware, refaire un
  test sans mobiliser le rack ni démonter le dôme.
- **Le poste de mise en service** — chaque carte neuve y passe avant d'être montée : présence I2C,
  clocks détectées, PVDD correct, un canal à la fois.

## 9. Position de repli

Si l'objection « pourquoi ne pas simplement garder les borniers sur la carte ampli » l'emporte, il
existe une solution honnête : **garder CN1 et U3 sur la première série de cartes v2**, et ne
concevoir la carte d'adaptation qu'au moment de la carte mère.

Ce qu'on perd : le débrochage sur ces premières cartes, ~9 % de surface consommée sur chacune, et la
validation du slot avant réplication. Ce n'est pas absurde — c'est simplement plus cher à terme.

⚠️ Cette position de repli était plus défendable **avant** qu'on identifie le troisième métier. Elle
consiste maintenant à payer 9 % de surface sur treize cartes, définitivement, pour éviter de
concevoir une carte à 2 $ dont on a besoin de toute façon pour l'usage hors dôme.

## 10. À faire

- [ ] Figer le brochage des deux connecteurs (dépend du routage de la carte ampli v2)
- [ ] Prévoir l'empreinte de buck 24 V → 3,3 V, non peuplée par défaut
- [ ] Vérifier D8/D9/D10 du XIAO contre le pinout officiel Seeed
- [ ] Trancher XIAO S3 nu ou « Sense » (lecteur microSD) selon le mode visé
- [ ] Éprouver la maturité de l'USB Audio Class sur ESP32-S3 si cette voie est retenue
- [ ] Schéma
- [ ] Routage 2 couches
- [ ] Orienter le header générique vers l'extérieur du contour (sortie de nappe)
- [ ] Commander **avec** les cartes ampli v2, même lot
- [ ] Une fois validée, copier le circuit du slot dans la carte mère
