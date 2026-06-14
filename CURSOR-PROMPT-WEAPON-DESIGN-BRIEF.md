# CURSOR PROMPT — Weapon Design Brief: 30 New Weapons (Wave 2)
> สร้าง: 13 มิ.ย. 2026 · อัปเดต: 13 มิ.ย. 2026 (เพิ่ม Tier Visual System + Image refs)
> ต่อจาก PrismLegendaryWeaponsCatalog.luau (13 weapons wave 1) + ItemTierConfig.luau

---

## 🎨 Tier Visual Progression System (สำคัญมาก)

> **"ระดับดาวสูง = สวยขึ้น + แรงขึ้น"**
> ภาพ concept art ที่ Praphan สร้างไว้ = visual target ระดับ ★3–★4 (Legendary skin)

### Visual Tier Map

| Tier | grandeurRank | ลักษณะ Visual | Target image style |
|------|-------------|--------------|-------------------|
| ★1 Basic | 1 | สีเงิน/เทา plain, ไม่มี glow | Common grey metal look |
| ★★ Standard | 2 | สีน้ำเงิน-ม่วง glow อ่อน, rune เริ่มปรากฏ | Blue shimmer |
| ★★★ Advanced | 3 | Purple-gold aura, dragon/rune detail | ← **ภาพ M4A1 Prism, Sword images** |
| ★★★★ Fused | 4 | Full legendary art: dragon head, fire/arcane VFX | ← **ภาพ AK-47 Empyrean, M-16 Draconic** |
| ⚡ Mythic | 5 | White-gold prism light, ethereal glow | ← **ภาพ Cathedral Longsword (blue-gold)** |

### Implementation ใน ItemTierConfig

เพิ่ม field `visualTier` เข้า `ItemDef`:

```lua
export type ItemDef = {
  -- ... fields เดิม ...
  visualTier: number,  -- 1-5, ใช้ select modelId + particle effect
  modelIdByTier: {number},  -- index ตรงกับ grandeurRank, rbxassetid://0 = placeholder
}
```

ตัวอย่าง StarSword1-4 ต้องมี modelIdByTier ที่ต่างกัน:
```lua
StarSword1 = { ..., visualTier = 1, modelIdByTier = {0} },  -- grey plain
StarSword2 = { ..., visualTier = 2, modelIdByTier = {0} },  -- blue glow
StarSword3 = { ..., visualTier = 3, modelIdByTier = {0} },  -- purple-gold
StarSword4 = { ..., visualTier = 4, modelIdByTier = {0} },  -- full legendary
```

---

## 📸 Visual Reference Map (ภาพ Praphan generate ไว้)

บันทึกภาพที่ `docs/visual-ref/weapons/`:

| ไฟล์ | ID ใน Catalog | Tier Visual | หมายเหตุ |
|------|-------------|-----------|---------|
| `weapon-ak47-empyrean-dragon.png` | `ak47` (wave1) | ★★★★ | Dragon Core + Arcane Magazine + Emperor's Crest |
| `weapon-m16-draconic-ascendance.png` | `m16` (wave1) | ★★★★ | Dragon's Fury + Starfire Muzzle + Runic Magazine |
| `weapon-m4a1-prism.png` | `m4a1` (wave1) | ★★★ | Black-gold + Compass Star + rainbow mag |
| `weapon-lmg-lion-arcane.png` | `prism_railgun` (wave2) | ★★★★ | Lion head + arcane compass + electric LMG |
| `weapon-launcher-rune-cannon.png` | `void_cannon` (wave2) | ★★★ | Rune wheel muzzle + angel wings + holy cannon |
| `weapon-dagger-void-arcane.png` | `prism_twin_daggers` (wave2) | ★★★ | Blue-gold blade + void aura + moon crossguard |
| `weapon-greatsword-cathedral-fire.png` | `blood_moon_blade` (wave2) | ★★★★ | Red-gold fire + rune engravings + cathedral bg |
| `weapon-spear-cathedral-crimson.png` | `demon_slaying_spear` (wave1) | ★★★★ | Crimson head + gold compass wheel + cathedral |
| `weapon-war-fan-crimson.png` | `goddess_fan` (wave1) | ★★★★ | Crimson-gold war fan + arcane wind spiral |
| `weapon-longsword-blue-gold.png` | `eternity_blade_skin` (wave2) | ★★★★ | Cathedral longsword, blue-white-gold prism light |
| `weapon-longsword-white-celestial.png` | `eternity_blade_skin` alt | Mythic ★5 | White-gold cloud longsword, celestial glow |
| `weapon-lmg-heavy-rune-ammo.png` | `void_cannon` alt | ★★★★ | Black LMG + rainbow runic ammo belt |
| `weapon-hammer-solar-fire.png` | `earth_shatter_hammer` (wave2) | ★★★★ | Massive hammer + solar fire compass + cathedral |

