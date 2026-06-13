# MASTER BLUEPRINT — Utopia of Eternity
**ฉบับรวมศูนย์ (Single Source of Truth)** · อัปเดต 13 มิ.ย. 2026
**รวม:** ความต้องการของ Praphan + ระบบเด่นจาก MMO ตำนาน (Lineage II / Ragnarok) + เกม Roblox ท็อป
**เอกสารลูก (รายละเอียด):** `BLUEPRINT-V2-WORLD-PROGRESSION.md` · `GDD-SOCIAL-VOICE.md` · `GDD-SHOP-RENTAL-COMMERCE.md` · `RESEARCH-CLASSIC-MMO-SYSTEMS.md` · `RESEARCH-ROBLOX-TOP-GAMES.md`

---

## 1. วิสัยทัศน์ (Vision)
> **"สรวงสวรรค์ลอยฟ้าที่เป็นบ้านหลังที่สองของผู้เล่น"** — เมืองยูโทเปียลอยเหนือเมฆ เริ่มจากเมืองมนุษย์ Neon Utopia เดินทางด้วยเครื่องบิน/Hyper Space ข้ามมิติ · ผู้เล่นไต่ระดับด้วยกุญแจ สร้างแคลน ทำสงครามชิงเขต ล่าบอส เทรดของ แต่งตัวอลังการ คุยสดกับเพื่อน — **สังคม + เศรษฐกิจผู้เล่น + ความแฟร์** เป็นหัวใจ ไม่ pay-to-win

## 2. เสาหลัก (Design Pillars)
1. **โลกสรวงสวรรค์ (World):** เมืองลอยฟ้า · Neon Utopia (เกิด) · Hellbound ต่างมิติ · ขนส่งทางอากาศ/Hyper Space
2. **ไต่ระดับด้วยกุญแจ (Progression):** Level 1-149 จากกุญแจเรียงเลข · 7 Tier (Newbie→Hero) · Quest · จิตอาสา→วิญญาณวีรชน
3. **เศรษฐกิจผู้เล่น (Player Economy):** ร้านเช่า · **เทรด P2P** · item tier+grandeur · **card/rune** · เหรียญนำโชค · **แฟร์ ไม่ pay-to-win**
4. **สังคม (Social):** ปาร์ตี้ · แคลน(progression+war) · เพื่อน/แจ้งเตือน · กระซิบ · **voice push-to-talk** · ตั้งค่าเสียง
5. **อายุยืน (Live & Fair):** **Clan War ชิงเขต** · **MVP boss** · live-ops calendar · เทศกาลตามฤดู · กันบอท · 3 มุมกล้อง
6. **📱 Mobile-First UX:** Radial Interaction Wheel · Auto-Battle toggle · thumb-zone HUD · scale-based UI · collapsible menus · target lock · follow system

## 3. 🔗 วงจรที่ทุกระบบผูกกัน (Core Interconnection)
```
        เก็บกุญแจ (quest/drop/จิตอาสา)
                 │  เลื่อน Level/Tier
                 ▼
        ปลดล็อก item tier ───► แต่งตัว/พาหนะ/อาวุธ (grandeur)
                 │                        ▲
                 │                card/rune จาก  │ ฟิวส์/อัปเกรด
                 ▼                  MVP boss      │
        ร้านเช่า ◄──► เทรด P2P ◄──────────────────┘
                 │  (เศรษฐกิจผู้เล่น · robux=cosmetic)
                 ▼
        Clan War ชิงเขต ──► แคลนผู้ชนะเก็บ "ภาษี" รายได้ร้านในเขต
                 ▲                              │
                 │ ปาร์ตี้+voice ประสานงาน        ▼
        เพื่อน/แจ้งเตือน/เชิญข้ามเมือง ◄─── live-ops calendar (รายสัปดาห์/ฤดู)
```
**หัวใจ:** กุญแจ→level→item; boss→card→item; ร้านเช่า↔เทรด=เศรษฐกิจ; Clan War เก็บภาษีจากร้านในเขต = endgame ที่มัดทุกอย่าง

