# Diagnostic et maintenance

> Créé le 2026-08-18. Comment savoir **rapidement ce qui se passe** sur 13 modules et 25 voies,
> depuis un client sur l'ordinateur relié en USB.
>
> Registres relevés dans le datasheet TAS5825M §9.5.3.3 et §9.6 (Table 9-6).

## 1. Pourquoi c'est jouable

Trois décisions prises le 18/08 rendent le diagnostic possible sans matériel supplémentaire :

1. **FAULTZ et WARNZ routés au connecteur**, câblés en OU par carte mère — une broche MCU pour
   quatre amplis.
2. **Adressage I2C par slot** — la Teensy sait quelle puce est physiquement où.
3. **La Teensy est déjà maître I2C** de toutes les puces, via le multiplexeur.

Il ne manque donc que du firmware et un client.

## 2. Ce que la puce sait dire d'elle-même

Le TAS5825M est bien mieux instrumenté qu'un ampli analogique. Registres utiles, relevés dans la
Table 9-6 :

| Registre | Nom | Ce qu'il apporte au diagnostic |
|---|---|---|
| `5Eh` | `PVDD_ADC` | ⭐ **La puce mesure sa propre alimentation.** Avec 13 puces, on obtient **13 points de mesure du rail 24 V** répartis dans le rack — un voltmètre distribué gratuit, qui localise une chute de tension dans la distribution. |
| `38h` | `BCK (SCLK)_MON` | La fréquence d'horloge **réellement vue** par cette puce |
| `37h` | `FS_MON` | La fréquence d'échantillonnage vue par cette puce |
| `39h` | `CLKDET_STATUS` | Détection d'erreur d'horloge |
| `68h` | `POWER_STATE` | État courant (deep sleep / HiZ / play) |
| `67h` | `DIE_ID` | **Test de présence** : si elle répond, le module est vivant sur I2C |
| `4Ch` | `DIG_VOL` | Volume numérique appliqué |
| `50h` | `AUTO_MUTE_CTRL` | Mise en sourdine automatique |

**Les deux registres qui changent tout** :

- **`PVDD_ADC`** transforme un problème d'alimentation diffus (« ça sature en bout de dôme ») en une
  mesure par module. Si la carte mère 3 lit 22,1 V pendant que la 1 lit 23,9 V, la chute dans la
  distribution est chiffrée, pas supposée.
- **`BCK_MON` / `FS_MON`** répondent à la question qui reviendra le plus souvent : *« le module 7
  est muet — est-ce l'audio ou l'horloge ? »* Si la puce voit son horloge, le problème est en aval.

## 3. Les protections et ce qu'elles signalent

D'après §9.5.3.3 :

| Événement | Comportement | Signalé par |
|---|---|---|
| **OCSD** — court-circuit franc | Coupe le canal en **< 100 ns**. Redémarrage possible par I2C. | broche FAULT + registre de défaut |
| **DC Detect** — offset continu en sortie | **FAULTZ passe bas**, sorties en haute impédance | FAULTZ |
| **CBC** — limitation cycle par cycle | Écrête proprement les crêtes, reprise normale à la disparition de la surcharge | transparent |
| **Repli thermique** | Réduit la puissance avant de couper | WARNZ |

⚠️ **Note importante pour la carte sub** : le datasheet précise que **la limitation CBC n'existe
qu'en BTL, pas en PBTL**. Le caisson perd donc la limitation douce et ne garde que l'OCSD, qui coupe
brutalement. Un court-circuit sur le câble du caisson provoquera un arrêt franc là où une voie
normale se contenterait d'écrêter.

## 4. La séquence de démarrage, et pourquoi PDN compte

Le datasheet §9.5.3.1 impose un ordre :

1. Configurer ADR
2. Monter les alimentations (PVDD ou DVDD, l'ordre est indifférent)
3. **PDN à l'état haut, attendre ≥ 5 ms, puis démarrer SCLK et LRCLK**
4. Mettre en HiZ et activer le DSP par I2C
5. Attendre 5 ms, charger les coefficients DSP, passer en Play

C'est la justification concrète du routage de PDN : **la Teensy peut redémarrer proprement un module
sans couper le 24 V de toute la carte mère**. Extinction par le registre `03h` D[1:0]=10 (HiZ) ou par
PDN bas.

Sans PDN piloté, la seule façon de sortir une puce d'un état bloqué serait de couper l'alimentation
des quatre cartes du même slot.

## 5. Le client USB

La Teensy 4.1 peut présenter **plusieurs classes USB simultanément** — le même câble transporte donc
l'audio *et* la télémétrie, sans connexion supplémentaire. *(À confirmer dans les types USB de
Teensyduino au moment du firmware.)*

**Ce que le client devrait montrer**, par ordre d'utilité :

- **Une grille de 13 modules × 2 voies.** Chaque module : présent/absent, défaut, alerte, PVDD lu,
  horloge vue. Un module en défaut se voit sans lire un chiffre.
