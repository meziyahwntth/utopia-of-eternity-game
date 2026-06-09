# Blockbench Brief — Marina Old Money

**Set ID:** `marina_old_money`  
**Trend:** Old Money / Quiet Luxury (DTI S-tier ~72%)  
**Bundle:** 1,299 R$  
**Concept:** `docs/visual-ref/fashion/teen-trend/teen-marina-old-money.png`

---

## Visual direction

- Neutral cream/linen palette — **no logos**
- Tailored silhouette, understated wealth
- Pearl + gold hardware only
- Prism cyan ใช้แค่ 5% (inner lining flash ไม่เห็นชัด)
- Mood: marina yacht club, Brookhaven influencer RP

---

## Piece 1 — `oldmoney_linen_blazer` (Linen Blazer)

| Field | Spec |
|-------|------|
| Slot | Shirt |
| Roblox type | `LayeredClothing` Torso (jacket layer) |
| File | `oldmoney_linen_blazer.bbmodel` |
| Max tris | 3,200 |
| Color | Linen cream #F5F0E6, buttons gold #D4AF37 |

### Modeling notes

1. Single-breasted blazer, 2 gold buttons
2. Structured shoulders + slight waist taper
3. Lapels: 45° notch, 0.3 stud depth
4. Sleeves end at wrist bone — ไม่ทับ watch accessory
5. Inner lining flash cyan #00E5FF (visible only on arm swing)

---

## Piece 2 — `oldmoney_tailored_pants` (Tailored Trousers)

| Field | Spec |
|-------|------|
| Slot | Pants |
| Roblox type | `LayeredClothing` Legs |
| File | `oldmoney_tailored_pants.bbmodel` |
| Max tris | 2,800 |
| Color | Taupe #C4B8A8 |

### Modeling notes

1. Straight leg, crease line down center (normal map or edge loop)
2. High waist sits at pelvis cage
3. Hem breaks at ankle — เปิดให้เห็น loafers

---

## Piece 3 — `oldmoney_pearl_stack` (Pearl Necklace Stack)

| Field | Spec |
|-------|------|
| Slot | Neck |
| Roblox type | `Accessory` Neck |
| File | `oldmoney_pearl_stack.bbmodel` |
| Max tris | 1,000 |
| Attach | Neck, rests on collarbone |

### Modeling notes

1. **Double strand** — 16 pearls per strand (instanced spheres, low poly icosphere)
2. Pearl color #FAF8F5, subtle specular
3. Clasp gold bar center-back

---

## Piece 4 — `oldmoney_loafers` (Classic Loafers)

| Field | Spec |
|-------|------|
| Slot | Shoes |
| Roblox type | `LayeredClothing` Shoes |
| File | `oldmoney_loafers.bbmodel` |
| Max tris | 1,800 |
| Color | Brown leather #8B6914, sole black |

### Modeling notes

1. Penny loafer silhouette — low heel
2. Gold horsebit detail optional (flat plane on vamp)
3. Mirror L/R export

---

## Piece 5 — `oldmoney_clutch` (Leather Clutch)

| Field | Spec |
|-------|------|
| Slot | Back |
| Roblox type | `Accessory` Back (หรือ Waist ถ้า clip น้อยกว่า) |
| File | `oldmoney_clutch.bbmodel` |
| Max tris | 1,500 |
| Attach | UpperTorso back, held in left hand pose optional |

### Modeling notes

1. Rectangular clutch 1.2 × 0.8 studs
2. Gold clasp rectangle center
3. **Hand-held variant:** attach to LeftHand with slight forward rotation
4. Leather texture #3D2B1F

---

## Assembly checklist

```
[ ] oldmoney_linen_blazer.bbmodel
[ ] oldmoney_tailored_pants.bbmodel
[ ] oldmoney_pearl_stack.bbmodel
[ ] oldmoney_loafers.bbmodel
[ ] oldmoney_clutch.bbmodel
[ ] Test with neutral skin tones 1–4
[ ] registerMesh × 5
```
