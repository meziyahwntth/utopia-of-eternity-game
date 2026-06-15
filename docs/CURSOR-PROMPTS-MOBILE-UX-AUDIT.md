# Cursor Prompt-Pack — Mobile-First UX Audit (Utopia of Eternity)

> สร้าง 15 มิ.ย. 2026 · เป้าหมาย: ปิด gap #3 ใน `MOBILE-FIRST-RPG-MATRIX.md` (collapsible/auto-hide ตอนสู้ + Scale/UIAspectRatioConstraint ทุก HUD + touch-zone นิ้วโป้ง)
> **วิธีใช้:** วางทีละ prompt ใน Cursor (Composer/Agent) ทำเสร็จทีละตัว commit แยก แล้ว Cowork จะ Rojo-sync + playtest + publish v12
> **กฎ:** Luau strict · client prediction + server validation · ทุก GUI ใช้ `Scale` ห้าม Offset (ยกเว้น stroke/padding เล็ก ๆ) · อย่าแตะ terrain/Workspace

## บริบทที่ตรวจจากโค้ดจริง (อย่าเดา ใช้ตามนี้)
- **ยังไม่มีสัญญาณ in-combat ใด ๆ** (`grep InCombat/CombatState/...` = ว่าง) → ต้องสร้างใหม่เป็น single source of truth ก่อน
- **client HUD/GUI = 57 ไฟล์** ใน `src/StarterPlayer/StarterPlayerScripts/*.client.luau`
- ใช้ `UIAspectRatioConstraint` แค่ 2 ไฟล์: `SkillBarClient`, `TargetingClient` (ของ v11) → อีก ~55 ไฟล์ยังไม่ audit
- ระบบที่ feed combat state ได้: `AutoBattleClient` (toggle on/off), `TargetingController` (lock/unlock target), `DeathValleyCombatHUD`/`SkillBarClient` (ยิงสกิล), damage events ฝั่ง server

---

## PROMPT 1 — สร้าง CombatStateController (single source of truth)

```
สร้าง ModuleScript ใหม่: src/ReplicatedStorage/Modules/CombatStateController.luau (Luau strict)
หน้าที่: เป็น single source of truth ฝั่ง client ว่าผู้เล่น "กำลังอยู่ในการต่อสู้" หรือไม่ เพื่อให้ HUD อื่นใช้ตัดสินใจ auto-hide

API:
- CombatStateController.IsInCombat(): boolean
- CombatStateController.Changed: RBXScriptSignal-like (ใช้ BindableEvent ภายใน) ส่งค่า (inCombat: boolean)
- CombatStateController.EnterCombat(reason: string)  -- ต่ออายุ timer ทุกครั้งที่ถูกเรียก
- CombatStateController.Start()  -- เรียกครั้งเดียวจาก client bootstrap

ตรรกะ enter/exit:
- เข้าสู่ combat เมื่อ: AutoBattle เปิด, มี target ถูก lock (TargetingController), ผู้เล่นยิงสกิลจาก SkillBar, หรือได้รับ/สร้าง damage (ฟังจาก RemoteEvent ที่มีอยู่ ถ้าไม่มีให้ทำ no-op hook ไว้ก่อนพร้อมคอมเมนต์ TODO)
- ออกจาก combat อัตโนมัติเมื่อไม่มี event ใด ๆ ต่อเนื่อง COMBAT_IDLE_SECONDS = 5 วินาที (ปรับได้ตัวแปรเดียวบนหัวไฟล์)
- กัน spam: ยิง Changed เฉพาะตอนค่าเปลี่ยนจริง

ห้าม hardcode; ให้ wire เข้ากับ TargetingController.luau และ AutoBattleClient.client.luau ที่มีอยู่ (เพิ่มการเรียก EnterCombat ในจุดที่ lock target / toggle auto-battle / fire skill) โดยไม่ทำลายพฤติกรรมเดิม
อ่านไฟล์ 2 ตัวนั้นก่อนแก้ และคงรูปแบบ require/strict typing ของโปรเจกต์
```

---

## PROMPT 2 — HUD Visibility Manager (auto-hide/collapsible ตอนสู้)

