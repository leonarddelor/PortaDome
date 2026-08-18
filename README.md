# PortaDome

Dôme démontable de **25 haut-parleurs** diffusant une bande son **synchronisée à l'échantillon
près** sur toutes les voies. Projet étudiant, ~1 an, rythme soutenu.

Le parti pris qui commande tout le reste : **une seule Teensy est le cerveau**, maître d'horloge
unique pour les 25 voies via 2 ports TDM. Rien d'autre n'a d'horloge propre — c'est ce qui interdit
la dérive entre haut-parleurs voisins.

---

## ⚠️ État au 2026-08-18 — à lire avant tout

Le dépôt contient **deux générations de carte ampli**. Ne pas les confondre :

| | Carte proto mono-puce | **Carte ampli v2** |
|---|---|---|
| État | Routée, gerbers vérifiés | **À concevoir** |
| Commandée ? | **Non, et ne le sera pas** | pas encore |
| Rôle aujourd'hui | **Référence** — valeurs vérifiées au datasheet et défauts trouvés | la carte qu'on construit |

**Le proto ne sera pas fabriqué.** Le projet a de l'avance, et une session de conception système le
18/08 a fait apparaître cinq écarts entre cette carte et ce dont le dôme a besoin — tous sur ses
**interfaces**, aucun visible en relisant son schéma. La refonte les corrige d'un coup.

Le document du proto reste précieux : il porte les valeurs vérifiées contre le datasheet et
l'historique des défauts trouvés, qui ne doivent pas être refaits.

---

## Ce qu'on construit

```
Ordinateur (USB)  ─┐
                   ├─► Teensy 4.1 ─TDM/I2C─► 3 cartes mères × 4 cartes ampli ─► 24 HP 8 Ω
Carte SD (secours) ─┘        (maître          + 1 carte MCU × 1 carte ampli   ─► 1 sub 4 Ω
                              d'horloge)         (PBTL)
```

Le tout dans un **rack 19" 3U ventilé**, cartes ampli **debout et débrochables**, sorties en
**Speakon NL4**. Budget estimé : **~920 $** hors haut-parleurs.

---

## Les documents

| Fichier | Ce qu'il contient |
|---|---|
| [`docs/architecture-systeme.md`](docs/architecture-systeme.md) | **Commencer par là.** Carte des décisions sur 9 sous-systèmes : ce qui est décidé, ce qui est ouvert, et le graphe de ce qui bloque quoi. |
| [`docs/proposition-carte-octo-dome.md`](docs/proposition-carte-octo-dome.md) | Proposition technique. Le §7 porte le cahier des charges de la carte ampli v2. |
| [`docs/mecanique-coffret.md`](docs/mecanique-coffret.md) | Rack 3U, cartes debout, ventilation push-pull, connectique. |
| [`docs/proto-ampli-tas5825m.md`](docs/proto-ampli-tas5825m.md) | Suivi du proto. **Le §7 liste les défauts trouvés** — à ne pas refaire. |
| [`docs/carte-adaptation.md`](docs/carte-adaptation.md) | Le slot de carte mère construit seul, pour tester les cartes ampli au banc. |
| [`docs/diagnostic-et-maintenance.md`](docs/diagnostic-et-maintenance.md) | Ce que les puces savent dire d'elles-mêmes, et le client USB de réglage et de dépannage. |
| [`docs/budget-coffret.html`](docs/budget-coffret.html) | Chiffrage par poste, avec niveau de confiance par ligne. |
| [`docs/projet-etudiant-feuille-de-route.md`](docs/projet-etudiant-feuille-de-route.md) | Méthode de travail, conventions git, glossaire. |
| [`mecanique/implantation-3u.scad`](mecanique/implantation-3u.scad) | Étude d'encombrement paramétrique. `F5` dans OpenSCAD, lire la console. |
| [`mecanique/references-step-et-cotes.md`](mecanique/references-step-et-cotes.md) | Où trouver chaque STEP, et quelles cotes sont vérifiées ou estimées. |

---

## Le travail à faire

Cinq chantiers. Les phases B et C **ne dépendent de rien** et peuvent démarrer immédiatement.

### A · Carte ampli v2 — le chemin critique

