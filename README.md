# OpenSCAD — 3D printing projects

## Model Y sliding console organizer

File: `model_y_sliding_console_organizer.scad`

Drop-in organizer for the **front** centre-console bay with the sliding lid on a **Tesla Model Y 2020–2024** (Gen‑2 console, not Juniper / not the under-armrest cubby).

### Holds
| Pocket | Sized for |
|---|---|
| **Card slot** | Credit / e-charge cards (ISO 85.6×54 mm), upright in a ~4 mm throat |
| **Coin well** | Loose change (~44×44 mm) |
| **Pen trough** | Pens / pencils along the cup-holder end (~14 mm wide) |
| **Sunglasses bay** | Folded sunglasses in the main open area |

### Layout (top view)
```
 screen end
┌──────────┬─────────────────────────┐
│  cards   │                         │
│          │      sunglasses         │
├──────────┤                         │
│  coins   │                         │
├──────────┴─────────────────────────┤
│           pens                     │
└────────────────────────────────────┘
 cup holders / USB
```

Side **rail lips** let the tray slide; a **cable notch** at the cup-holder end feeds USB from the ports below.

### Default size
| Dim | mm | Notes |
|---|---|---|
| Width | 167 | Gen‑2 trays ≈165; Y often a touch wider |
| Length | 145 | Slightly long so pockets stay reachable under the lid |
| Height | 55 | Leave lid clearance |

Tune `overall_w` / `overall_l` / `overall_h` (and the pocket params) at the top of the `.scad` after measuring your console.

### Print
- **Material:** PETG or ABS/ASA (PLA can soften in a hot cabin)
- **Layer:** 0.2 mm · **Walls:** 3–4 · **Infill:** 20–40%
- **Orientation:** open face up · **Supports:** none

### Export STL
Open in OpenSCAD → **F6** (Render) → **File → Export → Export as STL**.
