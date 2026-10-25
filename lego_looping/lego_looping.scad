// =====================================================================
//  LEGO(R)-compatible roller coaster LOOPING  (vertical loop)
//  Parametric OpenSCAD design - Guy Stynen / OpenSCAD repo
//  Compatible with the 2018+ LEGO roller coaster rail system
//  (26022, 25059, 25061, 26559/26560/26561, 34738, 80562, 80564 ...)
//
//  Geometry of the rail profile and the track ends was measured from the
//  LDraw part 26022.dat (CC BY 4.0, ldraw.org).  1 LDU = 0.4 mm.
//
//  Concept (same as LEGO 10303 Loop Coaster):
//   * the loop = 4 identical QUARTER pieces (like LEGO 80564), each with a
//     90 deg bend and a sideways offset of 2 studs (16 mm), so the exit is
//     shifted 8 studs (64 mm) sideways from the entry.
//   * every quarter end is an exact copy of a LEGO coaster track end:
//     1 x 2 "plate" end block, 2 studs on top, 1x2 anti-stud underneath.
//     Pieces are joined like real LEGO track: a 2x2 plate across the joint.
//   * support structure: BASE (bottom joints), 2 SIDE FRAMES with sliding
//     PADs (side joints), JOINER 2x2 plate (top joint).
//
//  Coordinates (assembly): X = travel direction at the entry, Y = sideways
//  (loop axis), Z = up.  Z = 0 is the top surface of your LEGO baseplate.
//
//  part = "assembly" | "quarter" | "quarter_print" | "base" | "frame" |
//         "frame_print" | "pad" | "joiner" | "test_track" | "connector_detail"
// =====================================================================

part = "assembly";

/* [Loop geometry] */
R_out      = 88;    // radius of the OUTER surface (bottom of track) in the bend.
                    // (R_out + 8) should be a multiple of 8 so all joints sit on the stud grid.
                    // 88 -> loop 192 mm (24 studs) long and high, like 4x LEGO 80564 (4x12x10).
q_offset   = 16;    // sideways shift per quarter (16 = 2 studs, LEGO uses 2 studs).
                    // total shift = 4*q_offset; must be > car width (32) + clearance.
n_seg      = 48;    // number of sweep segments in a 90 deg bend
sleeper_pitch = 12; // distance between cross ties (mm, along the outer surface)

/* [Fit / tolerances] */
fit_tol    = 0.15;  // clearance for LEGO studs in printed anti-stud holes (per side)
stud_tol   = 0.05;  // printed studs are made this much smaller (per side)
slide_tol  = 0.20;  // clearance of the pad <-> frame slide (per side)
frame_gap  = 2.0;   // free gap between frame and the outside of the loop

/* [Support / stand] */
base_h     = 3.2;   // thickness of the printed base (1 plate). The loop's track ends sit on it.
keel_t     = 2.0;   // radial thickness of the print keel (stays below the car's rail hooks)

/* [Preview] */
ghost      = false; // show LEGO 26022 track (needs ref/26022.stl from LDraw) in the assembly

$fn = 32;

// ---------------- LEGO constants (mm) ----------------
P   = 8.0;          // stud pitch
PL  = 3.2;          // plate height
STUD_D = 4.8;
STUD_H = 1.7;
// track profile (v = sideways, w = height above bottom of end block)
RAIL_V  = 12.0;     // rail centre +-12 mm  (60 LDU between rails)
RAIL_W  = 8.8;      // rail centre 8.8 mm above end-block bottom
RAIL_R  = 1.6;      // rail = 3.2 mm "bar"
END_L   = 8.0;      // end block = 1 stud long, 2 studs wide
FLANGE_V = 10.84;
FLANGE_L = 9.8;

// ---------------- quarter path ----------------
S0   = END_L;                       // straight part at each end
ARC  = PI * R_out / 2;              // arc length (outer surface)
LTOT = 2*S0 + ARC;
QSIZE = R_out + S0;                 // 96 with defaults
LOOP_C = QSIZE;                     // loop centre height above datum

function clamp01(x) = x < 0 ? 0 : (x > 1 ? 1 : x);
function th(s)  = (s - S0) / R_out * 180 / PI;
// base point of the outer surface in the X-Z plane
function bp(s) = s <= S0 ? [s, 0]
               : s <= S0 + ARC ? [S0 + R_out*sin(th(s)), R_out - R_out*cos(th(s))]
               : [S0 + R_out, R_out + (s - S0 - ARC)];
// inward normal (towards the loop centre)
function bn(s) = s <= S0 ? [0, 1]
               : s <= S0 + ARC ? [-sin(th(s)), cos(th(s))]
               : [-1, 0];
function bt(s) = s <= S0 ? [1, 0]
               : s <= S0 + ARC ? [cos(th(s)), sin(th(s))]
               : [0, 1];
