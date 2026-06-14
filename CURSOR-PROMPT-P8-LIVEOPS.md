# CURSOR PROMPT — P8 Live-ops (Event Calendar + Emote + Season Cosmetic)
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `c3b34c2` (P7 Camera/UX done)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §6 Roadmap P8 + §F Engagement

---

## บริบท

เกมมีระบบ Season/LoyKrathong อยู่แล้วใน `DeathValley/` — P8 ขยายให้ครอบคลุม:
1. **Event Calendar** — schedule ประกาศ + buff events (Double Drop, Double XP)
2. **Emote System** — animation emote สั้น (wave/dance/sit/laugh) + ปุ่ม HUD
3. **Season Cosmetic** — limited-time item pool เปลี่ยนรายซีซัน

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `EventCalendarConfig.luau` | ตาราง events ทั้งปี (วันที่, ชื่อ, buff type) | `ReplicatedStorage/Modules/` |
| `EventCalendarService.luau` | ตรวจ date → activate buff → broadcast | `ServerScriptService/LiveOps/` |
| `EmoteConfig.luau` | รายการ emote (id, name, animationId) | `ReplicatedStorage/Modules/` |
| `EmoteService.luau` | server validate + play animation | `ServerScriptService/Social/` |
| `EmoteClient.client.luau` | Emote wheel UI (4 slots) + keybind | `StarterPlayerScripts/` |
| `SeasonConfig.luau` | ซีซันปัจจุบัน + limited cosmetic pool | `ReplicatedStorage/Modules/` |
| `SeasonService.luau` | ตรวจซีซัน → ปลด/ล็อก cosmetic pool | `ServerScriptService/LiveOps/` |

---

## 1. EventCalendarConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/EventCalendarConfig.luau

export type EventEntry = {
  id         : string,
  nameTH     : string,
  startMonth : number,  -- 1–12
  startDay   : number,
  endMonth   : number,
  endDay     : number,
  buffType   : "DoubleExp" | "DoubleDrop" | "DoubleCurrency" | "None",
  buffValue  : number,  -- multiplier (เช่น 2 = ×2)
  bannerColor: Color3,
}

return {
  Events = {
    {
      id="songkran", nameTH="สงกรานต์ 🎉",
      startMonth=4, startDay=13, endMonth=4, endDay=15,
      buffType="DoubleExp", buffValue=2,
      bannerColor=Color3.fromRGB(80,200,255),
    },
    {
      id="loykrathong", nameTH="ลอยกระทง 🪔",
      startMonth=11, startDay=15, endMonth=11, endDay=16,
      buffType="DoubleDrop", buffValue=2,
      bannerColor=Color3.fromRGB(255,180,50),
    },
    {
      id="newyear", nameTH="ปีใหม่ 🎆",
      startMonth=12, startDay=31, endMonth=1, endDay=2,
      buffType="DoubleCurrency", buffValue=2,
      bannerColor=Color3.fromRGB(200,80,255),
    },
    {
      id="weekend", nameTH="Weekend Boost ⚡",
      startMonth=0, startDay=0, endMonth=0, endDay=0,  -- ตรวจแยก (เสาร์-อาทิตย์)
      buffType="DoubleExp", buffValue=1.5,
      bannerColor=Color3.fromRGB(100,255,150),
    },
  } :: { EventEntry },
}
```

---

## 2. EventCalendarService.luau

```lua
--!strict
-- ServerScriptService/LiveOps/EventCalendarService.luau

local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local EventCalendarConfig  = require(ReplicatedStorage.Modules.EventCalendarConfig)

type ActiveBuff = { buffType: string, value: number, eventName: string }
local currentBuffs: { ActiveBuff } = {}
local remotes: Folder

local EventCalendarService = {}

