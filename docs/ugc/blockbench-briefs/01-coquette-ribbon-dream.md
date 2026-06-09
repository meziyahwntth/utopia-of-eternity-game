# Blockbench Brief — Coquette Ribbon Dream

**Set ID:** `coquette_ribbon_dream`  
**Trend:** Coquette (DTI S-tier ~70%)  
**Bundle:** 1,199 R$  
**Concept:** `docs/visual-ref/fashion/teen-trend/teen-coquette-ribbon-dream.png`

---

## Visual direction

- Soft pink satin + white lace overlay
- Ribbon bows at collar and hair
- Pearl-cyan micro accent ที่ขอบ lace (Prism brand)
- Silhouette: fitted bodice + flared skirt midi
- Mood: romantic, feminine, TikTok coquette

---

## Piece 1 — `coquette_lace_dress` (Lace Dream Dress)

| Field | Spec |
|-------|------|
| Slot | Shirt (3D Layered Torso + Legs combo หรือแยก 2 ไฟล์ถ้า engine ต้องการ) |
| Roblox type | `LayeredClothing` — Dress (Torso+Legs single mesh) |
| File | `coquette_lace_dress.bbmodel` |
| Max tris | 3,500 |
| Material | SmoothPlastic body + Lace alpha plane (transparency 0.35) |

### Modeling notes

1. **Bodice:** fitted to R15 UpperTorso + LowerTorso cage
2. **Skirt:** 8-panel flare, hem 2 studs below knee
3. **Lace collar:** separate thin mesh plane, gold thread trim RGB(212,175,55)
4. **Back bow:** 12×8 stud ribbon at upper back — เป็นส่วนหนึ่งของ mesh
5. **UV:** 512×512 — pink base #FFB6C1, lace pattern white #FFFFFF

### QA

- [ ] ไม่ clip เมื่อ walk animation
- [ ] Arms ไม่ทะลุ lace shoulder
- [ ] Mobile < 3.5k tris

---

## Piece 2 — `coquette_bow_hair` (Ribbon Bow Hair)

| Field | Spec |
|-------|------|
| Slot | Hair |
| Roblox type | `Accessory` — Hair |
| File | `coquette_bow_hair.bbmodel` |
| Max tris | 2,500 |
| Attach | Head — offset Y +0.3, Z -0.1 |

### Modeling notes

1. Shoulder-length wavy hair + **large satin bow** on top-right
2. Bow: 3 studs wide, pink #FF69B4 with gold center knot
3. Hair color: soft blonde-pink gradient #FFE4E1 → #F5C6D0
4. Rig: static (no physics) — teen mobile budget

---

## Piece 3 — `coquette_mary_janes` (Pearl Mary Janes)

| Field | Spec |
|-------|------|
| Slot | Shoes |
| Roblox type | `LayeredClothing` LeftShoe + RightShoe (mirror) |
| File | `coquette_mary_janes.bbmodel` |
| Max tris | 2,000 (pair) |
| Color | Pearl white #F5F5F0, strap gold buckle |

### Modeling notes

1. Classic Mary Jane — rounded toe, 1-stud heel
2. Single strap per foot with rectangular gold buckle
3. Export L/R mirrored from one source mesh

---

## Piece 4 — `coquette_ribbon_choker` (Satin Ribbon Choker)

| Field | Spec |
|-------|------|
| Slot | Neck |
| Roblox type | `Accessory` — Neck |
| File | `coquette_ribbon_choker.bbmodel` |
| Max tris | 1,200 |
| Attach | Neck — flush to base of Head |

### Modeling notes

1. Thin satin band 0.4 stud height
2. Small bow center-front 1 stud
3. Optional tiny pearl drop (sphere 0.15 stud)

---

## Piece 5 — `coquette_soft_aura` (Soft Pink Aura) — VFX ONLY

ไม่ทำ Blockbench mesh

| Field | Spec |
|-------|------|
| Implementation | `VFX/CoquetteSoftAura.luau` |
| Particles | Soft pink motes, rate 8, lifetime 1.2s |
| Light | PointLight pink, range 6, brightness 0.4 |

---

## Assembly checklist

```
[ ] coquette_lace_dress.bbmodel
[ ] coquette_bow_hair.bbmodel
[ ] coquette_mary_janes.bbmodel
[ ] coquette_ribbon_choker.bbmodel
[ ] VFX aura module
[ ] Bundle thumbnail 512×512 from concept PNG
[ ] registerMesh × 4 + registerProduct bundle + pieces
```
