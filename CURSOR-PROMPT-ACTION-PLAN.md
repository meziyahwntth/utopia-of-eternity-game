# ACTION PLAN — Phase ถัดไป หลัง P3-C Verify
**สร้าง:** 13 มิ.ย. 2026 · **อิง:** MASTER-BLUEPRINT §11 + Research 2.5–2.7

---

## สถานะปัจจุบัน

| Phase | สถานะ |
|-------|--------|
| P0 Security | ✅ Done |
| P1 World | ✅ verified + commit |
| P2 Transport | ✅ Done |
| P3-A Social Core | ✅ commit f308016 |
| P3-B Guild/Clan | ✅ commit 2bb5128 |
| **P3-C Custom Chat + Interaction** | ⏳ รอ `rojo build` + `luau-lsp` → commit |

---

## ลำดับ Phase ถัดไป (เรียงลำดับ Impact × ความพร้อม)

---

### 🥇 ลำดับที่ 1 — P3-C+ Combat Foundation (เริ่มทันทีหลัง P3-C commit)
**เหตุผล:** Auto-Battle เป็น prerequisite ของ P4 Economy และ P5 Clan War — ทำก่อนดีสุด

**ระบบที่ต้องเขียน:**

#### Task A: CombatConfig + RemoteSetup
```
สร้าง: ReplicatedStorage/Modules/CombatConfig.luau
  - MaxRange per weapon type (Sword=10, Bow=50, Staff=30 studs)
  - AttackSpeed per tier (T1=1.0s … T5=0.6s)
  - BaseDamage per tier + SkillMultiplier table
แก้: SocialRemoteSetup.server.luau (หรือสร้าง CombatRemoteSetup ใหม่)
  - ensure("RemoteEvent", "CombatAttackRequest")
  - ensure("RemoteEvent", "CombatResultClient")
  - ensure("RemoteFunction", "AutoBattleToggle")
แก้: default.project.json — เพิ่ม Combat/ folder + entries
```

#### Task B: CombatService.luau (Server)
```
สร้าง: ServerScriptService/Combat/CombatService.luau
  - processAttack(player, npcId, skillId) → Sanity Check 3 ชั้น:
      1. Distance Check (≤ CombatConfig.MaxRange[weaponType])
      2. Rate Limit (MemoryStore token bucket, 1 attack per AttackSpeed)
      3. Line of Sight Raycast (workspace:Raycast → กำแพงกั้น?)
  - ผ่านทั้ง 3 → npc:TakeDamage(damage) server-side
  - ไม่ผ่าน → silent reject + log (warn)
```

#### Task C: AutoBattleService.luau (Server)
```
สร้าง: ServerScriptService/Combat/AutoBattleService.luau
  - playerAutoBattleState: {[userId]: {enabled: boolean, targetId: number?}}
  - setAutoMode(player, enabled) → บันทึก state
  - ส่ง confirmation กลับ client
```

#### Task D: AutoBattleClient.client.luau (Client)
```
สร้าง: StarterPlayerScripts/AutoBattleClient.client.luau
  - ToggleButton (bottom-left HUD, Scale-based, ≥44×44px)
  - RunService.Heartbeat loop: หา nearest enemy ใน MaxRange
  - Target Lock: Highlight + BillboardGui (ชื่อ/HP bar)
  - FireServer(Target_ID, Skill_ID) ตาม AttackSpeed tick
  - รับ CombatResultClient → แสดง damage number VFX + HP update
```

**Cursor Verify Command:**
```bash
luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/CombatConfig.luau \
  src/ServerScriptService/Combat/CombatService.luau \
  src/ServerScriptService/Combat/AutoBattleService.luau \
  src/StarterPlayer/StarterPlayerScripts/AutoBattleClient.client.luau
```

---

### 🥈 ลำดับที่ 2 — P3-C+ Radial Interaction Wheel + Target Lock UI
**เหตุผล:** Mobile-first mandate — context menu เดิม (list) ต้องอัปเกรดเป็น Radial Wheel

