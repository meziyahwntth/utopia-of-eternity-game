# Quant Build Technique Notes → Roblox Hybrid Translation

## Core insight: voxel approximation

Quant Build achieves "no visible corners" by using **very small blocks** arranged on circle/dome algorithms (Minecraft voxel approximation). Curves read smooth when:

- Diameter ≥ 10–12 blocks (Minecraft) → in Roblox: radius ≥ 8 studs with 0.1 stud micro-parts
- Stepped circle outline (Bresenham / midpoint) then fill or hollow
- Domes: stack circles of decreasing radius per Y layer
- Stairs/slabs soften transitions on roofs and arches

## Minecraft → Roblox mapping (Hybrid pipeline)

| Quant Build (MC) | Utopia Hybrid (Roblox) |
|------------------|------------------------|
| 1×1 block grid | Micro-part 0.05–0.2 stud (`MicroCurveBuilder`) |
| Large domes / towers | `SpecialMesh` sphere/cylinder shells (`OrganicCSGBuilder`) |
| Gold trim / neon lanes | Micro-part `fillArc` on rib paths |
| Terrain hills / caves | `Terrain:FillBall` + smooth |
| Interior detail | Separate zone, LOD off when far |

## Zone study (Thailand map — technique only)

| MC zone | Technique observed | Utopia equivalent |
|---------|-------------------|-------------------|
| Floating market | Horizontal curves, water planes, dense micro-detail | Canal Promenade (cyan water, curved boardwalk) |
| Thai houses / rice fields | Terraced levels, repeating arch modules | Solhaven garden terraces |
| Nature (island, cave) | Organic terrain + cave mouth sphere subtract | Death Valley beacon + cave entrance |
| Festival | Vertical banners, circular plaza | Hub Prism Heart Plaza dome |

## Roblox implementation modules

- `MicroCurveBuilder.luau` — `fillCircle`, `fillDome`, `fillArc`, `fillEllipse`
- `OrganicCSGBuilder.luau` — `createDome`, `createArch`, `createSpire`
- `WorldBuildConfig.luau` — per-place voxel size and palette

## Weld strategy

Micro-parts parented under `Model` per batch; `CanCollide = false` on trim; proxy collision part for walkable surfaces only.
