#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Ingest diary 2026-06-15 (design-direction consolidation) → Obsidian + Git
# รันบน Mac:  bash ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game/scripts/ingest-diary-2026-06-15.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO="$HOME/Desktop/Utopia of Eternity/utopia-of-eternity-game"
DIARY="$REPO/docs/mempalace/2026-06-15-design-direction-consolidation.md"
OBSIDIAN_DIR="$HOME/Obsidian/knowledge_base"
OBSIDIAN_FILE="$OBSIDIAN_DIR/utopia-of-eternity-design-direction-2026-06-15.md"

echo "==> [1/3] ตรวจไฟล์ diary"
[ -f "$DIARY" ] || { echo "❌ ไม่พบ diary: $DIARY"; exit 1; }
echo "    OK: $DIARY"

echo "==> [2/3] คัดลอกเข้า Obsidian"
if [ -d "$OBSIDIAN_DIR" ]; then
  cp -v "$DIARY" "$OBSIDIAN_FILE"
  echo "    ✅ Obsidian: $OBSIDIAN_FILE"
else
  echo "    ⚠️  ไม่พบโฟลเดอร์ Obsidian ($OBSIDIAN_DIR) — ข้ามขั้น Obsidian"
fi

echo "==> [3/3] Git add / commit / push"
cd "$REPO"
git add docs/MASTER-BLUEPRINT.md \
        docs/BLUEPRINT-V2-WORLD-PROGRESSION.md \
        docs/CLASS-JOB-SYSTEM-BLUEPRINT.md \
        docs/CURSOR-PROMPTS-MOBILE-UX-AUDIT.md \
        docs/POLICY-ECONOMY-PVP-ANTIGRIEF.md \
        docs/world/ \
        docs/death-valley/HORROR-DESIGN-RESEARCH.md \
        docs/death-valley/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md \
        docs/mempalace/2026-06-15-*.md
if git diff --cached --quiet; then
  echo "    ℹ️  ไม่มีอะไรให้ commit (อาจ commit ไปแล้ว)"
else
  git commit -m "docs: consolidate world/races/lore/policy + Class-Job blueprint (MASTER §13) + diary 2026-06-15"
  echo "    ✅ committed"
fi
echo "    ⬆️  pushing..."
git push origin main && echo "    ✅ pushed" || echo "    ⚠️  push ไม่สำเร็จ — เช็ก keychain/PAT แล้วรัน: git push origin main"

echo "==> [4/4] MemPalace ingest (CLI จริง)"
MP="/Users/macbook/blue-topaz-ai/venv-mempalace/bin/mempalace-code"
if [ -x "$MP" ]; then
  # mine ทั้ง wing ที่ repo root (mempalace.yaml = wing utopia_of_eternity) — incremental, รวม diary ใหม่
  ( "$MP" mine "$REPO" ) \
    && echo "    ✅ MemPalace ingested (wing utopia_of_eternity)" \
    || echo "    ⚠️  CLI ingest ไม่สำเร็จ — ลอง HTTP: bash \"$REPO/scripts/knowledge-ingest.sh\" \"$REPO\" --http"
else
  echo "    ⚠️  ไม่พบ mempalace-code ($MP) — ข้าม"
fi
echo "✅ เสร็จ"
