# Blueprint: Party-Size Scaling (รองรับ solo + party แฟร์)

> 15 มิ.ย. 2026 · ทำตามนโยบาย `world/SOLO-PLAYER-SUPPORT-2026-06.md` + `POLICY-ECONOMY-PVP-ANTIGRIEF.md` (no-P2W)
> อิงของจริง: `DeathValleyWeeklyBossService` (มี `baseHp + hpPerPlayer*partySize` แล้ว, reward flat), `DeathValleyWraithFactory` (มี `wraithHealthMultiplier` hook), `PrismDeathValleyDungeonConfig`, `PrismDeathValleySurvivalConfig`
> โค้ด → Cursor · รออนุมัติก่อนลงมือ

## 1. หลักการ (สำคัญ — กันเข้าใจผิด)
- **Solo (count=1) ต้องเล่นจบได้** — enemy/boss HP ที่ count=1 = baseline ที่ soloable + ได้ reward เต็ม (แค่ช้ากว่า)
- **Party = เร็วกว่า ไม่ใช่ "เงื่อนไขผ่าน"** — HP เพิ่มตามจำนวนคน แต่ DPS รวมก็เพิ่ม → ใช้เวลาใกล้เคียง, เคลียร์เร็วขึ้นเพราะมีคนช่วย
- **Reward per-capita แฟร์** — solo ได้ reward เต็ม base; party ได้ **โบนัสเล็กน้อย** (จูงใจสังคม) ไม่ใช่ "ไม่เล่นปาร์ตี้แล้วเสียเปรียบหนัก" (กัน social-pressure + no-P2W)
- **enemy damage** คงเดิม/สเกลเบามาก (อย่าทำให้ solo โดนรุมตาย — solo เจอศัตรูน้อยลงด้วย)
- ทุกค่าปรับใน config จุดเดียว

## 2. รวมศูนย์: PartySizeScaling module
สร้าง `ReplicatedStorage/Modules/PartySizeScaling.luau` — สูตรเดียวใช้ทั้งเกม (เลิก ad-hoc `baseHp + hpPerPlayer*n`)
```lua
export type ScaleResult = { hpMult: number, rewardMult: number, count: number }
-- config (ปรับได้):
--   MaxPartySize = 8
--   HpPerExtra = 0.6      -- 1p=1.00, 2p=1.60, 3p=2.20 ... (HP รวม; DPS รวมก็โตตามคน)
--   RewardPerExtra = 0.10 -- 1p=1.00, 2p=1.10 ... (โบนัสเบา per-capita แฟร์)
--   DamagePerExtra = 0.0  -- default ไม่สเกล enemy damage
-- API:
--   PartySizeScaling.compute(count: number): ScaleResult   -- clamp 1..Max
--   PartySizeScaling.scaleHp(baseHp, count): number
--   PartySizeScaling.scaleReward(baseReward, count): number
--   PartySizeScaling.countInPlace(): number                -- #Players:GetPlayers() (DeathValley=Place แยก)
--   PartySizeScaling.countInSet(set: {[number]: boolean}): number  -- สำหรับ dungeon instance
```
> หมายเหตุ: DeathValley เป็น Place แยก → ผู้เล่นทั้ง server = อยู่ในโซน → `countInPlace()` ใช้ได้. Dungeon เป็น instance → ใช้ `countInSet(participants)`

## 3. จุดที่ต้องผูก (อิงไฟล์จริง)
| ระบบ | ตอนนี้ | แก้เป็น |
|---|---|---|
| Weekly Boss | `bossMaxHp = baseHp + hpPerPlayer*partySize` (reward flat) | ใช้ `scaleHp(baseHp, count)` + `scaleReward(shardReward, count)` |
| Wraith waves | health มี `wraithHealthMultiplier` (night), จำนวน wave คงที่ | คูณ `hpMult` เพิ่ม + scale **จำนวน/ความถี่** wave ตามคน (solo เจอน้อยลง) |
| Dungeon | (PrismDeathValleyDungeonConfig — enemy/boss HP คงที่) | scale enemy/boss HP + reward ตาม **instance participants** |

