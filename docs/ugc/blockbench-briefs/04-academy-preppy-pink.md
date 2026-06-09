# Blockbench Brief — Academy Preppy Pink

**Set ID:** `academy_preppy_pink`  
**Trend:** Preppy (Brookhaven 2026 #1 meta)  
**Bundle:** 1,099 R$  
**Concept:** `docs/visual-ref/fashion/teen-trend/teen-academy-preppy-pink.png`

---

## Visual direction

- Pink sweater vest over white collar (school preppy)
- Plaid mini skirt black/pink/white
- Mary Jane shoes + ribbon bow hair
- Designer school bag — status flex Brookhaven RP
- Colors: #FF69B4 vest, #FFFFFF collar, plaid #1A1A1A + #FFB6C1

---

## Piece 1 — `preppy_sweater_vest` (Pink Sweater Vest)

| Field | Spec |
|-------|------|
| Slot | Shirt |
| Roblox type | `LayeredClothing` Torso |
| File | `preppy_sweater_vest.bbmodel` |
| Max tris | 3,000 |
| Color | Pink knit #FF69B4, white collar #FFFFFF |

### Modeling notes

1. **V-neck sweater vest** over **white Peter Pan collar** (2 mesh layers)
2. Ribbed hem + armholes (texture normal)
3. Gold button row center (3 buttons) #D4AF37
4. Fit: slightly loose preppy — ไม่ tight bodycon
5. Collar extends 0.4 stud above neckline

---

## Piece 2 — `preppy_plaid_skirt` (Plaid Mini Skirt)

| Field | Spec |
|-------|------|
| Slot | Pants |
| Roblox type | `LayeredClothing` Legs |
| File | `preppy_plaid_skirt.bbmodel` |
| Max tris | 2,600 |
| UV | Plaid pattern 256×256 repeating |

### Modeling notes

1. Pleated mini skirt — 12 pleats
2. Plaid: black, pink, white diagonal
3. High waist band 0.5 stud
4. Hem 4 studs below waist — Brookhaven teen proportion

---

## Piece 3 — `preppy_mary_janes` (Mary Jane Shoes)

| Field | Spec |
|-------|------|
| Slot | Shoes |
| Roblox type | `LayeredClothing` Shoes |
| File | `preppy_mary_janes.bbmodel` |
| Max tris | 1,900 |
| Color | Black patent #1A1A1A, pink sock trim optional |

### Modeling notes

1. Similar base to coquette mary janes แต่ **black patent** + pink bow on strap
2. Share shoe base mesh template — retexture only (save time)

---

## Piece 4 — `preppy_ribbon_bow` (Ribbon Bow Hair)

| Field | Spec |
|-------|------|
| Slot | Hair |
| Roblox type | `Accessory` Hair (partial — bow + bangs overlay) |
| File | `preppy_ribbon_bow.bbmodel` |
| Max tris | 1,800 |
| Attach | Head top |

### Modeling notes

1. Half-up hairstyle + **large pink bow** center-top
2. Optional heart-shaped clip gold accent (Prism brand)
3. Hair: dark brown #3D2314 straight

---

## Piece 5 — `preppy_designer_bag` (Designer School Bag)

| Field | Spec |
|-------|------|
| Slot | Back |
| Roblox type | `Accessory` Back |
| File | `preppy_designer_bag.bbmodel` |
| Max tris | 2,800 |
| Attach | UpperTorso, offset to right shoulder |

### Modeling notes

1. Structured handbag 1.5 × 1.2 studs — **ไม่ใส่ logo แบรนด์จริง**
2. Gold chain strap + pink leather body
3. Prism cyan stitch line ที่ขอบ (brand)
4. Optional charm: tiny key dangle

---

## Assembly checklist

```
[ ] preppy_sweater_vest.bbmodel
[ ] preppy_plaid_skirt.bbmodel
[ ] preppy_mary_janes.bbmodel (reuse coquette shoe rig)
[ ] preppy_ribbon_bow.bbmodel
[ ] preppy_designer_bag.bbmodel
[ ] Brookhaven RP screenshot test
[ ] registerMesh × 5
```

---

## Shared template note

`preppy_mary_janes` และ `coquette_mary_janes` ใช้ **shoe rig เดียวกัน** — แยกแค่ material/strap color ใน Blockbench
