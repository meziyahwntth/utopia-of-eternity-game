#!/usr/bin/env python3
"""Validate P0 publish secrets — Place IDs + Developer Product IDs."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SECRETS = ROOT / "src/ServerScriptService/Secrets"
PLACE_KEYS = ["Hub", "Solhaven", "Nocturne", "EternityCity", "DeathValley", "NeonUtopia"]
SHOP_RENT_PRODUCT_KEYS = ["shop_rent_7d", "shop_rent_30d"]

P0_PRODUCT_KEYS = [
    "dv_pack_survivor_starter",
    "dv_pack_hellbound_elite",
    "dv_pack_veteran_trail",
    "dv_pack_style_only",
    "dv_pack_commerce_luxury",
    "dv_pack_commerce_creator_spotlight",
    "dv_pack_ugc_generic",
]


def parse_luau_table(path: Path) -> dict[str, int]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    out: dict[str, int] = {}
    for match in re.finditer(r"(\w+)\s*=\s*(\d+)", text):
        key, value = match.group(1), int(match.group(2))
        out[key] = value
    return out


def main() -> int:
    place_path = SECRETS / "PlaceSecrets.luau"
    catalog_path = SECRETS / "CatalogSecrets.luau"
    errors: list[str] = []
    warnings: list[str] = []

    if not place_path.exists():
        errors.append(f"Missing {place_path} — run: bash scripts/init-secrets.sh")
    if not catalog_path.exists():
        errors.append(f"Missing {catalog_path} — run: bash scripts/init-secrets.sh")

    place = parse_luau_table(place_path) if place_path.exists() else {}
    catalog = parse_luau_table(catalog_path) if catalog_path.exists() else {}

    for key in PLACE_KEYS:
        if place.get(key, 0) <= 0:
            errors.append(f"PlaceSecrets.{key} not set (still 0)")

    if place.get("UniverseId", 0) <= 0:
        warnings.append("PlaceSecrets.UniverseId not set (optional for Bridge Open Cloud)")

    for key in P0_PRODUCT_KEYS:
        if catalog.get(key, 0) <= 0:
            errors.append(f"CatalogSecrets.{key} not set (still 0)")

    for key in SHOP_RENT_PRODUCT_KEYS:
        if catalog.get(key, 0) <= 0:
            warnings.append(f"CatalogSecrets.{key} not set — shop rental disabled until configured")

    print("=== P0 Publish Validation ===")
    print(f"PlaceSecrets: {place_path}")
    print(f"CatalogSecrets: {catalog_path}")
    print()

    if warnings:
        print("Warnings:")
        for w in warnings:
            print(f"  - {w}")
        print()

    if errors:
        print("BLOCKED — fix before publish:")
        for e in errors:
            print(f"  ✗ {e}")
        print()
        print("Guide: docs/P0-PUBLISH-SETUP.md")
        return 1

    print("OK — all P0 Place IDs and Developer Products configured.")
    configured_places = {k: place[k] for k in PLACE_KEYS}
    configured_products = {k: catalog[k] for k in P0_PRODUCT_KEYS}
    print("Places:", configured_places)
    print("Products:", configured_products)
    return 0


if __name__ == "__main__":
    sys.exit(main())
