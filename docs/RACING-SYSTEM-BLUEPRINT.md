# Blueprint: Racing System (NeonUtopia) — เมืองแข่งรถหลัก

> 15 มิ.ย. 2026 · อิง `world/FIVE-CITIES-REVISIT-2026-06.md` (NeonUtopia=แข่งรถหลัก, Nocturne=ดริฟต์รอง) · benchmark **Velocity Outlast**
> ต่อยอดของจริง: `Commerce/VehicleMountService` + `VehicleMountCatalog` (รถ/mount + iconAssetId), `World/NeonUtopiaWorldBuilder`, นโยบาย no-P2W (`feedback-economy-pvp-policy`) + solo-friendly
> โค้ด → Cursor · รออนุมัติก่อนลงมือ

## 1. ขอบเขต (v1)
- **โหมด:** Time-Trial (solo, แข่งกับเวลา + **ghost** ของ best ตัวเอง/โลก) · Wave Race (หลายคนพร้อมกัน) — solo เล่นจบได้เต็ม (solo-friendly)
- **แทร็ก:** เส้นทางในเมือง NeonUtopia + checkpoint เรียงลำดับ + start/finish
- **รางวัล:** เครดิต/กุญแจ + **cosmetic รถ (Grandeur Rank)** — **ไม่ขายความเร็วที่ทำให้ชนะ** (no-P2W; รถเร็วได้จากเล่น/เครดิต ไม่ใช่จ่ายอย่างเดียว)
- **Garage/แต่งรถ:** ต่อยอด VehicleMountCatalog (สี/skin Grandeur — cosmetic)
- **Anti-cheat:** server ตรวจ checkpoint ครบ+เรียงลำดับ + เวลาเป็นไปได้ (กัน teleport/speed hack) · ผูก RemoteGuard