### VFX Notes จากภาพ (ใส่ใน vfxNotes field)

```lua
-- AK-47 Empyrean Dragon (อัปเดต wave1 entry)
vfxNotes = "Dragon soul orb core pulses purple · Celestial flame wreath barrel · Emperor gold crest shoulder · Arcane rune magazine glows red · Full fire trail on fire",

-- M-16 Draconic Ascendance (อัปเดต wave1 entry)
vfxNotes = "Dragon's Fury crown head · Starfire muzzle dragon jaw · Runic magazine stores ancient power · Celestial stock ethereal energy · Purple-blue-gold fire trail",

-- M4A1 Prism (wave1 entry ที่มีอยู่แล้ว)
vfxNotes = "Black gold filigree body · Compass star scope mount · Purple rune magazine · Red gem trigger guard · Gold prism trail burst on fire",
```

---

---

## บริบท / Structure ที่มีอยู่แล้ว

**Layer 1 — Cosmetic Legendary (Prism Shop)**
`PrismLegendaryWeaponsCatalog.luau` → `PrismWeaponCatalog.luau`
- type: `LegendaryWeaponDef` (`id, displayName, kind, loadoutSlot, robux, conceptArtFile, element, vfxNotes, damagePerHit?`)
- kinds: Dagger | AssaultRifle | LMG | Launcher | Hammer | Greatsword | Longsword | Spear | Fan
- wave 1 มี 13 weapons แล้ว (blood_knife, m16, ak47, m4a1, goddess_fan, demon_slaying_spear, ...)

**Layer 2 — Functional Combat (ItemTierConfig)**
`ItemTierConfig.luau` → `ItemDef` (`id, name, requiredLevel, grandeurRank, weight, weaponType, tradeable, sockets?`)
- weaponType: "Sword" | "Bow" | "Staff" | "None"
- wave 1 มี StarSword2/3/4 (grandeurRank 2-4) แต่ยังขาด **Bow** และ **Staff** ทุก tier

---

## ไฟล์ที่ต้องแก้

| ไฟล์ | งาน |
|------|-----|
| `PrismLegendaryWeaponsCatalog.luau` | เพิ่ม 20 cosmetic Legendary entries |
| `ItemTierConfig.luau` | เพิ่ม 10 functional weapons (Bow + Staff tiers) |

---

## Part A — ItemTierConfig: Functional Bow & Staff Tiers + Damage Table

### Damage Per Tier (ค่าที่ใช้ใน CombatService)

> เพิ่ม field `baseDamage` เข้า `ItemDef` — CombatService อ่านค่านี้แทน hardcode

| Tier | grandeurRank | Sword dmg | Bow dmg | Staff dmg | Visual |
|------|-------------|-----------|---------|-----------|--------|
| ★1 | 1 | 10 | 9 | 8 | Plain grey |
| ★★ | 2 | 18 | 16 | 14 | Blue glow |
| ★★★ | 3 | 30 | 27 | 24 | Purple-gold aura |
| ★★★★ Fused | 4 | 48 | 43 | 38 | Full legendary art |
| ⚡ Mythic | 5 | 75 | — | 65 | Ethereal prism |

เพิ่ม field ใน ItemDef type:
```lua
export type ItemDef = {
  id            : string,
  name          : string,
  requiredLevel : number,
  grandeurRank  : number,
  weight        : number,
  weaponType    : WeaponType,
  tradeable     : boolean,
  sockets       : number?,
  baseDamage    : number,   -- ← เพิ่มใหม่
  visualTier    : number,   -- ← เพิ่มใหม่ (1-5)
}
```



