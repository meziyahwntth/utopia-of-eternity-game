#!/usr/bin/env python3
"""Generate EternityCity heightmap + colormap for Roblox Heightmap Importer.

v3 (2026-06-11):
  - Smaller SE bay (~20% sea), wider plateau (~40%), narrow beach band
  - Colormap uses Roblox material anchor RGB (nearest-match in importer)
  - Vertical flip before save (importer inverts Y)
  - Outputs assets/terrain/eternitycity-*-v3.png + meta JSON + zone stats

Height units 0..255 → world Y 0..256 when ImportPositionY=128, RegionHeight=256.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "terrain"
VERSION = "v3"

N = 1024
MAP_SIZE = 2048
REGION_HEIGHT = 256
IMPORT_POSITION_Y = 128
PLATEAU_H = 70
SEA_LEVEL_H = 52
PLATEAU_Y = 72
SEA_LEVEL_Y = 53

# v3 geometry — smaller bay clipped at SE corner, wider plateau
BAY_CX, BAY_CY, BAY_R = 940, 920, 340
BEACH_WIDTH = 58
PLATEAU_PX = (480, 480)
PLATEAU_RX, PLATEAU_RY = 450, 420
BAY_PX = (BAY_CX, BAY_CY)

rng = np.random.default_rng(20260611)
yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)


def fbm(scales=(256, 128, 64, 32, 16), weights=(1, 0.5, 0.25, 0.12, 0.06)):
    out = np.zeros((N, N))
    for s, w in zip(scales, weights):
        g = rng.random((N // s + 2, N // s + 2))
        img = (
            np.array(
                Image.fromarray((g * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC),
                dtype=np.float64,
            )
            / 255.0
        )
        out += w * img
    return out / sum(weights)


h = 72 + (1 - (xx + yy) / (2 * N)) * 18

d_bay = np.sqrt((xx - BAY_CX) ** 2 + (yy - BAY_CY) ** 2)
sea = d_bay < BAY_R
h = np.where(sea, 16 + 30 * np.clip(d_bay / BAY_R, 0, 1), h)
ring = (d_bay >= BAY_R) & (d_bay < BAY_R + BEACH_WIDTH)
h = np.where(ring, 50 + (d_bay - BAY_R) / float(BEACH_WIDTH) * 20, h)

pcx, pcy = PLATEAU_PX
prx, pry = PLATEAU_RX, PLATEAU_RY
d_pl = np.sqrt(((xx - pcx) / prx) ** 2 + ((yy - pcy) / pry) ** 2)
plateau = np.clip(1 - np.clip((d_pl - 1) / 0.35, 0, 1), 0, 1)
land = d_bay > BAY_R + 28
h = np.where(land, h * (1 - plateau) + PLATEAU_H * plateau, h)

m_n = np.clip((230 - yy) / 230, 0, 1)
m_w = np.clip((180 - xx) / 180, 0, 1)
mfac = np.clip(m_n + m_w, 0, 1.1)
mont = mfac * (80 + 130 * fbm()) * (1 - plateau)
h = np.where(land, np.maximum(h, 70 + mont - 8), h)

pts = [(560, 60), (540, 300), (575, 520), (660, 650), (740, 720)]
canal = np.full((N, N), 1e9)
for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
    for t in np.linspace(0, 1, 240):
        cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        canal = np.minimum(canal, (xx - cx) ** 2 + (yy - cy) ** 2)
canal = np.sqrt(canal)
cmask = np.clip(1 - canal / 26.0, 0, 1)
h = h * (1 - cmask) + 40 * cmask

h = gaussian_filter(h, 3.0)
h = np.clip(h, 0, 250)

# Flip vertical axis for Roblox Heightmap Importer (fixes SE bay appearing NW)
h = np.flipud(h)
plateau = np.flipud(plateau)
d_bay = np.flipud(d_bay)
canal = np.flipud(canal)

beach_mask = (h >= SEA_LEVEL_H) & (h < 72) & (d_bay >= BAY_R) & (d_bay < BAY_R + BEACH_WIDTH + 30)
plateau_mask = (plateau > 0.65) & (h >= 68) & (h <= 76)
mount_mask = h > 150
beach_global = (h >= SEA_LEVEL_H) & (h < 72)

# Roblox Heightmap Importer — anchor RGB per material (nearest-color match)
# See Roblox terrain material palette used by import colormap
MAT_GRASS = (106, 127, 63)
MAT_SAND = (194, 178, 128)
MAT_WATER = (13, 105, 172)
MAT_PAVEMENT = (127, 127, 127)
MAT_ROCK = (99, 100, 99)
MAT_SNOW = (248, 248, 248)

col = np.zeros((N, N, 3), dtype=np.uint8)
col[:] = MAT_GRASS
col[h < SEA_LEVEL_H] = MAT_WATER
col[beach_mask] = MAT_SAND
city = (plateau > 0.65) & (h >= SEA_LEVEL_H) & (canal > 26)
col[city] = MAT_PAVEMENT
col[h > 150] = MAT_ROCK
col[h > 200] = MAT_SNOW

total = float(N * N)
zone_stats = {
    "sea_pct": round(float((h < SEA_LEVEL_H).sum() / total * 100), 1),
    "beach_pct": round(float(beach_global.sum() / total * 100), 1),
    "beach_ring_pct": round(float(beach_mask.sum() / total * 100), 1),
    "plateau_pct": round(float(plateau_mask.sum() / total * 100), 1),
    "mount_pct": round(float(mount_mask.sum() / total * 100), 1),
    "method": "sea=h<52, beach=52<=h<72, plateau=plateau>0.65 & 68<=h<=76, mount=h>150",
}

OUT_DIR.mkdir(parents=True, exist_ok=True)
height_path = OUT_DIR / f"eternitycity-heightmap-{VERSION}.png"
color_path = OUT_DIR / f"eternitycity-colormap-{VERSION}.png"

Image.fromarray((np.clip(h / 255, 0, 1) * 65535).astype(np.uint16)).save(height_path)
Image.fromarray(col).save(color_path)

plateau_px_flipped = (PLATEAU_PX[0], N - 1 - PLATEAU_PX[1])
bay_px_flipped = (BAY_PX[0], N - 1 - BAY_PX[1])


def pixel_to_stud(px: float, py: float) -> tuple[float, float]:
    x = (px / N) * MAP_SIZE - MAP_SIZE / 2
    z = (py / N) * MAP_SIZE - MAP_SIZE / 2
    return round(x, 1), round(z, 1)


plateau_stud = pixel_to_stud(*plateau_px_flipped)
bay_stud = pixel_to_stud(*bay_px_flipped)

meta = {
    "version": VERSION,
    "MapSize": MAP_SIZE,
    "HeightmapResolution": N,
    "RegionHeight": REGION_HEIGHT,
    "ImportPositionY": IMPORT_POSITION_Y,
    "PlateauHeightMap": PLATEAU_H,
    "SeaLevelHeightMap": SEA_LEVEL_H,
    "PlateauY": PLATEAU_Y,
    "SeaLevelY": SEA_LEVEL_Y,
    "BayRadius": BAY_R,
    "PlateauRadii": [PLATEAU_RX, PLATEAU_RY],
    "PlateauCenterPixel": list(plateau_px_flipped),
    "BayCenterPixel": list(bay_px_flipped),
    "PlateauCenterStud": [plateau_stud[0], PLATEAU_Y, plateau_stud[1]],
    "BayCenterStud": [bay_stud[0], SEA_LEVEL_Y, bay_stud[1]],
    "verticalFlipApplied": True,
    "heightRange": [float(round(h.min(), 1)), float(round(h.max(), 1))],
    "zoneStats": zone_stats,
    "colormapMaterials": {
        "grass": {"rgb": list(MAT_GRASS), "material": "Grass"},
        "sand": {"rgb": list(MAT_SAND), "material": "Sand"},
        "water": {"rgb": list(MAT_WATER), "material": "Water"},
        "plateau": {"rgb": list(MAT_PAVEMENT), "material": "Pavement"},
        "rock": {"rgb": list(MAT_ROCK), "material": "Rock"},
        "snow": {"rgb": list(MAT_SNOW), "material": "Snow"},
    },
}

meta_path = OUT_DIR / f"eternitycity-terrain-{VERSION}-meta.json"
meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")

print("Wrote", height_path)
print("Wrote", color_path)
print("Wrote", meta_path)
print("h range", meta["heightRange"])
print("zone stats", zone_stats)
print("plateau stud", plateau_stud, "bay stud", bay_stud)
