# CURSOR PROMPT — Pet Design Brief: 15 New Pets (Wave 2)
> สร้าง: 13 มิ.ย. 2026
> ต่อจาก PetConfig.luau wave 1 (3 ตัว: slime_blue / fox_fire / dragon_mini)

---

## บริบท / Type ที่มีอยู่แล้ว

```lua
-- PetConfig.luau (อย่าแก้ type — เพิ่ม entries ใน PetConfig.Pets เท่านั้น)
export type PetBuff = {
  expBonus     : number,   -- multiplier เพิ่มจาก 1.0 (0.05 = +5%)
  pickupRadius : number,   -- studs รัศมีเก็บ item อัตโนมัติ
  luckBonus    : number,   -- โอกาส drop เพิ่ม (+0.03 = +3%)
}
export type PetRarity      = "Common" | "Rare" | "Epic" | "Legendary"
export type PetObtainMethod = "Event" | "Drop" | "Shop" | "Quest"

export type PetEntry = {
  id          : string,
  nameTH      : string,
  icon        : string,
  modelId     : string,   -- "rbxassetid://0" จนกว่าจะมี 3D model จริง
  rarity      : PetRarity,
  buff        : PetBuff,
  obtainMethod: PetObtainMethod,
}
```

**ไฟล์ที่ต้องแก้:**
`src/ReplicatedStorage/Modules/PetConfig.luau` — เพิ่มใน `PetConfig.Pets = { ... }` ต่อจาก dragon_mini

---

## 15 New Pet Entries

