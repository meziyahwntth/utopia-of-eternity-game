---
topic: utopia-of-eternity-mobile-ux-audit
date: 2026-06-15
tags: [utopia, mobile-ux, combat, hud, auto-hide, eternitycity, v12, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-15 — Mobile-UX Audit (auto-hide ตอนสู้) → EternityCity v12

## สรุป
ปิด gap "collapsible/auto-hide HUD ตอนสู้" (ชิ้นที่ confirm ว่าขาดใน Mobile-First Matrix) — Cowork เขียนโค้ดเอง (Praphan อนุมัติ override กฎ delegate-to-cursor ครั้งนี้ เพราะ Cursor เป็น IDE → computer-use tier "click" พิมพ์แทนไม่ได้)

## โค้ดที่เพิ่ม/แก้ (committed รอ push)
- **ใหม่** `ReplicatedStorage/Modules/CombatStateController.luau` — single source of truth in-combat (client) + `Changed` signal + `EnterCombat()` + `IsInCombat()`; ออกจาก combat อัตโนมัติเมื่อเงียบ 5s; server-safe (guard IsClient); auto-detect: ได้รับดาเมจ (Humanoid.HealthChanged) + ล็อกเป้า (TargetingController.onChanged)
- **ใหม่** `StarterPlayerScripts/HudVisibilityManager.client.luau` — ฟัง Changed → ซ่อน HUD ใน HIDE-list ตอนสู้ (ChatClient, DailyQuestUI, DailyStreakUI, FashionShowUI, DropNotif, PetDropNotif, DV toasts, leaderboards, EmoteHUD, SkyTreasureHUD), คง combat HUD; mobile-only (TouchEnabled); ปุ่ม peek 👁 manual override; opt-out attribute `MobileHudAutoHideOptOut`
- **แก้** `AutoBattleClient` (EnterCombat ตอน toggle on + ตอนยิง), `SkillBarClient` (EnterCombat ตอนยิงสกิล) — Targeting lock จับผ่าน onChanged (ไม่แก้ TargetingController)

## Verify (Studio command bar — ผ่าน)
`combatStateOK=true · isInCombatFn=true · enterFn=true · cscModule=true · hudMgr=true` · playtest PC+mobile-emulator ไม่มี error · **Publish v12** สำเร็จ

## ค้าง / ข้อสังเกต (สำคัญ)
- ⚠️ **visual auto-hide ยังไม่ spot-check จริง** — EternityCity ไม่มีศัตรู (trigger combat ธรรมชาติไม่ได้) + virtual joystick บังปุ่ม AutoBattle ใน emulator (= mobile-UX collision finding จริง!) → ควรเช็คใน **DeathValley** (มีศัตรู) หรือบนเครื่องจริง · ฟีเจอร์ปลอดภัย: mobile-gated + opt-out + HIDE-list อนุรักษ์นิยม + ไม่มี error
- **Broad Scale/UIAspectRatio sweep 57 HUD = เลื่อนเป็น incremental** (เสี่ยง rewrite blind; HUD combat+ปุ่มใหม่ใช้ Scale+aspect แล้ว)
- **finding ใหม่:** AutoBattle toggle (มุมล่างซ้าย) ชนกับ DynamicThumbstick → ควรย้าย/หลบใน sweep ถัดไป

## งานถัดไป
Race system prompt-pack (ตามที่ Praphan สั่งต่อ) → แล้ว Class/Job, Party-Size Scaling, Next-Gen Art

## Action ฝั่ง Mac
- ingest: `bash utopia-of-eternity-game/scripts/knowledge-ingest.sh ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game`
- git push (Praphan): commit Mobile-UX audit + diary
