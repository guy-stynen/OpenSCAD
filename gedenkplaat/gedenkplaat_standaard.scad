// ============================================================================
//  Standaard voor gedenkplaat (Roc du Maroc Finisher)
//  Plaat: 200 mm breed, ~140 mm hoog, achterkant vlak,
//         voorkant bol: 15 mm dik in het midden -> 7 mm aan de zijkanten (boog).
//  Standaard: 120 mm breed, plaat leunt 10 graden achterover.
//  Printer: FlashForge Adventurer 4 · PLA/PETG · 0.2 mm · 3 wanden · 20% infill
//  Printoriëntatie: zo, plat op de onderkant. Geen support nodig.
// ============================================================================

/* [Plaat] */
plaat_breedte   = 200;   // mm
plaat_dik_mid   = 15;    // dikte in het midden
plaat_dik_rand  = 7;     // dikte aan de zijkant (op 100 mm van het midden)
speling         = 0.6;   // ruimte rondom de plaat in de gleuf

/* [Standaard] */
breedte         = 120;   // totale breedte
hoek            = 10;    // graden achterover
voet_diepte     = 70;    // voor-achter
voet_h          = 5;     // dikte voetplaat (= bodem van de gleuf)
lip_h           = 2;     // hoogte voorste lip boven de gleufbodem (letters staan op 2,5 mm van de onderrand)
lip_wand        = 4;     // dikte voorste lip
rug_h           = 45;    // hoogte achtersteun boven de gleufbodem
rug_dik         = 6;
rug_breedte     = 90;
afronding       = 4;

$fn = 96;

// Boog van de voorkant: cirkel door (0, mid) en (±b/2, rand)
half   = plaat_breedte / 2;
sag    = plaat_dik_mid - plaat_dik_rand;
R      = (half*half + sag*sag) / (2*sag);
cy     = plaat_dik_mid - R;
function dik(x) = sqrt(R*R - x*x) + cy;

echo(str("Plaatdikte aan rand standaard (x=±", breedte/2, "): ", dik(breedte/2), " mm"));

// 2D-doorsnede van de plaat (bovenaanzicht): achterkant op y=0, voorkant naar -y
module plaat_2d(extra=0, xmax=half) {
    stappen = 60;
    pts_voor = [for (i=[0:stappen]) let(x = -xmax + 2*xmax*i/stappen) [x, -(dik(x) + extra)]];
    pts_achter = [[xmax, extra], [-xmax, extra]];
    polygon(concat(pts_voor, pts_achter));
}

// Alles in het "plaatframe": oorsprong = achterkant plaat, op gleufbodem; daarna gekanteld
module kantel() {
    translate([0, 0, voet_h]) rotate([-hoek, 0, 0]) children();
}

module afgerond_blok(b, d, h, r) {
    hull() for (sx=[-1,1], sy=[-1,1])
        translate([sx*(b/2-r), sy*(d/2-r), 0]) cylinder(h=h, r=r);
}

module standaard() {
    difference() {
        intersection() {
            union() {
                // Voetplaat
                translate([0, 0, 0]) afgerond_blok(breedte, voet_diepte, voet_h, afronding);
                // Voorste lip die de boog volgt
                kantel() translate([0,0,-voet_h-2])
                    linear_extrude(lip_h + voet_h + 2)
                        plaat_2d(extra = speling + lip_wand, xmax = breedte/2);
                // Achtersteun met afgeronde bovenhoeken
                kantel() translate([0, speling, -voet_h-2])
                    hull() {
                        translate([-rug_breedte/2, 0, 0]) cube([rug_breedte, rug_dik, 1]);
                        for (sx=[-1,1])
                            translate([sx*(rug_breedte/2 - 8), 0, rug_h + voet_h + 2 - 8])
                                rotate([-90,0,0]) cylinder(h=rug_dik, r=8);
                    }
            }
            // Niets onder de tafel en niet breder dan de standaard
            translate([-breedte/2, -voet_diepte/2, 0]) cube([breedte, voet_diepte, 200]);
        }
        // De gleuf zelf
        kantel() linear_extrude(300) plaat_2d(extra = speling, xmax = half + 5);
    }
}

// Voet loopt 35 mm voor en achter de plaat: stabiel bij 10 graden
standaard();