เพิ่มใน `ItemTierConfig.Items = { ... }` (ต่อจาก StarSword4):

```lua
-- ===== SWORD TIER 1 (ยังขาดอยู่) =====

StarSword1 = {
  id            = "StarSword1",
  name          = "★ Sword",
  requiredLevel = 1,
  grandeurRank  = 1,
  baseDamage    = 10,
  visualTier    = 1,  -- plain grey silver
  weight        = 6,
  weaponType    = "Sword",
  tradeable     = true,
  sockets       = 0,
},
-- อัปเดต StarSword2/3/4 ที่มีอยู่แล้ว เพิ่ม baseDamage + visualTier:
-- StarSword2: baseDamage=18, visualTier=2
-- StarSword3: baseDamage=30, visualTier=3  (purple-gold aura เหมือน M4A1 Prism image)
-- StarSword4: baseDamage=48, visualTier=4  (full legendary art เหมือน Cathedral Greatsword image)

-- ===== BOW TIERS (grandeurRank 1–4) =====

StarBow1 = {
  id            = "StarBow1",
  name          = "★ Bow",
  requiredLevel = 10,
  grandeurRank  = 1,
  baseDamage    = 9,
  visualTier    = 1,  -- plain wood bow
  weight        = 5,
  weaponType    = "Bow",
  tradeable     = true,
  sockets       = 0,
},
StarBow2 = {
  id            = "StarBow2",
  name          = "★★ Bow",
  requiredLevel = 25,
  grandeurRank  = 2,
  baseDamage    = 16,
  visualTier    = 2,  -- blue energy bow
  weight        = 6,
  weaponType    = "Bow",
  tradeable     = true,
  sockets       = 1,
},
StarBow3 = {
  id            = "StarBow3",
  name          = "★★★ Bow",
  requiredLevel = 45,
  grandeurRank  = 3,
  baseDamage    = 27,
  visualTier    = 3,  -- purple-gold celestial bow
  weight        = 7,
  weaponType    = "Bow",
  tradeable     = true,
  sockets       = 2,
},
StarBow4 = {
  id            = "StarBow4",
  name          = "★★★★ Bow (Fused)",
  requiredLevel = 65,
  grandeurRank  = 4,
  baseDamage    = 43,
  visualTier    = 4,  -- full legendary art: celestial longbow image
  weight        = 8,
  weaponType    = "Bow",
  tradeable     = false,
  sockets       = 2,
},

-- ===== STAFF TIERS (grandeurRank 1–4) =====

StarStaff1 = {
  id            = "StarStaff1",
  name          = "★ Staff",
  requiredLevel = 10,
  grandeurRank  = 1,
  baseDamage    = 8,
  visualTier    = 1,  -- plain wooden staff
  weight        = 4,
  weaponType    = "Staff",
  tradeable     = true,
  sockets       = 0,
},
StarStaff2 = {
  id            = "StarStaff2",
  name          = "★★ Staff",
  requiredLevel = 25,
  grandeurRank  = 2,
  baseDamage    = 14,
  visualTier    = 2,  -- blue crystal orb staff
  weight        = 5,
  weaponType    = "Staff",
  tradeable     = true,
  sockets       = 1,
},
StarStaff3 = {
  id            = "StarStaff3",
  name          = "★★★ Staff",
  requiredLevel = 45,
  grandeurRank  = 3,
  baseDamage    = 24,
  visualTier    = 3,  -- purple-gold arcane staff with rune rings
  weight        = 6,
  weaponType    = "Staff",
  tradeable     = true,
  sockets       = 2,
},
StarStaff4 = {
  id            = "StarStaff4",
  name          = "★★★★ Staff (Fused)",
  requiredLevel = 65,
  grandeurRank  = 4,
  baseDamage    = 38,
  visualTier    = 4,  -- full legendary: Rune Launcher image style (arcane muzzle wheel)
  weight        = 7,
  weaponType    = "Staff",
  tradeable     = false,
  sockets       = 3,
  -- Staff ได้ sockets 3 เพราะ magic weapon (card bonus สูงกว่า Sword/Bow)
},

-- ===== TIER 5 MYTHIC (endgame) =====

Eternity_Blade = {
  id            = "Eternity_Blade",
  name          = "⚡ Eternity Blade",
  requiredLevel = 100,
  grandeurRank  = 5,
  baseDamage    = 75,
  visualTier    = 5,  -- white-gold ethereal Cathedral longsword image (white celestial glow)
  weight        = 15,
  weaponType    = "Sword",
  tradeable     = false,
  sockets       = 3,
},
Eternity_Staff_Mythic = {
  id            = "Eternity_Staff_Mythic",
  name          = "⚡ Eternal Staff",
  requiredLevel = 100,
  grandeurRank  = 5,
  baseDamage    = 65,
  visualTier    = 5,  -- divine white-gold staff (Eternal Staff Divine image)
  weight        = 12,
  weaponType    = "Staff",
  tradeable     = false,
  sockets       = 4,  -- mage endgame flex: max sockets
},
```

