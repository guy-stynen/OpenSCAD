// Tesla Model Y (2020–2024) — Gen‑2 front centre console sliding-lid organizer
// Drop-in tray that rides on the felt rails and slides forward to reach the lower bay / USB ports.
//
// Fit basis (aftermarket Gen‑2 trays): ~165 × 130 × 60 mm.
// This design is slightly longer (145 mm) so pockets stay reachable under the lid,
// and a touch wider for the Model Y upper tray (often ~4 mm wider than Model 3).
// Measure your console and tweak the parameters below before printing.
//
// Print: PETG or ABS/ASA (cabin heat). 0.2 mm layers, 3–4 perimeters, 20–40% infill.
// Orientation: print open-side up. No supports needed.

/* [Fit — measure and adjust] */
overall_w = 167;   // left–right (mm). Start 165–169.
overall_l = 145;   // front–back (mm). Longer = harder to hide under the lid.
overall_h = 55;    // tray height (mm). Leave clearance to the closed lid.
wall = 2.0;
floor_t = 2.2;
corner_r = 5.0;

/* [Rail lips] */
lip_overhang = 4.0;       // each side, sits on console felt rails
lip_thickness = 2.4;
lip_inset_from_ends = 8.0;

/* [Layout] */
divider = 1.8;
front_row_depth = 38;     // card / coin / pen strip (screen end)
card_slot_w = 28;
coin_well_w = 42;
cable_notch_w = 18;
cable_notch_d = 12;
cable_notch_h = 14;       // from floor up — pass a USB cable through

/* [Quality] */
$fn = 48;

module rounded_rect(size, r) {
    x = size[0]; y = size[1]; z = size[2];
    r2 = min(r, x/2 - 0.01, y/2 - 0.01);
    hull() {
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (x/2 - r2), sy * (y/2 - r2), 0])
                cylinder(h = z, r = r2);
    }
}

module shell() {
    union() {
        difference() {
            rounded_rect([overall_w, overall_l, overall_h], corner_r);
            translate([0, 0, floor_t])
                rounded_rect([
                    overall_w - 2*wall,
                    overall_l - 2*wall,
                    overall_h
                ], max(0.5, corner_r - wall));
        }

        // Side lips for the felt rails
        for (sx = [-1, 1]) {
            translate([
                sx * (overall_w/2 + lip_overhang/2),
                0,
                overall_h - lip_thickness/2
            ])
                cube([
                    lip_overhang,
                    max(10, overall_l - 2*lip_inset_from_ends),
                    lip_thickness
                ], center = true);
        }
    }
}

module dividers() {
    inner_w = overall_w - 2*wall;
    h = overall_h - floor_t - 0.2;
    front_y = overall_l/2 - wall - front_row_depth/2;

    // Cross-wall: front strip vs main bay
    translate([0, overall_l/2 - wall - front_row_depth, floor_t + h/2])
        cube([inner_w, divider, h], center = true);

    // Coin | cards | pens splits in the front strip
    x_coin_cards = -inner_w/2 + coin_well_w;
    translate([x_coin_cards, front_y, floor_t + h/2])
        cube([divider, front_row_depth, h], center = true);

    x_cards_pens = x_coin_cards + card_slot_w;
    translate([x_cards_pens, front_y, floor_t + h/2])
        cube([divider, front_row_depth, h], center = true);
}

module cable_notch() {
    // Cup-holder / USB end — feed a cable from the ports below
    translate([0, -overall_l/2 + cable_notch_d/2 - 0.1, floor_t + cable_notch_h/2 - 0.01])
        cube([cable_notch_w, cable_notch_d + wall, cable_notch_h + 0.2], center = true);
    translate([0, -overall_l/2 + cable_notch_d/2, -0.1])
        cube([cable_notch_w - 2, cable_notch_d, floor_t + 0.3], center = true);
}

difference() {
    union() {
        shell();
        dividers();
    }
    cable_notch();
}