```lua
-- ===== Wave 2: Common (4 ตัว) =====

{
  id           = "crystal_rabbit",
  nameTH       = "กระต่ายคริสตัล 💎",
  icon         = "💎",
  modelId      = "rbxassetid://0",
  rarity       = "Common",
  buff         = { expBonus = 0.05, pickupRadius = 4, luckBonus = 0.01 },
  obtainMethod = "Drop",
},
{
  id           = "mushroom_sprite",
  nameTH       = "ดอกเห็ดอัจฉริยะ 🍄",
  icon         = "🍄",
  modelId      = "rbxassetid://0",
  rarity       = "Common",
  buff         = { expBonus = 0.08, pickupRadius = 2, luckBonus = 0 },
  obtainMethod = "Shop",
},
{
  id           = "star_chick",
  nameTH       = "ลูกไก่ดาว ⭐",
  icon         = "⭐",
  modelId      = "rbxassetid://0",
  rarity       = "Common",
  buff         = { expBonus = 0.06, pickupRadius = 3, luckBonus = 0.01 },
  obtainMethod = "Drop",
},
{
  id           = "ghost_jellyfish",
  nameTH       = "แมงกะพรุนผี 👻",
  icon         = "👻",
  modelId      = "rbxassetid://0",
  rarity       = "Common",
  buff         = { expBonus = 0.04, pickupRadius = 5, luckBonus = 0.02 },
  obtainMethod = "Drop",
},

-- ===== Wave 2: Rare (4 ตัว) =====

{
  id           = "shadow_wolf_pup",
  nameTH       = "ลูกหมาป่าเงา 🐺",
  icon         = "🐺",
  modelId      = "rbxassetid://0",
  rarity       = "Rare",
  buff         = { expBonus = 0.10, pickupRadius = 6, luckBonus = 0.04 },
  obtainMethod = "Drop",
},
{
  id           = "neon_frog",
  nameTH       = "กบนีออน 🐸",
  icon         = "🐸",
  modelId      = "rbxassetid://0",
  rarity       = "Rare",
  buff         = { expBonus = 0.08, pickupRadius = 5, luckBonus = 0.05 },
  obtainMethod = "Event",
},
{
  id           = "thunder_hawk",
  nameTH       = "เหยี่ยวฟ้าผ่า ⚡",
  icon         = "⚡",
  modelId      = "rbxassetid://0",
  rarity       = "Rare",
  buff         = { expBonus = 0.12, pickupRadius = 4, luckBonus = 0.03 },
  obtainMethod = "Quest",
},
{
  id           = "prism_butterfly",
  nameTH       = "ผีเสื้อปริซึม 🦋",
  icon         = "🦋",
  modelId      = "rbxassetid://0",
  rarity       = "Rare",
  buff         = { expBonus = 0.10, pickupRadius = 7, luckBonus = 0.04 },
  obtainMethod = "Shop",
},

-- ===== Wave 2: Epic (4 ตัว) =====

{
  id           = "angel_kitten",
  nameTH       = "แมวทูตสวรรค์ 😇",
  icon         = "😇",
  modelId      = "rbxassetid://0",
  rarity       = "Epic",
  buff         = { expBonus = 0.15, pickupRadius = 8, luckBonus = 0.06 },
  obtainMethod = "Event",
  -- Visual ref: white fluffy kitten, diamond forehead gem, gossamer wings, star pendant
},
{
  id           = "void_cat",
  nameTH       = "แมวแห่งความว่าง 🌑",
  icon         = "🌑",
  modelId      = "rbxassetid://0",
  rarity       = "Epic",
  buff         = { expBonus = 0.12, pickupRadius = 8, luckBonus = 0.08 },
  obtainMethod = "Drop",
  -- Visual ref: pitch-black cat, glowing void eyes, star constellation fur pattern
},
{
  id           = "ice_fox",
  nameTH       = "จิ้งจอกน้ำแข็ง ❄",
  icon         = "❄",
  modelId      = "rbxassetid://0",
  rarity       = "Epic",
  buff         = { expBonus = 0.14, pickupRadius = 6, luckBonus = 0.06 },
  obtainMethod = "Quest",
},
{
  id           = "golden_turtle",
  nameTH       = "เต่าทองคำ 🐢",
  icon         = "🐢",
  modelId      = "rbxassetid://0",
  rarity       = "Epic",
  buff         = { expBonus = 0.10, pickupRadius = 5, luckBonus = 0.10 },
  obtainMethod = "Shop",
  -- luckBonus สูง — เฉพาะ drop rate farming build
},

-- ===== Wave 2: Legendary (3 ตัว) =====

{
  id           = "phoenix_chick",
  nameTH       = "ลูกนกเพลิง 🔥",
  icon         = "🔥",
  modelId      = "rbxassetid://0",
  rarity       = "Legendary",
  buff         = { expBonus = 0.20, pickupRadius = 10, luckBonus = 0.08 },
  obtainMethod = "Quest",
  -- เงื่อนไข: ทำ main quest Chapter 4 จบ + kill eternal_warden MVP boss
},
{
  id           = "void_imp",
  nameTH       = "ปีศาจความว่าง 👿",
  icon         = "👿",
  modelId      = "rbxassetid://0",
  rarity       = "Legendary",
  buff         = { expBonus = 0.15, pickupRadius = 10, luckBonus = 0.12 },
  obtainMethod = "Drop",
  -- drop จาก eternal_warden MVP boss เท่านั้น (rate 0.5%)
},
{
  id           = "prism_core_orb",
  nameTH       = "ออร์บแกนกลางปริซึม ✨",
  icon         = "✨",
  modelId      = "rbxassetid://0",
  rarity       = "Legendary",
  buff         = { expBonus = 0.25, pickupRadius = 12, luckBonus = 0.10 },
  obtainMethod = "Event",
  -- seasonal event only — ไม่วางขาย Shop ถาวร
},
```

---

## NpcDropConfig — เพิ่ม pet drops ใหม่

ใน `src/ReplicatedStorage/Modules/NpcDropConfig.luau` เพิ่ม entries ใน NPC tables:

```lua
-- NPC 1 (Lv 1-10) — เพิ่ม common pets
{ dropType = "pet", petId = "crystal_rabbit",  minQty = 1, maxQty = 1, chance = 0.03 },
{ dropType = "pet", petId = "ghost_jellyfish",  minQty = 1, maxQty = 1, chance = 0.02 },

-- NPC 2 (Lv 11-25) — เพิ่ม rare
{ dropType = "pet", petId = "shadow_wolf_pup",  minQty = 1, maxQty = 1, chance = 0.015 },

-- NPC 4 (Lv 46-75) — เพิ่ม epic
{ dropType = "pet", petId = "void_cat",         minQty = 1, maxQty = 1, chance = 0.008 },

-- NPC 5 / MVP eternal_warden — legendary
{ dropType = "pet", petId = "void_imp",         minQty = 1, maxQty = 1, chance = 0.005 },
```