function ofs(s) = let(t = clamp01((s - S0) / ARC)) q_offset * (3*t*t - 2*t*t*t);
function P3(s, v, w) = let(b = bp(s), n = bn(s)) [b[0] + w*n[0], v + ofs(s), b[1] + w*n[1]];

// stations between s_a and s_b (inclusive)
function stations(sa, sb) = concat([sa],
     [for (i = [0:n_seg]) let(s = S0 + ARC*i/n_seg) if (s > sa + 0.01 && s < sb - 0.01) s],
     [sb]);

// generic sweep: pf(s) returns a CCW (v,w) polygon (same point count at every s)
module sweep(ss, pf) {
    M = len(pf(ss[0]));
    K = len(ss);
    pts = [for (s = ss) for (p = pf(s)) P3(s, p[0], p[1])];
    faces = concat(
        [[for (j = [0:M-1]) j]],
        [[for (j = [M-1:-1:0]) (K-1)*M + j]],
        [for (k = [0:K-2]) for (j = [0:M-1]) each [
            [k*M + j, (k+1)*M + j, (k+1)*M + (j+1)%M],
            [k*M + j, (k+1)*M + (j+1)%M, k*M + (j+1)%M]]]);
    polyhedron(points = pts, faces = faces, convexity = 6);
}

// ---------------- profile pieces (v,w), CCW ----------------
function circ(cv, cw, r, n = 20) = [for (i = [0:n-1]) [cv + r*cos(360*i/n), cw + r*sin(360*i/n)]];
// web from deck to rail: inner face at ~45 deg so it prints without support
WEB_R = [[9.4, 3.0], [10.9, 3.0], [11.89, 7.2], [10.56, 8.1], [7.6, 5.0]];
function mirv(poly) = [for (i = [len(poly)-1:-1:0]) [-poly[i][0], poly[i][1]]];
DECK = [[-10.5, 1.6], [10.5, 1.6], [10.5, 5.2], [-10.5, 5.2]];
Y_MIN = -(RAIL_V + RAIL_R);       // lowest point of the piece (print bed level)
function keel(s) = [[Y_MIN - ofs(s), 0], [-7.5, 0], [-7.5, keel_t], [Y_MIN - ofs(s), keel_t]];

// local frame at station s: u along track, v sideways, w inward
module at_s(s) {
    b = bp(s); n = bn(s); t = bt(s);
    multmatrix([[t[0], 0, n[0], b[0]],
                [0,    1, 0,    ofs(s)],
                [t[1], 0, n[1], b[1]],
                [0, 0, 0, 1]]) children();
}

// ---------------- LEGO track end block (local: u from end face inward) -------------
module end_block_pos() {
    // 1x2 plate body + flange up to the webs
    translate([0, -P, 0]) cube([END_L, 2*P, PL]);
    translate([0, -FLANGE_V, 1.6]) cube([FLANGE_L, 2*FLANGE_V, PL - 1.6]);
    // cross ridge at the inner edge of the end block (as on 26022)
    translate([END_L, -10.5, 1.6]) cube([FLANGE_L - END_L + 1.2, 21, 6.0 - 1.6]);
    // 2 studs on top
    for (v = [-P/2, P/2]) translate([END_L/2, v, PL - 0.01])
        cylinder(d = STUD_D - 2*stud_tol, h = STUD_H + 0.01);
}
module end_block_neg() {
    // 1x2 anti-stud cavity underneath (4.8 x 12.8 + tol) ...
    difference() {
        translate([END_L/2 - 2.4 - fit_tol, -6.4 - fit_tol, -1])
            cube([4.8 + 2*fit_tol, 12.8 + 2*fit_tol, 1 + 1.8]);
        // ... with the centre pin (3.2 mm) like a LEGO 1x2 plate
        translate([END_L/2, 0, -2]) cylinder(d = 3.2 - 2*fit_tol, h = 5);
    }
}

