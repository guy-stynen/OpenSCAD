// Flexi draak - print-in-place articulated dragon
// OpenSCAD 2021.01. Print flat, no supports.
// part = "dragon" | "test_joint" | "joint_section" | "check"
part = "dragon";
len_total = 100;   // nose to tail tip (mm)
clr  = 0.4;        // joint clearance
nt   = 4;          // number of tail segments (3..6)
th   = 7;          // body thickness (chest)
rear = 5.5;        // rear length of each segment behind its socket
swing = 22;        // max swing per joint (deg)
pose = 0;          // only for part="check": joint angle
$fn = 40;

// joint (fixed, not scaled)
rp1 = 1.8; rp2 = 2.5; wn = 2.2;

// ---------- layout ----------
N = 4 + nt;               // 0 head,1 neck,2 chest,3 hip,4.. tail
function Rn(k) = k==0 ? 8 : k==1 ? 6 : k==2 ? 9 : k==3 ? 8.5 :
    6.5 - (6.5-4.6)*(k-4)/max(1,nt-1);
function cn(k,s) = k==0 ? 0 : cn(k-1,s) - (Rn(k)*s + clr + rear*s);
natural = 13.2 + 15 - cn(N-1,1);
sc = len_total / natural;
function R(k) = max(Rn(k)*sc, 4.3);
function c(k) = k==0 ? 0 : c(k-1) - (R(k) + clr + rear*sc);
function H(k) = k==0 ? th : k==1 ? th-0.5 : k==2 ? th+0.5 : k==3 ? th :
    max(5.6, th-0.5 - 1.2*(k-4)/max(1,nt-1));
function hj(k) = min(H(k-1), H(k));          // joint height of joint at c(k)
echo(str("scale=", sc, " total length=", 13.2*sc - (c(N-1) - 15*sc)));

// ---------- helpers ----------
module cext(h, ch=1.2) {   // extrude with 45 deg stepped top chamfer
    linear_extrude(h-ch) children();
    for (i=[0:2]) translate([0,0,h-ch+i*ch/3])
        linear_extrude(ch/3+0.001) offset(delta=-(i+1)*ch/3) children();
}
module at(k) translate([c(k),0]) children();
module mirrory() { children(); mirror([0,1,0]) children(); }

function pin_prof(h) = let(zf = h - 1.0 - clr*1.42 - rp2)
    [[0,0],[rp1,0],[rp1,0.5],[rp2,0.5+rp2-rp1],[rp2,zf],[0,zf+rp2]];
module pin(h) rotate_extrude() polygon(pin_prof(h));
module cavity(h) rotate_extrude() {
    intersection() {
        offset(r=clr) union() { polygon(pin_prof(h)); mirror([1,0]) polygon(pin_prof(h)); }
        translate([0,-2]) square([20, 40]);
    }
    translate([0,-2]) square([rp1+clr, 2.6]);
}
module wedge2d(k) {   // slot for the neck bar of the previous segment
    module r() translate([-0.7,-(wn/2+clr)]) square([R(k)+3, wn+2*clr]);
    hull() { rotate(-swing) r(); r(); }
    hull() { rotate(swing) r(); r(); }
}

// ---------- 2D shapes ----------
module head2d() {
    s = sc;
    hull() { circle(7.5*s); translate([9*s,0]) circle(4.2*s); }
    mirrory() {
        translate([1*s,3.8*s]) circle(4.6*s);
        polygon([[-2*s,6*s],[-6.5*s,9.5*s],[1.5*s,8*s]]);         // cheek frill
        for (x=[4.5:1.6:11]) translate([x*s, (4.6 - 0.08*(x-4.5)*2.5)*s])
            polygon([[0,0],[1*s,0],[0.5*s,-1.0*s]]);              // teeth
    }
}
module leg2d(p0, pk, p1, w, dir) {
    hull() { translate(p0) circle(w/2); translate(pk) circle(w*0.42); }
    hull() { translate(pk) circle(w*0.42); translate(p1) circle(w*0.36); }
    for (a=[-40,0,40]) hull() { translate(p1) circle(w*0.4);
        translate(p1 + 3.0*sc*[cos(dir+a), sin(dir+a)]) circle(0.4); }
}
module front_legs2d() at(2) mirrory()
    leg2d([-0.5*sc,R(2)*0.55],[2*sc,R(2)+4*sc],[6.5*sc,R(2)+5.5*sc],4.2*sc,30);
module hind_legs2d() at(3) mirrory()
    leg2d([-1*sc,R(3)*0.55],[-1.5*sc,R(3)+4.5*sc],[-5.5*sc,R(3)+7*sc],4.6*sc,135);
// wing in chest coordinates (y>0)
wing_root=[0.5,6.5]; wrist=[2,19]; tips=[[-1,34],[-7,31],[-12,25]];
module wing_membrane2d() polygon(sc*[[2.5,6],[3,19],[-1,34],[-3.5,27.5],[-7,31],
    [-8,23.5],[-12,25],[-8.5,17],[-5,6]]);
module wings2d() at(2) mirrory() wing_membrane2d();
module bone2d(a,b,w1,w2) hull() { translate(a*sc) circle(w1/2); translate(b*sc) circle(w2/2); }