> ⚠️ ตรวจสอบ NPC IDs จาก CombatConfig.NpcIdAttribute ก่อนแก้

---

## PetClient.client.luau — Notification สำหรับ rarity ใหม่

ใน `PetClient.client.luau` ตรวจ rarity ก่อน show notification:

```lua
-- เพิ่มใน showPetNotif() function
local rarityColor = {
  Common    = Color3.fromRGB(180, 180, 200),
  Rare      = Color3.fromRGB(80,  160, 255),
  Epic      = Color3.fromRGB(160, 80,  255),
  Legendary = Color3.fromRGB(255, 180, 50),
}
-- ใช้ rarityColor[pet.rarity] แทน pink fixed color
```

---

## Image Prompts — AI Concept Art

> Save ที่ `docs/visual-ref/pets/` ชื่อ `pet-{id-with-dashes}.png`

```
pet-angel-kitten:
"Cute chibi Roblox-style pet companion, fluffy pure white kitten,
tiny gossamer fairy wings, diamond gem on forehead, crystal star pendant necklace,
surrounded by soft sparkles, white-gold divine light background,
game item card illustration style, transparent background ready" --ar 1:1

pet-void-cat:
"Chibi Roblox pet, sleek black cat with glowing void-purple eyes,
constellation star pattern on fur (like night sky), dark aura wisps,
floating in void space background, game companion art style" --ar 1:1

pet-phoenix-chick:
"Cute baby phoenix chick Roblox pet, fluffy red-orange-gold feathers,
tiny wings spreading, flame crown on head, warm golden fire glow,
chibi proportions, game item art style" --ar 1:1

pet-prism-core-orb:
"Roblox companion pet, floating luminous orb, rainbow prism crystal core,
light rays radiating outward, tiny face in the center, sparkle particles,
white background, game art illustration style" --ar 1:1

pet-shadow-wolf-pup:
"Chibi Roblox pet wolf pup, dark grey shadow fur, glowing cyan eyes,
shadow smoke wisps around paws, adorable chibi face, game companion style,
transparent background" --ar 1:1

pet-thunder-hawk:
"Chibi Roblox pet hawk, electric yellow feathers, lightning bolt wing patterns,
crackling electric aura, fierce tiny eyes, game item art" --ar 1:1

pet-ice-fox:
"Chibi Roblox pet fox, crystal ice-blue fur, snowflake pattern markings,
frozen breath effect, icy paw prints, white-blue color palette, game art" --ar 1:1

pet-prism-butterfly:
"Chibi Roblox pet butterfly, transparent rainbow prism wings refracting light,
pastel color shift effect, floating elegantly, sparkles around wings,
game companion illustration" --ar 1:1
```

---

## Git commit

```bash
git add src/ReplicatedStorage/Modules/PetConfig.luau
git add src/ReplicatedStorage/Modules/NpcDropConfig.luau
git add src/StarterPlayer/StarterPlayerScripts/PetClient.client.luau
git commit -m "feat(Pet): Wave 2 — 15 new pets (4 Common, 4 Rare, 4 Epic, 3 Legendary)

New pets: crystal_rabbit, mushroom_sprite, star_chick, ghost_jellyfish (Common)
  shadow_wolf_pup, neon_frog, thunder_hawk, prism_butterfly (Rare)
  angel_kitten, void_cat, ice_fox, golden_turtle (Epic)
  phoenix_chick, void_imp, prism_core_orb (Legendary)
NpcDropConfig: pet drops for NPC1/2/4/5 + MVP boss void_imp 0.5%
PetClient: rarity-colored notifications (grey/blue/purple/gold)"
```

## รายงานกลับ

- ✅/❌ BUILD strict · commit hash
- ยืนยัน: `#PetConfig.Pets` count = 18 (3 wave1 + 15 wave2)
- ยืนยัน: NpcDropConfig ไม่มี syntax error หลังเพิ่ม entries