// ---------------- one quarter ----------------
module quarter() {
    difference() {
        union() {
            // rails + webs over the full length (flush with the end faces)
            sweep(stations(0, LTOT), function(s) circ( RAIL_V, RAIL_W, RAIL_R));
            sweep(stations(0, LTOT), function(s) circ(-RAIL_V, RAIL_W, RAIL_R));
            sweep(stations(0, LTOT), function(s) WEB_R);
            sweep(stations(0, LTOT), function(s) mirv(WEB_R));
            // deck between the end blocks
            sweep(stations(FLANGE_L - 0.5, LTOT - FLANGE_L + 0.5), function(s) DECK);
            // print keel (flat on the bed when printed on its side)
            sweep(stations(0, LTOT), function(s) keel(s));
            // cross ties
            nsl = floor((LTOT - 2*FLANGE_L - 6) / sleeper_pitch);
            for (i = [0:nsl]) {
                s = FLANGE_L + 3 + 1.5 + i * (LTOT - 2*FLANGE_L - 9) / nsl;
                at_s(s) translate([-1.5, -10.0, 1.6]) cube([3, 20, 6.0 - 1.6]);
            }
            // LEGO-compatible end blocks
            end_frame_start() end_block_pos();
            end_frame_end()   end_block_pos();
        }
        end_frame_start() end_block_neg();
        end_frame_end()   end_block_neg();
        // keep the end faces perfectly flat
        translate([-50, -60, -50]) cube([50, 150, 200]);
        translate([-50, -60, QSIZE]) cube([250, 150, 50]);
    }
}
module end_frame_start() children();
module end_frame_end() {
    // u -> -Z, v -> -Y (end block is symmetric), w -> -X
    multmatrix([[0, 0, -1, QSIZE],
                [0, -1, 0, q_offset],
                [-1, 0, 0, QSIZE],
                [0, 0, 0, 1]]) children();
}

// ---------------- printed studs / anti-stud helpers ----------------
module studs2x2(h = STUD_H) {
    for (a = [-P/2, P/2], b = [-P/2, P/2]) translate([a, b, 0])
        cylinder(d = STUD_D - 2*stud_tol, h = h);
}
module antistud_hole(depth = 1.8) {
    translate([0, 0, -1]) cylinder(d = STUD_D + 2*fit_tol, h = depth + 1);
}

// ---------------- joiner: 2x2 plate (= LEGO 3022) ----------------
module joiner() {
    translate([-P, -P, 0]) cube([2*P, 2*P, PL]);
    translate([0, 0, PL - 0.01]) studs2x2(STUD_H + 0.01);
}

// ---------------- base: holds both bottom joints, sits on a baseplate ----------------
BASE_X0 = -2*P; BASE_X1 = 2*P;
BASE_Y0 = -2*P; BASE_Y1 = 4*q_offset + 2*P;
module base() {
    difference() {
        union() {
            translate([BASE_X0, BASE_Y0, 0]) cube([BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, base_h]);
            for (y = [0, 4*q_offset]) translate([0, y, base_h - 0.01]) studs2x2(STUD_H + 0.01);
        }
        for (x = [BASE_X0 + P/2 : P : BASE_X1 - 1], y = [BASE_Y0 + P/2 : P : BASE_Y1 - 1])
            translate([x, y, 0]) antistud_hole();
        // lightening slots between the two joints (keep it stiff)
        translate([-P + 2, 2*P + 2, -1]) cube([2*P - 4, 4*q_offset - 4*P - 4, base_h + 2]);
    }
}

// ---------------- side support frame (for the joint at X = +QSIZE) ----------------
PAD_T   = 4.8;                 // pad thickness (X)
RIB_W   = 6.0;                 // slide rib width (Y)
RIB_H   = 1.8;                 // slide rib height (X)
COL_X0  = QSIZE + PAD_T;       // inner face of the column
COL_D   = 16;
FR_Y0   = q_offset - P;        // frame occupies Y = q_offset +- 8
FR_TOP  = base_h + QSIZE + P + 4;
FOOT_X0 = QSIZE - 5*P;         // foot from 56 ...
FOOT_X1 = QSIZE + 3*P;         // ... to 120 (8 studs)
FOOT_H  = 6.4;

// 2D region occupied by the loop (outer surface), X-Z plane, quarter 1+2
module loop_region_2d(g) {
    // inside of the outer track surface of quarter 1 + 2 (a "stadium")
    translate([0, base_h]) offset(delta = g) hull() {
        translate([S0, QSIZE - S0]) circle(r = R_out, $fn = 180);
        translate([S0, QSIZE + S0]) circle(r = R_out, $fn = 180);
    }
}
module frame_2d() {
    difference() {
        union() {
            translate([COL_X0, 0]) square([COL_D, FR_TOP]);          // column
            translate([FOOT_X0, 0]) square([FOOT_X1 - FOOT_X0, FOOT_H]); // foot
            // diagonal brace
            hull() {
                translate([FOOT_X0 + 4, FOOT_H - 1]) square([6, 1]);
                translate([COL_X0, base_h + 58]) square([1, 10]);
            }
            // gusset at the foot
            polygon([[COL_X0 - 18, FOOT_H - 0.5], [COL_X0 + 0.5, FOOT_H - 0.5], [COL_X0 + 0.5, FOOT_H + 18]]);
        }
        // never touch the loop
        loop_region_2d(frame_gap);
    }
}
module frame() {
    difference() {
        union() {
            translate([0, FR_Y0 + 2*P, 0]) rotate([90, 0, 0]) linear_extrude(2*P) frame_2d();
            // slide rib on the inner face of the column
            translate([COL_X0 - RIB_H, q_offset - RIB_W/2, base_h + QSIZE - P - 2.5])
                cube([RIB_H + 0.01, RIB_W, FR_TOP - (base_h + QSIZE - P - 2.5)]);
        }
        // anti-stud holes in the foot (sits on a LEGO baseplate)
        for (x = [FOOT_X0 + P/2 : P : FOOT_X1 - 1], y = [FR_Y0 + P/2, FR_Y0 + 3*P/2])
            translate([x, y, 0]) antistud_hole();
    }
}

