// ============================================================================
//  ORBITAL ENGINE Mk.I  —  print-in-place planetary gear fidget
//  Built to wow a curious 12-year-old. Zero assembly. Just print & spin.
//  Tuned for FlashForge Adventurer 4 (220×200×250 mm) · PLA · 0.4 mm nozzle
// ============================================================================
//
// After printing: gently twist the centre knob back and forth until the
// gears free up — then give it a spin. Planets orbit the opposite way
// from the sun. That’s the “wait… what?!” moment.
//
// Print: flat on the bed · no supports · 0.2 mm layers · 3 walls · 20% infill
//        PLA (silk PLA = extra swagger) · bed ~55 °C · nozzle ~205 °C

/* [Gear geometry] */
mod = 1.75;              // gear module (mm) — chunky teeth for FDM
sun_teeth = 12;
planet_teeth = 12;       // ring teeth = sun + 2×planet = 36
planet_count = 3;
backlash = 0.5;          // print-in-place clearance (Adventurer 4 safe)
gear_h = 7;

/* [Housing] */
base_h = 2.8;
rim_w = 4;
knob_h = 7;
z_gap = 0.4;             // vertical clearance between layers
pin_r = 2.5;
pin_bore = 3.2;          // planet hole radius (≥ pin_r + 0.5)

/* [Quality] */
$fn = 72;

ring_teeth = sun_teeth + 2 * planet_teeth;

function pitch_r(t) = t * mod / 2;

sun_pr    = pitch_r(sun_teeth);
planet_pr = pitch_r(planet_teeth);
ring_pr   = pitch_r(ring_teeth);
orbit_r   = sun_pr + planet_pr;
outer_r   = ring_pr + mod + rim_w;

echo(str("Footprint diameter ≈ ", 2 * outer_r, " mm (Adventurer 4 bed: 220×200)"));

// ----- 2D gear outline (external or internal) -----
module gear2d(teeth, internal=false) {
    pr = pitch_r(teeth);
    tip = internal ? pr - 0.9 * mod : pr + mod;
    root = internal ? pr + 1.1 * mod : max(0.8, pr - 1.2 * mod);
    // Angular half-width of tooth, with backlash carved out
    half = 90 / teeth - (backlash * 90) / (PI * pr);

    if (internal) {
        difference() {
            circle(r = tip + rim_w); // unused path — caller clips
            union() {
                circle(r = tip);
                for (i = [0 : teeth - 1])
                    rotate(i * 360 / teeth)
                        tooth2d(root, tip, half, flip=true);
            }
        }
    } else {
        union() {
            circle(r = root);
            for (i = [0 : teeth - 1])
                rotate(i * 360 / teeth)
                    tooth2d(root, tip, half, flip=false);
        }
    }
}

module tooth2d(root, tip, half, flip=false) {
    // Simple tapered tooth — FDM-friendly, meshes with backlash
    a = flip ? half * 1.1 : half;
    b = flip ? half * 0.4 : half * 0.45;
    polygon([
        [root * cos(-a), root * sin(-a)],
        [tip  * cos(-b), tip  * sin(-b)],
        [tip  * cos( b), tip  * sin( b)],
        [root * cos( a), root * sin( a)]
    ]);
}

module external_gear(teeth, h, bore=0) {
    difference() {
        linear_extrude(h, convexity=10) gear2d(teeth, internal=false);
        if (bore > 0)
            translate([0, 0, -0.05]) cylinder(h=h+0.1, r=bore);
    }
}

module ring_gear(h) {
    // Annulus with internal teeth
    pr = ring_pr;
    tip = pr - 0.9 * mod;   // tooth tip toward centre
    root = pr + 1.1 * mod;  // tooth root outward
    half = 90 / ring_teeth - (backlash * 90) / (PI * pr);

