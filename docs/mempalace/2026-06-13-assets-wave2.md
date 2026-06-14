# MemPalace Diary — Asset Wave 2 (Fashion + Garage + Pet + Weapon Prompts)
**วันที่:** 13 มิ.ย. 2026
**Commits:** 53f568a (Fashion Wave2) · fe5804d (Garage) · bb00d80 (Pet Wave2) · 8264a66 (Weapon Wave2)

---

## 1. Teen Trend Fashion Wave 2 (53f568a)

60 ชุดใหม่ Sets 31–90 ใน `TeenTrendFashionSets.luau`:
- A (31-40): Street Chic & Baddie — Barbiecore, Bimbocore, Neon Baddie
- B (41-50): Party Night & Disco — Club, Rave Butterfly, Songkran 2027, Valentine
- C (51-60): Dark Alt & Gothic — Dark Fairy, Goth Lolita, Vampire, Devil-Angel Split
- D (61-70): Fantasy & Cosplay — Dragon Empress, Celestial Stardust, Prism Angel
- E (71-80): Seasonal Events — Christmas, Songkran Lotus, Loy Krathong, CNY, NYE
- F (81-90): Prestige Couture — Black Swan, White Swan, Met Gala, Ethereal Goddess

**Image Prompts:** `docs/visual-ref/fashion/teen-trend/IMAGE-PROMPTS-WAVE2.md` (60 prompts)
**แก้ bugs:** piece ID collision `cbs_` vs `cbsw_` + typo `bcdr_` → `bdr_`

---

## 2. Garage System: Vehicle + Legendary Mount (fe5804d)

**VehicleConfig:** 15 ยานพาหนะ (Personal/Group/Air/Water + 2 credit-only Legendary)
- `void_phantom_racer` = 50k credits, `eternal_sky_throne` = 100k credits

**MountConfig:** 7 legendary mounts (Ground 3 / Flying 4)
- Ground: white_timber_wolf (+22 spd), golden_lion_king (+26), celestial_white_deer (+20)
- Flying: red_gold_phoenix (+30), white_pegasus (+28), prism_white_dragon (+35, 150k credits Mythic), golden_griffin (+32)

**DataStore:** `UtopiaVehicleMount_v1` · pcall ครอบทุก operation
**Equip flow:** unequip ก่อนเสมอ → speed boost → placeholder model weld ที่ HumanoidRootPart
**BindableEvent:** `OpenGarage` ใน ReplicatedStorage → กด G หรือปุ่ม 🚗 HUD
**NOTE:** แยกจาก VehicleMountCatalog เดิม (catalog ≠ ownership layer)

**ขั้นถัดไป (Cursor):**
1. ใส่ modelId จริงจาก Roblox catalog
2. Flying mount: BodyVelocity + Y drift
3. Group ride: VehicleSeat pattern
4. Buy flow จากปุ่ม 🔒 Buy → Robux/credit prompt

---

## 3. Cursor Prompts ที่สร้าง (รอ Cursor implement)

| ไฟล์ | งาน | สถานะ |
|------|-----|--------|
| `CURSOR-PROMPT-FASHION-TEEN-60SETS.md` | 60 fashion sets Wave 2 | ✅ Cursor done 53f568a |
| `CURSOR-PROMPT-VEHICLE-MOUNT-BRIEF.md` | Garage system | ✅ Cursor done fe5804d |
| `CURSOR-PROMPT-PET-DESIGN-BRIEF.md` | 15 pets Wave 2 | ✅ Cursor done bb00d80 |
| `CURSOR-PROMPT-WEAPON-DESIGN-BRIEF.md` | 30 weapons + Tier Visual System | ✅ Cursor done 8264a66 |

---

## 4. Weapon Tier Visual System (ใหม่)

Praphan ส่งภาพ weapon concept art (ChatGPT generated):
- AK-47 Empyrean Dragon, M-16 Draconic Ascendance = ★★★★ tier visual target
- Cathedral Longsword white-gold = ⚡ Mythic visual target
- `WeaponVisualHelper.luau` ใหม่: map visualTier 1-5 → particle + color theme

**Damage table:**
★1: Sword 10, Bow 9, Staff 8
★★: 18/16/14
★★★: 30/27/24
★★★★ Fused: 48/43/38
⚡ Mythic: 75/—/65

---

## 5. Pet Wave 2 — Cursor done (bb00d80)

18 pets รวม (3 wave1 + 15 wave2):
- Common (4): crystal_rabbit, mushroom_sprite, star_chick, ghost_jellyfish
- Rare (4): shadow_wolf_pup, neon_frog, thunder_hawk, prism_butterfly
- Epic (4): angel_kitten (Event/wings), void_cat (Drop), ice_fox (Quest), golden_turtle (Shop/luck build)
- Legendary (3): phoenix_chick (Quest Ch4+boss), void_imp (0.5% MVP drop), prism_core_orb (seasonal event)

NpcDropConfig drops wired: NPC1 (3%+2%), NPC2 (1.5%), NPC4 (0.8%), NPC5/boss (0.5%)
PetClient: rarity-color notifications (grey/blue/purple/gold)
⚠️ void_imp ที่ NPC5 (CombatNpcId=5) — MVP eternal_warden ต้องเพิ่มใน MvpBossService แยก

---

## 6. Weapon Wave 2 — Cursor done (8264a66)

33 weapons รวม (13 wave1 + 20 wave2 cosmetic):
- Sword/GS ×6, Bow/Rifle ×5, Staff ×5, Heavy ×4
- WeaponKind union +Bow +Staff
- FusionConfig chains: Bow 1→4, Staff 1→4 (400/1200/3000 credits)
- WeaponVisualHelper.luau: tier 1-5 → particle+color (grey→blue→purple-gold→arcane→prism)
- CombatService: อ่าน baseDamage จาก ItemTierConfig (fallback CombatConfig.BaseDamage)
- ItemTierConfig: baseDamage + visualTier fields ครบทุก weapon tier

ขั้นถัดไป:
- Generate PNG concept art จาก IMAGE-PROMPTS.md → docs/visual-ref/weapons/
- ใส่ modelId จริงเมื่อมี 3D assets
- Wire equip sync WeaponType/WeaponTier attributes
