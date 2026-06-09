# Part Budget Estimates — Hybrid Microcurve

GDD targets: **mobile < 10,000** · **PC < 18,000** streamed parts per place.

## Per-component estimates (Hybrid)

| Component | Micro-only | Hybrid (target) |
|-----------|------------|-----------------|
| Dome R=20 stud | ~4,000 | ~80 (mesh) + ~400 trim |
| Arch span 30 stud | ~1,200 | ~40 + ~200 trim |
| Glow lane 100 stud | ~800 | ~600 micro |
| Plaza disc R=120 | ~6,000 | ~200 + ~1,000 trim |
| Transit stop | ~500 | ~350 |

## Per-place MVP greybox budgets (configured in WorldBuildConfig)

| Place | MaxParts | LOD distance |
|-------|----------|--------------|
| Hub | 8,000 | 512 |
| Solhaven | 8,000 | 512 |
| Nocturne | 8,000 | 480 |
| EternityCity | 16,000 | 640 |
| DeathValley | 7,000 | 480 |

## LOD rule

- **> LOD distance:** CSG/mesh silhouette only (no micro-trim)
- **< 128 stud:** full micro-trim visible