---

## 4. แคตตาล็อกระบบทั้งหมด (สถานะ + ที่มา)
> สถานะ: ✅DONE · 🔵CODE(เขียนแล้วรอ verify เต็ม) · 🟡PLAN · ที่มา: [P]=Praphan [M]=MMO [R]=Roblox

### เสา 1 — World
| ระบบ | สถานะ | ที่มา |
|------|------|------|
| เมือง Eternity ลอยฟ้า + ทะเลเมฆ + กันตก | ✅ verified | P |
| Neon Utopia (เมืองเกิด, luxe neon) | 🔵 | P |
| ขนส่งทางอากาศ Neon→Utopia (ตั๋วโดยสาร) | 🔵 | P |
| Hyper Space → Hellbound ต่างมิติ (+ค่าโดยสาร) | 🔵 | P |
| SpawnRouter ผู้เล่นใหม่→Neon (รอ Place ID) | 🟡 | P |
| 3 มุมกล้อง (1st/3rd/มุมสูง) | 🟡 | P |
| **🆕 แมพ PvP เฉพาะ "Eternal Colosseum" (Place แยก)** | 🟡 | P |

### เสา 2 — Progression
| ระบบ | สถานะ | ที่มา |
|------|------|------|
| Player Level จากกุญแจเรียงเลข 1-149 | ✅ มี PrismKeyService | P |
| 7 Player Tier (Newbie→Hero) + ฉายา | 🟡 | P |
| Quest กุญแจ | 🟡 (มี QuestBoard) | P |
| จิตอาสา → วิญญาณวีรชน (หุบเขามรณะ) | 🟡 | P |
| **Job/Class specialization** (สาย/สกิล) | 🟡 | M |

### เสา 3 — Player Economy
| ระบบ | สถานะ | ที่มา |
|------|------|------|
| Shop Rental (ร้านผู้เล่น) | ✅ Phase A | P |
| Item tier + grandeur (เสื้อ/พาหนะ/อาวุธ) | 🟡 P4 | P |
| Weight system (น้ำหนักเกิน -50%) | 🟡 | P |
| Item gating ตาม level + เหรียญนำโชค | 🟡 | P |
| กฎซื้อ Lv1-25 กุญแจ / Lv26+ กุญแจ+robux หรือ robux×5 | 🟡 | P |
| **Trading P2P (กล่องเทรดปลอดภัย) — Window-based, 2-step confirm, กันโกง** | 🟡 P4 | R+M |
| **Collection + Fusion (ฟิวส์ซ้ำ→เรืองแสง)** | 🟡 | R |
| **Card/Rune socket** (จากบอส, ปรับสเตต/อลังการ) | 🟡 | M |
| **Fair monetization (no pay-to-win) เป็นนโยบาย** | 🟡 | M+R |

### เสา 4 — Social
| ระบบ | สถานะ | ที่มา |
|------|------|------|
| แจ้งเตือนเพื่อนออนไลน์ข้ามเมือง | ✅ DONE | P |
| Party + `/invite` + teleport-to-join (cooldown 30น.) | 🟡 reuse Lfg | P |
| Whisper `/w` ข้ามเซิร์ฟ | 🟡 | P |
| **Guild/Clan + progression (level/reputation/perks/alliance/hall)** | 🟡 | P+M |
| Voice push-to-talk (Audio API) + ปุ่มโทร | 🟡 | P |
| Audio Settings (ปิดเพลง/SFX/แจ้งเตือน) | 🟡 | P |
| **🆕 Radial Interaction Wheel (มือถือ)** — จิ้มตัวละคร→วงล้อไอคอน (Trade/Whisper/Party/Clan/Follow) | 🟡 P3-C+ | M(RO) |
| **🆕 Follow System** — `PathfindingService` วิ่งตามเป้าหมายอัตโนมัติ | 🔵 stub P3-C | M(RO) |
| **🆕 In-game Report System** — ปุ่ม Report ตรงจากเมนูผู้เล่น | 🔵 stub P3-C | P |
| **🆕 Custom Chat GUI** — 5 channel tabs + voice toggle (Lineage II style) | 🔵 P3-C | M(LW) |