local function isDateInRange(month: number, day: number,
    sm: number, sd: number, em: number, ed: number): boolean
  if sm == 0 then return false end  -- ข้ามกรณี special (weekend ตรวจแยก)
  local startN = sm * 100 + sd
  local endN   = em * 100 + ed
  local nowN   = month * 100 + day
  if startN <= endN then
    return nowN >= startN and nowN <= endN
  else
    -- ข้ามปี (เช่น ธ.ค.-ม.ค.)
    return nowN >= startN or nowN <= endN
  end
end

local function isWeekend(): boolean
  -- os.date("%w") คือ 0=Sun, 6=Sat
  local wday = tonumber(os.date("%w")) or 0
  return wday == 0 or wday == 6
end

function EventCalendarService.checkAndApply()
  local month = tonumber(os.date("%m")) or 0
  local day   = tonumber(os.date("%d")) or 0
  currentBuffs = {}

  for _, event in EventCalendarConfig.Events do
    local active = false
    if event.id == "weekend" then
      active = isWeekend()
    else
      active = isDateInRange(month, day,
        event.startMonth, event.startDay,
        event.endMonth,   event.endDay)
    end

    if active then
      table.insert(currentBuffs, {
        buffType  = event.buffType,
        value     = event.buffValue,
        eventName = event.nameTH,
      })
    end
  end

  -- broadcast ไปยัง client ทุกคน
  if remotes then
    local ev = remotes:FindFirstChild("ActiveEventsUpdate") :: RemoteEvent?
    if ev then ev:FireAllClients(currentBuffs) end
  end

  print(string.format("[EventCalendar] %d active buffs", #currentBuffs))
end

-- ดึง multiplier สำหรับประเภทนั้น (เรียกจาก CombatService, CurrencyService ฯลฯ)
function EventCalendarService.getMultiplier(buffType: string): number
  local mult = 1.0
  for _, b in currentBuffs do
    if b.buffType == buffType then
      mult = mult * b.value
    end
  end
  return mult
end

function EventCalendarService.init(remotesFolder: Folder)
  remotes = remotesFolder
  local function ensure(cls: string, name: string)
    if not remotes:FindFirstChild(name) then
      local inst = Instance.new(cls); inst.Name = name; inst.Parent = remotes
    end
  end
  ensure("RemoteEvent", "ActiveEventsUpdate")

  -- ตรวจทุกชั่วโมง
  EventCalendarService.checkAndApply()
  local function scheduleNext()
    task.delay(3600, function()
      EventCalendarService.checkAndApply()
      scheduleNext()
    end)
  end
  scheduleNext()
end

return EventCalendarService
```

---

## 3. EmoteConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/EmoteConfig.luau
-- Animation IDs ต้องเป็น Roblox Animation asset ที่ถูกต้อง
-- ใช้ default Roblox animation IDs (ไม่มีลิขสิทธิ์ปัญหา)

export type EmoteEntry = {
  id          : string,
  nameTH      : string,
  icon        : string,        -- emoji สำหรับปุ่ม
  animationId : string,        -- rbxassetid://...
  looped      : boolean,
  durationSecs: number,        -- 0 = loop จนกด stop
}

return {
  Emotes = {
    { id="wave",  nameTH="โบกมือ",  icon="👋", animationId="rbxassetid://507770239", looped=false, durationSecs=3 },
    { id="dance", nameTH="เต้น",    icon="💃", animationId="rbxassetid://507771019", looped=true,  durationSecs=0 },
    { id="laugh", nameTH="หัวเราะ", icon="😂", animationId="rbxassetid://507770818", looped=false, durationSecs=3 },
    { id="sit",   nameTH="นั่ง",    icon="🪑", animationId="rbxassetid://507770454", looped=true,  durationSecs=0 },
  } :: { EmoteEntry },
}
```

---

## 4. EmoteService.luau (Server — validate + trigger)

```lua
--!strict
-- ServerScriptService/Social/EmoteService.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EmoteConfig       = require(ReplicatedStorage.Modules.EmoteConfig)

local EmoteService = {}
-- rate limit: cooldown 2 วินาที
local lastEmote: { [number]: number } = {}
local COOLDOWN = 2

local function findEmote(id: string): EmoteConfig.EmoteEntry?
  for _, e in EmoteConfig.Emotes do
    if e.id == id then return e end
  end
  return nil
end

function EmoteService.playEmote(player: Player, emoteId: string): (boolean, string)
  local now = os.time()
  local last = lastEmote[player.UserId] or 0
  if now - last < COOLDOWN then
    return false, string.format("รอ %d วินาที", COOLDOWN - (now - last))
  end

  local emote = findEmote(emoteId)
  if not emote then return false, "ไม่พบ emote" end

  lastEmote[player.UserId] = now

  -- broadcast ให้ client ทุกคนเล่น animation
  local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
  if remotes then
    local ev = remotes:FindFirstChild("EmotePlayed") :: RemoteEvent?
    if ev then
      ev:FireAllClients(player.UserId, emoteId, emote.animationId,
        emote.looped, emote.durationSecs)
    end
  end
  return true, emote.nameTH
end

function EmoteService.stopEmote(player: Player)
  local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
  if remotes then
    local ev = remotes:FindFirstChild("EmoteStopped") :: RemoteEvent?
    if ev then ev:FireAllClients(player.UserId) end
  end
end

return EmoteService
```

---

## 5. EmoteClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/EmoteClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EmoteConfig       = require(ReplicatedStorage.Modules.EmoteConfig)

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local emotePlayed  = remotes:WaitForChild("EmotePlayed")  :: RemoteEvent
local emoteStopped = remotes:WaitForChild("EmoteStopped") :: RemoteEvent
local playEmoteRF  = remotes:WaitForChild("PlayEmote")    :: RemoteFunction
local stopEmoteRF  = remotes:WaitForChild("StopEmote")    :: RemoteFunction

-- Emote Wheel UI (bottom-left, Scale-based)
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "EmoteHUD"
screenGui.ResetOnSpawn  = false
screenGui.Parent        = localPlayer.PlayerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size     = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.01, 0.88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextScaled = true
toggleBtn.Text = "😄"
toggleBtn.Parent = screenGui

local wheel = Instance.new("Frame")
wheel.Size    = UDim2.fromScale(0.22, 0.25)
wheel.Position= UDim2.fromScale(0.01, 0.62)
wheel.BackgroundTransparency = 1
wheel.Visible = false
wheel.Parent  = screenGui

local emotes = EmoteConfig.Emotes
for i, emote in emotes do
  local btn = Instance.new("TextButton")
  btn.Size     = UDim2.fromScale(0.45, 0.45)
  btn.Position = UDim2.fromScale(
    ((i-1) % 2) * 0.52,
    math.floor((i-1) / 2) * 0.52
  )
  btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
  btn.TextScaled = true
  btn.Text = emote.icon .. " " .. emote.nameTH
  btn.Parent = wheel

  btn.MouseButton1Click:Connect(function()
    wheel.Visible = false
    playEmoteRF:InvokeServer(emote.id)
  end)
end

-- ปุ่ม Stop (แสดงขณะ loop)
local stopBtn = Instance.new("TextButton")
stopBtn.Size     = UDim2.fromScale(0.07, 0.05)
stopBtn.Position = UDim2.fromScale(0.09, 0.88)
stopBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
stopBtn.TextScaled = true
stopBtn.Text = "⛔"
stopBtn.Visible = false
stopBtn.Parent = screenGui
stopBtn.MouseButton1Click:Connect(function()
  stopEmoteRF:InvokeServer()
  stopBtn.Visible = false
end)

toggleBtn.MouseButton1Click:Connect(function()
  wheel.Visible = not wheel.Visible
end)

-- เล่น animation ของผู้เล่นคนอื่น
local activeAnims: { [number]: AnimationTrack? } = {}

local function getAnimator(character: Model): Animator?
  local hum = character:FindFirstChildOfClass("Humanoid")
  if not hum then return nil end
  return hum:FindFirstChildOfClass("Animator")
end

emotePlayed:Connect(function(userId, _emoteId, animId, looped, duration)
  local uid = userId :: number
  local target = Players:GetPlayerByUserId(uid)
  if not target then return end
  local char = target.Character
  if not char then return end

  local animator = getAnimator(char)
  if not animator then return end

  -- หยุด animation เดิม
  local old = activeAnims[uid]
  if old then old:Stop() end

  local anim = Instance.new("Animation")
  anim.AnimationId = animId :: string
  local track = animator:LoadAnimation(anim)
  track.Looped = looped :: boolean
  track:Play()
  activeAnims[uid] = track

  -- ถ้าไม่ loop → auto-clear
  if not (looped :: boolean) and (duration :: number) > 0 then
    task.delay(duration :: number, function()
      if activeAnims[uid] == track then
        track:Stop()
        activeAnims[uid] = nil
      end
    end)
  end

  -- แสดงปุ่ม stop ถ้าเป็นตัวเอง
  if uid == localPlayer.UserId and (looped :: boolean) then
    stopBtn.Visible = true
  end
end)

emoteStopped:Connect(function(userId)
  local uid = userId :: number
  local track = activeAnims[uid]
  if track then track:Stop(); activeAnims[uid] = nil end
  if uid == localPlayer.UserId then stopBtn.Visible = false end
end)
```

---

## 6. SeasonConfig.luau + SeasonService.luau (โครงสร้าง)

```lua
--!strict
-- ReplicatedStorage/Modules/SeasonConfig.luau

export type Season = {
  id          : string,
  nameTH      : string,
  startMonth  : number,
  endMonth    : number,
  cosmeticPool: { string },  -- item IDs จาก ItemTierConfig
  themeColor  : Color3,
}

return {
  Seasons = {
    { id="summer",  nameTH="ฤดูร้อน ☀️",  startMonth=3,  endMonth=5,
      cosmeticPool={"SummerHat","BeachBoard","SunglassesSet"},
      themeColor=Color3.fromRGB(255,220,80) },
    { id="monsoon", nameTH="ฤดูฝน 🌧️",    startMonth=6,  endMonth=9,
      cosmeticPool={"RaincoatBlue","UmbrellaRed","CloudAura"},
      themeColor=Color3.fromRGB(80,150,255) },
    { id="winter",  nameTH="ฤดูหนาว ❄️",   startMonth=12, endMonth=2,
      cosmeticPool={"SantaHat","SnowboardWhite","IceAura"},
      themeColor=Color3.fromRGB(200,230,255) },
  } :: { Season },
  CurrentSeasonId = "summer",  -- อัปเดต manual หรือ auto ตาม date
}
```

```lua
--!strict
-- ServerScriptService/LiveOps/SeasonService.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeasonConfig      = require(ReplicatedStorage.Modules.SeasonConfig)

local SeasonService = {}

function SeasonService.getCurrentSeason(): SeasonConfig.Season?
  local month = tonumber(os.date("%m")) or 0
  for _, s in SeasonConfig.Seasons do
    if s.startMonth <= s.endMonth then
      if month >= s.startMonth and month <= s.endMonth then return s end
    else  -- ข้ามปี
      if month >= s.startMonth or month <= s.endMonth then return s end
    end
  end
  return nil
end

function SeasonService.isSeasonalItem(itemId: string): boolean
  local season = SeasonService.getCurrentSeason()
  if not season then return false end
  for _, id in season.cosmeticPool do
    if id == itemId then return true end
  end
  return false
end

return SeasonService
```

---

## 7. Wire Handlers — เพิ่มใน SocialRemoteSetup และ LiveOps bootstrap

เพิ่มใน `SocialRemoteSetup.server.luau`:
```lua
-- Emote remotes (P8)
ensure("RemoteFunction", "PlayEmote")
ensure("RemoteFunction", "StopEmote")
ensure("RemoteEvent",   "EmotePlayed")
ensure("RemoteEvent",   "EmoteStopped")
-- Event Calendar
ensure("RemoteEvent",   "ActiveEventsUpdate")
```

สร้าง `ServerScriptService/LiveOps/LiveOpsBootstrap.server.luau`:
```lua
--!strict
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local EventCalendarService = require(script.Parent.EventCalendarService)
local SeasonService        = require(script.Parent.SeasonService)
local EmoteService         = require(script.Parent.Parent.Social.EmoteService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
EventCalendarService.init(remotes)

-- Wire Emote remotes
local playEmoteRF  = remotes:WaitForChild("PlayEmote")  :: RemoteFunction
local stopEmoteRF  = remotes:WaitForChild("StopEmote")  :: RemoteFunction
playEmoteRF.OnServerInvoke  = function(player, emoteId) return EmoteService.playEmote(player, emoteId :: string) end
stopEmoteRF.OnServerInvoke  = function(player) EmoteService.stopEmote(player); return true end

local season = SeasonService.getCurrentSeason()
print(string.format("[LiveOps] Season: %s", season and season.nameTH or "none"))
```

---

## 8. default.project.json — เพิ่ม entries

```json
"EventCalendarConfig": { "$path": "src/ReplicatedStorage/Modules/EventCalendarConfig.luau" },
"EmoteConfig":         { "$path": "src/ReplicatedStorage/Modules/EmoteConfig.luau" },
"SeasonConfig":        { "$path": "src/ReplicatedStorage/Modules/SeasonConfig.luau" },
"EmoteService":        { "$path": "src/ServerScriptService/Social/EmoteService.luau" },
"EventCalendarService":{ "$path": "src/ServerScriptService/LiveOps/EventCalendarService.luau" },
"SeasonService":       { "$path": "src/ServerScriptService/LiveOps/SeasonService.luau" },
"LiveOpsBootstrap":    { "$path": "src/ServerScriptService/LiveOps/LiveOpsBootstrap.server.luau" },
"EmoteClient":         { "$path": "src/StarterPlayer/StarterPlayerScripts/EmoteClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | วิธีแก้ |
|---------|---------|
| Animation IDs ใน EmoteConfig | ใช้ Roblox default animations (507770239 ฯลฯ) — ถ้าใช้ custom asset ต้อง upload ก่อน |
| `EventCalendarService.getMultiplier` | เรียกจาก `CurrencyService.addCredits` / `CombatService.processAttack` เพื่อ apply buff |
| `SeasonConfig.CurrentSeasonId` | อัปเดต manual หรือเพิ่ม auto-detect จาก `getCurrentSeason()` |
| Pet/Companion | defer ไป P8+ (scope ใหญ่กว่า — ต้องมี PetService + animation + DataStore) |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p8.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/EventCalendarConfig.luau \
  src/ReplicatedStorage/Modules/EmoteConfig.luau \
  src/ReplicatedStorage/Modules/SeasonConfig.luau \
  src/ServerScriptService/Social/EmoteService.luau \
  src/ServerScriptService/LiveOps/EventCalendarService.luau \
  src/ServerScriptService/LiveOps/SeasonService.luau \
  src/ServerScriptService/LiveOps/LiveOpsBootstrap.server.luau \
  src/StarterPlayer/StarterPlayerScripts/EmoteClient.client.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P8): Live-ops — Event Calendar + Emote System + Season Cosmetic

- EventCalendarConfig: Songkran/LoyKrathong/NewYear/Weekend buffs
- EventCalendarService: hourly check, getMultiplier() for Combat/Currency
- EmoteConfig: 4 emotes (wave/dance/laugh/sit) with Roblox anim IDs
- EmoteService: server validate + broadcast (2s cooldown)
- EmoteClient: 4-slot wheel UI + stop button, Scale-based
- SeasonConfig: 3 seasons (summer/monsoon/winter) + cosmetic pool
- SeasonService: getCurrentSeason() + isSeasonalItem()
- LiveOpsBootstrap: wire all P8 services on server start"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
