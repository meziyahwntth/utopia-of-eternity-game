#!/usr/bin/env python3
"""Export UGC Blockbench brief from NationalFashionSets + concepts."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "ugc" / "CATALOG-BRIEF.md"
NATIONAL_DIR = ROOT / "docs" / "visual-ref" / "fashion" / "national"
CONCEPT_DIR = ROOT / "docs" / "visual-ref" / "fashion" / "concepts"


def main() -> None:
    lines = [
        "# UGC Catalog Brief — auto-generated",
        "",
        "| Item ID | Display | Slot | Robux | Concept |",
        "|---------|---------|------|-------|---------|",
    ]

    # Parse NationalFashionSets.luau loosely for ids (static companion to Luau)
    luau = (ROOT / "src/ReplicatedStorage/Modules/NationalFashionSets.luau").read_text()
    import re

    set_blocks = re.findall(
        r'(heritage|modern)\("([^"]+)", "([^"]+)", "([^"]+)", "([^"]+)", "([^"]+)"',
        luau,
    )
    for _kind, set_id, name, _code, _country, image in set_blocks:
        concept = NATIONAL_DIR / image
        if not concept.exists():
            concept = CONCEPT_DIR / image
        rel = concept.relative_to(ROOT) if concept.exists() else image
        lines.append(f"| `{set_id}` (bundle) | {name} | SET | — | `{rel}` |")

    piece_re = re.findall(
        r'(shirt|pants|shoes|hair|hat|back)\("([^"]+)", "([^"]+)", (\d+)\)',
        luau,
    )
    slot_map = {
        "shirt": "Shirt",
        "pants": "Pants",
        "shoes": "Shoes",
        "hair": "Hair",
        "hat": "Hat",
        "back": "Back",
    }
    for fn, item_id, display, robux in piece_re:
        lines.append(f"| `{item_id}` | {display} | {slot_map.get(fn, fn)} | {robux} | blockbench |")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(lines) - 4} rows)")


if __name__ == "__main__":
    main()
