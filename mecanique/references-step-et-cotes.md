# Modèles STEP et cotes de référence

> Document de travail pour l'assemblage FreeCAD du coffret 3U.
> Voir [`../docs/mecanique-coffret.md`](../docs/mecanique-coffret.md) pour les décisions,
> et [`implantation-3u.scad`](./implantation-3u.scad) pour l'étude d'encombrement paramétrique.
>
> ⚠️ **Statut des cotes** : ce document distingue explicitement ce qui a été **vérifié** de ce qui
> reste **estimé**. Ne pas percer, commander ou router sur une cote estimée.

## 1. Modèles STEP à récupérer

| Pièce | Où | Notes |
|---|---|---|
| **Carte ampli** | Export depuis EasyEDA Pro | `Fichier → Exporter → STEP` (ou 3D). Donne le contour, les composants et leurs hauteurs réelles — c'est la pièce la plus importante de la liste. |
| **Carte mère** | À créer | N'existe pas encore. En attendant, une plaque de 100 × 80 × 1,6 mm suffit à réserver le volume. |
| **Speakon NL4MP** | [neutrik.com](https://www.neutrik.com/en/product/nl4mp) → onglet Downloads | Neutrik publie **STEP et DXF**. Le DXF donne le gabarit de perçage du panneau, le STEP le volume de la fiche accouplée. **Prendre les deux.** |
| **Mean Well UHP-350-24** | [meanwell.com](https://www.meanwell.com) → fiche produit → section Download | Mean Well fournit les 3D. Récupérer aussi le plan coté pour les trous de fixation. |
| **Embases 2,54 mm** (2×4 et 2×8) | Site du fabricant (Wurth, Samtec, Harwin), ou SnapEDA / Ultra Librarian / ComponentSearchEngine | Prendre le **couple accouplé** mâle + femelle, pas seulement l'embase : c'est la hauteur accouplée qui compte pour la pile. |
| **Ventilateur 120 mm** | Noctua et Arctic publient des STEP | Un cube de 120 × 120 × 25 mm suffit pour l'encombrement ; le STEP réel sert surtout pour les trous de fixation. |
| **Châssis rack 19" 3U** | Hammond, Schroff, Rittal — tous publient des STEP | Décider d'abord si le châssis est acheté ou fabriqué. S'il est acheté, son STEP devient la référence de tout l'assemblage. |
| **Teensy 4.1** | GrabCAD, ou cotes PJRC | Modèles communautaires. Contour officiel : 61 × 18 mm. |
| **Entretoises et visserie** | [mcmaster.com](https://www.mcmaster.com) | Chaque référence a son STEP téléchargeable. C'est la source la plus rapide pour la visserie. Alternative : TraceParts. |
| **Entrée secteur CEI** | Schurter publie des STEP | Choisir le modèle (avec ou sans porte-fusible et interrupteur) avant de dessiner le panneau. |

## 2. Cotes vérifiées

Ces valeurs ont été relevées sur les fichiers de fabrication ou les fiches constructeur.

### Carte ampli (état 2026-08-18, avant refonte)

| Cote | Valeur | Source |
|---|---|---|
| Contour | **54,610 × 60,325 mm** | mesuré sur `Gerber_BoardOutlineLayer.GKO` |
| Trous de fixation | **4 × Ø 3,30 mm** | `Drill_NPTH_Through.DRL`, outil unique |
| Entraxe | **45,000 × 51,000 mm** | idem |
| Positions (depuis coin bas-gauche) | (4,805 / 55,662) · (49,805 / 55,662) · (4,805 / 4,662) · (49,805 / 4,662) | idem |
| Marges au bord | 4,805 mm gauche/droite · 4,66 mm haut/bas | calculé |

⚠️ Ces cotes valent pour la carte **actuelle**. La refonte peut les changer — mais l'implantation a
établi que **le rack ne contraint ni la longueur ni la hauteur** (jusqu'à 152 et 80 mm).

### Rack

| Cote | Valeur |
|---|---|
| 1 U | 44,45 mm |
| 3 U | 133,35 mm |
| Largeur panneau 19" | 482,6 mm |
| Largeur interne utile | ~450 mm |

### Alimentation Mean Well UHP-350-24

| Cote | Valeur |
|---|---|
| Encombrement | **220 × 62 × 31 mm** |
| Puissance | 350 W, 24 V, 14,6 A |
| Refroidissement | **convection, sans ventilateur** |
| Rendement | 94 % |

### Speakon Neutrik, série D

| Cote | Valeur |
|---|---|
| Perçage panneau | **24 mm** (23,8 mm) |
| Vis de fixation | **M3**, 2 par connecteur |

## 3. Cotes à vérifier avant de figer quoi que ce soit

| Cote | Pourquoi elle compte | Où la prendre |
|---|---|---|
| **Composant le plus haut de la carte ampli** | ⚠️ **La plus critique.** Elle fixe l'enveloppe en épaisseur, donc le canal d'air entre cartes — aujourd'hui estimé à 8 mm seulement. Estimation actuelle : condensateurs 390 µF à ~10,3 mm (d'après l'empreinte `CAP-SMD_BD10.0-L10.3-W10.3`). | STEP EasyEDA, ou fiche du condensateur et de la self |
| **Hauteur des selfs** Chilisin MHCI06024 | Deuxième composant le plus haut, potentiellement limitant | fiche Chilisin (`C280584`) |
| **Largeur de bride et entraxe mini des NL4** | Décide entre 1 rangée de 13 et 2 rangées de 7 sur le panneau. Estimation actuelle : 34 mm de pas | DXF Neutrik |
| **Hauteur accouplée des embases 2,54 mm** | Entre dans la hauteur de pile. Estimation actuelle : 11 mm | fiche du connecteur retenu |
| **Trous de fixation de l'alimentation** | Position et filetage | plan coté Mean Well |
| **Profondeur réelle du châssis** | Aujourd'hui prise à 300 mm arbitrairement, avec 98 mm inutilisés | catalogue du châssis retenu |

## 4. Vérifications à faire une fois assemblé dans FreeCAD

Ce que le modèle de volumes ne peut pas dire, et que l'assemblage réel dira :

1. **Canal d'air réel entre deux cartes ampli voisines.** C'est la contrainte identifiée : au pas de
   20 mm avec une enveloppe de ~12 mm, il ne reste que 8 mm. Mesurer entre les composants les plus
   hauts de deux cartes adjacentes, pas entre les PCB.
2. **Collision connecteur ↔ entretoises** sous les cartes mères.
3. **Dégagement des fiches Speakon accouplées** en face arrière — le corps de la fiche câble est
   nettement plus gros que le connecteur panneau, et c'est lui qui borne l'entraxe utilisable.
4. **Rayon de courbure des 25 câbles HP** en sortie de panneau, et leur maintien mécanique.
5. **Chemin d'air** : vérifier qu'aucun volume ne fait écran entre les ventilateurs et les cartes,
   et que l'alimentation est bien en aval.
6. **Accès à l'extraction d'une carte ampli** : peut-on la sortir sans outil et sans démonter autre
   chose ? C'est tout l'intérêt du format debout, et c'est le genre de chose qui ne se voit qu'en 3D.
7. **Longueurs d'entretoises** : les déduire de l'assemblage plutôt que de les choisir a priori.
8. **Accès au câblage secteur** et distance de sécurité par rapport aux cartes.

## 5. Ordre suggéré

1. **Exporter la carte ampli en STEP** depuis EasyEDA — c'est la pièce qui débloque le reste, et
   elle donne la hauteur du composant le plus haut, la cote la plus critique de la liste §3.
2. **Choisir le châssis** (acheté ou fabriqué). Son STEP devient la référence de l'assemblage.
3. Importer alimentation, Speakon, ventilateurs.
4. Placer, puis dérouler les vérifications du §4.
5. **Reporter dans `docs/mecanique-coffret.md`** toute cote que l'assemblage tranche — en
   particulier la §8 « ce qui reste à coter ».
