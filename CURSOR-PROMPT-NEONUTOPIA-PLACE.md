# CURSOR PROMPT — สร้าง Neon Utopia Place + Publish
> สร้าง: 13 มิ.ย. 2026
> เป้าหมาย: สร้าง Place ใหม่ชื่อ "Neon Utopia" ใน Universe และ publish ไฟล์เกม

---

## บริบท

- Universe ID: `10293115628`
- API Key: อยู่ใน `bridge/.env` ตัวแปร `ROBLOX_OPEN_CLOUD_API_KEY`
- ไฟล์เกมที่จะ publish: `utopia-playtest.rbxlx` (เหมือน EternityCity)
- เมื่อได้ Place ID ให้อัป `src/ServerScriptService/Secrets/PlaceSecrets.luau` บรรทัด `NeonUtopia = 0`

---

## ขั้นตอน 1 — สร้าง Place ใน Roblox Universe

รัน curl จาก terminal (ในโปรเจกต์ root):

```bash
source bridge/.env
curl -s -X POST \
  "https://apis.roblox.com/universes/v1/10293115628/places" \
  -H "x-api-key: ${ROBLOX_OPEN_CLOUD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Neon Utopia","description":"มหานครมนุษย์ neon — จุดเริ่มต้นผู้เล่นใหม่"}'
```

ผลลัพธ์จะได้ JSON เช่น `{"placeId": 123456789}` — จด Place ID นั้นไว้

> ⚠️ ถ้า endpoint นี้ไม่ work ให้ลอง:
> ```bash
> curl -s -X POST \
>   "https://apis.roblox.com/cloud/v2/universes/10293115628/places" \
>   -H "x-api-key: ${ROBLOX_OPEN_CLOUD_API_KEY}" \
>   -H "Content-Type: application/json" \
>   -d '{"displayName":"Neon Utopia"}'
> ```

---

## ขั้นตอน 2 — อัป PlaceSecrets.luau

ใน `src/ServerScriptService/Secrets/PlaceSecrets.luau` แก้:

```lua
-- เดิม
NeonUtopia = 0,

-- ใหม่ (แทนที่ PLACE_ID_HERE ด้วยตัวเลขจริงจากขั้นตอน 1)
NeonUtopia = PLACE_ID_HERE,
```

---

## ขั้นตอน 3 — สร้าง publish command

สร้างไฟล์ `utopia-publish-neonutopia.command` ที่ `~/Desktop/Utopia of Eternity/` (copy จาก utopia-publish-eternitycity.command แล้วแก้ place_id):

```bash
#!/usr/bin/env bash
# Publish Neon Utopia (PLACE_ID_HERE) from utopia-playtest.rbxlx
set -euo pipefail
ROOT="$HOME/Desktop/Utopia of Eternity/utopia-of-eternity-game"
LOG="$ROOT/PUBLISH-NEONUTOPIA-LOG.txt"
exec > "$LOG" 2>&1
echo "=== $(date) ==="
cd "$ROOT"

if [[ -f bridge/.env ]]; then
  set -a
  source bridge/.env
  set +a
fi
if [[ -z "${ROBLOX_OPEN_CLOUD_API_KEY:-}" ]]; then
  echo "ERROR: ROBLOX_OPEN_CLOUD_API_KEY not set"
  exit 1
fi

echo "=== validate-p0-publish ==="
python3 scripts/validate-p0-publish.py

RBXLX="$ROOT/utopia-playtest.rbxlx"
echo "=== publishing Neon Utopia ==="
ls -la "$RBXLX"
python3 - "10293115628" "PLACE_ID_HERE" "$RBXLX" <<'PY'
import json, os, sys, urllib.error, urllib.request
universe_id, place_id, rbxlx_path = sys.argv[1:4]
api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
with open(rbxlx_path, "rb") as h:
    body = h.read()
url = f"https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions?versionType=Published"
req = urllib.request.Request(url, data=body,
    headers={"x-api-key": api_key, "Content-Type": "application/xml"}, method="POST")
try:
    with urllib.request.urlopen(req, timeout=300) as resp:
        status, raw = resp.status, resp.read().decode("utf-8")
except urllib.error.HTTPError as exc:
    print(f"HTTP {exc.code} {exc.read().decode('utf-8', errors='replace')[:500]}")
    raise SystemExit(1)
payload = json.loads(raw) if raw else {}
version = payload.get("versionNumber")
print(f"HTTP {status}")
print(f"placeId={place_id}")
print(f"versionNumber={version}")
if not version:
    print(f"response={raw[:500]}")
    raise SystemExit(1)
PY
echo "DONE — Neon Utopia published."
```

หลังสร้างไฟล์: `chmod +x "$HOME/Desktop/Utopia of Eternity/utopia-publish-neonutopia.command"`

---

## ขั้นตอน 4 — ลบไฟล์ชั่วคราว

```bash
rm -f "$HOME/Desktop/Utopia of Eternity/utopia-create-neonutopia-place.command"
```

---

## ขั้นตอน 5 — Git commit

```bash
git add src/ServerScriptService/Secrets/PlaceSecrets.luau
git commit -m "feat(place): Neon Utopia Place ID <PLACE_ID_HERE>

PlaceSecrets.NeonUtopia = <PLACE_ID_HERE>
SpawnRouter จะ route ผู้เล่นใหม่มาที่นี่อัตโนมัติ"
```

---

## รายงานกลับ

- ✅/❌ Place ID ที่ได้ (ตัวเลข)
- ✅/❌ PlaceSecrets.luau อัปเดตแล้ว
- ✅/❌ utopia-publish-neonutopia.command สร้างแล้ว
- commit hash
