// ============================================================================
//  Open grid 140 x 150 mm, ca. 10 mm dik, vakjes van ongeveer 20 mm
//  De verdeling wordt automatisch berekend: aantal vakken = round(maat / doel)
//  140 / 20 = 7 vakken  -> 20,00 mm hart-op-hart
//  150 / 20 = 7,5 -> 8   -> 18,75 mm hart-op-hart  (dichter bij vierkant dan 7 x 21,4)
//  Printer: FlashForge Adventurer 4 · PLA/PETG · 0.2 mm · plat, geen support
// ============================================================================

/* [Afmetingen] */
breedte   = 140;   // X
lengte    = 150;   // Y
dikte     = 10;    // hoogte van het grid
doel_vak  = 20;    // gewenste vakmaat (hart-op-hart)
wand      = 2;     // dikte van de binnenribben
rand      = 2;     // dikte van de buitenrand
hoek_r    = 2;     // afronding buitenhoeken

nx = max(1, round(breedte / doel_vak));
ny = max(1, round(lengte  / doel_vak));

// Openingen zo verdelen dat alle vakken even groot zijn
open_x = (breedte - 2*rand - (nx-1)*wand) / nx;
open_y = (lengte  - 2*rand - (ny-1)*wand) / ny;

echo(str("Verdeling: ", nx, " x ", ny, " vakken; opening ", open_x, " x ", open_y, " mm"));

module afgeronde_plaat(b, l, h, r) {
    hull() for (x=[r, b-r], y=[r, l-r]) translate([x, y, 0]) cylinder(h=h, r=r, $fn=32);
}

difference() {
    afgeronde_plaat(breedte, lengte, dikte, hoek_r);
    for (i=[0:nx-1], j=[0:ny-1])
        translate([rand + i*(open_x + wand), rand + j*(open_y + wand), -1])
            cube([open_x, open_y, dikte + 2]);
}