### เสา 5 — Live & Fair
| ระบบ | สถานะ | ที่มา |
|------|------|------|
| **Clan War ชิงเขต** (เก็บภาษีร้านในเขต) | 🟡 | M |
| **MVP World Boss** (top-contributor ได้เกรล+card) | 🟡 ยก DV Weekly Boss | M |
| **Live-ops Event Calendar** | 🟡 | R |
| เทศกาลตามฤดู (LoyKrathong) + Fashion Show + Festival | ✅ มี | P+R |
| Daily Login Streak + codes | ✅ มี streak | R |
| กันบอท/AFK farm เข้มงวด | ✅ P0 + 🟡 ขยาย | P |
| **🆕 Player Action Log (Anti-Bot DB)** — บันทึก chat/trade/item ลง DataStore เพื่อ audit | 🟡 P6 | P |
| **🆕 Auto-Battle / Auto-Skill Toggle** — client loop + server validate (Lineage W style) | 🟡 P3-C+ | M(LW) |
| **🆕 Target Lock System** — จิ้ม/คลิก → Highlight + BillboardGui + Lock toggle | 🟡 P3-C+ | M(LW) |
| **Olympiad-style Arena (ผูก Hero tier)** | 🟡 | M |
| Pet/Companion (ต่อยอด Mount) · emote · คู่/สหาย | 🟡 | M+R |
| Visible power (aura/glow ตาม tier) | 🟡 | R |

---

## 5. นโยบายหลัก (Principles — บังคับทุกระบบ)
1. **Fair / No pay-to-win:** robux = cosmetic/ความสะดวก/identity เท่านั้น · core หาได้ด้วยกุญแจ/เครดิต · odds โปร่งใส · ไม่มี UI หลอก (ปลอดภัยสำหรับผู้เล่นอายุน้อย)
2. **Server-authoritative:** client ส่ง intent, server ตัดสินทุกอย่าง (กันโกง/บอท)
3. **Modular:** ทุกระบบเป็น module แยก, config-driven, สื่อสารผ่าน RemoteGuard
4. **Strict Truth:** ตรวจของเดิมก่อนเขียน (reuse), verify ทุกอย่าง (rojo build + playtest)
5. **Social-first:** ทุกฟีเจอร์หนุนการเล่นด้วยกัน (บ้านหลังที่สอง)

---

## 6. ROADMAP รวม (จัดลำดับตาม impact × ผูกหลายระบบ)
> ✅เสร็จ: P0 (security) · P1 (world ลอยฟ้า, verified) · P2 (transport) · S1 (friend notify)

| เฟส | งาน | ทำไมลำดับนี้ |
|----|-----|------------|
| **P3-A Social Core** | Party(+invite/teleport cooldown) · Whisper · Audio Settings | หัวใจ "เล่นไม่ต้องพิมพ์" + ฐานของ voice/clan |
| **P3-B Guild/Clan** | GuildService + progression (level/rep/perks/alliance/hall) | ฐานของ Clan War |
| **P3-C Voice** | VoiceChannel (Audio API) push-to-talk + ปุ่มโทร | ต่อจาก party/clan (เสี่ยง→ทำหลังฐานแน่น) |
| **P4 Economy** | Item tier+grandeur · Weight · gating · **Trading P2P** · **Fusion** · **Card/Rune** | เศรษฐกิจ — ผูก boss/clan war |
| **P5 Endgame** | **Clan War ชิงเขต (เก็บภาษีร้าน)** · **MVP Boss** · Arena | endgame ที่มัดทุกระบบ |
| **P6 Anti-bot** | ขยาย AntiBotGuard/FarmGuard/HumanityCheck | ปกป้องเศรษฐกิจ/แข่งขัน |
| **P7 Camera/UX** | 3 มุมกล้อง · visible power (aura/glow) | ขัดเงา |
| **P8 Live-ops** | Event Calendar · Pet · emote · season · limited cosmetic | คงผู้เล่นระยะยาว |

