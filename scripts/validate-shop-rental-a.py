#!/usr/bin/env python3
"""Static validation for Shop Rental Phase A."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FILES = [
    ROOT / "src/ReplicatedStorage/Modules/ShopRentalConfig.luau",
    ROOT / "src/ServerScriptService/World/ShopUnitKit.luau",
    ROOT / "src/ServerScriptService/World/ShopPromoterNpcKit.luau",
    ROOT / "src/ServerScriptService/Commerce/ShopRentalService.luau",
    ROOT / "src/ServerScriptService/Commerce/ShopRentalHandlers.server.luau",
    ROOT / "src/StarterPlayer/StarterPlayerScripts/ShopRentalUI.client.luau",
]

PROJECT_ENTRIES = [
    "ShopUnitKit",
    "ShopPromoterNpcKit",
    "ShopRentalService",
    "ShopRentalHandlers",
]

REMOTE_NAMES = [
    "GetShopDirectory",
    "RentShop",
    "SetShopName",
    "ShopLeaseChanged",
    "OpenShopPromoterDialog",
]


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    for path in REQUIRED_FILES:
        if not path.exists():
            errors.append(f"Missing file: {path.relative_to(ROOT)}")

    config_path = ROOT / "src/ReplicatedStorage/Modules/ShopRentalConfig.luau"
    if config_path.exists():
        text = config_path.read_text(encoding="utf-8")
        up_match = re.search(r"UPFloors\s*=\s*(\d+)", text)
        up_slots_match = re.search(r"UPSlotsPerFloor\s*=\s*(\d+)", text)
        et_match = re.search(r"ETFloors\s*=\s*(\d+)", text)
        et_slots_match = re.search(r"ETSlotsPerFloor\s*=\s*(\d+)", text)
        if up_match and up_slots_match and et_match and et_slots_match:
            total = (
                int(up_match.group(1)) * int(up_slots_match.group(1))
                + int(et_match.group(1)) * int(et_slots_match.group(1))
            )
            if total != 56:
                errors.append(f"ShopRentalConfig room count {total} != 56")
        qa_count = text.count("q = ")
        if qa_count < 6:
            errors.append(f"PromoterQA needs >= 6 pairs (found {qa_count})")

    project_path = ROOT / "default.project.json"
    if project_path.exists():
        blob = project_path.read_text(encoding="utf-8")
        for entry in PROJECT_ENTRIES:
            if entry not in blob:
                errors.append(f"default.project.json missing entry: {entry}")

    remote_setup = ROOT / "src/ServerScriptService/Commerce/CommerceRemoteSetup.server.luau"
    if remote_setup.exists():
        remote_text = remote_setup.read_text(encoding="utf-8")
        for name in REMOTE_NAMES:
            if name not in remote_text:
                errors.append(f"CommerceRemoteSetup missing remote: {name}")

    commerce_shop = ROOT / "src/ServerScriptService/Commerce/CommerceShopService.server.luau"
    if commerce_shop.exists():
        if "ShopRentalService.tryProcessReceipt" not in commerce_shop.read_text(encoding="utf-8"):
            errors.append("CommerceShopService missing ShopRentalService.tryProcessReceipt chain")

    world_config = ROOT / "src/ReplicatedStorage/Modules/WorldBuildConfig.luau"
    if world_config.exists():
        m = re.search(r"EternityCity\s*=\s*\{[\s\S]*?MaxParts\s*=\s*(\d+)", world_config.read_text(encoding="utf-8"))
        if m and int(m.group(1)) < 20000:
            warnings.append(f"EternityCity MaxParts={m.group(1)} may be tight (measured ~19,970)")

    ui_path = ROOT / "src/StarterPlayer/StarterPlayerScripts/ShopRentalUI.client.luau"
    if ui_path.exists():
        ui_text = ui_path.read_text(encoding="utf-8")
        if "result.ok" not in ui_text or "result.rooms" not in ui_text:
            errors.append("ShopRentalUI must unwrap GetShopDirectory {ok, rooms}")

    print("=== Shop Rental Phase A Validation ===")
    if warnings:
        print("Warnings:")
        for w in warnings:
            print(f"  - {w}")
        print()
    if errors:
        print("FAILED:")
        for e in errors:
            print(f"  ✗ {e}")
        return 1
    print("OK — Shop Rental Phase A static checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
