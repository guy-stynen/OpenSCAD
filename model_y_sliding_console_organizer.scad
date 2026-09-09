// Tesla Model Y (2020–2024) — Gen‑2 front centre console sliding-lid organizer
// Holds: credit/e-charge cards · coins · pens · sunglasses
//
// Fit basis (aftermarket Gen‑2 trays): ~165 × 130 × 60 mm.
// Slightly longer (145 mm) so pockets stay reachable under the lid.
// Measure your console and tweak the parameters below before printing.
//
// Print: PETG or ABS/ASA (cabin heat). 0.2 mm layers, 3–4 perimeters, 20–40% infill.
// Orientation: print open-side up. No supports needed.

/* [Fit — measure and adjust] */
overall_w = 167;   // left–right (mm). Start 165–169.
overall_l = 145;   // front–back (mm)
overall_h = 55;    // tray height (mm) — leave lid clearance
wall = 2.0;
floor_t = 2.2;
corner_r = 5.0;

/* [Rail lips] */
lip_overhang = 4.0;
lip_thickness = 2.4;
lip_inset_from_ends = 8.0;

/* [Pockets — sized for real items] */
// ISO credit card ≈ 85.6 × 54.0 × 0.76 mm
card_slot_clearance = 2.5;     // extra width for 2–3 cards + finger
card_slot_w = 54.0 + card_slot_clearance;  // cards stand on long edge
card_slot_gap = 4.0;           // throat for stacked cards
card_pocket_depth = 48;        // how far cards sit into the tray (Y)

// Coin well — euros / mixed change
coin_well_w = 44;
coin_well_d = 44;
coin_ramp_rise = 10;           // floor rises this much — coins slide to the low edge

// Pen trough — typical pen ~140 × Ø10 mm (along tray width)
pen_trough_w = 14;
pen_trough_clearance = 2;

// Sunglasses bay uses remaining space (folded frames ~140 × 55–65 mm)

divider = 1.8;
cable_notch_w = 18;
cable_notch_d = 12;
cable_notch_h = 14;

/* [Quality] */
$fn = 48;

function left_col_w() = max(card_slot_w, coin_well_w) + divider;

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

// Layout (top view, +Y toward screen / wireless pad, −Y toward cup holders):
//
//  +Y (screen)
//  ┌──────────┬─────────────────────────┐
//  │  cards   │                         │
//  │  (slot)  │      sunglasses         │
//  ├──────────┤                         │
//  │  coins   │                         │
//  │  (ramp)  │                         │
//  ├──────────┴─────────────────────────┤
//  │           pens (full width)        │
//  └────────────────────────────────────┘
//  −Y (cup holders / USB)

module dividers() {
    inner_w = overall_w - 2*wall;
    inner_l = overall_l - 2*wall;
    h = overall_h - floor_t - 0.2;
    lc = left_col_w();

    // Pen trough along the cup-holder end (−Y), full inner width
    translate([0, -overall_l/2 + wall + pen_trough_w, floor_t + h/2])
        cube([inner_w, divider, h], center = true);

    // Vertical wall: left column (cards+coins) vs sunglasses bay
    left_wall_len = inner_l - pen_trough_w - divider;
    left_wall_y = overall_l/2 - wall - left_wall_len/2;
    translate([-overall_w/2 + wall + lc, left_wall_y, floor_t + h/2])
        cube([divider, left_wall_len, h], center = true);

    // Split cards (toward +Y) from coins (toward pens)
    split_y = overall_l/2 - wall - card_pocket_depth;
    translate([
        -overall_w/2 + wall + lc/2,
        split_y,
        floor_t + h/2
    ])
        cube([lc, divider, h], center = true);

    // Thin throat walls for the card slot
    card_centre_x = -overall_w/2 + wall + lc/2;
    card_centre_y = overall_l/2 - wall - card_pocket_depth/2;
    throat_wall = 1.2;
    half_gap = card_slot_gap / 2;
    for (sx = [-1, 1]) {
        translate([
            card_centre_x + sx * (half_gap + throat_wall/2),
            card_centre_y,
            floor_t + h/2
        ])
            cube([throat_wall, card_pocket_depth - 1, h], center = true);
    }
}

// Sloping coin floor: high at the outer (−X) wall, low at the sunglasses
// divider — coins pool at the low edge so you can pinch them easily.
module coin_ramp() {
    lc = left_col_w();
    well_w = lc - divider;                          // clear width inside left column
    split_y = overall_l/2 - wall - card_pocket_depth;
    y_hi = split_y - divider/2;                     // under card split
    y_lo = -overall_l/2 + wall + pen_trough_w + divider/2;
    well_d = y_hi - y_lo;
    rise = coin_ramp_rise;

    // Origin at outer-left corner of the coin pocket, on top of the floor
    x0 = -overall_w/2 + wall;
    y0 = y_lo;

    // Hull a tall thin slab on the outer wall down to a flat sliver on the inner edge
    translate([x0, y0, floor_t])
        hull() {
            // High edge (outer wall, −X)
            cube([0.2, well_d, rise]);
            // Low edge (toward sunglasses / +X) — almost flush with floor
            translate([well_w - 0.2, 0, 0])
                cube([0.2, well_d, 0.2]);
        }
}

module cable_notch() {
    translate([0, -overall_l/2 + cable_notch_d/2 - 0.1, floor_t + cable_notch_h/2 - 0.01])
        cube([cable_notch_w, cable_notch_d + wall, cable_notch_h + 0.2], center = true);
    translate([0, -overall_l/2 + cable_notch_d/2, -0.1])
        cube([cable_notch_w - 2, cable_notch_d, floor_t + 0.3], center = true);
}

difference() {
    union() {
        shell();
        dividers();
        coin_ramp();
    }
    cable_notch();
}
