# CURSOR PROMPT — Pet Drop from NPC Kill
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก visit_zone (99852be)
> แก้: NpcDropConfig + NpcDropService · ไม่ต้องแก้ CombatService

---

## บริบท

ปัจจุบัน `DropEntry` รองรับแค่ `itemId` (วัตถุดิบ)
ต้องการเพิ่ม **pet drop** — เมื่อ NPC ตาย มีโอกาสสุ่มได้ pet เข้า collection ผู้เล่น

**API ที่มีอยู่แล้ว:**
- `PetService.grantPet(player, petId)` → `(boolean, string)` — `ServerScriptService/Commerce/PetService`
- `PetConfig.Pets` — pet IDs ที่มี: `"slime_blue"`, `"fox_fire"`, `"dragon_mini"`
- `NpcDropService.grantDrops(player, npcId)` — เรียกจาก CombatService หลัง kill

---

## ไฟล์ที่ต้องแก้

| ไฟล์ | Action |
|------|--------|
| `NpcDropConfig.luau` | เพิ่ม `dropType` + `petId` ใน DropEntry type + เพิ่ม pet entries ใน NPC profiles |
| `NpcDropService.luau` | แก้ `grantDrops()` ให้ handle dropType="pet" → PetService.grantPet |

---

## 1. NpcDropConfig.luau — แก้ type + เพิ่ม pet entries

### แก้ DropEntry type

```lua
-- เดิม:
export type DropEntry = {
  itemId  : string,
  minQty  : number,
  maxQty  : number,
  chance  : number,
}

-- แก้เป็น:
export type DropEntry = {
  dropType: "item" | "pet",  -- เพิ่ม field นี้ (default "item" ถ้าไม่ระบุ)
  itemId  : string,          -- ใช้เมื่อ dropType == "item" หรือ dropType == nil
  petId   : string?,         -- ใช้เมื่อ dropType == "pet"
  minQty  : number,          -- qty สำหรับ item (pet ไม่ใช้ field นี้ ใส่ 1)
  maxQty  : number,
  chance  : number,
}
```

### เพิ่ม pet drop entries ใน NPC profiles

**NPC 2 (ทหารซอมบี้)** — เพิ่มใน `dropTable`:
```lua
{ dropType="pet", itemId="slime_blue", petId="slime_blue", minQty=1, maxQty=1, chance=0.02 },
-- 2% chance drop สไลม์ฟ้า (Common)
```

**NPC 3 (อัศวินมืด)** — เพิ่มใน `dropTable`:
```lua
{ dropType="pet", itemId="fox_fire", petId="fox_fire", minQty=1, maxQty=1, chance=0.008 },
-- 0.8% chance drop จิ้งจอกไฟ (Rare)
```

**NPC 5 (Boss)** — เพิ่มใน `dropTable`:
```lua
{ dropType="pet", itemId="slime_blue",  petId="slime_blue",  minQty=1, maxQty=1, chance=0.10 },
{ dropType="pet", itemId="fox_fire",    petId="fox_fire",    minQty=1, maxQty=1, chance=0.04 },
{ dropType="pet", itemId="dragon_mini", petId="dragon_mini", minQty=1, maxQty=1, chance=0.01 },
-- Boss: 10% slime, 4% fox, 1% dragon_mini (Legendary)
```

> **หมายเหตุ:** entries เดิม (StoneFragment/IronOre/MagicCrystal) ไม่ต้องแก้ — เพิ่มต่อท้าย dropTable เท่านั้น
> field `itemId` ใน pet entry ใส่ค่าเดียวกับ `petId` เพื่อให้ type ไม่มี nil error

---

## 2. NpcDropService.luau — แก้ grantDrops + rollDrops

### แก้ DropResult type (เพิ่ม dropType)

```lua
-- เดิม:
export type DropResult = {
  itemId : string,
  qty    : number,
}

-- แก้เป็น:
export type DropResult = {
  dropType: "item" | "pet",
  itemId  : string,
  qty     : number,
  petId   : string?,
}
```

### แก้ rollDrops() — handle dropType

```lua
function NpcDropService.rollDrops(npcId: number): { DropResult }
  local profile = getProfile(npcId)
  local results: { DropResult } = {}

  for _, entry in profile.dropTable do
    if math.random() <= entry.chance then
      local entryType = entry.dropType or "item"  -- backward compat
      if entryType == "pet" then
        table.insert(results, {
          dropType = "pet",
          itemId   = entry.petId or entry.itemId,
          qty      = 1,
          petId    = entry.petId,
        })
      else
        local qty = math.random(entry.minQty, entry.maxQty)
        table.insert(results, {
          dropType = "item",
          itemId   = entry.itemId,
          qty      = qty,
          petId    = nil,
        })
      end
    end
  end

  return results
end
```

### แก้ grantDrops() — เรียก PetService สำหรับ pet drop

