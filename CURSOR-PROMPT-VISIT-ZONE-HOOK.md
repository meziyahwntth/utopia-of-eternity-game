# CURSOR PROMPT — visit_zone Quest Hook
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Bounty Escrow (818edc8)
> งาน: ปิดช่องว่าง visit_zone objective ใน QuestSystem

---

## บริบท

`QuestConfig` มี objective `"visit_zone"` แต่ไม่เคยมี hook เรียก `QuestService.recordProgress(player, "visit_zone", 1)`
ปัจจุบัน progress=0 ตลอด

**สิ่งที่รู้:**
- Eternity City ลอยที่ `SkyAltitude = 2000` (Y พื้นจริง ≈ 2004)
- landmark centers จาก `EternityTerrainSetup.getLandmarkPosition()` — เป็น Vector3 ก่อน lift
- หลัง `SkyCityLift.apply(model, 2000)` → Y จริง = original Y + 2000
- MarinaCenter default = `Vector3.new(180, 0, -80)` → หลัง lift Y ≈ 2004, X=180, Z=-80
- AuroraOrigin default = `Vector3.new(0, 0, -120)` → Y ≈ 2004, X=0, Z=-120
- SkyRailOrigin default = `Vector3.new(0, 0, 40)` → Y ≈ 2004, X=0, Z=40
- TwilightOrigin (Canal) default = `Vector3.new(-100, 0, 80)` → Y ≈ 2004, X=-100, Z=80
- ตำแหน่งจริงอาจต่างจาก default ถ้า Landmarks DataStore บันทึกค่าอื่น — ใช้ **แค่ radius proximity** ปลอดภัยกว่า bounding box

---

## ไฟล์ที่ต้องสร้าง/แก้

| ไฟล์ | Action | Path |
|------|--------|------|
| `ZoneConfig.luau` | สร้างใหม่ | `ReplicatedStorage/Modules/` |
| `ZoneDetectorClient.client.luau` | สร้างใหม่ | `StarterPlayerScripts/` |
| `QuestHandlers.server.luau` | แก้: เพิ่ม ZoneVisited remote handler | `ServerScriptService/Progression/` |

---

## 1. ZoneConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/ZoneConfig.luau
-- World Y offset = SkyAltitude(2000) + localFloor(4) = 2004

export type ZoneEntry = {
  id      : string,         -- ตรงกับ questConfig visit_zone targetZoneId
  nameTH  : string,
  center  : Vector3,        -- ตำแหน่งกลางหลัง lift (X, Y≈2004, Z)
  radius  : number,         -- studs ในแนวราบ (XZ-plane)
}

local SKY_Y = 2004          -- Y พื้น Eternity City หลัง lift

return {
  Zones = {
    {
      id="marina", nameTH="Marina District",
      center=Vector3.new(180, SKY_Y, -80),
      radius=120,
    },
    {
      id="aurora", nameTH="Aurora Spire",
      center=Vector3.new(0, SKY_Y, -120),
      radius=100,
    },
    {
      id="canal", nameTH="Canal Promenade",
      center=Vector3.new(-100, SKY_Y, 80),
      radius=120,
    },
    {
      id="skyrail", nameTH="Sky Rail Plaza",
      center=Vector3.new(0, SKY_Y, 40),
      radius=100,
    },
  } :: { ZoneEntry },
  -- check interval (วินาที) — ไม่ต้อง check ทุก frame
  CHECK_INTERVAL = 2.0,
}
```

---

## 2. ZoneDetectorClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/ZoneDetectorClient.client.luau
-- ตรวจว่า player เข้า zone ไหม (XZ proximity) แล้วแจ้ง server

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ZoneConfig = require(ReplicatedStorage.Modules.ZoneConfig)

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

-- ส่ง server ผ่าน RemoteEvent (server validate ซ้ำ)
local zoneVisitedEv: RemoteEvent? = nil
task.spawn(function()
  zoneVisitedEv = remotes:WaitForChild("ZoneVisited", 10) :: RemoteEvent?
end)

-- ติดตาม zones ที่เคยเข้าแล้วใน session นี้ (ป้องกัน spam)
local visitedThisSession: { [string]: boolean } = {}

local timeSinceCheck = 0.0

RunService.Heartbeat:Connect(function(dt)
  timeSinceCheck += dt
  if timeSinceCheck < ZoneConfig.CHECK_INTERVAL then return end
  timeSinceCheck = 0.0

  local char = localPlayer.Character
  if not char then return end
  local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return end

  local playerPos = hrp.Position

  for _, zone in ZoneConfig.Zones do
    if visitedThisSession[zone.id] then continue end

    -- XZ-plane distance เท่านั้น (ไม่นับ Y เพราะ building มีหลายชั้น)
    local dx = playerPos.X - zone.center.X
    local dz = playerPos.Z - zone.center.Z
    local distXZ = math.sqrt(dx*dx + dz*dz)

    if distXZ <= zone.radius then
      visitedThisSession[zone.id] = true
      if zoneVisitedEv then
        zoneVisitedEv:FireServer(zone.id)
      end
    end
  end
end)

-- reset เมื่อ respawn (ให้เก็บ quest progress ใหม่ได้ถ้าต้องการ)
-- ไม่ reset visitedThisSession — quest "visit_zone" ควรทำได้ครั้งเดียวต่อ session
```

---

## 3. QuestHandlers.server.luau — เพิ่ม ZoneVisited handler

ค้นหาในไฟล์ `QuestHandlers.server.luau` แล้วเพิ่มหลังบรรทัด `ensure("RemoteEvent", "QuestCompleted")`:

```lua
ensure("RemoteEvent", "ZoneVisited")
```