---

## FusionConfig — เพิ่ม Bow & Staff fusion recipes

ใน `FusionConfig.luau` เพิ่ม:

```lua
-- Bow chain
{ inputId = "StarBow1",  inputQty = 2, outputId = "StarBow2",  creditCost = 400 },
{ inputId = "StarBow2",  inputQty = 2, outputId = "StarBow3",  creditCost = 1200 },
{ inputId = "StarBow3",  inputQty = 2, outputId = "StarBow4",  creditCost = 3000 },

-- Staff chain
{ inputId = "StarStaff1", inputQty = 2, outputId = "StarStaff2", creditCost = 400 },
{ inputId = "StarStaff2", inputQty = 2, outputId = "StarStaff3", creditCost = 1200 },
{ inputId = "StarStaff3", inputQty = 2, outputId = "StarStaff4", creditCost = 3000 },
```

---

## Part B — PrismLegendaryWeaponsCatalog: 20 Cosmetic Legendary

เพิ่มใน `PrismLegendaryWeaponsCatalog.Weapons = { ... }` ต่อจาก entry สุดท้าย:

```lua
-- ===== SWORD / GREATSWORD (6 ตัว) =====

{
  id             = "eternity_blade_skin",
  displayName    = "Eternity Blade",
  kind           = "Longsword",
  loadoutSlot    = "heavy",
  robux          = 1699,
  conceptArtFile = "eternity-blade.png",
  element        = "Prism",
  vfxNotes       = "White-gold crystal blade · prism light trail · fracture particles",
  damagePerHit   = 22,
},
{
  id             = "void_cleaver",
  displayName    = "Void Cleaver",
  kind           = "Greatsword",
  loadoutSlot    = "heavy",
  robux          = 1499,
  conceptArtFile = "void-cleaver.png",
  element        = "Void",
  vfxNotes       = "Black blade with void rift crack · purple energy seep",
  damagePerHit   = 20,
},
{
  id             = "sakura_katana",
  displayName    = "Sakura Katana",
  kind           = "Longsword",
  loadoutSlot    = "light",
  robux          = 1399,
  conceptArtFile = "sakura-katana.png",
  element        = "Nature",
  vfxNotes       = "Cherry blossom petals trail · pink blade shimmer",
  damagePerHit   = 16,
},
{
  id             = "thunder_claymore",
  displayName    = "Thunder Claymore",
  kind           = "Greatsword",
  loadoutSlot    = "heavy",
  robux          = 1499,
  conceptArtFile = "thunder-claymore.png",
  element        = "Lightning",
  vfxNotes       = "Electric arc crackling on blade · yellow storm aura",
  damagePerHit   = 19,
},
{
  id             = "blood_moon_blade",
  displayName    = "Blood Moon Blade",
  kind           = "Longsword",
  loadoutSlot    = "heavy",
  robux          = 1599,
  conceptArtFile = "blood-moon-blade.png",
  element        = "Arcane",
  vfxNotes       = "Crimson moon aura · blood drip VFX on swing",
  damagePerHit   = 18,
},
{
  id             = "prism_twin_daggers",
  displayName    = "Prism Twin Daggers",
  kind           = "Dagger",
  loadoutSlot    = "light",
  robux          = 1299,
  conceptArtFile = "prism-twin-daggers.png",
  element        = "Prism",
  vfxNotes       = "Dual rainbow light trail · prism burst on hit",
  damagePerHit   = 14,
},

-- ===== BOW (5 ตัว) =====

{
  id             = "celestial_longbow",
  displayName    = "Celestial Longbow",
  kind           = "Longsword",   -- repurpose slot; note: Bow not in WeaponKind → use Spear slot
  loadoutSlot    = "light",
  robux          = 1399,
  conceptArtFile = "celestial-longbow.png",
  element        = "Celestial",
  vfxNotes       = "Star arrows · golden bow limb glow · constellation trail",
  damagePerHit   = 17,
},
-- ⚠️ NOTE TO CURSOR: WeaponKind ไม่มี "Bow" — ให้เพิ่ม "Bow" เข้า union type:
-- export type WeaponKind = ... | "Bow"
-- แล้วใช้ kind = "Bow" ในทุก bow entry ด้านล่าง

{
  id             = "void_shadow_bow",
  displayName    = "Void Shadow Bow",
  kind           = "Longsword",
  loadoutSlot    = "light",
  robux          = 1499,
  conceptArtFile = "void-shadow-bow.png",
  element        = "Void",
  vfxNotes       = "Dark matter arrows · shadow void burst on impact",
  damagePerHit   = 18,
},
{
  id             = "prism_sniper_rifle",
  displayName    = "Prism Sniper Rifle",
  kind           = "AssaultRifle",
  loadoutSlot    = "light",
  robux          = 1599,
  conceptArtFile = "prism-sniper.png",
  element        = "Prism",
  vfxNotes       = "Rainbow light beam trail · scope prism flash",
  damagePerHit   = 25,
},
{
  id             = "sakura_shortbow",
  displayName    = "Sakura Shortbow",
  kind           = "Longsword",
  loadoutSlot    = "light",
  robux          = 1199,
  conceptArtFile = "sakura-shortbow.png",
  element        = "Nature",
  vfxNotes       = "Petal arrow trail · green nature burst",
  damagePerHit   = 15,
},
{
  id             = "thunder_repeater",
  displayName    = "Thunder Repeater",
  kind           = "AssaultRifle",
  loadoutSlot    = "light",
  robux          = 1399,
  conceptArtFile = "thunder-repeater.png",
  element        = "Lightning",
  vfxNotes       = "Chain lightning on rapid fire · electric barrel glow",
  damagePerHit   = 16,
},

-- ===== STAFF / MAGIC (5 ตัว) =====
-- ⚠️ NOTE: WeaponKind ไม่มี "Staff" — เพิ่มเข้า union เช่นกัน

{
  id             = "prism_crystal_staff",
  displayName    = "Prism Crystal Staff",
  kind           = "Hammer",   -- placeholder จนกว่าจะเพิ่ม "Staff" ใน union
  loadoutSlot    = "heavy",
  robux          = 1499,
  conceptArtFile = "prism-crystal-staff.png",
  element        = "Prism",
  vfxNotes       = "Prism orb tip · rainbow mana pulse · staff glow trail",
  damagePerHit   = 14,
},
{
  id             = "void_wand",
  displayName    = "Void Wand",
  kind           = "Hammer",
  loadoutSlot    = "light",
  robux          = 1299,
  conceptArtFile = "void-wand.png",
  element        = "Void",
  vfxNotes       = "Void singularity orb · purple-black swirl on cast",
  damagePerHit   = 16,
},
{
  id             = "eternal_staff_divine",
  displayName    = "Eternal Staff Divine",
  kind           = "Hammer",
  loadoutSlot    = "heavy",
  robux          = 1699,
  conceptArtFile = "eternal-staff-divine.png",
  element        = "Holy",
  vfxNotes       = "Angel wing feather burst · divine white-gold light column",
  damagePerHit   = 13,
},
{
  id             = "dragon_tome_staff",
  displayName    = "Dragon Tome Staff",
  kind           = "Hammer",
  loadoutSlot    = "heavy",
  robux          = 1599,
  conceptArtFile = "dragon-tome-staff.png",
  element        = "Draconic",
  vfxNotes       = "Dragon head top · fire breath VFX on cast · scales trail",
  damagePerHit   = 17,
},
{
  id             = "lunar_moon_staff",
  displayName    = "Lunar Moon Staff",
  kind           = "Hammer",
  loadoutSlot    = "heavy",
  robux          = 1399,
  conceptArtFile = "lunar-moon-staff.png",
  element        = "Arcane",
  vfxNotes       = "Crescent moon orb · silver moonbeam cast trail",
  damagePerHit   = 15,
},

-- ===== HEAVY (Hammer / Launcher) (4 ตัว) =====

{
  id             = "earth_shatter_hammer",
  displayName    = "Earth Shatter Hammer",
  kind           = "Hammer",
  loadoutSlot    = "heavy",
  robux          = 1499,
  conceptArtFile = "earth-shatter-hammer.png",
  element        = "Earth",
  vfxNotes       = "Rock crystal smash VFX · ground crack on hit",
  damagePerHit   = 24,
},
{
  id             = "void_cannon",
  displayName    = "Void Cannon",
  kind           = "Launcher",
  loadoutSlot    = "heavy",
  robux          = 1799,
  conceptArtFile = "void-cannon.png",
  element        = "Void",
  vfxNotes       = "Black hole projectile · purple singularity explosion",
  damagePerHit   = 28,
},
{
  id             = "prism_railgun",
  displayName    = "Prism Railgun",
  kind           = "LMG",
  loadoutSlot    = "heavy",
  robux          = 1699,
  conceptArtFile = "prism-railgun.png",
  element        = "Prism",
  vfxNotes       = "Continuous rainbow energy beam · prism shard spray",
  damagePerHit   = 20,
},
{
  id             = "dragon_mortar",
  displayName    = "Dragon Mortar",
  kind           = "Launcher",
  loadoutSlot    = "heavy",
  robux          = 1599,
  conceptArtFile = "dragon-mortar.png",
  element        = "Draconic",
  vfxNotes       = "Dragon fire projectile arc · fire pillar explosion",
  damagePerHit   = 26,
},
```

