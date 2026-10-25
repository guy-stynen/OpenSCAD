// ============================================================================
//  Minimalistische standaard voor gedenkplaat (Roc du Maroc Finisher)
//  Zo weinig mogelijk zichtbaar: vooraan enkel een lipje van 2 mm,
//  alles anders zit verstopt achter de plaat (< 30 mm hoog).
//  Plaat: 200 mm breed, achterkant vlak, voorkant boog 15 -> 7 mm.
//  Plaat leunt 10° achterover; daardoor kan hij niet naar voren kantelen
//  en volstaan twee driehoekige steunpoten achteraan.
//  Printer: FlashForge Adventurer 4 · PLA/PETG · 0.2 mm · 3 wanden · 30% infill
//  Printoriëntatie: zo, plat op de onderkant. Geen support nodig.
// ============================================================================

/* [Plaat] */
plaat_breedte   = 200;
plaat_dik_mid   = 15;
plaat_dik_rand  = 7;
speling         = 0.6;

/* [Standaard] */
breedte         = 120;   // breedte van de wieg
hoek            = 10;    // graden achterover
bodem           = 3;     // dikte onder de gleuf
lip_h           = 2;     // letters staan op 2,5 mm van de onderrand
lip_wand        = 2.4;   // dikte voorste lip (6 lagen bij 0,4 mm nozzle)
rug_h           = 25;    // hoogte achterwand boven de gleufbodem
rug_dik         = 3;
poot_lengte     = 35;    // hoe ver de steunpoten naar achter lopen
poot_dik        = 4;
poot_inzet      = 8;     // afstand van de poot tot de zijkant van de wieg

$fn = 96;

half = plaat_breedte / 2;
sag  = plaat_dik_mid - plaat_dik_rand;
R    = (half*half + sag*sag) / (2*sag);
cy   = plaat_dik_mid - R;
function dik(x) = sqrt(R*R - x*x) + cy;

module plaat_2d(extra_voor=0, extra_achter=0, xmax=half) {
    n = 60;
    voor = [for (i=[0:n]) let(x = -xmax + 2*xmax*i/n) [x, -(dik(x) + extra_voor)]];
    polygon(concat(voor, [[xmax, extra_achter], [-xmax, extra_achter]]));
}

module kantel() { translate([0, 0, bodem]) rotate([-hoek, 0, 0]) children(); }

module standaard() {
    difference() {
        intersection() {
            union() {
                // Wieg: lip vooraan + bodem
                kantel() translate([0, 0, -bodem - 4])
                    linear_extrude(lip_h + bodem + 4)
                        plaat_2d(speling + lip_wand, speling + rug_dik, breedte/2);
                // Achterwand (verstopt achter de plaat), afgeronde bovenhoeken
                kantel() translate([0, speling, -bodem - 4])
                    hull() {
                        translate([-breedte/2, 0, 0]) cube([breedte, rug_dik, 1]);
                        for (sx=[-1,1])
                            translate([sx*(breedte/2 - 5), 0, rug_h + bodem + 4 - 5])
                                rotate([-90,0,0]) cylinder(h=rug_dik, r=5);
                    }
                // Twee driehoekige steunpoten naar achter
                for (sx=[-1,1])
                    translate([sx*(breedte/2 - poot_inzet) - poot_dik/2, 0, 0])
                        rotate([90,0,90]) linear_extrude(poot_dik)
                            hull() {
                                square([poot_lengte, 3]);
                                translate([0, 0]) square([1, rug_h * 0.8]);
                            }
            }
            translate([-breedte/2, -40, 0]) cube([breedte, 40 + poot_lengte + 5, 100]);
        }
        kantel() linear_extrude(300) plaat_2d(speling, speling, half + 5);
    }
}

standaard();