**ระบบที่ต้องแก้:**
```
แก้: StarterPlayerScripts/InteractionClient.client.luau
  - เปลี่ยน buildMenu() จาก list TextButton → วงล้อ Frame
  - ตำแหน่ง: SurfaceGui หรือ ScreenGui absolute ตาม click position
  - ปุ่ม 8 ทิศทาง (Trade/Whisper/Party/Clan/Follow/Carry/Block/Report)
  - animation: tween scale 0→1 เมื่อเปิด
  - touch zone ≥44×44px
สร้าง: ReplicatedStorage/Modules/RadialMenuConfig.luau
  - actions[], icons[], angles[], colors[]
```

---

### 🥉 ลำดับที่ 3 — P4 Economy Core (Item Tier + Trading P2P)
**เหตุผล:** ผูกกับ Low-Tier Material Sink (2.7) — ต้องมี Trading ก่อน Clan War Tax มีความหมาย

**ระบบที่ต้องเขียน:**
```
สร้าง: ReplicatedStorage/Modules/ItemTierConfig.luau
  - item definitions: {id, name, requiredLevel, grandeurRank, weight, weaponType}
สร้าง: ReplicatedStorage/Modules/ItemCraftingConfig.luau
  - Grandeur recipe: ★★★ Sword → StoneFragment×500 + IronOre×200 + MagicCrystal×50
สร้าง: ServerScriptService/Progression/WeightService.luau
  - totalWeight() + applyPenalty(player) → Humanoid.WalkSpeed × 0.5
สร้าง: ServerScriptService/Commerce/TradingService.luau
  - 2-step confirm window (propose→lock→confirm→execute)
  - server validate ทุก step (กันโกง)
สร้าง: StarterPlayerScripts/TradingClient.client.luau
  - Trade Window GUI (2-party, items + confirm button)
```

---

### 🔷 ลำดับที่ 4 — P5 Clan War + Tax Distribution
**เหตุผล:** endgame ที่มัดทุกระบบ — ต้องรอ P3-B clan + P4 economy ก่อน

**ระบบที่ต้องเขียน (Phase P5):**
```
สร้าง: ServerScriptService/ClanWar/ClanWarService.luau
สร้าง: ServerScriptService/ClanWar/TaxDistributionService.luau  ← 50/30/20 split
สร้าง: ServerScriptService/ClanWar/TerritoryStore.luau          ← DataStore
สร้าง: ServerScriptService/ClanWar/DefensiveFatigueService.luau ← weekly -5% HP
สร้าง: ReplicatedStorage/Modules/ClanWarConfig.luau + TaxConfig.luau
```

---

### 🔶 ลำดับที่ 5 — P5+ Mercenary + P6 Sky Treasure RNG Event
```
P5+: MercenaryService + BountyService + BountyBoardClient
P6:  SkyTreasureService (cron ทุก 2 ชม.) + SkyTreasureClient (banner + minimap)
```

---

## สรุป: เริ่มโค้ดระบบใดก่อน?

```
┌─────────────────────────────────────────────────────────┐
│  1️⃣  P3-C verify + commit (ทำทันที → ส่ง Cursor prompt)  │
│  2️⃣  CombatService + AutoBattleClient (P3-C+ Combat)     │
│  3️⃣  Radial Interaction Wheel upgrade (P3-C+ Mobile)     │
│  4️⃣  ItemTierConfig + WeightService + TradingService (P4)│
│  5️⃣  ClanWarService + TaxDistributionService (P5)        │
└─────────────────────────────────────────────────────────┘
```

**เหตุผลลำดับนี้:** Combat เป็นฐานของ Auto-Battle → Trade เป็นฐานของ Tax Economy → Clan War ใช้ทั้งคู่

---

## ไฟล์อ้างอิง
- `docs/MASTER-BLUEPRINT.md` §11 — สถาปัตยกรรมเชิงลึก 2.5–2.7
- `docs/BLUEPRINT-V2-WORLD-PROGRESSION.md` §J–M — schema + code snippets
- `CURSOR-PROMPT-P3C-VERIFY.md` — P3-C verify ก่อนเริ่ม P3-C+
