---
topic: utopia-of-eternity-capital-rename-underground-fps
date: 2026-06-16
tags: [utopia, rename, underground-racing, transparent-floor, fps, city-defense, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-16 — เปลี่ยนแผน: Utopia capital rename + underground racing + FPS city-defense

## 1) Display rename เมืองหลวง → "Utopia" (display-only, ปลอดภัย)
- Praphan อยาก rename Eternity→Utopia เมืองหลวง · ผมเตือนว่า **full PlaceKey rename** ("EternityCity" ใน 51 ไฟล์) เสี่ยง DataStore/ClanWar/place mapping ของเกม live + ผู้เล่นมองไม่เห็น (PlaceKey เป็นรหัสภายใน) → Praphan เลือก **display-only**
- แก้ `GameConfig.Places.EternityCity`: name "Utopia of Eternity"→**"Utopia"**, subtitle "Sky Capital of Eternity" · `Sanctuary.Names.EternityCity` → "Utopia Sanctuary"
- **คง PlaceKey "EternityCity" ภายใน** (ไม่แตะ 51 ไฟล์/DataStore/place 94486544638073) · Eternity = ชื่อโลก/endgame

## 2) Underground racing ใต้เมือง Utopia + ฟุตบาทโปร่งใส
- **ใหม่** `World/UtopiaUndergroundRaceBuilder.luau` (vanilla): รันหลัง SkyCityLift (ตำแหน่ง absolute จาก WorldGround) · idempotent
  - เจาะรูพื้น: destroy WorldGround → สร้างกรอบ 4 แถบ เหลือรูกลาง 220×220 (**ตั้งชื่อแถบหนึ่ง "WorldGround" ให้ VoidRecovery:68 ยังเจอ**)
  - **พื้นโปร่งใส = SmoothPlastic Transparency 0.55 (ไม่ใช้ Glass)** — กัน Glass culling ของ transparent ด้านล่าง (ตามที่ Praphan วิจัย)
  - chamber ลึก 60 + ผนัง + neon + ring 6 checkpoints ที่ Y-55
- **RacingConfig:** เพิ่ม track "utopia_underground_gp" (placeKey EternityCity, reward 180)
- **แก้ RaceTrackService:** proximity ใช้ **ตำแหน่ง checkpoint part จริง** (checkpointPartPos by attribute) แทน config position → กันปัญหา SkyCityLift ยกพิกัด (robust ทุก place รวม NeonUtopia)
- hook ท้าย `EternityCityWorldBuilder:Build` (pcall, 2 return path หลัง SkyCityLift) + เพิ่ม builder ใน default.project.json (World per-file)

## 3) FPS City Defense — Blueprint+prompt-pack (กลับมติเลื่อน FPS)
- doc `docs/FPS-CITY-DEFENSE-BLUEPRINT.md` · team Defenders(Utopia)/Rebels + match + **reward routing**: Defender ที่เป็นแคลน/พันธมิตร Utopia + ชนะ → clan reward (ผ่าน GuildService alliance API); Rebel/non-clan → map reward เท่านั้น · no-P2W
- **combat paradigm:** v1 = instanced place แยก + reuse 3rd-person combat (Auto-Lock/Skill Bar) → true FPS controls = phase ถัดไป (paradigm ต่างจาก tab-target)
- 4 Cursor prompts (Config+project.json / Service+Reward+Handlers / Client UI / ArenaBuilder)

## สถานะ
- โค้ด (1)(2) + blueprint (3) เสร็จ + commit-ready · JSON valid
- **⚠️ publish EternityCity ค้าง** — Studio churn (reopen Hub + "Restart to update" ค้าง + Cursor เด้ง) → verify+publish ตอน Studio นิ่ง: เปิด EternityCity (94486544638073) grid-view → Rojo reconnect (ไฟล์ใหม่ใน World folder เดิม = reconnect พอ ไม่ต้อง restart) → playtest underground (track build + พื้นโปร่งใสมองทะลุ) → Publish

## Action ฝั่ง Mac
```
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
git add -A && git commit -m "feat: Utopia capital display rename + underground racing (transparent floor) + FPS city-defense blueprint" && git push origin main
bash scripts/knowledge-ingest.sh ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
```
