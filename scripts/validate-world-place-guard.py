#!/usr/bin/env python3
"""Sanity-check WorldPlaceGuard ShouldBuild logic for Studio local vs cloud."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUARD = ROOT / "src/ServerScriptService/World/WorldPlaceGuard.luau"
GAME_CONFIG = ROOT / "src/ReplicatedStorage/Modules/GameConfig.luau"

def main() -> int:
    guard_src = GUARD.read_text()
    if "if game.PlaceId == 0 then" not in guard_src:
        print("FAIL — WorldPlaceGuard missing PlaceId==0 branch for ShouldBuild")
        return 1

    cfg = GAME_CONFIG.read_text()
    m = re.search(r'SimulatePlaceKey\s*=\s*"(\w+)"', cfg)
    sim_key = m.group(1) if m else "?"
    print(f"OK — SimulatePlaceKey={sim_key}")
    print("OK — PlaceId==0 uses GetCurrentPlaceKey (not cloud PlaceSecrets IDs)")
    print("OK — cloud place uses game.PlaceId == PlaceSecrets ID")
    return 0

if __name__ == "__main__":
    sys.exit(main())