---

## WeaponKind Union Update

ใน `PrismLegendaryWeaponsCatalog.luau` บรรทัด type union เพิ่ม:

```lua
-- เดิม
export type WeaponKind =
  "Dagger" | "AssaultRifle" | "LMG" | "Launcher" | "Hammer" | "Greatsword" | "Longsword" | "Spear" | "Fan"

-- ใหม่ (เพิ่ม Bow + Staff)
export type WeaponKind =
  "Dagger" | "AssaultRifle" | "LMG" | "Launcher" | "Hammer"
  | "Greatsword" | "Longsword" | "Spear" | "Fan"
  | "Bow" | "Staff"

-- PrismWeaponCatalog.luau → CLASS_MAP เพิ่ม:
Bow   = "Bow",
Staff = "Staff",
```

---

## Image Prompts — Weapon Concept Art

> Save ที่ `docs/visual-ref/weapons/` ชื่อ `weapon-{id-with-dashes}.png`
> Style: white-gold Eternity City aesthetic, Roblox 3D render quality, front/side view

```
weapon-eternity-blade:
"Legendary fantasy longsword, white pearl blade with gold filigree patterns,
prism crystal core running down the blade, rainbow light diffraction,
ornate gold crossguard, glowing edge aura, white background,
game weapon concept art, front view" --ar 2:3

weapon-void-cleaver:
"Massive fantasy greatsword, obsidian black blade with purple void energy cracks,
void mist flowing from edge, dark rune engravings, heavy ornate handle,
game weapon concept art, front view, white background" --ar 2:3

weapon-sakura-katana:
"Elegant katana sword, pale pink blade with cherry blossom petal etching,
gold and rose gold guard, silk wrapped handle, falling sakura petals VFX,
Japanese fantasy game weapon art, front view" --ar 2:3

weapon-celestial-longbow:
"Fantasy longbow, golden celestial star constellation body,
arrow nocked made of pure light, star dust trail, glowing limb tips,
white background, game weapon concept front view" --ar 2:3

weapon-prism-crystal-staff:
"Tall fantasy mage staff, crystal prism orb at top emitting rainbow light,
gold filigree staff body, magical runes glowing, white pearl finish,
game weapon concept art, front view, white background" --ar 2:3

weapon-void-cannon:
"Futuristic-fantasy heavy cannon weapon, black matte with purple void energy glow,
singularity barrel swirl, ornate dark metal, shoulder-mounted design,
game weapon concept art, white background" --ar 2:3

weapon-prism-railgun:
"Sci-fi fantasy LMG railgun, white-gold body, rainbow energy coils along barrel,
prism crystal power cell, continuous glow effect, sleek futuristic design,
game weapon concept art, white background" --ar 2:3

weapon-eternal-staff-divine:
"Divine holy staff, pure white crystal top with angel wing spread,
golden staff with feather engravings, holy light radiance,
white-gold divine aesthetic, game weapon art, front view" --ar 2:3
```

