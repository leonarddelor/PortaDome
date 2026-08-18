// =============================================================================
// PortaDome — implantation du coffret 3U
// =============================================================================
//
// But : repondre a « est-ce que ca rentre », et surtout determiner la taille
// que la carte ampli peut avoir. Ce ne sont que des volumes d'encombrement,
// pas des modeles reels — pour les collisions fines, passer par FreeCAD avec
// les STEP d'EasyEDA, Mean Well et Neutrik.
//
// Les echo() en bas verifient les degagements et affichent VERDICT dans la
// console. Change une cote, relance (F5), lis la console.
//
// Voir docs/mecanique-coffret.md
// =============================================================================


/* [Carte ampli — LA variable de l'etude] */

// Longueur, dans le sens de la profondeur du rack (54.6 = carte actuelle)
carte_long      = 54.6;
// Hauteur, du connecteur en bas au bord superieur (60.3 = carte actuelle)
carte_haut      = 60.3;
// Enveloppe en epaisseur : PCB + composants les plus hauts (selfs ~4mm, condos ~10mm)
carte_ep        = 12;
// Pas entre cartes — contraint par la ventilation, ne pas descendre sous 20
carte_pas       = 20;
// Cartes par carte mere
cartes_par_mere = 4;


/* [Rack 3U] */

rack_u          = 3;
rack_larg_utile = 450;   // entre montants
rack_prof       = 300;   // profondeur interne, au choix
tole            = 2;     // epaisseur des toles


/* [Carte mere] */

mere_larg_marge = 10;    // marge de chaque cote des cartes enfichees
mere_prof       = 80;
mere_ep         = 1.6;
mere_z          = 12;    // hauteur des entretoises sous la carte mere
mere_nb         = 3;
mere_ecart      = 12;    // espace entre deux cartes meres

connecteur_h    = 11;    // hauteur du couple embase male + femelle accouple


/* [Carte MCU] */

mcu_larg        = 100;
mcu_prof        = 80;


/* [Alimentation — Mean Well UHP-350-24] */

alim_long       = 220;
alim_larg       = 62;
alim_haut       = 31;


/* [Ventilation] */

vent_dia        = 120;
vent_ep         = 25;
vent_nb         = 2;


/* [Speakon NL4 — face arriere] */

// ATTENTION : cutout 24mm et vis M3 confirmes. L'entraxe ci-dessous est une
// ESTIMATION — le prendre dans le DXF Neutrik avant de percer quoi que ce soit.
spk_cutout      = 24;
spk_pas         = 34;    // <<< A CONFIRMER SUR DXF NEUTRIK
spk_nb          = 13;
spk_rangees     = 2;
spk_ecart_rang  = 45;


/* [Affichage] */

montrer_rack    = true;
montrer_cartes  = true;
montrer_alim    = true;
montrer_vent    = true;
montrer_panneau = true;
eclate          = 0;     // ecarte les blocs en Z pour y voir clair


// =============================================================================
// Valeurs derivees
// =============================================================================

rack_haut    = rack_u * 44.45;
rack_h_utile = rack_haut - 2 * tole;

mere_larg    = cartes_par_mere * carte_pas + 2 * mere_larg_marge;
meres_larg   = mere_nb * mere_larg + (mere_nb - 1) * mere_ecart;
larg_totale  = meres_larg + mere_ecart + mcu_larg;

// hauteur du sommet de la carte ampli au-dessus du plancher
pile_haut    = mere_z + mere_ep + connecteur_h + carte_haut;

// profondeur occupee par une rangee carte mere + alim derriere
prof_occupee = mere_prof + 20 + alim_larg;

spk_par_rang = ceil(spk_nb / spk_rangees);
spk_larg     = spk_par_rang * spk_pas;

vent_larg    = vent_nb * vent_dia;


// =============================================================================
// Modules
// =============================================================================

module carte_ampli() {
    color("SeaGreen", 0.85)
        cube([carte_ep, carte_long, carte_haut]);
}

module bloc_mere() {
    // la carte mere elle-meme
    color("DarkSlateBlue", 0.9)
        translate([0, 0, mere_z])
            cube([mere_larg, mere_prof, mere_ep]);

    // les cartes ampli debout dessus
    if (montrer_cartes)
        for (i = [0 : cartes_par_mere - 1])
            translate([mere_larg_marge + i * carte_pas + (carte_pas - carte_ep) / 2,
                       (mere_prof - carte_long) / 2,
                       mere_z + mere_ep + connecteur_h])
                carte_ampli();

    // le volume des connecteurs, pour voir la place qu'ils prennent
    color("Goldenrod", 0.6)
        for (i = [0 : cartes_par_mere - 1])
            translate([mere_larg_marge + i * carte_pas + (carte_pas - carte_ep) / 2,
                       (mere_prof - carte_long) / 2,
                       mere_z + mere_ep])
                cube([carte_ep, carte_long, connecteur_h]);
}

module bloc_mcu() {
    color("DarkSlateBlue", 0.9)
        translate([0, 0, mere_z])
            cube([mcu_larg, mcu_prof, mere_ep]);

    // 1 carte ampli (le sub) + volume Teensy
    if (montrer_cartes) {
        translate([mere_larg_marge, (mcu_prof - carte_long) / 2,
                   mere_z + mere_ep + connecteur_h])
            carte_ampli();

        color("Firebrick", 0.85)
            translate([mcu_larg - 70, 10, mere_z + mere_ep])
                cube([61, 18, 8]);   // Teensy 4.1
    }
}

