# Mécanique du coffret — rack 3U ventilé

> Document créé le 2026-08-18. Troisième volet, avec
> [`architecture-systeme.md`](./architecture-systeme.md) (carte des décisions) et
> [`proposition-carte-octo-dome.md`](./proposition-carte-octo-dome.md) (proposition technique).
>
> **Raison d'être** : la mécanique était le dernier bloc entièrement vide de la carte des décisions,
> et elle y apparaissait trois fois comme dépendance. Elle contraint l'électronique en retour —
> l'orientation des cartes fixe l'emplacement des connecteurs, donc le routage.

## 1. Format — 3U rack 19"

✅ **Décidé.** Rack 19", **3U** (133,35 mm), largeur utile ~450 mm.

Quatre raisons qui se cumulent :

1. **Ventilateurs 120 mm.** À débit égal, un gros ventilateur lent est radicalement plus silencieux
   qu'un petit rapide. Le 2U (~83 mm utiles) imposerait du 80 mm sifflant. Dans un lieu d'écoute,
   c'est le critère décisif.
2. **Alimentation à l'intérieur**, sous ou derrière les cartes mères.
3. **Pas de 20 mm entre cartes** conservé pour la circulation d'air (voir §5).
4. Marge de câblage.

Coût : encombrement et poids. Secondaire pour une installation fixe.

## 2. Implantation générale

✅ **Décidé** : coffret central contenant **3 cartes mères + 1 carte MCU + l'alimentation**.
25 câbles HP en sortent. Les amplis sont centralisés, jamais répartis dans le dôme — le TDM à
5-12 MHz ne voyage pas sur plusieurs mètres, l'analogique oui.

```
   ┌─────────────────────── 19" / 450 mm utiles ───────────────────────┐
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐   ┌──────────────────┐  │
3U │  │ Carte    │  │ Carte    │  │ Carte    │   │   Carte MCU      │  │  flux d'air
   │  │ mère 1   │  │ mère 2   │  │ mère 3   │   │   (Teensy + sub) │  │  ═══════►
   │  │ 4 cartes │  │ 4 cartes │  │ 4 cartes │   │   1 carte ampli  │  │
   │  └──────────┘  └──────────┘  └──────────┘   └──────────────────┘  │
   │  ┌─────────────────────────────────────────────────────────────┐  │
   │  │  Alimentation 24 V (en aval du flux)                        │  │
   │  └─────────────────────────────────────────────────────────────┘  │
   └───────────────────────────────────────────────────────────────────┘
```

❌ **Ouvert** : l'implantation exacte, à dessiner. La contrainte s'est nettement desserrée depuis le
choix de l'alimentation UHP (§6) : **62 mm de large au lieu de 124**, ce qui laisse la place à côté
des ~300 mm des trois cartes mères sans avoir à superposer.

📐 **Modèle paramétrique : [`mecanique/implantation-3u.scad`](../mecanique/implantation-3u.scad)**
— ouvrir dans OpenSCAD, changer une cote, F5, lire la console. Les `echo()` vérifient largeur,
hauteur, profondeur, panneau et ventilation, et affichent OK ou DEPASSE.

**Résultat de la première passe (2026-08-18)** : ça rentre, avec 14 mm de marge en largeur, 44 mm en
hauteur, 98 mm en profondeur. Et surtout — voir §8.3 — **la largeur du rack est consommée par le pas
× 13 cartes (260 mm), pas par les dimensions de la carte ampli**.

**Outils libres pour cette étude** (choisis le 2026-08-18) :
- **OpenSCAD** pour l'étude d'encombrement — c'est du code, donc le fichier **vit dans le dépôt, se
  versionne et se diffe** comme le reste de la documentation. Des boîtes paramétriques suffisent à
  répondre à « est-ce que ça rentre ».
- **FreeCAD** pour l'assemblage réel : EasyEDA Pro exporte le PCB en **STEP**, Mean Well et Neutrik
  publient également des STEP. On assemble des modèles réels, pas des approximations — c'est là que
  les collisions apparaissent.
- **Front Panel Designer** (Schaeffer, gratuit) pour le panneau arrière : il produit un panneau
  réellement fabricable, avec les vraies cotes des 13 Speakon + secteur + USB.

## 3. Cartes ampli — format debout

✅ **Décidé** : les cartes ampli s'enfichent **perpendiculairement** aux cartes mères, comme des
barrettes mémoire.

Bénéfices : peu de nappes, connexions robustes, air circulant entre les cartes, et **cartes
remplaçables** — on en garde une en rechange, on la met à n'importe quelle place (l'adressage I2C
est imposé par le slot, voir architecture-systeme §4).

- **Pas entre cartes : 20 mm** (contraint par la ventilation, voir §5)
- **Hauteur : 60,3 mm** — provisoire, dépend de §8
- **Connecteurs sur le bord inférieur**, bornier HP supprimé du bord supérieur

⚠️ **CN1 et U3 disparaissent de la carte ampli.** Un bornier à vis annule l'intérêt d'une carte
débrochable : il faudrait un tournevis dans le rack et un dévissage avant chaque extraction. PVDD et
sorties HP passent désormais par les connecteurs.