// ---------------- pad: 2x2 studs facing the loop, groove for the frame rib -------------
// modelled in print orientation: studs up (+Z), groove on the bed side
module pad() {
    difference() {
        translate([-P, -P, 0]) cube([2*P, 2*P, PAD_T]);
        translate([-P - 1, -RIB_W/2 - slide_tol, -1]) cube([2*P + 2, RIB_W + 2*slide_tol, 1 + RIB_H + slide_tol]);
    }
    translate([0, 0, PAD_T - 0.01]) studs2x2(STUD_H + 0.01);
}
// pad placed in the assembly at the joint X = +QSIZE
module pad_placed() {
    // pad local: studs +Z -> -X ; local X -> Z ; local Y -> Y
    translate([QSIZE + PAD_T, q_offset, base_h + QSIZE])
        multmatrix([[0, 0, -1, 0], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]]) pad();
}

// ---------------- test piece: 2-stud straight with LEGO ends --------------------
module test_track() {
    L = 2*END_L;
    difference() {
        union() {
            for (s = [0, 1]) translate([s*L, 0, 0]) mirror([s, 0, 0]) end_block_pos();
            for (v = [-1, 1]) translate([0, v*RAIL_V, RAIL_W]) rotate([0, 90, 0]) cylinder(r = RAIL_R, h = L, $fn = 20);
            for (pp = [WEB_R, mirv(WEB_R)]) translate([0, 0, 0]) rotate([90, 0, 90]) linear_extrude(L) polygon(pp);
            translate([0, -7.5, 0]) rotate([90, 0, 90]) linear_extrude(L)
                polygon([[Y_MIN + 7.5, 0], [0, 0], [0, keel_t], [Y_MIN + 7.5, keel_t]]);
        }
        for (s = [0, 1]) translate([s*L, 0, 0]) mirror([s, 0, 0]) end_block_neg();
    }
}

// ---------------- assembly ----------------
module quarter_k(k) {
    translate([0, k*q_offset, base_h + LOOP_C]) rotate([0, -90*k, 0])
        translate([0, 0, -LOOP_C]) quarter();
}
module assembly() {
    cols = ["orange", "gold", "orange", "gold"];
    for (k = [0:3]) color(cols[k]) quarter_k(k);
    color("silver") base();
    color("steelblue") frame();
    color("steelblue") translate([0, 4*q_offset, 0]) rotate([0, 0, 180]) frame();
    color("lightskyblue") pad_placed();
    color("lightskyblue") translate([0, 4*q_offset, 0]) rotate([0, 0, 180]) pad_placed();
    color("silver") translate([0, 2*q_offset, base_h + 2*QSIZE]) joiner();
    if (ghost) {
        color("red", 0.9) translate([-32, 0, base_h + PL]) import("ref/26022.stl");
        color("red", 0.9) translate([32, 4*q_offset, base_h + PL]) import("ref/26022.stl");
    }
    // LEGO baseplate hint
    %translate([-136, -40, -3.2]) cube([272, 4*q_offset + 80, 3.2]);
}

// ---------------- print orientations ----------------
module quarter_print() {        // on its side, keel down, no supports except under the lower rail
    translate([0, 0, -Y_MIN]) rotate([90, 0, 0]) quarter();
}
module frame_print() {          // flat, extrusion direction up
    rotate([90, 0, 0]) translate([0, -FR_Y0, 0]) frame();
}

if (part == "assembly") assembly();
else if (part == "quarter") quarter();
else if (part == "quarter_print") quarter_print();
else if (part == "base") base();
else if (part == "frame") frame();
else if (part == "frame_print") frame_print();
else if (part == "pad") pad();
else if (part == "joiner") joiner();
else if (part == "test_track") translate([0, 0, -Y_MIN]) rotate([90, 0, 0]) test_track();   // print orientation (on its side)
else if (part == "test_set") { translate([0, 0, -Y_MIN]) rotate([90, 0, 0]) test_track(); translate([8, 40, 0]) joiner(); }
else if (part == "connector_detail") {
    quarter();
    if (ghost) color("red", 0.8) translate([-32, 0, PL]) import("ref/26022.stl");
}
