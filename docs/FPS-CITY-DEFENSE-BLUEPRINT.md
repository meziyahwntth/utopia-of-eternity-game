# Blueprint: FPS City Defense — "Defense of Utopia" (Defenders vs Rebels)

> 16 มิ.ย. 2026 · Praphan: FPS ป้องกันเมืองหลวง Utopia (EternityCity place) · team select + reward ผ่านแคลน/พันธมิตร
> อิงของจริง: `Social/GuildService` (alliance API: allianceInvite/Accept, countAllianceMembers, isAllianceSpeaker), `ClanWar/*`, `Combat/CombatService` (server-auth), นโยบาย `POLICY-ECONOMY-PVP-ANTIGRIEF` (no-P2W, PvP opt-in zone)
> **กลับมติเดิม** (FPS เคยเลื่อน) — Praphan ยืนยันทำ

## 1. ภาพรวม
โหมด **PvP ป้องกันเมือง** (opt-in): ผู้เล่นเลือกทีม
- **Defenders (ฝ่ายเมือง Utopia)** — ป้องกันเมือง/จุดยุทธศาสตร์
- **Rebels (กบฏ)** — โจมตี/ยึด
จบแมตช์ → ฝ่ายชนะ
- **Defender ที่เป็นสมาชิกแคลน/พันธมิตรของ Utopia + ชนะ → ได้รางวัลแคลน/พันธมิตร** (ผ่าน GuildService)
- **Rebel (ใครก็ตาม) → ได้แค่รางวัลแมพปกติ** (เครดิต/แต้ม) ไม่ได้รางวัลแคลน (เพราะไม่ช่วยป้องกันเมือง)
- ทุกคนได้รางวัลแมพพื้นฐานตามผลงาน (kills/objective) — no-P2W (รางวัล = เครดิต/cosmetic/แต้ม ไม่ขายพลัง)

## 2. ⚠️ ประเด็นต้องตัดสินใจ: Combat paradigm
- **A. True FPS** (first-person aim, hitscan/projectile, recoil) = งานใหญ่ + คนละ paradigm กับ combat MMORPG (tab-target) → control/anim/anti-cheat ชุดใหม่
- **B. v1 reuse 3rd-person combat** ที่มีอยู่ (Auto-Lock/Skill Bar) เป็น "team battle" ก่อน แล้วค่อยอัป FPS controls ทีหลัง = เร็วกว่ามาก
- **แนะนำ:** v1 = **instanced battleground place แยก** + เริ่มด้วย B (reuse combat) เพื่อทำ loop ทีม+reward ให้ครบก่อน → upgrade เป็น true FPS controls ใน phase ถัดไป
- เป็น **Place แยก** (sandbox PvP, ไม่ปนกับ MMORPG economy; entry ผ่าน terminal ในเมือง Utopia) — ตาม MMORPG-FPS-CITY-MAPPING

