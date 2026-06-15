---
topic: utopia-of-eternity-race-system
date: 2026-06-15
tags: [utopia, race, เผ่า, class, stat-stacking, eternitycity, v14, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-15 — Race System → EternityCity v14

## สรุป
implement ระบบเผ่า (Race) เอง (Cowork) ตาม RACE-SYSTEM-BLUEPRINT.md — live v14 · interlock กับ Class/Job (v13)

## โค้ดที่เพิ่ม/แก้
- **ใหม่** `ReplicatedStorage/Modules/RaceConfig.luau` — 4 เผ่าเล่นได้: Human(NeonUtopia)/Elf(Solhaven)/DarkElf(Nocturne)/Alien(EternityCity) + Orc สูญพันธุ์(ไม่เล่นได้); statMods เบา hp/atk/walkSpeed (1.0±0.05); classAffinity, racialPassive, lore, meshBodyId=nil(placeholder)
- **ใหม่** `ServerScriptService/Progression/RaceService.luau` — DataStore(pcall) get/set/requestSelect (debounce, ฟรี v1), applyToCharacter (attr PlayerRace + WalkSpeed + เรียก ClassService recompute HP), getHpMult/getAtkMult
- **ใหม่** `RaceRemoteSetup.server.luau` + `RaceHandlers.server.luau` — RequestRaceSelect/GetMyRace + RaceChanged + init
- **ใหม่** `StarterPlayerScripts/RaceSelectClient.client.luau` — UI เลือกเผ่า mobile-first, **auto-open เมื่อยังไม่มีเผ่า** (เลือกตอนสร้างตัว)
- **แก้** `ClassService.applyToCharacter` — MaxHealth = base × class.hp × **race.hp** (stack; lazy require RaceService)
- **แก้** `CombatService.computeDamage` — damage × class.atk × **race.atk**
- **แก้** `default.project.json` — เพิ่ม 3 entry Race (RaceService/RemoteSetup/Handlers) ใน Progression (ServerScriptService map ทีละไฟล์ — บทเรียน v13)

## Verify (ผ่านครบ end-to-end)
- RaceCfg: true, get("Elf") ok, count=4 · RaceSvcMembers: true true true · RaceSelectUI: true
- Playtest: **RaceSelect UI auto-เปิดเอง** แสดง 4 เผ่า+lore+stat+บ้านเกิด → เลือก Elf → UI เปลี่ยนเป็น "เผ่าปัจจุบัน"
- **server apply ยืนยัน:** RACE=Elf · WalkSpeed=16 (1.0×16) · MaxHP=95 (race hp 0.95×100, ไม่มีคลาส) — stat stack ถูกต้อง
- **Publish v14** สำเร็จ

## ค้าง
- เผ่า × คลาส รวมกัน (เช่น Elf+Mage) ทดสอบเฉพาะ Elf เปล่า ๆ (Lv1 ไม่มีคลาส) → spot-check combo เมื่อ Lv10+
- mesh body ต่อเผ่า = Next-Gen Art (placeholder); RaceSelect ยังไม่มีภาพเผ่า (รอ art)
- re-select cost = free(debounce 2s) → เพิ่ม config ภายหลัง
- racialPassive ยัง flavor (EXP+3% Human ยังไม่ wire กับ PlayerLevelService) → เติมภายหลัง

## งานถัดไป (option)
- implement Racing system (NeonUtopia) จาก RACING-SYSTEM-BLUEPRINT.md
- Next-Gen Art track (เจนภาพตาม NEXTGEN-IMAGE-PROMPTS.md ให้ชน benchmark)
- spot-check visual (class-pick @Lv10+, auto-hide ใน DeathValley) บนเครื่องจริง

## Action ฝั่ง Mac
- ingest: `bash utopia-of-eternity-game/scripts/knowledge-ingest.sh ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game`
- git push (Praphan): Race system + project.json + diary