## 2. ไฟล์ที่ต้องเพิ่ม
```
ReplicatedStorage/Modules/  RacingConfig.luau          (tracks, checkpoints, rewards, ghost sample rate)
ServerScriptService/Racing/ RaceService.luau           (start/checkpoint/finish, server-auth timing/validation)
                            RaceLeaderboardStore.luau  (DataStore best times — pcall)
                            RaceRemoteSetup.server.luau
                            RaceHandlers.server.luau
ServerScriptService/World/  NeonUtopiaRaceTrackBuilder.luau (checkpoint/start parts ในเมือง)
StarterPlayer/StarterPlayerScripts/ RaceClient.client.luau (HUD เวลา/checkpoint/ghost + ปุ่มเริ่ม, mobile-first)
```
> ⚠️ **บทเรียน v13:** `default.project.json` map ServerScriptService **ทีละไฟล์** → ต้องเพิ่ม $path ของ Racing/* + NeonUtopiaRaceTrackBuilder เอง ไม่งั้น Rojo ไม่ sync (ReplicatedStorage/StarterPlayerScripts map ทั้งโฟลเดอร์ ไม่ต้องเพิ่ม)

---

# Cursor Prompt-Pack (วางทีละ prompt, commit แยก) — บอก Cursor อ่าน blueprint นี้ก่อน

## PROMPT 1 — RacingConfig + project.json
```
อ่าน docs/RACING-SYSTEM-BLUEPRINT.md ก่อน
สร้าง src/ReplicatedStorage/Modules/RacingConfig.luau (Luau strict): นิยาม track(s) ของ NeonUtopia
(checkpoints เป็น list ของ {position/cframe, radius}, startCFrame, laps, rewardCredits, rewardKeyChance,
ghostSampleHz=10, maxPlausibleSpeed). helper: RacingConfig.getTrack(id).
แก้ default.project.json: เพิ่ม $path สำหรับ ServerScriptService/Racing/* + World/NeonUtopiaRaceTrackBuilder.luau
(ServerScriptService map ทีละไฟล์)
```

## PROMPT 2 — RaceService + Leaderboard + Remotes/Handlers (server-auth)
```
สร้าง RaceService.luau + RaceLeaderboardStore.luau + RaceRemoteSetup.server.luau + RaceHandlers.server.luau
ใน src/ServerScriptService/Racing/
- RaceService: startRun(player,trackId) → ติดตาม checkpoint ที่ผ่าน (เรียงลำดับ, ในรัศมี), finish → คำนวณเวลา server-side
- Anti-cheat: ปฏิเสธถ้าข้าม checkpoint, เวลาต่ำกว่า min plausible, หรือ speed เกิน maxPlausibleSpeed
- reward เมื่อจบ (เครดิต/กุญแจ) ตาม RacingConfig — no-P2W (รางวัลเล่นได้, ไม่ขายความเร็ว)
- RaceLeaderboardStore: best time ต่อ track (DataStore pcall) + top list
- Remotes: StartRace/CheckpointPing/FinishRace (RemoteEvent/Function) ผ่าน RemoteGuard:Register (rate-limit)
อ่าน VehicleMountService + SecurityRemoteBootstrap ก่อน
```

## PROMPT 3 — NeonUtopiaRaceTrackBuilder (วาง checkpoint ในเมือง)
```
สร้าง src/ServerScriptService/World/NeonUtopiaRaceTrackBuilder.luau (Luau strict)
- สร้าง start/finish gate + checkpoint markers (อ่านจาก RacingConfig) ใน NeonUtopia place
- เรียกจาก WorldBootstrap เมื่อ build NeonUtopia (อ่าน NeonUtopiaWorldBuilder ก่อน ดู build hook)
- checkpoint = invisible part + visual marker (mobile-readable); ตั้ง attribute CheckpointIndex
```

## PROMPT 4 — RaceClient HUD + ghost (mobile-first)
```
สร้าง src/StarterPlayer/StarterPlayerScripts/RaceClient.client.luau (Luau strict)
- ปุ่มเริ่มแข่งใกล้ start gate → StartRace · HUD: timer, checkpoint X/N, best time
- Ghost: บันทึก CFrame ตัวเองตอน best run (RacingConfig.ghostSampleHz) แล้ว replay เป็นรถโปร่งแสง (solo แข่งกับ ghost)
- client prediction timer + server เป็นผู้ตัดสินเวลา/รางวัล
- mobile-first: Scale + UIAspectRatioConstraint + touch zone; ผูก auto-hide ตอน combat ไม่เกี่ยว (race เป็น HUD ของตัวเอง)
```

## PROMPT 5 — Garage/cosmetic (ต่อยอด VehicleMount)
```
ต่อยอด VehicleMountCatalog/Service: เพิ่ม cosmetic skin/Grandeur ของรถสำหรับ racing (cosmetic ไม่เพิ่มความเร็วชนะ)
UI garage เลือก skin (mobile-first). reward cosmetic จากอันดับ/ความสำเร็จ race (no-P2W)
```

## หลัง Cursor เสร็จ — Cowork
เพิ่ม $path ใน project.json ครบ → Rojo Disconnect/Connect (re-read) → command-bar verify (RacingConfig/RaceService require, Racing/* ใน ServerScriptService, remotes runtime) → playtest NeonUtopia (วิ่ง checkpoint→finish→เวลา+รางวัล, ghost replay) → publish → memory/diary

## Definition of Done
- [ ] Time-Trial solo จบได้ + ghost replay · Wave race หลายคน
- [ ] server-auth timing + anti-cheat (ข้าม checkpoint/speed hack ถูกปฏิเสธ)
- [ ] leaderboard best time (DataStore) · reward no-P2W (cosmetic/เครดิต/กุญแจ ไม่ขายความเร็ว)
- [ ] เพิ่มไฟล์ Racing/* + builder ใน default.project.json · UI mobile-first · กราฟิกชน Velocity Outlast (ใช้ NEXTGEN-IMAGE-PROMPTS รถ)
