# Blockbench Briefs — Tier S Teen Trend (4 Sets)

**Priority:** P0 · **Date:** 8 มิถุนายน 2026  
**Sets:** Coquette · Old Money · Gothic · Preppy  
**Total meshes:** 20 (aura = VFX ไม่ทำ mesh)

---

## Tier S ชุดที่ทำก่อน

| ลำดับ | Set ID | Brief | Concept | ชิ้น mesh |
|-------|--------|-------|---------|-----------|
| 1 | `coquette_ribbon_dream` | [01-coquette-ribbon-dream.md](01-coquette-ribbon-dream.md) | `teen-trend/teen-coquette-ribbon-dream.png` | 4 |
| 2 | `marina_old_money` | [02-marina-old-money.md](02-marina-old-money.md) | `teen-trend/teen-marina-old-money.png` | 5 |
| 3 | `twilight_gothic_rose` | [03-twilight-gothic-rose.md](03-twilight-gothic-rose.md) | `teen-trend/teen-twilight-gothic-rose.png` | 4 |
| 4 | `academy_preppy_pink` | [04-academy-preppy-pink.md](04-academy-preppy-pink.md) | `teen-trend/teen-academy-preppy-pink.png` | 5 |

---

## Global rules (ทุกชุด)

### Prism palette

| Name | RGB | ใช้เมื่อ |
|------|-----|----------|
| Pearl | 245, 245, 240 | ผ้าหลัก / old money |
| Gold | 212, 175, 55 | trim, buttons, chain |
| Cyan | 0, 229, 255 | Prism accent (เบา) |
| Soft Pink | 255, 182, 193 | Coquette / Preppy |
| Charcoal | 30, 36, 50 | Gothic |

### Blockbench project

- Template: **Roblox R15** (plugin) หรือ Generic Model + manual rig
- Unit: 1 Blockbench unit = 1 stud (approx)
- Origin: avatar pelvis (0,0,0) — ยืนตรง T-pose reference
- Export: `assets/ugc/blockbench/tier-s/{item_id}.bbmodel`

### Poly budget (mobile-safe)

| Slot | Max tris |
|------|----------|
| 3D Shirt / Dress layer | 3,500 |
| 3D Pants / Skirt | 2,800 |
| Shoes | 2,000 |
| Hair | 2,500 |
| Neck / Face | 1,200 |
| Back bag | 3,000 |

### Aura pieces (`*_aura`)

ไม่สร้าง mesh — ใช้ `ParticleEmitter` + `PointLight` ใน Studio แยก VFX module

### หลัง export

1. Upload ใน Creator Dashboard → copy Asset ID
2. `PrismCatalogAssets.registerMesh(itemId, assetId)`
3. Developer Product → `registerProduct(itemId, productId)`

---

## Build order (แนะนำ)

```
Week 1: coquette_lace_dress + preppy_sweater_vest + gothic_corset_top
Week 2: skirts/pants + shoes ทั้ง 4 ชุด
Week 3: hair + neck + back accessories
Week 4: Studio assemble + shop thumbnail test
```

Manifest: `assets/ugc/blockbench/tier-s/manifest.json`