## 3. โครงระบบ (ไฟล์ใหม่)
```
ReplicatedStorage/Modules/  CityDefenseConfig.luau   (teams, match duration, objectives, reward tiers, rebel rewardMult)
ServerScriptService/CityDefense/
    CityDefenseService.luau     (join/leave team, match state, win condition, server-auth)
    CityDefenseRewardService.luau (reward routing: defender+clan/alliance→clan reward; rebel→map reward)
    CityDefenseRemoteSetup.server.luau · CityDefenseHandlers.server.luau
StarterPlayer/StarterPlayerScripts/  CityDefenseClient.client.luau (team-select UI + match HUD, mobile-first)
ServerScriptService/World/  CityDefenseArenaBuilder.luau (แมพป้องกันเมือง — greybox; art ทีหลัง)
```
> ⚠️ **บทเรียน:** ServerScriptService map ทีละไฟล์ใน default.project.json → เพิ่ม CityDefense/* + ArenaBuilder เอง · เขียน vanilla (เลี่ยง parse trip)

## 4. Reward routing (หัวใจตามที่ Praphan สั่ง)
```
จบแมตช์ → winner = Defenders หรือ Rebels
สำหรับผู้เล่นแต่ละคน:
  base = CityDefenseConfig.mapReward(perf)   -- เครดิต/แต้ม ตาม kills/objective (ทุกคนได้)
  ถ้า team == winner:
     ถ้า team == "Defenders" และ GuildService: player.clan ∈ Utopia clan หรือ alliance ของ Utopia:
        + clan reward (ผ่าน GuildService/ClanVault) — Defender ที่ช่วยเมืองจริง
     else (Rebel ชนะ หรือ Defender ที่ไม่ใช่แคลน/พันธมิตร Utopia):
        + win bonus แมพปกติ (ไม่มี clan reward)
```
- "Utopia clan" = แคลนเจ้าของเขต Utopia (จาก ClanWar TerritoryStore) หรือ config UtopiaDefenderClanId
- เช็คพันธมิตร: `GuildService.getAllianceOf(clanId)` == Utopia's alliance
- no-P2W: รางวัลทั้งหมด = เครดิต/cosmetic/แต้ม

---

# Cursor Prompt-Pack (ทำหลัง core MMORPG; วางทีละ prompt) — บอก Cursor อ่าน blueprint นี้ก่อน

## PROMPT 1 — CityDefenseConfig + project.json
```
อ่าน docs/FPS-CITY-DEFENSE-BLUEPRINT.md ก่อน
สร้าง src/ReplicatedStorage/Modules/CityDefenseConfig.luau (Luau strict, vanilla):
teams {Defenders, Rebels}, matchDuration, objectives, mapReward(perf), winBonus, UtopiaDefenderClanId(config),
clanRewardCredits. helper getTeamColor(id).
แก้ default.project.json: เพิ่ม folder ServerScriptService/CityDefense (4 ไฟล์) + World/CityDefenseArenaBuilder (per-file map)
```

## PROMPT 2 — CityDefenseService + RewardService + Remotes/Handlers (server-auth)
```
สร้าง src/ServerScriptService/CityDefense/* (Luau strict, vanilla):
- CityDefenseService: joinTeam(player, "Defenders"/"Rebels"), leaveTeam, match state machine (lobby→active→ended),
  win condition (objective/score/timer), server-authoritative. กัน team-swap abuse (debounce/lock ระหว่างแมตช์)
- CityDefenseRewardService: routing ตาม §4 (defender+clan/alliance Utopia ชนะ→clan reward ผ่าน GuildService/ClanVault;
  rebel/non-clan→map reward เท่านั้น). no-P2W
- RemoteSetup (folder CityDefenseRemotes) + Handlers (ผ่าน RemoteGuard:Register; แก้ SecurityRemoteBootstrap)
อ่าน GuildService (alliance API) + ClanWar TerritoryStore + CombatService ก่อน
```

## PROMPT 3 — CityDefenseClient UI (team select + HUD, mobile-first)
```
สร้าง src/StarterPlayer/StarterPlayerScripts/CityDefenseClient.client.luau (vanilla):
- หน้า team-select เมื่อเข้า arena: 2 ปุ่มใหญ่ Defenders (Utopia) / Rebels + อธิบาย reward ต่างกัน (Defender แคลน/พันธมิตร = clan reward)
- match HUD: timer, score 2 ทีม, objective, ทีมตัวเอง · mobile-first Scale+UIAspectRatioConstraint
- combat v1 = reuse 3rd-person (Auto-Lock/Skill Bar) ภายใน arena
```

## PROMPT 4 — CityDefenseArenaBuilder (greybox map)
```
สร้าง src/ServerScriptService/World/CityDefenseArenaBuilder.luau (vanilla):
- greybox แมพป้องกันเมือง: กำแพงเมือง Utopia, จุด objective (capture points), spawn 2 ทีม, cover
- build เฉพาะใน place arena (หรือ zone) · art สวยตาม benchmark ทีหลัง (NEXTGEN-IMAGE-PROMPTS)
```

## หลัง Cursor — Cowork
project.json + Rojo restart (folder ใหม่) → verify require + folder → playtest team-select+match+reward → publish · memory/diary

## Definition of Done
- [ ] เลือกทีม Defenders/Rebels ได้ · match จบมีผู้ชนะ (server-auth)
- [ ] reward routing: Defender แคลน/พันธมิตร Utopia ชนะ = clan reward · Rebel/non-clan = map reward เท่านั้น
- [ ] no-P2W · กัน team-swap abuse · UI mobile-first
- [ ] เพิ่มไฟล์ใน project.json + vanilla (กัน parse) · combat v1 reuse 3rd-person (true FPS = phase ถัดไป)
