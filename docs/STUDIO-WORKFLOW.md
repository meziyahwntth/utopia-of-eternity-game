# Studio Workflow — Long-term (Jun 2026+)

**Default:** code on disk → `rojo build` / Script Sync → Play in Studio.  
**Computer Use (Cua / Peekaboo):** only for Roblox **Dashboard** tasks after **Public/Limited Save** (~10 Jun 2026).

---

## 1. Daily dev loop (no Rojo Connect required)

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"
bash scripts/studio-playtest-build.sh
```

In Studio: **File → Open from File…** → `/tmp/utopia-playtest.rbxlx` → **Play (F5)**.

Optional live sync: enable **File → Beta Features → Studio Script Sync** and sync scripts to this repo.

---

## 2. Rojo serve (when plugin works)

```bash
rojo serve default.project.json   # localhost:34872
```

Studio: **Plugins → Rojo → Connect**. If Rojo button missing → install from [Creator Store](https://create.roblox.com/marketplace/asset/13916111004/Rojo-7) → restart Studio.

---

## 3. Cursor “ทำเหมือนคน” — Computer Use stack

### Boot (once per login session)

```bash
bash scripts/start-cua-driver-daemon.sh
```

Verify: `cua-driver status` → daemon running, socket at `~/Library/Caches/cua-driver/cua-driver.sock`.

### MCP servers (Cursor)

Configured in `~/.cursor/mcp.json`:

| Server | Role |
|--------|------|
| **cua-driver** | Background click/type on native apps (Roblox Studio) |
| **peekaboo** | Fallback vision + natural-language agent |

**Reload Cursor** after MCP changes (Cmd+Shift+P → “Reload Window”).

### Cua Driver — known issue (v0.2.0)

| Tool | Status |
|------|--------|
| `launch_app` | ✅ Works (use `bundle_id: com.Roblox.RobloxStudio`) |
| `get_window_state` | ✅ Works (pass `pid` + `window_id` from launch_app) |
| `click` / `hotkey` / `type_text` | ✅ Use with element_index from tree |
| `list_apps` / `list_windows` | ❌ Hangs — **do not use**; use `launch_app` instead |

Example (terminal):

```bash
cua-driver call launch_app '{"bundle_id":"com.Roblox.RobloxStudio"}' --compact
cua-driver call get_window_state '{"pid":PID,"window_id":WID}' --compact
```

### macOS permissions

Grant **Accessibility** + **Screen Recording** to **CuaDriver.app** (`/Applications/CuaDriver.app`).

Peekaboo: grant the same to Terminal/Cursor/npx as prompted on first use.

---

## 4. Agent policy — Roblox touch points

| Action | Until ~10 Jun 2026 | After `Public Save แล้ว` |
|--------|-------------------|-------------------------|
| `rojo build` / local scripts | ✅ Always | ✅ |
| `rojo serve` + Studio Play | ✅ Manual Studio | ✅ |
| `publish-all-places.sh` | ❌ | ✅ With user OK |
| Creator Dashboard Configure Save | ❌ Manual only | ✅ Manual → then agent verify |
| Browser on roblox.com / create.roblox.com | ❌ Lock risk | Computer Use only if user asks |

**Trigger after Public/Limited Save:** message **`Public Save แล้ว`** or **`Limited Save แล้ว`**.

---

## 5. Open experience (group-owned)

Do **not** use deep links to `/places/119887759427070/...` (404).

1. [create.roblox.com/dashboard/creations](https://create.roblox.com/dashboard/creations) → group **Utopia of Eternity**
2. Click experience → **Edit in Studio**
3. Or Studio **File → Open from File** after `studio-playtest-build.sh`

---

## 6. Quick validation (no Roblox web)

```bash
python3 scripts/validate-p0-publish.py
bash scripts/test-creator-payout-flow.sh
curl -sS https://api.utopiaofeternity.com/health
```
