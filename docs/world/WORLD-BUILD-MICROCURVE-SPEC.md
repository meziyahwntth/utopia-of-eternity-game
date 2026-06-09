# World Build — Hybrid Microcurve Spec

## Inspiration

Technique study from **Quant Build** (Thailand, 2nd place MrBeast Minecraft "Build Your Country"). We adopt **voxel approximation** and **micro-block curves** — not Thai landmark content.

- Study notes: `docs/reference/quant-build-study/`
- Discord map download: https://discord.gg/ZmhqqVMs (Free Download channel)

## Pipeline

```
WorldBootstrap → place builder → OrganicCSG (silhouette) + MicroCurveBuilder (trim)
```

| Module | Path |
|--------|------|
| `WorldBuildConfig` | `src/ReplicatedStorage/Modules/WorldBuildConfig.luau` |
| `MicroCurveBuilder` | `src/ReplicatedStorage/Modules/MicroCurveBuilder.luau` |
| `OrganicCSGBuilder` | `src/ServerScriptService/World/OrganicCSGBuilder.luau` |
| `ArchRibKit` | `src/ServerStorage/WorldKits/ArchRibKit.luau` |
| `WorldBootstrap` | `src/ServerScriptService/World/WorldBootstrap.luau` |

## Place builders

| Place | Builder | Model name |
|-------|---------|------------|
| Hub | `HubWorldBuilder` | `UtopiaHubWorld` |
| Solhaven | `SolhavenWorldBuilder` | `UtopiaSolhaven` |
| Nocturne | `NocturneWorldBuilder` | `UtopiaNocturne` |
| Eternity City | `EternityCityWorldBuilder` | `UtopiaEternityCity` |
| Death Valley | `DeathValleyWorldBuilder` | `UtopiaDeathValley` |

## API summary

### MicroCurveBuilder

- `fillCircle(center, radiusStuds, y, opts)`
- `fillEllipse(center, radiusX, radiusZ, y, opts)`
- `fillDome(center, radiusStuds, heightStuds, opts)`
- `fillArc(points, widthStuds, opts)`

`opts.voxelStuds`: 0.05–0.2 (per-place in `WorldBuildConfig`)

### OrganicCSGBuilder

- `createDome`, `createArch`, `createSpire`, `createGlassBand`

## Palette (Prism Solarpunk)

| Name | RGB |
|------|-----|
| Pearl | 245, 245, 240 |
| Gold | 212, 175, 55 |
| Cyan | 0, 229, 255 |

## Studio checklist

1. `rojo serve` → Play
2. Confirm correct `Utopia*` model for current place
3. Part count within budget (see console `[Utopia WorldBuild]` log)
4. Curved sanctuary ring + district landmarks visible
5. Hub: teleport kiosks + shuttle stop functional