module body2d(k) difference() {
    union() {
        if (k==0) head2d(); else at(k) circle(R(k));
        if (k>0 && k<N-1) hull() { at(k) circle(R(k)); at(k+1) circle(0.85*min(R(k),R(k+1))); }
        if (k==N-1) at(k) {
            hull() { circle(R(k)); translate([-6*sc,0]) circle(1.6*sc); }
            spade2d();
        }
    }
    if (k<N-1) at(k+1) circle(R(k+1)+clr);
    if (k>0) at(k) wedge2d(k);
}
module spade2d() scale(sc) polygon([[-4,0],[-7,5.5],[-9.5,2],[-15,0],[-9.5,-2],[-7,-5.5]]);

module horns3d() {
    s=sc; hh=H(0);
    mirrory() {
        hull() { translate([-2.5*s,4.2*s,0]) cylinder(r=1.8*s,h=hh+1.8);
                 translate([-7*s,7.5*s,0]) cylinder(r=1.1*s,h=hh-0.8); }
        hull() { translate([-7*s,7.5*s,0]) cylinder(r=1.1*s,h=hh-0.8);
                 translate([-10.5*s,9.6*s,0]) cylinder(r=0.35,h=1.6); }
    }
}
module spike(k) { // dorsal spike behind the socket, swept back
    L = rear*sc - 1.4; x0 = c(k) - 0.9; h = H(k);
    hull() {
        translate([x0-L, -1.2*sc, h-0.5]) cube([L, 2.4*sc, 0.5]);
        translate([x0-L, -0.2, h]) cube([0.4, 0.4, 3.0*sc]);
    }
}

// ---------- 3D segments ----------
module seg_main(k) {
    hh = H(k);
    cext(hh) body2d(k);
    if (k==0) {
        // skull dome, brows, horns, eyes
        translate([0,0,hh-0.01]) cext(1.6) offset(delta=-1.2*sc)
            hull() { circle(5*sc); translate([7*sc,0]) circle(2.6*sc); }
        mirrory() hull() { translate([-0.8*sc,6*sc,0]) cylinder(r=0.9*sc,h=hh+1.4);
                           translate([1.2*sc,3.3*sc,0]) cylinder(r=0.7*sc,h=hh+1.6); }
        horns3d();
    }
    if (k>0) spike(k);
    if (k==N-1) translate([0,0,0]) at(k) spike_tail();
    if (k==2) {
        cext(4.8) front_legs2d();
        at(2) mirrory() {
            linear_extrude(1.4) wing_membrane2d();
            linear_extrude(3.6) { bone2d(wing_root,wrist,2.8,2.2);
                for (t=tips) bone2d(wrist,t,1.8,0.8);
                translate(wrist*sc) circle(1.7*sc); }
        }
    }
    if (k==3) cext(5.0) hind_legs2d();
}
module spike_tail() {}

module seg(k) {
    difference() {
        seg_main(k);
        if (k<N-1) at(k+1) translate([0,0,-1]) cylinder(r=R(k+1)+clr, h=40);
        if (k>0) at(k) {
            cavity(hj(k));
            translate([0,0,-1]) linear_extrude(40) wedge2d(k);
        }
        if (k==0) {  // eye sockets with eyeball, nostrils
            mirrory() {
                translate([2.6*sc,4.6*sc,H(0)-1.5]) difference() {
                    cylinder(r=1.9*sc,h=10); cylinder(r=1.1*sc,h=1.2); }
                translate([11.2*sc,1.5*sc,H(0)-1.4]) cylinder(r=0.65*sc,h=10);
            }
        }
    }
    if (k<N-1) at(k+1) {
        pin(hj(k+1));
        translate([0,-wn/2,0]) cube([R(k+1)+clr+1.5, wn, hj(k+1)]);
    }
}

module dragon() for (k=[0:N-1]) seg(k);

// ---------- test joint: two short segments ----------
module test_joint() {
    // reuse chest(2)->hip(3) geometry without legs/wings
    module tb(k) cext(H(k)) body2d(k);
    difference() {
        intersection() { tb(2); at(2) translate([-20,-R(2),-1]) cube([40, 2*R(2), 30]); }
        at(3) translate([0,0,-1]) cylinder(r=R(3)+clr, h=40);
    }
    at(3) { pin(hj(3)); translate([0,-wn/2,0]) cube([R(3)+clr+1.5, wn, hj(3)]); }
    difference() {
        at(3) cext(H(3)) difference() { circle(R(3)); wedge2d(3); }
        at(3) { cavity(hj(3)); translate([0,0,-1]) linear_extrude(40) wedge2d(3); }
    }
}

// ---------- 2D collision check ----------
module foot2d(k) {
    body2d(k);
    if (k==0) projection() horns3d();
    if (k==2) { front_legs2d(); wings2d(); }
    if (k==3) hind_legs2d();
    if (k<N-1) at(k+1) { circle(rp2); translate([0,-wn/2]) square([R(k+1)+clr+1.5, wn]); }
}
function ang(j) = pose == 99 ? ((j%2)*2-1)*20 : pose;
module chainrot(k, j=1) {
    if (j>k) children();
    else translate([c(j),0]) rotate(ang(j)) translate([-c(j),0]) chainrot(k, j+1) children();
}
module check() for (i=[0:N-2]) for (k=[i+1:N-1]) intersection() {
    chainrot(i) offset(delta=0.1) foot2d(i);
    difference() {
        chainrot(k) offset(delta=0.1) foot2d(k);
        if (k==i+1) chainrot(k) at(k) circle(rp2+clr+0.4);
    }
}

if (part=="dragon") dragon();
else if (part=="test_joint") test_joint();
else if (part=="check") check();
else if (part=="joint_section") difference() { test_joint(); translate([-100,0,-1]) cube([200,50,50]); }