---

## Weapon Summary Table

| # | ID | Layer | Kind | Element | Robux | dmg/hit |
|---|-----|-------|------|---------|-------|---------|
| **FUNCTIONAL (ItemTierConfig)** |
| 1 | StarSword1 | Functional | Sword | — | — | — |
| 2 | StarBow1-4 | Functional | Bow | — | — | — |
| 3 | StarStaff1-4 | Functional | Staff | — | — | — |
| 4 | Eternity_Blade | Functional | Sword | — | credits | — |
| **COSMETIC (PrismLegendary Wave 2)** |
| 5 | eternity_blade_skin | Cosmetic | Longsword | Prism | 1699 | 22 |
| 6 | void_cleaver | Cosmetic | Greatsword | Void | 1499 | 20 |
| 7 | sakura_katana | Cosmetic | Longsword | Nature | 1399 | 16 |
| 8 | thunder_claymore | Cosmetic | Greatsword | Lightning | 1499 | 19 |
| 9 | blood_moon_blade | Cosmetic | Longsword | Arcane | 1599 | 18 |
| 10 | prism_twin_daggers | Cosmetic | Dagger | Prism | 1299 | 14 |
| 11 | celestial_longbow | Cosmetic | Bow | Celestial | 1399 | 17 |
| 12 | void_shadow_bow | Cosmetic | Bow | Void | 1499 | 18 |
| 13 | prism_sniper_rifle | Cosmetic | Rifle | Prism | 1599 | 25 |
| 14 | sakura_shortbow | Cosmetic | Bow | Nature | 1199 | 15 |
| 15 | thunder_repeater | Cosmetic | Rifle | Lightning | 1399 | 16 |
| 16 | prism_crystal_staff | Cosmetic | Staff | Prism | 1499 | 14 |
| 17 | void_wand | Cosmetic | Staff | Void | 1299 | 16 |
| 18 | eternal_staff_divine | Cosmetic | Staff | Holy | 1699 | 13 |
| 19 | dragon_tome_staff | Cosmetic | Staff | Draconic | 1599 | 17 |
| 20 | lunar_moon_staff | Cosmetic | Staff | Arcane | 1399 | 15 |
| 21 | earth_shatter_hammer | Cosmetic | Hammer | Earth | 1499 | 24 |
| 22 | void_cannon | Cosmetic | Launcher | Void | 1799 | 28 |
| 23 | prism_railgun | Cosmetic | LMG | Prism | 1699 | 20 |
| 24 | dragon_mortar | Cosmetic | Launcher | Draconic | 1599 | 26 |

