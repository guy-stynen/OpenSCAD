// Flexi draak SCHATTIG (cute/kawaii) - print-in-place articulated dragon
// OpenSCAD 2021.01. Print flat, no supports.
// part = "dragon" | "test_joint" | "joint_section" | "check"
part = "dragon";
len_total = 100;   // nose to tail tip (mm)
clr  = 0.4;        // joint clearance
nt   = 4;          // number of tail segments (3..6)
th   = 7;          // body thickness (chest)
rear = 5.5;        // rear length of each segment behind its socket
rear0 = 8.5;       // head: distance behind neck socket
swing = 22;        // max swing per joint (deg)
pose = 0;          // only for part="check": joint angle
$fn = 40;

// joint (fixed, not scaled)
rp1 = 1.8; rp2 = 2.5; wn = 2.2;

// ---------- layout ----------
N = 4 + nt;               // 0 head,1 neck,2 chest,3 hip,4.. tail
function Rn(k) = k==0 ? 8 : k==1 ? 6 : k==2 ? 10 : k==3 ? 9.5 :
    7.2 - (7.2-4.8)*(k-4)/max(1,nt-1);
function cn(k,s) = k==0 ? 0 : cn(k-1,s) - (Rn(k)*s + clr + (k==1 ? rear0 : rear)*s);
natural = 13.5 + 12 - cn(N-1,1);
sc = len_total / natural;
function R(k) = max(Rn(k)*sc, 4.3);
function c(k) = k==0 ? 0 : c(k-1) - (R(k) + clr + (k==1 ? rear0 : rear)*sc);
function H(k) = k==0 ? th+0.5 : k==1 ? th-0.5 : k==2 ? th+0.5 : k==3 ? th :
    max(5.6, th-0.5 - 1.2*(k-4)/max(1,nt-1));
function hj(k) = min(H(k-1), H(k));          // joint height of joint at c(k)
echo(str("scale=", sc, " total length=", 13.5*sc - (c(N-1) - 12*sc)));

// ---------- helpers ----------
module cext(h, ch=2.0) {   // extrude with rounded (quarter circle) stepped top
    n = 5; linear_extrude(h-ch) children();
    for (i=[0:n-1]) let(z=(i+1)*ch/n) translate([0,0,h-ch+i*ch/n])
        linear_extrude(ch/n+0.001) offset(delta=-(ch - sqrt(ch*ch - z*z*0.92))) children();
}
module dome(r, h) for (i=[0:5]) let(z=i*h/6) translate([0,0,z])
    cylinder(r=max(0.3, r*sqrt(1-pow(z/h,2))), h=h/6+0.001);
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
    hull() { circle(12.5*s); translate([5*s,0]) scale([1,1.1]) circle(8.5*s); }
    mirrory() translate([-5.5*s,9.5*s]) circle(3.0*s);   // round ear/cheek puffs
}
module leg2d(p0, pk, p1, w, dir) {
    hull() { translate(p0) circle(w/2); translate(p1) circle(w*0.55); }
    translate(p1) circle(w*0.7);
}
module beans(p1, w, dir) {   // toe beans, raised on top of the foot
    translate(p1) { bean(w*0.3, 4.6, 0.9);
        for (a=[-45,0,45]) translate(w*0.47*[cos(dir+a), sin(dir+a)]) bean(w*0.15, 4.2, 0.8); }
}
module bean(r, z, h) { cylinder(r=r, h=z); translate([0,0,z-0.01]) dome(r, h);
}
FL=[[0*sc,R(2)*0.55],[3.5*sc,R(2)+3.5*sc]]; HL=[[-1*sc,R(3)*0.55],[-3*sc,R(3)+4.2*sc]];
module front_legs2d() at(2) mirrory() leg2d(FL[0],0,FL[1],4.8*sc,40);
module hind_legs2d() at(3) mirrory() leg2d(HL[0],0,HL[1],5.4*sc,120);
// wing in chest coordinates (y>0)
wing_root=[2.5,8]; wrist=[3.5,17]; tips=[[-0.5,25],[-5.5,22],[-8.5,16.5]];
module wing_membrane2d() scale(sc) difference() {
    hull() { translate([5,7]) circle(1.5); translate([-3.5,7.5]) circle(1.5);
             translate(wrist) circle(2); for (t=tips) translate(t) circle(1.4); }
    for (p=[[-4.4,24.9,2.4],[-9.4,19.8,2.4],[-8,11.3,3]]) translate([p[0],p[1]]) circle(p[2]);
}
module wings2d() at(2) mirrory() wing_membrane2d();
module bone2d(a,b,w1,w2) hull() { translate(a*sc) circle(w1/2); translate(b*sc) circle(w2/2); }

