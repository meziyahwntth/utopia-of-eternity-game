# GDD — Utopia of Eternity (MVP Soft Launch)

**Version:** 0.1 · **Date:** 8 มิถุนายน 2026  
**Platform:** Roblox · **Universe:** Utopia of Eternity (IP-safe 100%)  
**Official web:** [utopiaofeternity.com](https://utopiaofeternity.com)

---

## One-liner

Hang out กลางวัน · ล่าปริศนาข้ามเมือง · horror กลางคืนถาวรเมื่อพร้อม

---

## MVP Scope — 5 Places

| # | Place | Time mode | Core loop |
|---|-------|-----------|-----------|
| 1 | **Utopia Plaza Hub** | Permanent day | Spawn, Museum, Garden Gate, Teleport |
| 2 | **Solhaven** | Permanent day | Garden grow 3 stages, treasure, trade |
| 3 | **Nocturne Alley** | Permanent twilight | Sherlock clues, cipher 3:33 — **not horror** |
| 4 | **Utopia of Eternity** | Permanent day | Solarpunk photo mode, monorail, fashion |
| 5 | **หุบเขามรณะ** | **Eternal night** | Opt-in horror on **planet Hellbound** — Hyperdrive from Eternity City |

Phase 8 (post-launch): Citadel Arcane, Verdant Depths, Skyward Perch

**Hellbound travel:** `docs/death-valley/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md`  
**Social dungeons (every city):** `docs/systems/SOCIAL-DUNGEON-SYSTEM.md`

---

## Security (Phase 0.5 + Category I — implemented in code)

**Utopia Shield:** RemoteGuard, RateLimiter, MovementValidator, EconomyGuard, EconomyInflationGuard, Honeypot, BackdoorScanner

**Utopia Sentinel:** Strike system, BanRegistry, EvasionDetector, BanBroadcast, **SevereOffenseGate** (perm ban), **GriefingGuard**, **EmulatorDetector** (device block 7d → perm), **LogExportBridge** → Bridge AI

**Full spec:** `docs/design/DESIGN-V02-SYSTEMS.md` § I

---

## Design Volume 02 (systems)

Social/friends, หุบเขามรณะ co-op, Prism Keys rotation, Helper NPC, Seasonal, Mounts, Utopia of Eternity flagship, Onboarding, MMORPG patterns — see **`docs/design/DESIGN-V02-SYSTEMS.md`**

**IP audit:** `docs/legal/IP-AUDIT-UTOPIA-OF-ETERNITY.md`

**Fan license (Eternity Forge):** `docs/design/DESIGN-V03-FAN-LICENSE-PROGRAM.md` · `FanExperienceGuard.luau`

---

## Sanctuary Plaza (every city — expanded)
- **120 stud** default safe zone (Utopia of Eternity **280 stud**)
- **3+ spawn points** per city (Utopia of Eternity **8+**)
- No PvP, no Wraiths (หุบเขามรณะ uses จุดไฟชีวิต variant)
- **Mount Pad** — flying mounts (unicorn, etc.) summon/dismiss **only here**
- **Prism Transit Stop** — **Prism Hover Shuttle** (20 seats) จอดรับ-ส่ง · ออกทุก **15 นาที** · ไม่รอที่นั่งครบ · วิ่งครบ route ทุกเมือง
- Ground mounts only in Outskirts

| City | Sanctuary name |
|------|----------------|
| Hub | Prism Heart Plaza |
| Solhaven | Sunhaven Sanctuary |
| Nocturne | Twilight Meet Point |
| Utopia of Eternity | Eternity Sanctuary |
| หุบเขามรณะ | จุดไฟชีวิต |

**Prism Transit Stop (greybox MVP — Hub first):**
- Canopy สีขาว + แถบทอง · กระจก cyan · ชานชาล glow lane
- Shuttle journey: low cruise → cloud layer → heaven sky → teleport → descend → dock
- Dev: `GameConfig.PublicTransit.DevFastIntervalSeconds = 60` ใน Studio

---

## World Build — Hybrid Microcurve (implemented)

Technique inspired by Quant Build (MrBeast Minecraft, 2nd place) — **original Prism Solarpunk** content only.

| Place | Builder | Districts / features |
|-------|---------|---------------------|
| Hub | `HubWorldBuilder` | Organic plaza, museum dome, garden arch, teleports |
| Solhaven | `SolhavenWorldBuilder` | 3-stage garden terraces, curved canal |
| Nocturne | `NocturneWorldBuilder` | Twilight arches, meet ring |
| Utopia of Eternity | `EternityCityWorldBuilder` | Coastline, marina, spire cluster, Sky Rail, zone gates, Aurora Mega Mall + Sky Lounge 50, Premium Shop |
| หุบเขามรณะ | `DeathValleyWorldBuilder` | Cave mouth, life beacon |

**Spec:** `docs/world/WORLD-BUILD-MICROCURVE-SPEC.md` · **Streaming:** `docs/world/WORLD-STREAMING-SPEC.md`

---

## Meta systems

### Prism Keys
- Total count **hidden** — UI shows `Prism Keys: ??`
- Key #1 fixed tutorial · **#2–#5** sequential · **#6+ random tiers** (6–25 → 26–40 → 41–60 → 61–80 → 81–99)
- **Ghost trade** in Death Valley zones 3–5: 3 keys → 1 chosen number · 1-minute window
- Non-linear progress · ต้องเดินทางข้ามเมืองทุกดอก
- Server-side clues, some keys require หุบเขามรณะ nights + multi-city clues
- **Eternity City:** keys 1–10 ห้าม spawn ในเมือง · Preview Tour (<10 total) = Sanctuary only · gate keys 11/15/20 ปลด zone · rewards เมื่อได้หมายเลข 1/5/10/15/20 · 25 = Live Mirror

### Luminlings
- Grow 3 visual stages (Solhaven garden)
- Museum showcase in Hub

### Utopia Wardrobe & Eternity Commerce
- MVP target **500+ cosmetics** year 1
- Cosmetic only — no P2W stats
- Lazy-load catalog UI
- **Full design:** `docs/commerce/FASHION-AND-SHOPS-DESIGN.md`
- Catalog modules: `PrismFashionCatalog.luau`, `PrismCommerceConfig.luau`
- Eternity City = **commerce flagship** — fashion, vehicles, mounts, weapons, beauty
- ทุกร้านอยู่ใน **Commerce Peace Zone** (ห้าม PvP / combat tools)
- Deploy gate: Signature 6 ชุด · Seasonal 6 เทศกาล · National 10 ประเทศ · ร้าน 17 แห่ง
- **Face creation:** Template Forge (default) · **Prism Live Mirror** ปลดที่กุญแจ **25** — live camera เท่านั้น (PDPA) · `docs/systems/FACE-CREATION-SYSTEM.md`

---

## Performance budget (per Place)

| Metric | Mobile | PC |
|--------|--------|-----|
| Streamed parts | < 8,000 | < 15,000 |
| StreamingTargetRadius | 512 | 768 |
| FPS | ≥ 30 | ≥ 60 |
| Join time | < 25s | < 15s |

---

## Monetization principles

- Game Pass = convenience, not combat power
- Gacha with pity + displayed rates
- Seasonal items return to legacy shop after 6 months
- DevEx-ready from day one

---

## IP red lines

No franchise names, no copied models/audio, no brainrot meme characters, no AI-generated copyrighted characters. Original Utopia of Eternity universe only.

---

## Timeline

~6–8 weeks full dev after Phase 0.5 complete → soft launch with creator early access.

**Full design:** `~/.cursor/plans/roblox_ip-safe_game_design_3a5374d5.plan.md`