**เริ่มทันที:** P3-A (Party + Whisper + Audio Settings) → P3-B (Clan) → แล้วต่อ P4/P5 ที่ผูก Trading+ClanWar+MVP boss

---

## 7. 🆕 แมพ PvP เฉพาะ — "Eternal Colosseum" (Place แยก)
**แนวคิด (Praphan):** มีแมพ PvP โดยเฉพาะ เพื่อให้ผู้เล่น**รวมตัวกันเป็นสังคม** · โลกหลัก = sanctuary (ปลอดภัย ไม่ตีกัน) → PvP เกิด**เฉพาะในแมพนี้**
**กฎ:** ranged = PvE-only ในโลกหลัก → ในสนามใช้ **arena loadout เฉพาะ** (melee/สกิลสนาม/อาวุธสนามที่สมดุล) เพื่อความแฟร์
**โหมด (เสนอ):**
1. **Ranked Arena (Olympiad)** — 1v1 / 3v3 จัดอันดับรายสัปดาห์ → ผูกตำแหน่ง **"Hero"** (Lv100-149) + leaderboard
2. **Clan Scrim / Team Deathmatch** — ทีม/แคลนซ้อมรบ (ฝึกก่อน Clan War จริง)
3. **Free-for-All / Battle Royale ย่อ** — สนุกเร็ว เข้าได้ทุกคน
**เข้าถึง:** portal/ขนส่งจาก Neon Utopia หรือ Utopia · reward = เหรียญเกียรติยศ → แลก cosmetic (ไม่ใช่พลัง = แฟร์)
**สถานะ:** Place ใหม่ (เหมือน Neon/Hellbound) — builder + PvP combat (เปิด FriendlyFire เฉพาะที่นี่) + matchmaking

---

## 8. 💡 ค่าที่แนะนำทั้งหมด (ข้อเสนอ Claude — ปรับได้, อิง RO/L2/Roblox)
> **พันธมิตร (Alliance) = มิตรภาพระหว่างแคลน** (Praphan) → หลายแคลนจับมือ: แชทพันธมิตรร่วม, ไม่ตีกันใน war, ร่วมรบ siege ได้

### Party (ปาร์ตี้)
| ค่า | แนะนำ | เหตุผล |
|----|------|-------|
| สมาชิกสูงสุด | **12** (Praphan — เท่า Ragnarok) | สังคมใหญ่, ลุยบอส/ดันเจี้ยนเป็นหมู่ |
| Raid (รวมหลายปาร์ตี้ล่า MVP) | **2 ปาร์ตี้ = 24** | บอสใหญ่ต้องการคนเยอะ |
| หัวหน้า | 1 (โอน/เชิญ/เตะได้) | — |
| teleport-to-join cooldown | **30 นาที/คน** | กันใช้แทนเครื่องบิน (ยืนยันแล้ว) |

### Clan / Guild (แคลน)
| ค่า | แนะนำ | เหตุผล |
|----|------|-------|
| สมาชิกสูงสุด | **เริ่ม 20 → +5/clan level → สูงสุด 65 (Lv10)** | โตตามแคลน (แบบ RO/L2) ให้รู้สึก progress |
| Clan Level | **1-10** (XP จากกิจกรรม/ชนะ war) | ปลด cap + perks |
| ยศ (4) | **Leader(1) · Officer(≤3) · Veteran · Member** | Officer เชิญ/เตะ/เปิด war ได้ |
| สร้างแคลน | **ต้อง Lv16+ (Apprentice) + ค่าใช้จ่ายในเกม** (เครดิต/กุญแจ) · robux = ทางเลือกเสริม | กันแคลนสแปม + แฟร์ |
| Clan perks | บัฟ EXP/คีย์, คลังแคลน, Clan Hall, clan skill | ปลดตามเลเวล |

