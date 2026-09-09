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
card_slot_clearance = 2.5;
card_slot_w = 54.0 + card_slot_clearance;
card_slot_gap = 4.0;
card_pocket_depth = 48;

// Coin dish — round well + finger scoop (better than a flat ramp)
coin_dish_d = 42;              // inner bowl diameter
coin_dish_depth = 12;          // how deep the bowl sinks below the floor top
coin_rim_h = 3;                // raised lip around the bowl (keeps coins in while driving)
coin_scoop_w = 22;             // finger notch width toward the sunglasses bay
coin_scoop_drop = 8;           // how much the scoop lowers the rim

// Pen trough — typical pen ~140 × Ø10 mm
pen_trough_w = 14;
pen_trough_clearance = 2;

divider = 1.8;
cable_notch_w = 18;
cable_notch_d = 12;
cable_notch_h = 14;

/* [Quality] */
$fn = 64;

function left_col_w() = max(card_slot_w, coin_dish_d + 6) + divider;

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

// Layout (top view, +Y toward screen, −Y toward cup holders):
//
//  ┌──────────┬─────────────────────────┐
//  │  cards   │                         │
//  │  (slot)  │      sunglasses         │
//  ├──────────┤                         │
//  │  ◕ coins │  ← finger scoop here    │
//  │  (dish)  │                         │
//  ├──────────┴─────────────────────────┤
//  │           pens                     │
//  └────────────────────────────────────┘

module dividers() {
    inner_w = overall_w - 2*wall;
    inner_l = overall_l - 2*wall;
    h = overall_h - floor_t - 0.2;
    lc = left_col_w();

    translate([0, -overall_l/2 + wall + pen_trough_w, floor_t + h/2])
        cube([inner_w, divider, h], center = true);

    left_wall_len = inner_l - pen_trough_w - divider;
    left_wall_y = overall_l/2 - wall - left_wall_len/2;
    translate([-overall_w/2 + wall + lc, left_wall_y, floor_t + h/2])
        cube([divider, left_wall_len, h], center = true);

    split_y = overall_l/2 - wall - card_pocket_depth;
    translate([
        -overall_w/2 + wall + lc/2,
        split_y,
        floor_t + h/2
    ])
        cube([lc, divider, h], center = true);

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

// Centre of the coin pocket (left column, under the card split)
function coin_centre() =
    let (
        lc = left_col_w(),
        split_y = overall_l/2 - wall - card_pocket_depth,
        y_lo = -overall_l/2 + wall + pen_trough_w + divider,
        y_hi = split_y - divider/2,
        cx = -overall_w/2 + wall + (lc - divider)/2,
        cy = (y_lo + y_hi) / 2
    )
    [cx, cy];

// Round dish: hemispherical-ish bowl + raised rim, with a finger scoop
// cut toward the sunglasses bay (+X) so you can dip and scoop.
module coin_dish() {
    c = coin_centre();
    cx = c[0];
    cy = c[1];
    r = coin_dish_d / 2;
    rim_r = r + 2.5;

    // Build solid rim + floor pad, then carve the bowl and scoop
    difference() {
        union() {
            // Raised rim ring (sits on the tray floor)
            translate([cx, cy, floor_t])
                cylinder(h = coin_rim_h, r = rim_r);
            // Extra floor pad under the dish so we can carve below floor_t
            // without punching through the tray bottom
            translate([cx, cy, 0])
                cylinder(h = floor_t + 0.01, r = rim_r);
        }

        // Bowl cavity — spherical cap for a smooth scooping surface
        translate([cx, cy, floor_t + coin_rim_h])
            sphere(r = r);
        // Flatten anything above the rim (sphere would stick up)
        translate([cx, cy, floor_t + coin_rim_h + r/2])
            cube([rim_r*2 + 2, rim_r*2 + 2, r], center = true);

        // Ensure bowl reaches down to coin_dish_depth below floor top
        translate([cx, cy, floor_t - coin_dish_depth])
            cylinder(h = coin_dish_depth + coin_rim_h + 0.1, r1 = r * 0.35, r2 = r);

        // Finger scoop — lower the rim toward +X (sunglasses side)
        translate([cx + r * 0.55, cy, floor_t + coin_rim_h - coin_scoop_drop])
            cube([coin_scoop_w, coin_scoop_w * 0.9, coin_scoop_drop + coin_rim_h + 1], center = true);
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
        coin_dish();
    }
    cable_notch();
}
