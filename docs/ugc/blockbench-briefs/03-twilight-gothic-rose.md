# Blockbench Brief — Twilight Gothic Rose

**Set ID:** `twilight_gothic_rose`  
**Trend:** Gothic (DTI S-tier ~74%)  
**Bundle:** 1,399 R$  
**Concept:** `docs/visual-ref/fashion/teen-trend/teen-twilight-gothic-rose.png`

---

## Visual direction

- Black velvet + deep purple twilight accents
- Corset boning lines visible (embossed, ไม่ใช่ expose มากเกิน — Roblox moderation safe)
- Platform boots สูง — signature Gothic DTI
- Rose motif ที่ corset center (IP-safe original rose, ไม่ใช่ franchise)
- Aura: purple-black particle smoke

---

## Piece 1 — `gothic_corset_top` (Velvet Corset Top)

| Field | Spec |
|-------|------|
| Slot | Shirt |
| Roblox type | `LayeredClothing` Torso |
| File | `gothic_corset_top.bbmodel` |
| Max tris | 3,400 |
| Color | Velvet black #1A1A24, boning gold #D4AF37, rose crimson #8B1538 |

### Modeling notes

1. Sweetheart neckline — moderation safe coverage
2. 6 vertical boning strips (raised 0.05 stud)
3. Center **rose emblem** flat emboss 1 stud diameter
4. Off-shoulder optional straps (thin, 0.15 stud)
5. Material: Fabric + slight sheen on velvet zones

---

## Piece 2 — `gothic_layer_skirt` (Layered Midi Skirt)

| Field | Spec |
|-------|------|
| Slot | Pants |
| Roblox type | `LayeredClothing` Legs (skirt) |
| File | `gothic_layer_skirt.bbmodel` |
| Max tris | 3,000 |
| Color | Outer black, inner tulle purple #4A2040 transparency 0.5 |

### Modeling notes

1. **3 layers:** outer velvet midi, tulle mid, short underskirt
2. Asymmetric hem +1 stud longer at back
3. Lace trim at hem — alpha plane
4. Physics: none (static layers)

---

## Piece 3 — `gothic_choker_stack` (Choker Stack)

| Field | Spec |
|-------|------|
| Slot | Neck |
| Roblox type | `Accessory` Neck |
| File | `gothic_choker_stack.bbmodel` |
| Max tris | 1,400 |
| Attach | Neck |

### Modeling notes

1. **3 chokers stacked:** velvet band, thin chain, spike ring (blunt spikes — moderation safe)
2. Center **rose charm** matching corset
3. Metals: gunmetal #4A4A52 + gold accents

---

## Piece 4 — `gothic_platform_boots` (Platform Boots)

| Field | Spec |
|-------|------|
| Slot | Shoes |
| Roblox type | `LayeredClothing` Shoes |
| File | `gothic_platform_boots.bbmodel` |
| Max tris | 2,200 |
| Color | Black boot, gold buckle, purple sole edge |

### Modeling notes

1. Knee-high platform boot — platform 0.6 stud height
2. 4 buckle straps per boot (left side)
3. Heel block 0.8 stud
4. Highest poly piece — optimize buckles to quads

---

## Piece 5 — `gothic_dark_aura` (Twilight Aura) — VFX ONLY

| Field | Spec |
|-------|------|
| Implementation | `VFX/GothicTwilightAura.luau` |
| Particles | Purple smoke wisps + rose petal rare spawn |
| Light | PointLight purple #6B2D5B, range 8 |

---

## Assembly checklist

```
[ ] gothic_corset_top.bbmodel
[ ] gothic_layer_skirt.bbmodel
[ ] gothic_choker_stack.bbmodel
[ ] gothic_platform_boots.bbmodel
[ ] VFX aura
[ ] Moderation self-review (coverage, spikes blunt)
[ ] registerMesh × 4
```