```lua
-- เพิ่ม require PetService (lazy, เพื่อหลีก circular)
local function getPetService()
  return require(game:GetService("ServerScriptService").Commerce.PetService) :: any
end

function NpcDropService.grantDrops(player: Player, npcId: number): { DropResult }
  local drops = NpcDropService.rollDrops(npcId)
  if #drops == 0 then return drops end

  local itemStore  = getItemStore()
  local petService = getPetService()

  for _, drop in drops do
    if drop.dropType == "pet" and drop.petId then
      local ok, msg = petService.grantPet(player, drop.petId)
      if not ok then
        -- ถ้ามี pet อยู่แล้ว → ไม่ error แค่ skip
        if msg ~= "มี pet นี้แล้ว" then
          warn("[NpcDropService] grantPet failed:", msg)
        end
      end
    else
      -- item drop เดิม (รวม DoubleDrop + pet luck)
      itemStore.addItem(player.UserId, drop.itemId, drop.qty)
    end
  end

  -- แจ้ง client (ส่ง drops ทั้ง item + pet)
  local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("SocialRemotes") :: Folder?
  if remotes then
    local ev = remotes:FindFirstChild("ItemDropped") :: RemoteEvent?
    if ev then ev:FireClient(player, drops) end
  end

  return drops
end
```

---

## 3. DropNotifClient.client.luau — รองรับ pet drop notification

ค้นหาใน `DropNotifClient` ส่วนที่รับ `ItemDropped` event แล้ว **เพิ่ม** การแสดง pet drop:

```lua
-- เดิม (ใน OnClientEvent handler):
for _, drop in (drops :: { DropResult }) do
  local icon  = itemIcons[drop.itemId]  or "📦"
  local color = itemColors[drop.itemId] or Color3.fromRGB(200, 200, 200)
  spawnNotif(string.format("%s +%d %s", icon, drop.qty, drop.itemId), color)
end

-- แก้เป็น:
type DropResult = { dropType: string?, itemId: string, qty: number, petId: string? }
for _, drop in (drops :: { DropResult }) do
  if drop.dropType == "pet" then
    -- pet drop — แสดงพิเศษ
    spawnNotif("🐾 ได้รับสัตว์เลี้ยง: " .. (drop.petId or drop.itemId) .. "!",
      Color3.fromRGB(255, 180, 255))
  else
    local icon  = itemIcons[drop.itemId]  or "📦"
    local color = itemColors[drop.itemId] or Color3.fromRGB(200, 200, 200)
    spawnNotif(string.format("%s +%d %s", icon, drop.qty, drop.itemId), color)
  end
end
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| `dropType` optional | entries เดิมที่ไม่มี `dropType` → `entry.dropType or "item"` ใน rollDrops() ป้องกัน nil |
| pet ซ้ำ | `grantPet()` คืน `false, "มี pet นี้แล้ว"` → NpcDropService skip อย่างเงียบ |
| dragon_mini 1% บน Boss | หายากจงใจ — Legendary pet ไม่ควรหาง่าย |
| DoubleDrop event | ปัจจุบัน DoubleDrop ใช้กับ `qty` ของ item เท่านั้น → pet drop ไม่ได้รับ DoubleDrop (ถูกต้อง) |
| `itemId` ใน pet entry | ใส่ค่าเดียวกับ `petId` เพื่อให้ Luau strict ไม่ error (field ไม่เป็น nil) |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-petdrop.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/NpcDropConfig.luau \
  src/ServerScriptService/Combat/NpcDropService.luau \
  src/StarterPlayer/StarterPlayerScripts/DropNotifClient.client.luau
```

## ทดสอบใน Studio (Server console)

```lua
-- ทดสอบ rollDrops บน Boss (NPC 5) หลาย ๆ ครั้ง
local DS = require(game.ServerScriptService.Combat.NpcDropService)
for i = 1, 20 do
  local drops = DS.rollDrops(5)
  for _, d in drops do
    if d.dropType == "pet" then
      print("🐾 PET DROP:", d.petId)
    end
  end
end

-- ทดสอบ grantDrops จริง
local p = game.Players:GetPlayers()[1]
DS.grantDrops(p, 5)
-- ดู PetStore ว่าได้ pet หรือยัง
local PS = require(game.ServerScriptService.Commerce.PetService)
print(PS.getCollection(p))
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Pet): pet drop from NPC kill

- NpcDropConfig: +dropType field (item|pet), +petId field in DropEntry
  NPC2(zombie)=2% slime, NPC3(knight)=0.8% fox, NPC5(boss)=10%/4%/1%
- NpcDropService: rollDrops handles dropType=pet, grantDrops calls
  PetService.grantPet for pet drops (skip if already owned)
- DropNotifClient: 🐾 special notification for pet drops"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- rollDrops(5) ×20 — ได้ pet กี่ครั้ง และ petId อะไร