**รวม Wave 2: 10 functional + 20 cosmetic = 30 weapons**
**Grand total: 10 functional + 33 cosmetic (13 wave1 + 20 wave2)**

---

## CombatService — ใช้ baseDamage จาก ItemTierConfig

ใน `CombatService.luau` (หรือ file ที่ handle damage) แก้ให้อ่าน `baseDamage` จาก equipped weapon:

```lua
-- หา equipped weapon ของ player
local function getWeaponDamage(player: Player): number
  local inventoryData = PlayerItemStore.getInventory(player)
  local equippedWeaponId = inventoryData.equippedWeapon  -- field ที่ต้องมี
  if not equippedWeaponId then return 10 end  -- default unarmed

  local def = ItemTierConfig.Items[equippedWeaponId]
  if not def or not def.baseDamage then return 10 end
  return def.baseDamage
end
```

> ⚠️ ถ้า PlayerItemStore ยังไม่มี `equippedWeapon` field → เพิ่มใน schema ก่อน

---

## VisualTier Helper (ReplicatedStorage)

สร้าง `WeaponVisualHelper.luau` ใน `ReplicatedStorage/Modules/`:

```lua
--!strict
-- WeaponVisualHelper.luau
-- Map visualTier → particle effect name + color theme
local WeaponVisualHelper = {}

export type VisualTheme = {
  particleEffect: string,
  primaryColor: Color3,
  secondaryColor: Color3,
  glowIntensity: number,
}

local TIER_THEME: {[number]: VisualTheme} = {
  [1] = {  -- ★ Basic
    particleEffect = "None",
    primaryColor   = Color3.fromRGB(160, 160, 170),  -- grey silver
    secondaryColor = Color3.fromRGB(120, 120, 130),
    glowIntensity  = 0,
  },
  [2] = {  -- ★★ Standard
    particleEffect = "BlueShimmer",
    primaryColor   = Color3.fromRGB(80,  120, 255),   -- blue
    secondaryColor = Color3.fromRGB(40,  60,  180),
    glowIntensity  = 0.3,
  },
  [3] = {  -- ★★★ Advanced
    particleEffect = "PurpleGoldAura",
    primaryColor   = Color3.fromRGB(160, 80,  255),   -- purple
    secondaryColor = Color3.fromRGB(255, 190, 40),    -- gold
    glowIntensity  = 0.6,
  },
  [4] = {  -- ★★★★ Fused Legendary
    particleEffect = "DragonArcane",
    primaryColor   = Color3.fromRGB(200, 100, 255),   -- arcane purple
    secondaryColor = Color3.fromRGB(255, 160, 40),    -- fire gold
    glowIntensity  = 1.0,
  },
  [5] = {  -- ⚡ Mythic
    particleEffect = "PrismEternal",
    primaryColor   = Color3.fromRGB(255, 255, 240),   -- white pearl
    secondaryColor = Color3.fromRGB(100, 200, 255),   -- celestial blue
    glowIntensity  = 1.5,
  },
}

function WeaponVisualHelper.getTheme(visualTier: number): VisualTheme
  return TIER_THEME[visualTier] or TIER_THEME[1]
end

return WeaponVisualHelper
```

