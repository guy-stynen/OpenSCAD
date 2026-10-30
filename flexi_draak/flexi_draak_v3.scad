// Flexi draak v3 - chubby "cute flexi" style, sculpted 3D, print-in-place
// Original OpenSCAD geometry (style inspired by cute articulated dragons).
// Printed upright on its belly, no supports. OpenSCAD 2021.01
// part = "dragon" | "test_joint" | "check"
part = "dragon";
len_total = 100;   // nose to tail tip
clr  = 0.4;        // joint clearance
nt   = 4;          // tail segments
swing = 20;        // max swing per joint (deg)
pose = 0;          // check only
$fn = 36;

rp1 = 1.8; rp2 = 2.5; wn = 2.2;   // joint (not scaled)

// ---------- layout (unscaled values, scaled by sc) ----------
N = 3 + nt;   // 0 head, 1 chest, 2 hip, 3.. tail
function Rn(k) = k==1 ? 11 : k==2 ? 10 : 7.6 - (7.6-5.4)*(k-3)/max(1,nt-1);
function Bn(k) = k==1 ? 12.5 : k==2 ? 11.5 : Rn(k);          // lateral half width
function Hn(k) = k==1 ? 10 : k==2 ? 9 : 5.0 - 0.9*(k-3)/max(1,nt-1); // half height
function Gn(k) = k==1 ? 10.6 : k==2 ? 6 : 5;                  // gap to next pivot
function cn(k,s) = k==0 ? 0 : cn(k-1,s) - (Rn(k)*s + clr + Gn(k-1)*s);
nose = 18; tailx = 9;
natural = nose - (cn(N-1,1) - tailx);
sc = len_total/natural;
function R(k) = Rn(k)*sc;
function c(k) = k==0 ? 0 : c(k-1) - (R(k) + clr + Gn(k-1)*sc);
function hj(k) = k<=2 ? 6.0 : 5.4;      // joint height at pivot k
echo(str("scale=", sc, "  length=", nose*sc - (c(N-1) - tailx*sc)));

// ---------- helpers ----------
module mirrory() { children(); mirror([0,1,0]) children(); }
// ellipsoid resting on the bed, underside kept <= 45 deg by a hull to a 0.7 footprint
module blob(p, r) hull() {
    translate([p[0],p[1],r[2]]) scale(r) sphere(1);
    translate([p[0],p[1],0]) linear_extrude(0.01) scale([r[0],r[1]]*0.7) circle(1);
}
module ring(p, r) translate(p) { cylinder(r1=r, r2=r+0.5, h=0.5); translate([0,0,0.5]) cylinder(r1=r+0.5, r2=r, h=0.5); }

function pin_prof(h) = let(zf = h - 1.0 - clr*1.42 - rp2)
    [[0,0],[rp1,0],[rp1,0.5],[rp2,0.5+rp2-rp1],[rp2,zf],[0,zf+rp2]];
module pin(h) rotate_extrude() polygon(pin_prof(h));
module cavity(h) rotate_extrude() {
    intersection() {
        offset(r=clr) union() { polygon(pin_prof(h)); mirror([1,0]) polygon(pin_prof(h)); }
        translate([0,-2]) square([20,40]);
    }
    translate([0,-2]) square([rp1+clr, 2.6]);
}
module wedge2d(k) {
    module r() translate([-0.7,-(wn/2+clr)]) square([R(k)+4, wn+2*clr]);
    hull() { rotate(-swing) r(); r(); }
    hull() { rotate(swing) r(); r(); }
}
module slot3d(k) {   // slot for bar, closed above with a 45 deg stepped roof (no bridge)
    translate([0,0,-1]) linear_extrude(hj(k)+clr+1) wedge2d(k);
    for (i=[0:20]) translate([0,0,hj(k)+clr+i*0.3])
        linear_extrude(0.31) offset(delta=-i*0.3) wedge2d(k);
}
module at(k) translate([c(k),0,0]) children();

// ---------- head ----------
module head() scale(sc) difference() {
    union() {
        blob([-3,0], [13,14.5,13]);                 // cranium
        blob([9,0],  [9,10.5,8]);                   // snout
        mirrory() {
            hull() { translate([8,10,12]) sphere(7); translate([8,3.5,5.5]) sphere(7); }  // big eyes
            // cheek spikes
            hull() { translate([-6,12,10]) sphere(2.6); translate([-10,16,16]) sphere(0.9); }
            hull() { translate([-2,12.5,7]) sphere(2.2); translate([-5,16,11.5]) sphere(0.8); }
            // horns
            hp = [[0,6.5,22.5,4.4],[-1,7.3,27,3.6],[-2.6,7.9,30.5,2.8],[-4.6,8.2,33,2.0],[-6.2,8.3,34.6,1.3]];
            for (i=[0:3]) hull() { translate([hp[i][0],hp[i][1],hp[i][2]]) sphere(hp[i][3]);
                                   translate([hp[i+1][0],hp[i+1][1],hp[i+1][2]]) sphere(hp[i+1][3]); }
            for (i=[1:3]) ring([hp[i][0],hp[i][1],hp[i][2]-0.5], hp[i][3]-0.1);
        }
    }
    mirrory() {
        translate([15.5,3.3,8]) rotate([0,90,0]) linear_extrude(6) rotate(45) square(2.2, center=true); // nostrils
        translate([8,10,12] + 7*[0.62,0.45,0.64]) sphere(1.6);                                         // eye shine dimple
    }
    translate([0,0,-100]) cube(200, center=true);
}