และเพิ่ม handler ต่อท้ายไฟล์ (ก่อน `return` ถ้ามี):

```lua
-- hook visit_zone
local zoneVisitedEv2 = remotes:WaitForChild("ZoneVisited") :: RemoteEvent
local ZoneConfig2 = require(ReplicatedStorage.Modules.ZoneConfig)

zoneVisitedEv2.OnServerEvent:Connect(function(player: Player, zoneId: any)
  -- validate: zoneId ต้องเป็น string และอยู่ใน ZoneConfig
  if typeof(zoneId) ~= "string" then return end
  local valid = false
  for _, zone in ZoneConfig2.Zones do
    if zone.id == zoneId then valid = true; break end
  end
  if not valid then return end

  -- server-side proximity check (ป้องกัน client โกง)
  local char = player.Character
  local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return end
  local playerPos = hrp.Position

  local inZone = false
  for _, zone in ZoneConfig2.Zones do
    if zone.id == zoneId then
      local dx = playerPos.X - zone.center.X
      local dz = playerPos.Z - zone.center.Z
      if math.sqrt(dx*dx + dz*dz) <= zone.radius + 20 then  -- +20 studs tolerance
        inZone = true
      end
      break
    end
  end
  if not inZone then
    warn("[ZoneDetector] player", player.Name, "claimed zone", zoneId, "but is out of range")
    return
  end

  QuestService.recordProgress(player, "visit_zone", 1)
end)
```

> **หมายเหตุ:** ต้อง require `ZoneConfig` ด้านบนไฟล์ด้วย:
> ```lua
> local ReplicatedStorage = game:GetService("ReplicatedStorage")
> -- เพิ่มบรรทัดนี้หลัง requires ที่มีอยู่:
> -- local ZoneConfig2 = require(ReplicatedStorage.Modules.ZoneConfig)
> -- (ตั้งชื่อ ZoneConfig2 เพื่อไม่ชนกับ variable ที่อาจมีอยู่)
> ```

---

## 4. QuestConfig.luau — เพิ่ม targetZoneId ให้ quest visit_marina

แก้ไขเพิ่ม `targetZoneId` ใน template `visit_marina`:

```lua
-- เดิม:
{
  id="visit_marina", nameTH="นักท่องเที่ยว",
  descTH="ไปที่ Marina District",
  objective="visit_zone", targetCount=1,
  reward={ rewardType="xp", amount=200 },
},
-- แก้เป็น:
{
  id="visit_marina", nameTH="นักท่องเที่ยว",
  descTH="ไปที่ Marina District",
  objective="visit_zone", targetCount=1,
  targetZoneId="marina",   -- เพิ่มบรรทัดนี้
  reward={ rewardType="xp", amount=200 },
},
```

และเพิ่ม field `targetZoneId: string?` ใน `QuestTemplate` type:

```lua
export type QuestTemplate = {
  id         : string,
  nameTH     : string,
  descTH     : string,
  objective  : QuestObjective,
  targetCount: number,
  targetZoneId: string?,   -- เพิ่มบรรทัดนี้
  reward     : QuestReward,
}
```

---

## 5. default.project.json — เพิ่ม entries

```json
"ZoneConfig":          { "$path": "src/ReplicatedStorage/Modules/ZoneConfig.luau" },
"ZoneDetectorClient":  { "$path": "src/StarterPlayer/StarterPlayerScripts/ZoneDetectorClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| ตำแหน่งอาจคลาดเคลื่อน | ถ้า EternityTerrainSetup บันทึก override ไว้ใน DataStore → ตำแหน่งจริงอาจต่างจาก default ใน ZoneConfig — ปรับ radius ใหญ่ขึ้น (120 studs) เพื่อรองรับ |
| XZ-only distance | ใช้ XZ เท่านั้น ไม่นับ Y เพราะ building มีหลายชั้น ผู้เล่นบนชั้น 2 ก็ควรนับว่าอยู่ใน zone |
| server tolerance +20 | ป้องกัน false-reject จาก network latency ขณะ player เดินออกจาก zone ก่อน packet ถึง server |
| `visitedThisSession` | reset เมื่อ script reload (rejoin) — ให้ quest ทำได้ใหม่ทุก session อย่างถูกต้อง |
| `QuestTemplate.targetZoneId` | optional field — quest อื่นที่ไม่ใช่ visit_zone ไม่ต้องกรอก |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-zone.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/ZoneConfig.luau \
  src/ReplicatedStorage/Modules/QuestConfig.luau \
  src/ServerScriptService/Progression/QuestHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/ZoneDetectorClient.client.luau
```

## ทดสอบใน Studio

1. เปิด Studio → Play
2. เดินไปที่พื้นที่ Marina (X≈180, Z≈-80)
3. รอ 2 วิ (CHECK_INTERVAL)
4. Server console:
```lua
local QS = require(game.ServerScriptService.Progression.QuestService)
local p = game.Players:GetPlayers()[1]
-- ถ้ามี quest visit_marina → ดู progress
for _, q in QS.getQuests(p) do
  if q.questId == "visit_marina" then print(q.progress) end
end
-- ควรได้ 1
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Quest): visit_zone hook via ZoneDetectorClient

- ZoneConfig: 4 zones (marina/aurora/canal/skyrail) with XZ radius
- ZoneDetectorClient: Heartbeat proximity check every 2s, fires ZoneVisited RE
- QuestHandlers: ZoneVisited handler with server-side validation + tolerance
- QuestConfig: +targetZoneId field in QuestTemplate type + visit_marina zone"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- ทดสอบ: เดินเข้า zone แล้ว progress เพิ่มไหม