Surface récupérée par la suppression des deux borniers 5,08 mm : **à réinvestir en cuivre**, donc en
dissipation — pas en réduction de taille.

## 4. Connectique

### Carte ampli → carte mère : deux connecteurs séparés

| Connecteur | Format | Contenu |
|---|---|---|
| **Puissance** | 2×4 (8 broches) | PVDD ×2, PGND ×2, OUT_A±, OUT_B± |
| **Signal** | 2×8 (16 broches) | 3V3, BCLK, LRCLK, SDIN, SDA, SCL, PDN, FAULTZ, WARNZ, ADR + 6 GND intercalés |

**La séparation des domaines devient physique** : puissance et numérique ne partagent plus ni
connecteur ni chemin de retour. C'est la réponse structurelle à la question EM d'origine.

Deux broches 2,54 mm en parallèle donnent ~6 A pour 3,4 A demandés sur PVDD.

### Face arrière

- **13 × Speakon NL4**, 2 voies par connecteur → 26 voies pour 25 HP, une en réserve.
  Correspondance exacte : **un NL4 par carte ampli**. La carte sub en PBTL utilise une paire de
  pôles.
- Entrée secteur (CEI) si l'alim est interne
- USB depuis l'ordinateur — embase sur panneau

⚠️ **Speakon, pas jack 6,35.** Un jack TS **court-circuite la sortie pendant l'insertion** (la pointe
frotte la masse) : on stresserait l'étage de sortie à chaque manipulation. Il ne verrouille pas, et
surtout il est **confondable avec un connecteur ligne** — 25 jacks identiques portant du 24 V
d'ampli finiraient par recevoir une sortie de console. Le Speakon existe précisément pour rendre
cette confusion impossible, et il verrouille au quart de tour.

## 5. Refroidissement

✅ **Décidé** : **ventilation forcée en push-pull**, flux **avant-arrière**, parallèle aux faces des
cartes. **2 soufflants de 120 mm en façade + 1 extracteur de 120 mm en face arrière.**

⚠️ **La direction du flux n'est pas un choix.** Les cartes debout créent des canaux orientés
avant-arrière (espacées en largeur, leur longueur suivant la profondeur). Un flux latéral buterait
perpendiculairement sur leur tranche et les contournerait au lieu de les traverser. **Le pas de
20 mm est contraint par la même logique** — resserrer à 15 mm étranglerait les canaux.

**Pourquoi push-pull et pas seulement des soufflants** : les canaux ne font que ~8 mm, c'est un
chemin restrictif. Souffler à l'avant *et* extraire à l'arrière double le différentiel de pression
disponible. Sur un chemin dégagé la différence serait marginale ; ici elle compte.

**Garder plus de débit entrant que sortant** (2 contre 1) maintient le coffret en **surpression** :
l'air n'entre que par les ventilateurs, donc un filtre sert réellement à quelque chose. En
dépression, la poussière entre par tous les interstices et aucun filtre ne la retient.

**Implantation du panneau arrière** : le bloc Speakon est décalé sur la gauche (238 mm) pour libérer
la droite à l'extracteur (120 mm) — total 378 mm sur 450 utiles. Centrer les Speakon ne laisserait
que 106 mm de chaque côté, insuffisant pour un 120 mm.

