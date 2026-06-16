---
topic: utopia-of-eternity-racing-system
date: 2026-06-16
tags: [utopia, racing, neonutopia, time-trial, leaderboard, rojo, project-json, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-16 — Racing System (NeonUtopia) — โค้ดเสร็จ + verified (publish ค้าง)

## สรุป
implement Racing system (เมืองแข่งรถหลัก NeonUtopia) เอง ตาม RACING-SYSTEM-BLUEPRINT.md — โค้ดครบ + sync เข้า Studio verified แล้ว แต่ **publish ค้าง** (Studio reopen ไป Hub + pending update)

## โค้ดที่เพิ่ม/แก้
- **ใหม่** `ReplicatedStorage/Modules/RacingConfig.luau` — track "neon_grand_prix" (loop รัศมี 95 รอบเมือง, 6 checkpoints, reward 150 credits, minPlausibleTime 8s, maxRunTime 180s)
- **ใหม่** `ServerScriptService/Racing/` : RaceTrackService (server-auth start/checkpoint/finish + anti-cheat: order+proximity+minTime), RaceLeaderboardStore (best time DataStore), RaceRemoteSetup (folder **RacingRemotes** — เลี่ยงชนกับ Race/เผ่า "RaceRemotes"), RaceHandlers
- **ใหม่** `ServerScriptService/World/NeonUtopiaRaceTrackBuilder.luau` — start gate + checkpoint parts (attribute) + hook ใน NeonUtopiaWorldBuilder:Build (pcall)
- **ใหม่** `StarterPlayerScripts/RaceClient.client.luau` — checkpoint .Touched→ping, ปุ่มเริ่ม (proximity), HUD timer/checkpoint/finish (mobile-first)
- **แก้** `default.project.json` — เพิ่ม folder "Racing" (4 ไฟล์) + World/NeonUtopiaRaceTrackBuilder
- reward = credits (CurrencyService.addCredits) — no-P2W; ghost/wave-race/garage = follow-up

## ⚠️ บทเรียนใหญ่ (debug 2 ชม.)
1. **เพิ่ม folder ใหม่ใน project.json → rojo serve ต้อง RESTART** (reconnect ไม่พอ; folder เดิมเพิ่มไฟล์ reconnect ได้ แต่ folder ใหม่ไม่ได้)
2. **ไฟล์ luau ที่ Rojo parse ไม่ผ่าน → "could not be turned into a Roblox Instance" + ทิ้งทั้ง parent folder + rojo ค้างสถานะ** (reconnect/แก้ไฟล์สด ไม่ recover) → ต้อง restart rojo สะอาด. 2 ไฟล์ที่พัง (RaceHandlers, NeonUtopiaRaceTrackBuilder) แก้ด้วยเขียน **vanilla** (numeric for แทน generalized-for, ตัด if-expression, ตัด emoji ในสตริง, ตัด module-type annotation) — แม้ construct เหล่านั้นใช้ได้ในไฟล์อื่น แต่เลี่ยงไว้ปลอดภัยสุด
3. Ctrl+C ใน rojo terminal กดแล้วไม่ติดบ่อย → ปิดหน้าต่าง (Cmd+W → Terminate) ชัวร์กว่า

## Verify (ผ่าน)
`Racing= true Handlers true TrackSvc true Setup true Lb true Builder true` (หลัง vanilla rewrite + clean rojo restart) · RacingConfig cp=6 · RaceClient sync

## ✅ PUBLISHED — NeonUtopia v4 LIVE
- restart Studio (update) → เปิด NeonUtopia ผ่าน Asset Manager (grid-view double-click; list-view ไม่ติด) → Rojo connect+Accept → **verify PlaceId=119711258870458** (safety gate) → Play: **[Racing] Neon Grand Prix track built - 6 checkpoints + [Racing] handlers online, ไม่มี Racing error** → Publish "Neon Utopia" **v4**
- errors ใน playtest: PrismKeyService:101 (hydratePlayer)/VehicleMountClient = **Studio DataStore artifact pre-existing** (PlayerStore.load nil ใน Studio) ไม่ใช่ Racing code
## ค้าง
- ยังไม่ขับ race ครบ loop จริง (ต้องเดิน/ขับรอบ radius 95) → spot-check บนเครื่องจริง
- ghost replay / wave race / garage cosmetic = follow-up (v1 = time-trial+checkpoint+leaderboard+reward)

## งานถัดไป
- restart Studio (update) → เปิด NeonUtopia (+EternityCity) → Rojo sync → playtest race → publish
- Next-Gen Art track · spot-check class/race/auto-hide บนเครื่องจริง

## Action ฝั่ง Mac
```
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
git add -A && git commit -m "feat: Racing system (NeonUtopia) + project.json + diary" && git push origin main
bash scripts/knowledge-ingest.sh ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
```
