#!/usr/bin/env python3
"""Generate EternityCity heightmap + colormap for Roblox Heightmap Importer.

v2 changes (2026-06-11):
  - Vertical flip before save (importer inverts Y — bay SE must appear SE in Studio)
  - Colormap concrete tuned to limestone grey (not near-white)
  - Outputs assets/terrain/eternitycity-*-v2.png (16-bit height, 8-bit color)

Height units 0..255 map to world Y 0..256 when ImportPositionY=128, RegionHeight=256.
  plateau target h=70 -> world ~70-72 after blur
  waterline h=52 -> sea level ~52-53
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "terrain"

N = 1024
MAP_SIZE = 2048
REGION_HEIGHT = 256
IMPORT_POSITION_Y = 128
PLATEAU_H = 70
SEA_LEVEL_H = 52
PLATEAU_Y = 72
SEA_LEVEL_Y = 53

# Source pixel coords (pre-flip). Importer flips Y, so we flip before save.
PLATEAU_PX = (460, 470)
BAY_PX = (860, 800)

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

bay_cx, bay_cy, bay_r = 860, 800, 460
d_bay = np.sqrt((xx - bay_cx) ** 2 + (yy - bay_cy) ** 2)
sea = d_bay < bay_r
h = np.where(sea, 16 + 30 * np.clip(d_bay / bay_r, 0, 1), h)
ring = (d_bay >= bay_r) & (d_bay < bay_r + 90)
h = np.where(ring, 50 + (d_bay - bay_r) / 90.0 * 20, h)

pcx, pcy, prx, pry = 460, 470, 350, 320
d_pl = np.sqrt(((xx - pcx) / prx) ** 2 + ((yy - pcy) / pry) ** 2)
plateau = np.clip(1 - np.clip((d_pl - 1) / 0.35, 0, 1), 0, 1)
land = d_bay > bay_r + 60
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
beach_mask = (h >= SEA_LEVEL_H) & (h < 72) & (d_bay < bay_r + 150)

# Colormap — limestone concrete, not near-white
grass = (106, 158, 77)
sand = (236, 221, 178)
water = (38, 140, 190)
conc = (165, 158, 148)  # warm limestone / concrete
rock = (118, 114, 110)
snow = (210, 212, 218)

col = np.zeros((N, N, 3), dtype=np.uint8)
col[:] = grass
col[h < SEA_LEVEL_H] = water
col[beach_mask] = sand
city = (plateau > 0.65) & (h >= SEA_LEVEL_H) & (canal > 26)
col[city] = conc
col[h > 150] = rock
col[h > 200] = snow

OUT_DIR.mkdir(parents=True, exist_ok=True)
height_path = OUT_DIR / "eternitycity-heightmap-v2.png"
color_path = OUT_DIR / "eternitycity-colormap-v2.png"

Image.fromarray((np.clip(h / 255, 0, 1) * 65535).astype(np.uint16)).save(height_path)
Image.fromarray(col).save(color_path)

# Post-flip pixel coords for GameConfig (saved PNG row 0 = north in Studio after import)
plateau_px_flipped = (PLATEAU_PX[0], N - 1 - PLATEAU_PX[1])
bay_px_flipped = (BAY_PX[0], N - 1 - BAY_PX[1])


def pixel_to_stud(px: float, py: float) -> tuple[float, float]:
    x = (px / N) * MAP_SIZE - MAP_SIZE / 2
    z = (py / N) * MAP_SIZE - MAP_SIZE / 2
    return round(x, 1), round(z, 1)


plateau_stud = pixel_to_stud(*plateau_px_flipped)
bay_stud = pixel_to_stud(*bay_px_flipped)

meta = {
    "MapSize": MAP_SIZE,
    "HeightmapResolution": N,
    "RegionHeight": REGION_HEIGHT,
    "ImportPositionY": IMPORT_POSITION_Y,
    "PlateauHeightMap": PLATEAU_H,
    "SeaLevelHeightMap": SEA_LEVEL_H,
    "PlateauY": PLATEAU_Y,
    "SeaLevelY": SEA_LEVEL_Y,
    "PlateauCenterPixel": list(plateau_px_flipped),
    "BayCenterPixel": list(bay_px_flipped),
    "PlateauCenterStud": [plateau_stud[0], PLATEAU_Y, plateau_stud[1]],
    "BayCenterStud": [bay_stud[0], SEA_LEVEL_Y, bay_stud[1]],
    "verticalFlipApplied": True,
    "heightRange": [float(round(h.min(), 1)), float(round(h.max(), 1))],
}

meta_path = OUT_DIR / "eternitycity-terrain-v2-meta.json"
meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")

print("Wrote", height_path)
print("Wrote", color_path)
print("Wrote", meta_path)
print("h range", meta["heightRange"])
print("plateau stud", plateau_stud, "bay stud", bay_stud)