1. **Nettoyer le schéma existant.** Trois références LCSC manquantes (10 kΩ, 4,7 kΩ, 1 µF) et une
   contamination : la référence du 470 nF a été recopiée sur des lignes déclarées 100 nF et 680 nF.
   À corriger avant de dupliquer le projet, sinon ça se propage.
2. **Modifier le schéma** : router `PDN`, `FAULTZ`, `WARNZ` et `ADR` vers le connecteur ; supprimer
   CN1 et U3 ; passer les 22 µF PVDD en CMS ; strap PBTL **après** le filtre LC.
3. **Router en 4 couches**, plan GND continu en couche 2, connecteurs sur le bord inférieur
   (2×4 puissance + 2×8 signal), vias thermiques **dans l'empreinte** de U1.
4. **Exporter en STEP** → débloque la phase D et donne la cote la plus critique du projet : la
   hauteur du composant le plus haut, dont dépend le canal d'air de 8 mm entre cartes.
5. **Commander**, avec la carte d'adaptation ci-dessous.

### B · Carte d'adaptation 1 slot — à concevoir en parallèle

La carte v2 n'a plus de bornier : elle ne peut être testée qu'enfichée. Or la carte mère n'existera
pas avant des semaines, et les fils Dupont (~1 A) ne supportent ni les 3,4 A de PVDD ni les 2,1 A de
sortie.

Un petit 2 couches portant les deux embases femelles, un bornier PVDD, un bornier HP, un header
signaux vers XIAO ou Teensy 3.6, la résistance ADR et des trous de fixation. ~10 $ les 5.

**Cette carte est un slot de la carte mère.** La concevoir valide le circuit du slot avant de le
répliquer ×4 — c'est isoler les variables, pas faire un détour.

### C · Firmware et client — indépendants de tout le matériel

Peut démarrer aujourd'hui. Init I2C du TAS5825M à réécrire (le driver Sonocotta cible le TAS5805M),
configuration des GPIO0/1/2 en `WARNZ`/`FAULTZ` (registres `60h`-`63h`), I2S stéréo d'abord puis
TDM, répartition des slots conforme à `architecture-systeme.md` §4.

Côté ordinateur, un **client USB** de réglage et de dépannage (voir
[`diagnostic-et-maintenance.md`](docs/diagnostic-et-maintenance.md)). La Teensy n'est qu'un relais
I2C : toute l'intelligence est dans le client, ce qui permet d'itérer sur les réglages **sans
reflasher**.

### D · Mécanique — après l'export STEP

Assemblage FreeCAD à partir des vrais modèles (voir `mecanique/references-step-et-cotes.md`).
Vérifier en priorité le **canal d'air réel entre deux cartes voisines** : estimé à 8 mm, et le pas
de 20 mm ne peut pas être élargi sans faire déborder le rack.

### E · Carte mère ×4 — après validation du slot en phase B

4 couches avec plan PVDD (13,6 A pour 4 slots), buck 24 V → 3,3 V, multiplexeur I2C, `FAULTZ`/`WARNZ`
câblés en OU, adressage par slot.

---

## Les deux décisions qui débloquent le plus

1. **Choisir le haut-parleur.** L'impédance est figée (8 Ω), le modèle non. Budget d'alimentation,
   section des câbles et géométrie du châssis en dépendent tous.
2. **Acheter ou fabriquer le châssis.** L'écart va de 60 à 250 $, soit près de 20 % du budget.

## Le piège connu

**~10 mF de capacité de réserve cumulée** sur 13 cartes. Une alimentation de 350 W part en sécurité
ou fait disjoncter au premier allumage, et aucune précharge n'est prévue. C'est le seul défaut de la
liste qui se manifeste par « rien ne démarre » sans indiquer sa cause. Solution notée : séquencer
les 3 cartes mères à ~200 ms d'écart, plus une NTC.

---

## Conventions

Un commit = une idée ; le message explique **pourquoi**, pas seulement quoi. Toute affirmation
matérielle (broche, référence, valeur de registre) se recoupe contre le datasheet officiel — y
compris celles produites par un assistant. **La mesure gagne sur l'affirmation.** Les décisions se
consignent dans les documents datés, pas dans un historique de conversation.