- **Le rail 24 V par module**, puisqu'on l'a gratuitement. C'est la mesure qui trahit un problème de
  distribution avant qu'il ne devienne audible.
- **Un journal horodaté** des événements. Sur une installation qui tourne, savoir *quand* le module
  7 a fauté vaut mieux que savoir qu'il a fauté.
- **Le niveau par voie**, pour vérifier d'un coup d'œil que les 25 voies reçoivent bien du signal —
  c'est le test qui distingue un problème de routage des slots TDM d'un problème matériel.

**Le protocole n'a pas besoin d'être sophistiqué** : du texte sur le port série USB suffit, et reste
lisible dans un terminal si le client n'est pas lancé. Ne pas inventer un format binaire avant d'en
avoir le besoin.

## 6. Le client sert aussi à régler le filtrage

Le TAS5825M porte **15 biquads par voie**, plus DRC et AGL. Sur un dôme, l'égalisation dépend de la
position de chaque haut-parleur — c'est précisément ce que la spec §7 attend du DSP intégré. Le
client n'est donc pas seulement un moniteur : c'est l'outil de réglage.

### Ne pas recalculer ce que TI calcule déjà

TI fournit **PPC3** (PurePath Console 3), qui conçoit les filtres et **exporte le jeu de
coefficients**. Le datasheet §10.2.3.2 décrit ce flux comme la voie normale. Il ne faut donc pas
écrire un calculateur de biquads : on conçoit dans PPC3, on exporte, et **le client se charge de
pousser les coefficients vers la bonne puce**.
*(À vérifier : PPC3 fonctionne-t-il sans l'EVM de TI branché ?)*

Ce que PPC3 ne sait pas faire et que le client doit apporter : viser **une puce parmi treize**, à
travers la Teensy et le multiplexeur, et régler **en écoutant**, en se déplaçant dans le dôme.

### L'architecture qui découle : la Teensy reste bête

Le client ne parle jamais I2C directement — il demande à la Teensy de le faire.

```
Client (ordinateur)  ──USB série──►  Teensy  ──I2C via mux──►  13 × TAS5825M
   toute l'intelligence              simple relais
```

Le protocole se réduit à trois opérations : **lire un registre**, **écrire un registre**, **et
diffuser la télémétrie**, chacune adressée par numéro de module. Rien de plus.

Le bénéfice est décisif au quotidien : **on itère sur le client sans jamais reflasher la Teensy**.
Sur un an de réglages, c'est la différence entre une boucle de cinq secondes et une de deux minutes.

### Où vivent les coefficients

Trois options, par ordre de préférence :

1. **Fichier sur la carte SD de la Teensy** — un jeu par position dans le dôme, éditable
   centralement, rechargeable sans recompiler. **Recommandé.**
2. Compilés dans le firmware — impose une recompilation à chaque retouche de réglage.
3. EEPROM externe par puce — le TAS5825M sait démarrer sur une EEPROM (registres `56h`-`5Bh`,
   Table 9-6). Élégant mais dispersé : treize mémoires à maintenir au lieu d'un fichier.

### Construire par couches

- **Couche 1 — télémétrie en lecture seule.** Nécessaire de toute façon pour la mise en service,
  et sans risque : on ne peut rien casser en lisant.
- **Couche 2 — écriture de registres.** Volume, mute, PDN, redémarrage d'un module.
- **Couche 3 — coefficients DSP.** Le réglage du dôme proprement dit.

La couche 1 peut démarrer aujourd'hui : elle ne dépend d'aucun choix matériel restant.

## 7. Le déroulé d'un dépannage

1. **Un voyant s'allume** — FAULTZ ou WARNZ d'une carte mère passe bas. Le MCU sait sur quelle carte
   mère, pas sur quelle puce (les lignes sont câblées en OU).
2. **Le MCU interroge les 4 puces** de cette carte mère et lit leurs registres de défaut. Il sait
   maintenant laquelle et pourquoi.
3. **Le client affiche** le module, la nature du défaut, et son historique.
4. **Redémarrage à distance** par PDN ou par I2C, sans toucher au rack.
5. Si le défaut persiste : **la carte se remplace en la débrochant**, sans outil et sans dévisser
   quoi que ce soit — c'est la raison d'être du format debout. Les cartes étant identiques et
   adressées par leur slot, une carte de rechange se met à n'importe quelle place.
6. La carte suspecte part sur la **carte d'adaptation** au banc, où on l'examine une voie à la fois.

## 8. À faire

- [ ] Confirmer les types USB combinés de la Teensy 4.1 (audio + série)
- [ ] Vérifier si PPC3 fonctionne sans l'EVM TI branché
- [ ] Définir le protocole série : lire registre / écrire registre / télémétrie, adressés par module
- [ ] Relever les registres de défaut au-delà de `68h` — la Table 9-6 se poursuit page 45
- [ ] Vérifier si une **lecture de température de puce** existe dans le reste de la table
- [ ] Écrire la couche de lecture I2C (indépendante du matériel, peut démarrer maintenant)
- [ ] Définir le format de télémétrie sur le port série