module body2d(k) difference() {
    union() {
        if (k==0) head2d(); else at(k) circle(R(k));
        if (k>0 && k<N-1) hull() { at(k) circle(R(k)); at(k+1) circle(0.85*min(R(k),R(k+1))); }
        if (k==N-1) at(k) {
            hull() { circle(R(k)); translate([-4*sc,0]) circle(2.2*sc); }
            spade2d();
        }
    }
    if (k<N-1) at(k+1) circle(R(k+1)+clr);
    if (k>0) at(k) wedge2d(k);
}
module spade2d() scale(sc) offset(r=0.8) offset(delta=-0.8) union() {   // heart
    mirrory() hull() { translate([-5.5,2.4]) circle(3.0); translate([-11.5,0]) circle(0.9); } }

module horns3d() {
    s=sc; hh=H(0);
    mirrory() {
        hull() { translate([-2.5*s,4.2*s,0]) cylinder(r=1.8*s,h=hh+1.8);
                 translate([-7*s,7.5*s,0]) cylinder(r=1.1*s,h=hh-0.8); }
        hull() { translate([-7*s,7.5*s,0]) cylinder(r=1.1*s,h=hh-0.8);
                 translate([-10.5*s,9.6*s,0]) cylinder(r=0.35,h=1.6); }
    }
}
module spike(k) { // two soft round back bumps behind the socket
    L = rear*sc - 1.2; x0 = c(k) - 0.9; h = H(k); r = min(1.9, L/3.2);
    for (f=[0.3,0.75]) translate([x0 - L*f, 0, h-0.6]) dome(r*(1.2-f*0.4), 1.6+0.6);
}
// ---------- 3D segments ----------
module seg_main(k) {
    hh = H(k);
    cext(hh) body2d(k);
    if (k==0) {
        mirrory() {
            translate([2*sc,5.4*sc,hh-0.3]) dome(4.0*sc, 2.0);         // big eyeballs
            translate([-5*sc,7.5*sc,hh-0.6]) dome(2.6*sc, 2.8);          // nub horns
            translate([7.5*sc,7.8*sc,hh-0.8]) dome(1.8*sc, 1.0);          // cheeks
        }
        translate([-3*sc,0,hh-0.6]) dome(1.6*sc, 1.6);                     // head bump
    }
    if (k>0) spike(k);
    if (k==N-1) translate([0,0,0]) at(k) spike_tail();
    if (k==2) {
        cext(4.8) front_legs2d(); at(2) mirrory() beans(FL[1],4.8*sc,40);
        at(2) mirrory() {
            linear_extrude(1.6) wing_membrane2d();
            linear_extrude(3.2) { bone2d(wing_root,wrist,2.8,2.2);
                for (t=tips) bone2d(wrist,t,1.8,1.4);
                translate(wrist*sc) circle(1.7*sc); }
        }
    }
    if (k==3) { cext(5.0) hind_legs2d(); at(3) mirrory() beans(HL[1],5.4*sc,120); }
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
        if (k==0) {  // pupils with highlight, nostrils, smile
            mirrory() {
                translate([2.8*sc,5.2*sc,H(0)+1.0]) difference() {
                    cylinder(r=2.4*sc,h=10);
                    translate([-0.8*sc,0.8*sc,-1]) cylinder(r=0.85*sc,h=20); }
                translate([12*sc,1.8*sc,H(0)-0.6]) cylinder(r=0.55*sc,h=10);
            }
            translate([6.5*sc,0,H(0)-1.0]) linear_extrude(10) intersection() {
                difference() { circle(4.2*sc); circle(3.4*sc); }
                rotate(-50) square(20); rotate(-40) square(20); mirror([0,1]) rotate(-50) square(20); }
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