```
สร้าง LocalScript ใหม่: src/StarterPlayer/StarterPlayerScripts/HudVisibilityManager.client.luau (Luau strict)
หน้าที่: ฟัง CombatStateController.Changed แล้ว auto-hide/แสดง HUD ที่ "ไม่จำเป็นตอนสู้" เพื่อให้เห็นตัวละครชัดบนมือถือ

ออกแบบ:
- มี registry (table) ของ ScreenGui ที่จะ auto-hide ตอน inCombat=true เช่น: ChatClient, DailyQuestUI, DailyStreakUI, FestivalCountdown, FashionShowUI, DropNotifClient, social toasts, leaderboard HUD ที่ไม่ใช่ combat
- HUD ที่ "ห้ามซ่อน" (ต้องเห็นตลอด): SkillBarClient, TargetingClient, DeathValleyCombatHUD, LevelHUDClient(HP/MP), MvpBossHUD
- การซ่อน = fade ลื่น (TweenService GroupTransparency ผ่าน CanvasGroup หรือ tween each element) ไม่ใช่ set Visible=false กระตุก; ใช้เวลา ~0.25s
- กลับมาแสดงเมื่อ inCombat=false
- ต้องมี manual override: ปุ่ม/ท่าทางให้ผู้เล่นเรียก HUD กลับมาชั่วคราวได้แม้อยู่ในสู้ (เช่น แตะที่ขอบจอ)
- mobile-only behavior: ตรวจ UserInputService.TouchEnabled — บน PC ไม่ต้อง auto-hide ก็ได้ (หรือ config ได้)
- อย่าผูกชื่อ ScreenGui แบบเดา: ให้ใช้ PlayerGui:WaitForChild ตามชื่อจริง และถ้าไม่เจอให้ skip เงียบ ๆ (ผู้เล่นบาง place ไม่มี GUI ครบ)

เพิ่ม config table บนหัวไฟล์ให้ปรับ list hide/keep ได้ง่าย พร้อมคอมเมนต์ว่าแต่ละตัวมาจากไฟล์ไหน
```

---

## PROMPT 3 — Scale / UIAspectRatioConstraint / touch-zone sweep

```
ทำ Mobile-First UX sweep กับ client HUD ทั้งหมดใน src/StarterPlayer/StarterPlayerScripts/*.client.luau (57 ไฟล์)
เป้าหมายตาม Feature Matrix: ทุก GUI ต้อง responsive บนจอเล็ก + ปุ่มใหญ่พอนิ้วโป้ง

ทำเป็นรอบ ๆ ทีละ ~10 ไฟล์ (commit ย่อย) อย่าแก้รวดเดียวทั้งหมด:
1. แปลง UDim2.new(x_offset,...) ที่เป็น absolute offset สำหรับ Size/Position ของ element ใหญ่ → UDim2.fromScale (อิงสัดส่วนจอ) ; คง offset ได้เฉพาะ stroke/padding/corner เล็ก ๆ
2. ปุ่ม action (โจมตี/สกิล/radial) ที่ยังไม่มี → เพิ่ม UIAspectRatioConstraint (กันบิดเบี้ยวบนจอแนวต่าง) และบังคับขนาดต่ำสุด ~44x44pt-equivalent ด้วย scale ที่เหมาะ
3. ตรวจ anchor/layout: action หลักชิดล่าง-ขวา, ระบบเมนู (Inventory/Chat/Auto-Battle) ล่าง/บน-ซ้าย ตาม matrix
4. อย่าเปลี่ยน logic เกม เปลี่ยนเฉพาะ layout/sizing; ทดสอบ require ผ่านหลังแก้ทุกไฟล์

ก่อนเริ่มแต่ละไฟล์ให้ list ว่าจะแก้บรรทัดไหน เหตุผลอะไร เพื่อ review ได้ง่าย
รายงานท้ายงาน: ตารางไฟล์ที่แก้ + จำนวน offset→scale ที่แปลง + ไฟล์ที่เพิ่ม aspect constraint
```

---

## หลัง Cursor ทำเสร็จ — Cowork จะทำ (computer-use)
1. ยืนยัน Rojo live-sync เข้า Studio (EternityCity 94486544638073) — ค่าง connection ไว้ได้
2. command-bar verify: `CombatStateController` require ผ่าน, `HudVisibilityManager` มีใน StarterPlayerScripts
3. Playtest มือถือ-emulate (Studio Device emulator → phone): เปิด AutoBattle/lock target → เช็ก chat/quest/notif fade หาย, skill bar/target/HP คงอยู่ → ออกจากสู้ → กลับมา
4. File → Publish to Roblox → **v12** + บันทึก memory/diary

## Definition of Done
- [ ] CombatStateController.Changed ยิงถูกตอน enter/exit จริง (ไม่ spam)
- [ ] HUD ไม่จำเป็น fade ตอนสู้, HUD combat คงอยู่, มี manual override
- [ ] ทุก HUD audit แล้ว: Scale (ไม่ใช่ offset), aspect constraint บนปุ่ม action, touch zone ใหญ่พอ
- [ ] playtest บน device emulator ผ่าน + publish v12
