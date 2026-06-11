# Utopia Scripts

| Script | Purpose |
|--------|---------|
| `meshy-hero-mesh.py` | Meshy image-to-3D → decimated OBJ for hero landmarks |
| `gen-eternity-terrain.py` | EternityCity heightmap + colormap v3 |
| `studio-playtest-build.sh` | `rojo build` → Desktop playtest rbxlx |
| `publish-place.sh` | Publish single place (user-approved only) |
| `validate-p0-publish.py` | Pre-publish checks |
| `validate-world-place-guard.py` | WorldPlaceGuard regression |

## Meshy hero mesh

```bash
# One-time deps (or: python3 -m venv .meshy-venv && source .meshy-venv/bin/activate)
pip install requests trimesh fast-simplification networkx

# Add MESHY_API_KEY to bridge/.env (see bridge/.env.example)

python3 scripts/meshy-hero-mesh.py docs/visual-ref/city-concept/<image>.png <LandmarkName>

# Dry-run (no API credits):
python3 scripts/meshy-hero-mesh.py --dry-run docs/visual-ref/city-concept/foo.png SkyRailPlaza

# Decimate existing /tmp or assets OBJ only:
python3 scripts/meshy-hero-mesh.py --decimate-only /tmp/meshy-raw.obj EternityTower
```

Output: `assets/City/<LandmarkName>-18k.obj` (≤19k faces, Roblox-safe).

Concept images: `docs/visual-ref/city-concept/`
