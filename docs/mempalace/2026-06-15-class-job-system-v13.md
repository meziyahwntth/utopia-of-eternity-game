---
topic: utopia-of-eternity-class-job-system
date: 2026-06-15
tags: [utopia, class, job, combat, skillbar, eternitycity, v13, project-json, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-15 — Class/Job System → EternityCity v13

## สรุป
implement ระบบ Class/Job (MMORPG core ชิ้นที่ขาด) เอง (Cowork) ตาม CLASS-JOB-SYSTEM-BLUEPRINT.md — live v13

## โค้ดที่เพิ่ม/แก้
- **ใหม่** `ReplicatedStorage/Modules/ClassConfig.luau` — 3 base (Warrior/Mage/Hunter = Sword/Staff/Bow) → 9 sub-class (Guardian/Berserker/Paladin · Elementalist/Sage/Warlock · Ranger/Assassin/Trickster), statMods(hp/atk/cdMult), skills, unlockLevel 10/40, helpers (get/getSubclassesOf/allowsSkill/canChange)
- **แก้** `CombatConfig.luau` — เพิ่ม SkillMultiplier/SkillCooldown 14 สกิลใหม่ + `SkillMeta` (icon/label) ต่อ skill
- **ใหม่** `ServerScriptService/Progression/ClassService.luau` — DataStore(pcall) get/set/requestChange(level gate+debounce), applyToCharacter (attr PlayerClass/WeaponType + MaxHealth ตาม hp mod), getAtkMult/getCdMult/allowsSkill
- **ใหม่** `ClassRemoteSetup.server.luau` + `ClassHandlers.server.luau` — RequestClassChange/GetMyClass (RemoteFunction) + ClassChanged (RemoteEvent) + init
- **แก้** `CombatService.luau` — skill-of-class check (reject ยิงข้ามคลาส) + atk/cd statMods; ไม่มีคลาส = default (ไม่พังเกมเดิม)
- **แก้** `SkillBarClient.client.luau` — render สกิลตามคลาส active (GetMyClass + ClassChanged), fallback default
- **ใหม่** `ClassSelectClient.client.luau` — UI เลือกคลาส mobile-first (auto-open เมื่อไม่มีคลาส+Lv10; ปุ่ม 🎓 เปิดได้ตลอด)

## ⚠️ บทเรียนสำคัญ (debug detour)
`default.project.json` map **ServerScriptService ทีละไฟล์ ($path รายไฟล์)** ไม่ใช่ทั้งโฟลเดอร์ → ClassService/ClassRemoteSetup/ClassHandlers **ไม่ sync** จน error "ClassService is not a valid member of Progression". **แก้: เพิ่ม 3 entry ใน project.json Progression** → Disconnect/Connect Rojo re-read → เข้า. (ReplicatedStorage + StarterPlayerScripts map ทั้งโฟลเดอร์ → ClassConfig/CombatConfig/UI เข้าเอง). เพิ่มเติม: CombatConfig.SkillMeta ที่ "nil" ใน edit-mode command bar = require cache ค้าง (clone+require ยืนยัน 🔥 OK)

## Verify (ผ่านครบ)
- SVCmembers: true true true (3 ไฟล์เข้า Progression) · SkillMetaFireball: 🔥 (clone+require)
- ClassConfig Warrior + 3 sub OK · PartySizeScaling OK
- runtime: ClassRemotes created (true true true), no error · myLevel=1
- **end-to-end:** RequestClassChange("Warrior") @Lv1 → false "ต้องถึงเลเวล 10" (gate+pipeline ทำงาน)
- **Publish v13** สำเร็จ

## ค้าง
- visual class-pick @Lv10+ ยังไม่ทดสอบ (test char Lv1) → spot-check เมื่อมี char เลเวลสูง/บนเครื่องจริง
- trainer NPC ที่ EternityCity (ตอนนี้ใช้ปุ่ม 🎓 placeholder)
- re-select cost = free (debounce 2s) — เพิ่ม cost config ภายหลังได้ (ตาม blueprint)
- support sub-class (Sage) self-sustain ผ่าน hp stat (heal mechanic = future)

## งานถัดไป (ตามที่ Praphan สั่ง)
Next-Gen Art track (ChatGPT image prompts เมือง/รถ/เผ่า) → Racing system prompt-pack (NeonUtopia)

## Action ฝั่ง Mac
- ingest: `bash utopia-of-eternity-game/scripts/knowledge-ingest.sh ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game`
- git push (Praphan): Class/Job + project.json + diary