**Débit nécessaire : faible.** Charge thermique ~75 W (13 puces à ~5 W dissipés + pertes de l'alim).
Pour 10 °C d'élévation il faut de l'ordre de **13 CFM** — un seul 120 mm y suffirait presque à
basse vitesse. Avec trois, la marge est telle qu'ils peuvent **tous tourner très lentement**. C'est
là que se gagne le silence : par la vitesse, pas par le nombre.

**Ce que la ventilation rend** : le budget thermique passe d'environ **27 W à ~40 W continus par
puce** (le θJA baisse quand l'air balaie le cuivre, et l'ambiant interne reste proche de la pièce au
lieu de grimper). ⚠️ **Ordre de grandeur à mesurer, pas à croire.**

**Pilotage** : le MCU dispose déjà de **WARNZ** (routé au connecteur) pour accélérer les
ventilateurs à l'approche du repli thermique. Mieux encore si la puce expose une lecture de
température par I2C — **à chercher dans la table des registres, datasheet §9.6**. Si elle existe, on
régule en continu au lieu de réagir à une alerte.

L'alimentation est placée **en aval du flux**, pour ne pas préchauffer les amplis.

❌ **Ouvert** : référence des ventilateurs et courbe pression/débit (les 8 mm de canal imposent de
regarder la pression statique, pas seulement le débit libre), filtre à l'entrée ou non.

## 6. Alimentation

Voir [spec §8](./proposition-carte-octo-dome.md) pour le dimensionnement.

- ✅ **Décidé** : à l'intérieur du rack. **Mean Well UHP-350-24** — 350 W, 24 V, 14,6 A,
  **220 × 62 × 31 mm**, **refroidissement par convection sans ventilateur**, rendement 94 %.
  (Cotes et absence de ventilateur vérifiées le 2026-08-18 ; à reconfirmer sur la fiche Mean Well
  avant achat.)

  ⚠️ **La série LRS a été écartée** : contrairement à ce qu'on avait supposé, **elle embarque un
  ventilateur dès 350 W** (convection seulement jusqu'à 150-200 W). Un ventilateur de 40 mm dans
  l'alimentation serait la source de bruit la plus aiguë du rack — exactement ce que le choix du 3U
  cherche à éviter. La UHP est en outre **deux fois moins large** (62 contre 124 mm), ce qui résout
  la contrainte d'encombrement du §2.

- **Calibre : 350 W suffisent.** Les 500-600 W de la spec étaient estimés sur ~38 W/voie. À ~30 W
  réels, la consommation moyenne sur programme musical tourne vers ~145 W ; les 10 mF de réserve
  encaissent les crêtes, et le plafond thermique des puces borne de toute façon le régime soutenu.
- ⚠️ **Appel de courant** : ~10 mF de réserve cumulée. Solution offerte par la topologie —
  **séquencer les 3 cartes mères** à ~200 ms d'écart, ce qui divise l'appel en trois paquets de
  ~3,3 mF, combiné à une NTC. Le MCU pilote les relais, ce qui donne au passage un démarrage propre
  (amplis en PDN, I2C configuré, puis activation).
- ❌ **Ouvert** : référence exacte, cotes à confirmer sur la fiche, implantation.

## 7. Visserie et fixation

- **M3 partout.** Motif des cartes ampli : entraxe 45 × 51 mm (provisoire, voir §8).
- ❌ **Ouvert** : hauteur des entretoises (dépend de l'empilage), matière (nylon ou laiton),
  maintien des cartes debout — le connecteur seul suffit-il, ou faut-il des glissières ?

## 8. Ce qui reste à coter

Rien de ce qui suit n'est bloquant aujourd'hui, mais tout doit tomber avant de router.

1. **Largeur de bride et entraxe minimum des Speakon NL4** — dans le DXF/STEP Neutrik. Le cutout
   (24 mm) et les vis (M3) sont confirmés ; l'entraxe ne l'est pas.
2. ~~Cotes exactes de l'alimentation~~ — **fait** : UHP-350-24, 220 × 62 × 31 mm, sans ventilateur.
   À reconfirmer sur la fiche avant achat.
3. ~~La carte ampli garde-t-elle 54,6 × 60,3 mm ?~~ — **l'implantation a répondu (2026-08-18)** :
   **le rack ne contraint ni la longueur ni la hauteur de la carte.**

   | Dimension | Actuelle | Maximum admis par le rack |
   |---|---|---|
   | Longueur (profondeur) | 54,6 mm | **152,6 mm** |
   | Hauteur | 60,3 mm | **~80 mm** (en gardant 25 mm d'air au-dessus) |
   | Épaisseur | ~12 mm | **bornée par le pas de 20 mm — non négociable** |

   La largeur du rack est consommée par **le pas × 13 cartes = 260 mm**, indépendamment des
   dimensions de la carte. Conclusion : **la taille de la carte ampli se décide sur des critères
   électriques et thermiques, plus mécaniques.** L'argument de garder 54,6 × 60,3 (en 4 couches, la
   surface de cuivre **est** le dissipateur) reste donc le seul en lice — et rien n'interdit
   d'agrandir si le routage le demande.

   ⚠️ **Nouvelle contrainte découverte** : les deux condensateurs de 390 µF font **10 mm de haut**.
   Debout sur la carte, avec un PCB de 1,6 mm, l'enveloppe atteint ~12 mm — il ne reste que **8 mm
   de canal d'air** au pas de 20 mm. Or le pas ne peut pas être élargi : à 25 mm, la largeur totale
   passe à ~496 mm pour 450 utiles. Trois pistes, à arbitrer : coucher les électrolytiques, prendre
   du bulk plus plat, ou **déporter la réserve PVDD sur la carte mère** (une par 4 cartes). Cette
   dernière libérerait beaucoup de place et d'épaisseur, mais éloigne le réservoir de la puce — ce
   qui dégrade justement la réponse aux transitoires qu'il sert à tenir.
4. **Maintien mécanique des cartes debout** — glissières ou connecteur seul.
5. **Débit d'air nécessaire**, nombre et implantation des ventilateurs.
6. **Dessin du panneau arrière** — 13 Speakon + secteur + USB.
7. **Hauteurs d'entretoises**, une fois l'empilage dessiné.

## 9. Points de vigilance

- **Bruit de ventilation dans le lieu d'écoute.** C'est le critère qui a imposé le 3U. À vérifier à
  l'oreille une fois monté, pas seulement sur une fiche technique.
- **Bruit de commutation de l'alimentation** à proximité de l'audio. Une LRS est correcte, mais son
  placement compte.
- **Extraction d'une carte sans outil** — c'est tout l'intérêt du format debout. Si le montage final
  demande un tournevis, on a perdu le bénéfice.
- **25 câbles HP en sortie de coffret** : prévoir le maintien mécanique, sinon la contrainte
  remonte dans les Speakon.
