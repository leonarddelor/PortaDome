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

❌ **Ouvert** : l'implantation exacte. 3 cartes mères (~300 mm) + alim (~215 mm) = 515 mm pour
450 mm utiles : **elles ne tiennent pas sur une seule rangée**. Le 3U permet de superposer, à
dessiner.

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

✅ **Décidé** : **ventilation forcée**, flux **avant-arrière**, parallèle aux faces des cartes.

Les cartes debout créent naturellement des canaux d'air. **Le pas de 20 mm est contraint par ça** —
resserrer à 15 mm pour gagner de la place étranglerait les canaux.

**Ce que la ventilation rend** : le budget thermique passe d'environ **27 W à ~40 W continus par
puce** (le θJA baisse quand l'air balaie le cuivre, et l'ambiant interne reste proche de la pièce au
lieu de grimper). ⚠️ **Ordre de grandeur à mesurer, pas à croire.**

**Pilotage** : le MCU dispose déjà de **WARNZ** (routé au connecteur) pour accélérer les
ventilateurs à l'approche du repli thermique. Mieux encore si la puce expose une lecture de
température par I2C — **à chercher dans la table des registres, datasheet §9.6**. Si elle existe, on
régule en continu au lieu de réagir à une alerte.

L'alimentation est placée **en aval du flux**, pour ne pas préchauffer les amplis.

❌ **Ouvert** : débit nécessaire (à calculer), nombre de ventilateurs, filtre à l'entrée ou non
(un filtre ajoute de la restriction et de la maintenance).

## 6. Alimentation

Voir [spec §8](./proposition-carte-octo-dome.md) pour le dimensionnement.

- ✅ **Décidé** : à l'intérieur du rack si la place le permet. Famille **Meanwell LRS**, refroidie
  par convection donc **sans ventilateur propre** — elle profite du flux du coffret et n'ajoute
  aucun bruit.
- **Calibre : 400-450 W en 24 V.** Les 500-600 W de la spec étaient estimés sur ~38 W/voie ; à
  ~30 W réels et compte tenu du plafond thermique des puces (~325 W de sortie soutenue pour
  24 voies), 450 W est le bon calibre avec de la marge pour les crêtes.
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

1. **Pas minimum entre Speakon NL4** — sur le dessin mécanique Neutrik. Décide si 7 par rangée
   passent sur 450 mm utiles.
2. **Cotes exactes de l'alimentation** — sur la fiche Meanwell.
3. **La carte ampli garde-t-elle 54,6 × 60,3 mm ?** Décision volontairement rouverte : c'est
   l'implantation mécanique qui doit trancher, pas une préférence a priori. Argument pour garder :
   en 4 couches, la surface de cuivre **est** le dissipateur, et le thermique est la contrainte
   qui borne le système.
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