    difference() {
        cylinder(h=h, r=root + 0.8);
        // Hollow centre out to tip circle
        translate([0,0,-0.05]) cylinder(h=h+0.1, r=tip);
        // Cut tooth gaps (material removed between teeth)
        for (i = [0 : ring_teeth - 1]) {
            rotate(i * 360 / ring_teeth + 180 / ring_teeth)
                translate([0,0,-0.05])
                    linear_extrude(h+0.1)
                        polygon([
                            [0, 0],
                            [(tip - 0.2) * cos(-half), (tip - 0.2) * sin(-half)],
                            [(root + 1) * cos(-half*0.5), (root + 1) * sin(-half*0.5)],
                            [(root + 1) * cos( half*0.5), (root + 1) * sin( half*0.5)],
                            [(tip - 0.2) * cos( half), (tip - 0.2) * sin( half)]
                        ]);
        }
    }
}

// ----- print-in-place assembly -----

module housing() {
    union() {
        // Floor
        difference() {
            cylinder(h=base_h, r=outer_r);
            // Dimple under sun for free spin
            translate([0,0,-0.05]) cylinder(h=0.9, r=sun_pr*0.6);
        }
        // Outer armour drum
        translate([0,0,base_h])
            difference() {
                cylinder(h=gear_h + 2*z_gap + 1.5, r=outer_r);
                translate([0,0,-0.05])
                    cylinder(h=gear_h + 2*z_gap + 1.7, r=outer_r - rim_w + 0.2);
            }
        // Hex thruster fins
        for (a = [0 : 60 : 300])
            rotate(a)
                translate([outer_r - 0.8, 0, base_h + gear_h/2 + 0.5])
                    cube([4, 9, gear_h - 1], center=true);
        // Ring gear seated on the floor
        translate([0,0,base_h + z_gap])
            ring_gear(gear_h);
    }
}

module sun() {
    translate([0,0,base_h + z_gap]) {
        external_gear(sun_teeth, gear_h);
        // Top captive washer
        translate([0,0,gear_h + z_gap])
            cylinder(h=1.2, r=sun_pr - mod*0.4);
        // Hex knob + jewel
        translate([0,0,gear_h + z_gap + 1.2]) {
            cylinder(h=knob_h, r=8.5, $fn=6);
            translate([0,0,knob_h]) sphere(r=4.2);
        }
        // Bottom captive stub into floor dimple
        translate([0,0,-z_gap - 0.7])
            cylinder(h=0.7, r=sun_pr*0.45);
    }
}

module planet(i) {
    a = i * 360 / planet_count;
    // Mesh phase: half-tooth offset when sun & planet tooth counts match
    mesh = 180 / planet_teeth + a * sun_teeth / planet_teeth;
    rotate(a)
        translate([orbit_r, 0, base_h + z_gap])
            rotate(mesh)
                external_gear(planet_teeth, gear_h, bore=pin_bore);
}

module carrier() {
    z = base_h + z_gap + gear_h + z_gap;
    // Ring that rides above the planets
    difference() {
        translate([0,0,z]) cylinder(h=1.5, r=orbit_r + 5);
        translate([0,0,z-0.05]) cylinder(h=1.7, r=10);
        for (a = [0 : 60 : 300])
            rotate(a + 30)
                translate([orbit_r * 0.55, 0, z-0.05])
                    cylinder(h=1.7, r=3);
    }
    // Axle pins through each planet (printed in place)
    for (i = [0 : planet_count - 1]) {
        a = i * 360 / planet_count;
        rotate(a)
            translate([orbit_r, 0, base_h + z_gap - 0.15])
                cylinder(h=gear_h + z_gap + 1.7, r=pin_r);
    }
    // Pin caps above carrier so planets can’t float off
    for (i = [0 : planet_count - 1]) {
        a = i * 360 / planet_count;
        rotate(a)
            translate([orbit_r, 0, z + 1.5])
                cylinder(h=1.0, r=pin_r + 1.2);
    }
}

// ===== single solid for export =====
housing();
sun();
for (i = [0 : planet_count - 1]) planet(i);
carrier();
