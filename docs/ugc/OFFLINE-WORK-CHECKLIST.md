# Blockbench UGC — Offline Work Checklist

**Date:** 9 มิ.ถุนายน 2026 · **No Roblox upload required**

Work through Tier S briefs locally before Public Save (~10 Jun 2026).

---

## Tier S sets (20 meshes)

| Set | Brief | Meshes | Status |
|-----|-------|--------|--------|
| coquette_ribbon_dream | [01-coquette-ribbon-dream.md](blockbench-briefs/01-coquette-ribbon-dream.md) | 4 | [ ] |
| marina_old_money | [02-marina-old-money.md](blockbench-briefs/02-marina-old-money.md) | 5 | [ ] |
| twilight_gothic_rose | [03-twilight-gothic-rose.md](blockbench-briefs/03-twilight-gothic-rose.md) | 4 | [ ] |
| academy_preppy_pink | [04-academy-preppy-pink.md](blockbench-briefs/04-academy-preppy-pink.md) | 5 | [ ] |

---

## Per-mesh checklist

For each `.bbmodel` export:

1. [ ] Prism palette only (Pearl / Gold / Cyan accents — see [TIER-S-INDEX.md](blockbench-briefs/TIER-S-INDEX.md))
2. [ ] No franchise logos, text, or copyrighted shapes
3. [ ] Export `.fbx` + PNG texture to `assets/ugc/tier-s/<set-id>/`
4. [ ] Record provenance line in set folder `PROVENANCE.txt` (source: original Blockbench, date, author)
5. [ ] Triangle budget ≤ 4K tris per accessory (Roblox UGC guideline)

---

## After Public Save (manual Roblox only)

- Upload via Creator Dashboard → UGC catalog (group-owned)
- Wire asset IDs into `CatalogSecrets.luau` when products are registered
- Run `python3 scripts/validate-p0-publish.py`

---

## Reference

- Visual concepts: `docs/visual-ref/fashion/teen-trend/`
- Catalog brief: [CATALOG-BRIEF.md](CATALOG-BRIEF.md)
- Pipeline: [BLOCKBENCH-PIPELINE.md](BLOCKBENCH-PIPELINE.md)