### Alliance (พันธมิตร = มิตรภาพระหว่างแคลน)
| ค่า | แนะนำ | เหตุผล |
|----|------|-------|
| จำนวนแคลนต่อพันธมิตร | **สูงสุด 3 แคลน** | แบบ L2 — กองทัพร่วมแต่ไม่ใหญ่เกินคุม |
| สิทธิ์ | แชทพันธมิตรร่วม · ไม่ friendly-fire ใน war · ร่วม siege | = "มิตรภาพ" จริง |
| หัวหน้าพันธมิตร | leader ของแคลนนำ | — |

### Clan War / ชิงเขต
| ค่า | แนะนำ | เหตุผล |
|----|------|-------|
| รอบเวลา | **เสาร์ 20:00 (server time), 45 นาที** | prime time ไทย, ยาวพอมัน ไม่ล้า |
| สิทธิ์ลงทะเบียน | Clan Lv **3+** | ต้องสร้างแคลนจริงก่อน (แบบ L2) |
| รางวัลผู้ชนะ | ถือเขต 1 สัปดาห์ → **% ภาษีจากค่าเช่าร้านในเขต** + Clan Hall + ตรา + cosmetic | มัดเศรษฐกิจ+สังคม |
| เขตที่ชิง | เริ่ม **3 เขตใน Eternity City** (Marina / Aurora / Canal) | ต่อยอด landmark ที่มี |

### Economy / ค่าอื่น (ตั้งไว้แล้ว — ปรับได้)
| ค่า | แนะนำ |
|----|------|
| ค่าโดยสารเครื่องบิน Neon→Utopia | 1 ตั๋ว / 25 Robux |
| ค่า Hyper Space → Hellbound | 1 ตั๋ว / 35 Robux |
| ตั๋วเริ่มต้นผู้เล่นใหม่ | 5 ตั๋ว |
| เหรียญนำโชค ปลด weight gating | ทองแดง 1ด. / เงิน 2ด. / ทอง 3ด. |
| ซื้อไอเทม | Lv1-25 กุญแจฟรี · Lv26+ กุญแจ+robux **หรือ** robux×5 |

---

## 9. ROADMAP อัปเดต (เพิ่ม PvP Arena)
> P5 Endgame เพิ่ม: **Eternal Colosseum (แมพ PvP)** + Clan War + MVP Boss + Arena ranked
> ลำดับ: P3-A สังคมหลัก → P3-B แคลน(+alliance) → P3-C voice → P4 เศรษฐกิจ(trade/fusion/card) → **P5 PvP Arena + Clan War + MVP boss** → P6 กันบอท → P7 กล้อง/visible power → P8 live-ops


---

## 10. 📱 Mobile-First Design Mandates (เพิ่ม 13 มิ.ย. 2026)
> ที่มา: วิเคราะห์จาก Lineage W + Ragnarok Mobile + Roblox Mobile standard