---

# Cursor Prompt-Pack (วางทีละ prompt, commit แยก)

## PROMPT 1 — PartySizeScaling module (รวมศูนย์)
```
สร้าง src/ReplicatedStorage/Modules/PartySizeScaling.luau (Luau strict) ตาม §2 ของ docs/PARTY-SIZE-SCALING-BLUEPRINT.md
config: MaxPartySize=8, HpPerExtra=0.6, RewardPerExtra=0.10, DamagePerExtra=0.0 (บนหัวไฟล์ ปรับง่าย)
API: compute(count)->{hpMult,rewardMult,count}, scaleHp(baseHp,count), scaleReward(baseReward,count), countInPlace(), countInSet(set)
clamp count 1..MaxPartySize. คอมเมนต์หลักการ solo-viable + per-capita fair ให้ชัด
```

## PROMPT 2 — Weekly Boss ใช้สูตรรวมศูนย์
```
แก้ src/ServerScriptService/DeathValley/DeathValleyWeeklyBossService.luau:
- แทน `bossMaxHp = math.floor(boss.baseHp + boss.hpPerPlayer*partySize)` ด้วย PartySizeScaling.scaleHp(boss.baseHp, count) (count = PartySizeScaling.countInPlace())
- scale reward: shardReward → PartySizeScaling.scaleReward(boss.shardReward, count) ตอนแจกให้ participants
- คง flow เดิม (participants/clear/broadcast). อ่านไฟล์ก่อนแก้ คงพฤติกรรม solo (count=1) ให้ soloable
ตรวจว่า solo (1 คน) HP ไม่สูงเกินจนตีไม่ไหว — baseHp ควร = ค่าที่ solo ไหว (ปรับใน boss def ถ้าจำเป็น)
```

## PROMPT 3 — Wraith waves + Survival เอนทิตี scale
```
แก้ src/ServerScriptService/DeathValley/DeathValleyWraithFactory.luau + ตัวเรียก spawnWave (SurvivalHandlers/NightService):
- คูณ wraith HP ด้วย PartySizeScaling hpMult (รวมกับ wraithHealthMultiplier เดิม)
- scale "จำนวน wraith ต่อ wave / ความถี่" ตาม count (solo เจอน้อยลง, party เจอมากขึ้น) — กัน solo โดนรุมตาย
- enemy damage คงเดิม (DamagePerExtra=0)
อ่านไฟล์ก่อน คง night modifier เดิม
```

## PROMPT 4 — Dungeon scale ตาม instance participants
```
แก้ระบบ dungeon (PrismDeathValleyDungeonConfig + service ที่ spawn enemy/boss ในดันเจี้ยน):
- นับผู้เล่นใน instance ด้วย PartySizeScaling.countInSet(participants ของ instance นั้น)
- scale enemy/boss HP (scaleHp) + reward (scaleReward) ตาม count
- ถ้า dungeon ยังไม่มี participant tracking → เพิ่ม set ผู้เล่นที่เข้า instance
ทดสอบ require ผ่าน + solo เคลียร์ดันเจี้ยนได้ (count=1)
```

## หลัง Cursor เสร็จ — Cowork
Rojo-sync → command-bar verify (PartySizeScaling require + scaleHp/scaleReward คืนค่าถูก: เช็ค compute(1).hpMult==1, compute(4).hpMult==2.8) → playtest DeathValley solo (boss/wraith/dungeon ไหวคนเดียว) + จำลองหลายคน → publish → memory/diary

## Definition of Done
- [ ] PartySizeScaling เป็นสูตรเดียวใช้ทุกระบบ (ไม่มี ad-hoc เหลือ)
- [ ] solo (count=1): boss/wraith/dungeon เคลียร์ได้ + reward เต็ม base
- [ ] party: HP/จำนวนศัตรูเพิ่ม + reward โบนัสเบา (per-capita แฟร์) ไม่ gate
- [ ] enemy damage ไม่พุ่งจน solo ตายฟรี · ปรับทุกค่าผ่าน config · ไม่พังพฤติกรรมเดิม
