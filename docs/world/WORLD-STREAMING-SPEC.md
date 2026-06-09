# World Streaming Spec — Microcurve Places

## Studio setup (per place file)

1. Enable **StreamingEnabled** in Workspace properties
2. Set **StreamingTargetRadius** per profile in `WorldBuildConfig.luau`
3. Anchor large district folders at fixed positions (builders already use anchored parts)

## Streaming anchors (Eternity City)

| District | Anchor position (studs) | Radius |
|----------|-------------------------|--------|
| AuroraSpireDistrict | (0, 0, -120) | 200 |
| CanalPromenade | (80, 0, 60) | 180 |
| SkyRailPlaza | (0, 25, -40) | 160 |
| TwilightOverpass | (-100, 0, 80) | 120 |
| Eternity Sanctuary | (0, 0, 0) | 280 |

## LOD rules

| Distance | Render |
|----------|--------|
| > `LodDistanceStuds` | CSG/mesh silhouette only |
| < `MicroTrimDistanceStuds` (128) | Full micro-trim visible |

## Part budgets (`GameConfig.WorldBuild`)

| Platform | Max streamed parts |
|----------|-------------------|
| Mobile | 10,000 |
| PC | 18,000 |

Per-place caps in `WorldBuildConfig.Profiles[*].MaxParts`.

## Validation

- Developer Console → count parts under `Utopia*` model
- Walk curve edges at 10 stud distance — corners should not read as blocky
- Mobile test: enable StreamingEnabled + mid-tier device emulator
