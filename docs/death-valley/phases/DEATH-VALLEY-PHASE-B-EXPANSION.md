# Death Valley Phase B — Depth, POI & Expandable Horizon

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-A-SURVIVAL.md`

---

## คำตอบ: ขยายแมปต่อได้ไหม? ผู้เล่นจะเบื่อไหม?

**ได้ — และควรออกแบบให้ไม่มี “จบเกม” แบบ 99 Nights**

| ชั้น | ไม่ให้เบื่อ | ขยายได้อย่างไร |
|------|------------|----------------|
| **Loop รายคืน** | Night Modifier ทุก 5 คืน (rule ใหม่ ไม่ใช่แค่ scale HP) | เพิ่ม modifier ใหม่ทุก patch |
| **แผนที่** | **Horizon Rings** — วงแหวนปลดล็อกตาม Nights Survived | Ring 1 POI · Ring 2 Deep Wilds · Ring 3 Mega Gate · Ring 4+ seasonal |
| **Meta จักรวาล** | Prism Keys · ghost trade · Mega Dungeon 2→50 · กลับ Hub/Eternity | ไม่ติดอยู่แมพเดียว |
| **Social** | Co-op 4 · dungeon 50 · weekly boss · challenge leaderboard | session ยาวขึ้น ~1.9x กับเพื่อน |
| **Live ops** | Patch ใหม่ = POI ใหม่ / modifier ใหม่ / key rotate | ไม่ต้องรื้อแมพเก่า |

**หลักการ:** ผู้เล่นไม่ “จบ” แล้วเลิก —  они **เปลี่ยนโหมด** (survival → explore → raid → meta keys → กลับเมืองโชว์ของ)

---

## Phase B Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| B1 | **Night Modifier** | ทุก 5 คืน — Echo Raid / Spirit Breach / Hollow Surge / Legion Muster |
| B2 | **Whispering Grove POI** | Morse clue · wraith หนา · hint กุญแจ #8 |
| B3 | **Hollow Lake POI** | Opt-in jumpscare · hint กุญแจ #10 |
| B4 | **Session Checkpoint** | Beacon **Lv3** — บันทึก run หลังแต่ละคืน (server session MVP) |
| B5 | **Horizon Rings** | ปลดวงแหวนที่ 5 / 15 / 20 Nights Survived |
| B6 | **Hellbound Path Stub** | ทางเดินจาก Peak Colony marker → Sanctuary (preview pipeline) |

**Phase C (ถัดไป):** DataStore checkpoint · Hellbound travel playable · Zones 2–5 · weekly boss

---

## Night Modifiers (ทุก 5 คืน)

| คืน | ID | ผล |
|-----|-----|-----|
| 5, 15, 25… | `echo_raid` | +2 Whisper · fuel drain x1.15 |
| 10, 20, 30… | `spirit_breach` | +1 Stalker · wave +15s |
| 15, 25, 35… | `hollow_surge` | Stalker speed x1.25 · POI Hollow Lake active |
| 20, 30, 40… | `legion_muster` | +1 Legion Echo · wraith HP x1.2 |

สูตร: `modifierIndex = math.floor((currentNight - 1) / 5) % 4`

---

## Horizon Rings

| Ring | ปลดเมื่อ | พื้นที่ |
|------|---------|---------|
| 0 | เริ่มเกม | Sanctuary + Beacon core |
| 1 | **5** Nights Survived | Whispering Grove + Hollow Lake |
| 2 | **15** Nights Survived | Deep Wilds markers + shard nodes |
| 3 | **20** Nights Survived | Mega Dungeon surface gate (Zone 1) |

Gate parts ใช้ `MinNightsSurvived` attribute — server เปิด/ปิด `CanCollide`

---

## Checkpoint (Beacon Lv3)

หลังคืนสำเร็จ + Beacon ≥ Lv3:
- บันทึก server checkpoint: `nightsSurvived`, `currentNight`, `beaconLevel`, `beaconFuel`
- ผู้เล่นได้ attribute `DV_CheckpointSaved = true`
- Rejoin **เซิร์ฟเวอร์เดิม** → state ยังอยู่ (MVP)
- **Phase C:** DataStore ข้าม session

---

## Validation

```bash
rg "NightModifier|HorizonRing|WhisperingGrove|HollowLake|Checkpoint" utopia-of-eternity-game/src/
```

Studio: รอด 5 คืน → Ring 1 เปิด · คืน 5 modifier · Grove clue · Lv3 beacon → checkpoint message