### Feature Requirements Matrix
| ระบบ | แรงบันดาลใจ | Requirement บังคับ |
|------|-----------|-----------------|
| **Targeting System** | Lineage W | Auto-Lock: จิ้ม NPC/ผู้เล่น → Highlight + BillboardGui · ปุ่ม Lock/Unlock toggle |
| **Radial Interaction Wheel** | Ragnarok Mobile | จิ้มตัวละคร → วงล้อไอคอน (Trade · Whisper · Party · Clan · Follow) รอบตัวละครนั้น · เหมาะนิ้วโป้ง |
| **Follow System** | Ragnarok Mobile | `Humanoid:MoveTo()` / `PathfindingService` วิ่งตาม target · ใช้ในปาร์ตี้ + social train |
| **Auto-Battle Toggle** | Lineage W | ปุ่ม toggle มุมซ้ายล่าง · client loop หาศัตรูใกล้สุด → lock → auto attack/skill off-cooldown · server validate |
| **Custom Chat GUI** | Lineage W | 5 channel tabs + mic toggle · ✅ P3-C done |
| **Trade Window** | MMORPG standard | GUI 2 ฝ่าย · ขั้นตอน: เสนอ → ล็อค → ยืนยัน 2 ฝ่าย → execute · server-authoritative |
| **HUD Layout** | Mobile Standard | Bottom-right: Attack/Skill/Jump (ใหญ่สำหรับนิ้วโป้ง) · Bottom/Top-left: Bag/Chat/Auto-battle · ทุก element ใช้ Scale ไม่ใช่ Offset · UIAspectRatioConstraint |
| **Collapsible UI** | Mobile Standard | Chat/menu ซ่อนอัตโนมัติระหว่างต่อสู้ · กด toggle แสดงอีกครั้ง · ไม่บดบัง viewport |
| **Player Log / Anti-Bot** | Admin system | บันทึก action log (chat/trade/item move) ลง DataStore · ตรวจ pattern บอท/ฟาร์มไก่ · ban ได้ทันที |
| **In-game Report** | Admin system | ปุ่ม Report ใน context menu ผู้เล่น → เก็บ log + แจ้ง admin channel |

### กฎ Developer (บังคับ)
1. **Touch Zone:** ปุ่มทุกอันใน Radial Menu และ HUD ต้องใหญ่พอสำหรับนิ้วโป้ง (≥44×44 pixel ที่ 360p)
2. **Scale-only UI:** ห้ามใช้ Offset บน component หลัก — ใช้ Scale + UIAspectRatioConstraint เท่านั้น
3. **Auto-hide logic:** Chat/Radial Menu ต้องมี timer auto-hide (≤5 วินาที หลังไม่ interract)
4. **Server-authoritative Auto-Battle:** client ส่ง intent → server ยืนยันก่อนทุก action (กันบอท exploit)
5. **Radial Menu แทน List:** เลิกใช้ list-based interaction menu → ใช้ Radial Wheel (P3-C InteractionClient มี stub แล้ว — ต้องอัปเกรดเป็น radial)

### HUD Zone Map (มือถือแนวตั้ง)
```
┌─────────────────────────────────┐
│ [มินิแผนที่]  [ชื่อ/HP/MP]  [🔔] │  ← TOP (ข้อมูล เข้าถึงนิ้วชี้)
│                                 │
│          [GAME WORLD]           │  ← กลางว่าง (ทัศนวิสัย)
│                                 │
│ [🎒][💬][⚔️Auto]              │  ← BOTTOM-LEFT (menu/toggle)
│                   [Skill3][Sk4] │  ← BOTTOM-RIGHT TOP
│                   [Skill1][⚔️] │  ← BOTTOM-RIGHT (โจมตีใหญ่)
└─────────────────────────────────┘
```

### Roadmap Mobile Systems
| Phase | ระบบ | Priority |
|-------|------|---------|
| P3-C+ | Radial Interaction Wheel อัปเกรดจาก context menu | HIGH |
| P3-C+ | Target Lock System + Highlight + BillboardGui | HIGH |
| P3-C+ | Auto-Battle Toggle (client loop + server validate) | HIGH |
| P4 | Trade Window 2-step + Player Log | HIGH |
| P4+ | HUD refactor ทั้งหมด → Scale-based + thumb zones | MEDIUM |
| P6 | Player Action Log DataStore + Anti-Bot pattern detection | HIGH |

---

*จบ Master Blueprint — อัปเดต 13 มิ.ย. 2026 (Mobile-First)*