> Client ใช้ `WeaponVisualHelper.getTheme(def.visualTier)` เพื่อตกแต่ง weapon model บน character

---

## Git commit

```bash
git add src/ReplicatedStorage/Modules/PrismLegendaryWeaponsCatalog.luau
git add src/ReplicatedStorage/Modules/ItemTierConfig.luau
git add src/ReplicatedStorage/Modules/FusionConfig.luau
git add src/ReplicatedStorage/Modules/WeaponVisualHelper.luau
git commit -m "feat(Weapons): Wave 2 — 30 new weapons + Tier Visual System

ItemTierConfig: StarSword1 + StarBow1-4 + StarStaff1-4 + Eternity_Blade (Mythic Lv100)
FusionConfig: Bow chain (1→2→3→4) + Staff chain fusion recipes
PrismLegendaryWeaponsCatalog: +20 cosmetic legendaries
  Sword/Greatsword x6 (Eternity Blade, Void Cleaver, Sakura Katana, ...)
  Bow/Rifle x5 (Celestial Longbow, Void Shadow Bow, Prism Sniper, ...)
  Staff x5 (Prism Crystal Staff, Void Wand, Eternal Divine, Dragon Tome, Lunar Moon)
  Heavy x4 (Earth Hammer, Void Cannon, Prism Railgun, Dragon Mortar)
WeaponKind union: +Bow +Staff types"
```

## รายงานกลับ

- ✅/❌ BUILD strict · commit hash
- ยืนยัน: `#PrismLegendaryWeaponsCatalog.Weapons` = 33 (13+20)
- ยืนยัน: ItemTierConfig ไม่มี duplicate key
- ยืนยัน: FusionConfig Bow/Staff chains ไม่ชนกับ recipe เดิม