// ---------- body parts ----------
module front_legs() at(1) scale(sc) mirrory() {
    hull() { blob([1,8],[5,5,5.5]); blob([7,15],[4.5,4,3.2]); }
    for (a=[-35,0,35]) let(d=[cos(25+a), sin(25+a)]) blob([7,15]+4.3*d, [1.6,1.6,1.6]);
}
module hind_legs() at(2) scale(sc) mirrory() {
    hull() { blob([-2,7.5],[5.5,5.5,6]); blob([-3,16],[4.5,5,3.4]); }
    for (a=[-35,0,35]) let(d=[cos(60+a), sin(60+a)]) blob([-3,16]+4.6*d, [1.7,1.7,1.7]);
}
module wing2d() offset(r=1) offset(delta=-1) polygon([[3,8],[-8,8],[-8.5,15],[-12,18.5],[-10,20],[-13.5,24],[-11.5,25.5],[-14,30],[-9,30.5],[-3,24]]);
module wings() at(1) scale(sc) mirrory() translate([0,5.5,0]) rotate([18,0,0]) {
    rotate([90,0,0]) translate([0,0,-1.2]) linear_extrude(2.4) wing2d();
    hull() { translate([2,0,9]) sphere(2.2); translate([-2,0,23]) sphere(2.0); }
    hull() { translate([-2,0,23]) sphere(2.0); translate([-8,0,30.5]) sphere(1.5); }   // leading edge bone
}
module seg_body(k) {
    last = (k==N-1);
    intersection() {
        hull() {
            blob([c(k),0], [R(k), Bn(k)*sc, Hn(k)*sc]);
            if (!last) blob([c(k+1),0], 0.8*[min(R(k),R(k+1)), min(R(k),R(k+1)), Hn(k+1)*sc]);
            else blob([c(k)-tailx*sc+3*sc,0], [3*sc,3*sc,2.5*sc]);
        }
        union() { at(k) cylinder(r=R(k), h=100); at(k) translate([-200,-100,0]) cube([200,200,100]); }
    }
    // tail spikes (soft, rounded, 45 deg)

}
module seg_main(k) {
    if (k==0) head(); else seg_body(k);
    if (k==1) { front_legs(); wings(); }
    if (k==2) hind_legs();
}
module seg(k) {
    difference() {
        seg_main(k);
        if (k<N-1) at(k+1) translate([0,0,-1]) cylinder(r=R(k+1)+clr, h=100);
        if (k>0) at(k) { cavity(hj(k)); slot3d(k); }
    }
    if (k<N-1) at(k+1) { pin(hj(k+1)); translate([0,-wn/2,0]) cube([barlen(k), wn, hj(k+1)]); }
}
function barlen(k) = min(R(k+1)+clr+2, c(k)-c(k+1) - (rp2+2*clr+1.2));
module dragon() for (k=[0:N-1]) seg(k);

module test_joint() {   // tail joint 3->4 as two short pieces
    k=3;
    difference() {
        intersection() { seg_body(k); at(k) translate([-30,-20,0]) cube([60,40,30]); }
        at(k+1) translate([0,0,-1]) cylinder(r=R(k+1)+clr, h=100);
    }
    at(k+1) { pin(hj(k+1)); translate([0,-wn/2,0]) cube([barlen(k), wn, hj(k+1)]); }
    difference() {
        intersection() { seg_body(k+1); at(k+1) translate([-4,-20,0]) cube([40,40,30]); }
        at(k+1) { cavity(hj(k+1)); slot3d(k+1); }
    }
}

// ---------- 2D collision check (projections) ----------
module foot2d(k) difference() { projection() seg_main(k); if (k<N-1) at(k+1) circle(R(k+1)+clr); }
function ang(j) = pose==99 ? ((j%2)*2-1)*20 : pose;
module chainrot(k, j=1) {
    if (j>k) children();
    else translate([c(j),0]) rotate(ang(j)) translate([-c(j),0]) chainrot(k, j+1) children();
}
module check() for (i=[0:N-2]) for (k=[i+1:N-1]) intersection() {
    chainrot(i) offset(delta=0.1) foot2d(i);
    difference() { chainrot(k) offset(delta=0.1) foot2d(k);
        if (k==i+1) chainrot(k) at(k) { circle(rp2+clr+0.4); offset(delta=0.3) wedge2d(k); } }
}

if (part=="dragon") dragon();
else if (part=="test_joint") test_joint();
else if (part=="check") check();