module bloc_alim() {
    color("Silver", 0.9)
        cube([alim_long, alim_larg, alim_haut]);
}

module ventilateur() {
    color("DimGray", 0.7)
        rotate([-90, 0, 0])
            difference() {
                translate([-vent_dia/2, -vent_dia/2, 0])
                    cube([vent_dia, vent_dia, vent_ep]);
                translate([0, 0, -1]) cylinder(d = vent_dia - 8, h = vent_ep + 2, $fn = 64);
            }
}

module panneau_arriere() {
    color("Gainsboro", 0.5)
        difference() {
            cube([rack_larg_utile, tole, rack_h_utile]);

            // les cutouts Speakon
            for (r = [0 : spk_rangees - 1])
                for (i = [0 : spk_par_rang - 1])
                    if (r * spk_par_rang + i < spk_nb)
                        translate([(rack_larg_utile - spk_larg) / 2 + spk_pas/2 + i * spk_pas,
                                   -1,
                                   rack_h_utile/2 - (spk_rangees-1)*spk_ecart_rang/2 + r * spk_ecart_rang])
                            rotate([-90, 0, 0])
                                cylinder(d = spk_cutout, h = tole + 2, $fn = 32);
        }
}

module enveloppe_rack() {
    color("LightSteelBlue", 0.12)
        cube([rack_larg_utile, rack_prof, rack_h_utile]);
}


// =============================================================================
// Assemblage
// =============================================================================

if (montrer_rack) enveloppe_rack();

// les 3 cartes meres, alignees a l'avant derriere les ventilateurs
for (m = [0 : mere_nb - 1])
    translate([m * (mere_larg + mere_ecart), vent_ep + 15, 0])
        bloc_mere();

// la carte MCU a droite
translate([meres_larg + mere_ecart, vent_ep + 15, 0])
    bloc_mcu();

// l'alimentation, derriere, en aval du flux
if (montrer_alim)
    translate([(rack_larg_utile - alim_long) / 2,
               vent_ep + 15 + mere_prof + 20,
               eclate])
        bloc_alim();

// les ventilateurs en facade
if (montrer_vent)
    for (v = [0 : vent_nb - 1])
        translate([(rack_larg_utile - vent_larg) / 2 + vent_dia/2 + v * vent_dia,
                   0,
                   rack_h_utile / 2])
            ventilateur();

if (montrer_panneau)
    translate([0, rack_prof, 0]) panneau_arriere();


// =============================================================================
// Verifications — lire la console apres F5
// =============================================================================

echo();
echo("========== PortaDome / implantation 3U ==========");
echo(str("Carte ampli etudiee : ", carte_long, " x ", carte_haut, " mm"));
echo();

// --- largeur ---
marge_larg = rack_larg_utile - larg_totale;
echo(str("LARGEUR  occupee ", larg_totale, " / ", rack_larg_utile,
         " mm   -> marge ", marge_larg, " mm  ",
         marge_larg >= 0 ? "OK" : "### DEPASSE ###"));

// --- hauteur ---
marge_haut = rack_h_utile - pile_haut;
echo(str("HAUTEUR  pile ", pile_haut, " / ", rack_h_utile,
         " mm   -> degagement au-dessus ", marge_haut, " mm  ",
         marge_haut >= 25 ? "OK (air)" :
         marge_haut >= 0  ? "JUSTE — peu de place pour l'air" : "### DEPASSE ###"));

// --- profondeur ---
prof_totale = vent_ep + 15 + prof_occupee;
marge_prof  = rack_prof - prof_totale;
echo(str("PROFONDEUR occupee ", prof_totale, " / ", rack_prof,
         " mm   -> marge ", marge_prof, " mm  ",
         marge_prof >= 0 ? "OK" : "### DEPASSE ###"));

// --- panneau arriere ---
echo(str("PANNEAU  ", spk_nb, " Speakon en ", spk_rangees, " rangees de ", spk_par_rang,
         " -> ", spk_larg, " / ", rack_larg_utile, " mm  ",
         spk_larg <= rack_larg_utile ? "OK" : "### DEPASSE ###",
         "   (pas ", spk_pas, " mm A CONFIRMER SUR DXF NEUTRIK)"));

// --- ventilation ---
echo(str("VENTILO  ", vent_nb, " x ", vent_dia, " mm -> ", vent_larg, " mm de facade  ",
         vent_dia <= rack_h_utile ? "OK en hauteur" : "### TROP HAUT POUR CE U ###"));

echo();
echo("--- Ce que l'implantation autorise pour la carte ampli ---");
echo(str("  LONGUEUR : peut passer de ", carte_long, " a ",
         carte_long + marge_prof, " mm   (marge en profondeur du rack)"));
echo(str("  HAUTEUR  : peut passer de ", carte_haut, " a ",
         carte_haut + marge_haut - 25, " mm   (en gardant 25 mm d'air au-dessus)"));
echo(str("  EPAISSEUR : bornee par le pas de ", carte_pas,
         " mm, lui-meme contraint par la ventilation — NON negociable"));
echo();
echo(str("La largeur du rack est consommee par le pas x 13 cartes = ",
         (mere_nb * cartes_par_mere + 1) * carte_pas,
         " mm. C'est le pas qui borne, pas les dimensions de la carte."));
echo("=================================================");
