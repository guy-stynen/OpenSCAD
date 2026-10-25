// ============================================================================
//  Sleutelhanger: kettingblad-tandwiel met bergsilhouet en mountainbiker
//  Ca. 42 x 48 mm, 4 mm dik – past makkelijk in een broekzak.
//  De lucht is open (doorkijk), bergen met verdiepte sneeuwkappen en mountainbiker.
//  Printer: FlashForge Adventurer 4 · PLA/PETG · 0.2 mm · 100% infill aanbevolen
//  Printoriëntatie: plat, geen support.
//  Tip: pauzeer de print op 3,2 mm en wissel van kleur voor kleurige bergtoppen.
// ============================================================================

/* [Afmetingen] */
buiten_d     = 40;    // diameter over de tanden
tanden       = 22;    // aantal tanden
tand_h       = 2.2;   // hoogte van een tand
ring_breedte = 3.5;   // breedte van de ring binnen de tanden
dikte        = 4;     // totale dikte
relief       = 0.8;   // diepte van de sneeuwkappen/gravure
ring_gat     = 5;     // gat voor de sleutelring
oog_d        = 10;    // diameter van het oog bovenaan

$fn = 72;

wortel_r = buiten_d/2 - tand_h;
binnen_r = wortel_r - ring_breedte;

// --- Tandwiel (kettingblad-stijl, afgeronde tanden) --------------------------
module tandwiel_2d() {
    circle(r = wortel_r + 0.01);
    for (i = [0:tanden-1])
        rotate(i * 360/tanden)
            hull() {
                translate([wortel_r - 0.5, 0]) square([0.5, 360/tanden * PI * wortel_r / 180 * 0.6], center=true);
                translate([buiten_d/2 - 1.0, 0]) circle(r = 1.0, $fn=20);
            }
}

// --- Bergen: grote piek, kleinere piek links, heuvel rechts ------------------
module bergen_2d() {
    polygon([
        [-binnen_r-1, -3], [-12, 2], [-8, 6.5], [-5, 3.5],
        [ 1, 12.5], [ 5, 7.5], [ 8, 9.5], [binnen_r+1, -1],
        [binnen_r+1, -binnen_r-1], [-binnen_r-1, -binnen_r-1]
    ]);
}
module sneeuw_2d() {
    // sneeuwkap grote piek
    polygon([[1,14],[4.8,9.3],[3.6,9.3],[2.2,9.9],[1,8.6],[-0.4,10.0],[-1.8,9.0],[-3,9.0]]);
    // sneeuwkap linkse piek
    polygon([[-8,8],[-5.6,4.9],[-6.6,4.9],[-7.3,5.2],[-8.1,4.4],[-8.9,5.4],[-9.8,5.4]]);
    // sneeuwkap rechtse top
    polygon([[8,11],[10.6,7.7],[9.6,7.7],[8.7,8.2],[7.9,7.4],[6.9,8.4],[6,8.4]]);
}
// Kronkelend pad (mountainbike-trail) naar beneden
module trail_2d() {
    pts = [for (t=[0:0.05:1]) [ -1 + 4*sin(t*360), 6.2 - t*2.6 ]];
    for (i=[0:len(pts)-2]) hull() { translate(pts[i]) circle(r=0.55,$fn=12); translate(pts[i+1]) circle(r=0.55,$fn=12); }
}
// Mountainbike met renner (lijnen van lijn_b breed)
lijn_b = 0.85;
module lijn(a, b) { hull() { translate(a) circle(d=lijn_b,$fn=12); translate(b) circle(d=lijn_b,$fn=12); } }
module mtb_2d() {
    achter = [-5, 0]; voor = [5, 0]; trapas = [-0.3, 0.2];
    zadel = [-1.8, 4.6]; balhoofd = [3.4, 4.4]; stuur = [3.0, 5.9];
    schouder = [1.0, 8.4]; knie = [1.6, 3.6];
    // wielen (met dikke banden)
    for (w = [achter, voor]) translate(w) difference() { circle(r=3.3,$fn=40); circle(r=3.3-lijn_b-0.25,$fn=40); }
    // frame
    lijn(achter, trapas); lijn(trapas, zadel); lijn(zadel, achter);
    lijn(zadel, balhoofd); lijn(trapas, balhoofd); lijn(balhoofd, voor); lijn(balhoofd, stuur);
    // renner
    lijn(zadel + [0, 0.5], schouder);          // romp
    lijn(schouder, stuur);                     // arm
    lijn(zadel + [0, 0.5], knie); lijn(knie, trapas);   // been
    translate(schouder + [1.1, 1.5]) circle(r=1.25,$fn=24);  // hoofd met helm
    // grond onder de wielen
    lijn([-10, -3.75], [10, -3.75]);
}
bike_pos   = [0.5, -8.2];
bike_schaal = 1.0;

// Zon in de lucht
module zon_2d() { translate([-7.6, 10.3]) circle(r = 2.6); }

module sleutelhanger() {
    difference() {
        union() {
            // Ring met tanden
            linear_extrude(dikte) difference() { tandwiel_2d(); circle(r = binnen_r); }
            // Bergen binnen de ring
            linear_extrude(dikte) intersection() { circle(r = binnen_r + 0.5); bergen_2d(); }
            // Zon (iets lager, verbonden met de ring via een straal)
            linear_extrude(dikte - relief) {
                zon_2d();
            }
            // Oog voor de sleutelring
            linear_extrude(dikte) difference() {
                hull() {
                    translate([0, buiten_d/2 + 2.5]) circle(d = oog_d);
                    translate([0, wortel_r - 1]) circle(d = oog_d);
                }
                circle(r = binnen_r);
            }
        }
        translate([0, buiten_d/2 + 2.5, -1]) cylinder(d = ring_gat, h = dikte + 2);
        // Sneeuwkappen en trail verdiept
        translate([0, 0, dikte - relief]) linear_extrude(relief + 1) {
            intersection() { circle(r = binnen_r); union() { sneeuw_2d(); translate(bike_pos) scale(bike_schaal) mtb_2d(); } }
        }
    }
}

sleutelhanger();
