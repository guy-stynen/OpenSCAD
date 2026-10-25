# LEGO® achtbaan-looping (3D-print, OpenSCAD)

Parametrische verticale looping die past op het officiële LEGO roller-coaster railsysteem
(10261, 10303, 31084 – rails 26022, 25059, 25061, 26559/26560/26561, 34738, 80562, 80564).
Ontworpen voor een **FlashForge Adventurer 4** (220 × 200 × 250 mm, nozzle 0,4, PLA).

![assembly](preview/lego_looping_assembly_persp_v1.png)

## Concept
Zelfde aanpak als de officiële looping van **10303 Loop Coaster**: 4 identieke **kwartstukken**
(zoals LEGO 80564 "Quarter Loop 4×12×10"), elk 90° gebogen met **2 noppen (16 mm) zijwaartse verschuiving**.
In- en uitgang liggen daardoor 8 noppen (64 mm) naast elkaar, de looping is 192 × 192 mm (24 × 24 noppen).

Elk uiteinde is een exacte kopie van een LEGO-railuiteinde (gemeten uit LDraw 26022.dat):
1×2 "plaat"-eindblok, 2 noppen bovenop, 1×2 anti-nop eronder. Verbinden gaat zoals bij echte
LEGO-rails: een 2×2 plaat (of de geprinte `joiner`) over de naad.

## Onderdelen (map `stl/`)
| Bestand | Aantal | Orientatie |
|---|---|---|
| `lego_looping_quarter_print_v1.stl` | 4 | op de zijkant (kiel op bed), supports alleen onder de onderste rail |
| `lego_looping_frame_print_v1.stl` | 2 | plat, geen supports (2e frame = zelfde stuk, 180° gedraaid geplaatst) |
| `lego_looping_pad_v1.stl` | 2 | noppen omhoog |
| `lego_looping_base_v1.stl` | 1 | plat |
| `lego_looping_joiner_v1.stl` | 1 | noppen omhoog (of gebruik een echte LEGO 2×2 plaat) |
| `lego_looping_test_set_v1.stl` | 1 | **eerst printen!** kort railstuk + 2×2 joiner om de pasvorm te testen |

## Parameters (`lego_looping.scad`)
`R_out` (88 → stud-raster), `q_offset` (16 = 2 noppen), `fit_tol` (0,15), `stud_tol` (0,05),
`slide_tol` (0,20), `frame_gap`, `base_h`, `keel_t`, `n_seg`, `sleeper_pitch`, `ghost`.
Renderen: `openscad -D 'part="quarter_print"' -o q.stl lego_looping.scad`
(parts: assembly, quarter, quarter_print, base, frame, frame_print, pad, joiner, test_track, test_set, connector_detail).

## Printinstellingen
PLA · laag 0,2 mm · 3–4 wanden · 20–30 % infill · brim op de kwartstukken ·
supports "alleen vanaf bed", overhang-drempel ±55–60° (alleen onder de onderste rail; de rest is zelfdragend).

## Opbouw
1. Base op LEGO-grondplaat; ingang-eindblok en uitgang-eindblok van de looping op de nop-pads.
2. Kwartstukken onderling verbinden: zijnaden met een `pad` (noppen in beide anti-noppen),
   bovenste naad met de `joiner` / 2×2 plaat.
3. Frames van buitenaf schuiven: de rib glijdt in de groef van de pad, dan het frame ±2 mm laten zakken op de grondplaat.
4. Gewone LEGO-rails aan in- en uitgang: hun eindblok op dezelfde nop-pad van de base (rails liggen dus 1 plaat hoger dan de grondplaat).

## Risico's
- De wagentjes hangen ondersteboven met de **haken onder de rail** – de rail-onderkant moet glad zijn (supportsporen bijschuren).
- Er is genoeg **snelheid** nodig (≈2 m/s bij de ingang; LEGO 10303 gebruikt een hoge lifttoren).
- Noppen in de eindblokken worden liggend geprint → print eerst de test-set en pas `fit_tol`/`stud_tol` aan.

Railprofiel afgeleid van LDraw-onderdelen (CC BY 4.0, ldraw.org). LEGO® is een merk van de LEGO Group; dit is geen officieel product.
