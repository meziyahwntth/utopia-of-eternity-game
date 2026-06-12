--!strict
--[[
	AudioSettingsClient (P3-A) — ปิด/เปิด เพลง · SFX · แจ้งเตือน แยกกัน (เพื่อสมาธิ)
	- สร้าง SoundGroup (Music/SFX/Notify) + จัดเสียงที่ยังไม่มีกลุ่มเข้ากลุ่ม (looping→Music อื่นๆ→SFX)
	- voice ไม่ถูกปิดที่นี่ (ผู้เล่นยังได้ยินเสียงคุยเสมอ)
	- โหลด/บันทึกค่าผ่าน server (DataStore)
]]
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local audioGet = remotes:WaitForChild("AudioGet") :: RemoteFunction
local audioSet = remotes:WaitForChild("AudioSet") :: RemoteEvent

local function ensureGroup(name: string): SoundGroup
	local g = SoundService:FindFirstChild(name)
	if g and g:IsA("SoundGroup") then
		return g
	end
	local ng = Instance.new("SoundGroup")
	ng.Name = name
	ng.Parent = SoundService
	return ng
end

local musicG = ensureGroup("Music")
local sfxG = ensureGroup("SFX")
local notifyG = ensureGroup("Notify")

-- retrofit เสียงที่ยังไม่มีกลุ่ม
local function classify(sound: Sound)
	if sound.SoundGroup ~= nil then
		return
	end
	if sound.Looped then
		sound.SoundGroup = musicG
	else
		sound.SoundGroup = sfxG
	end
end
for _, d in game:GetDescendants() do
	if d:IsA("Sound") then
		classify(d)
	end
end
game.DescendantAdded:Connect(function(d)
	if d:IsA("Sound") then
		task.defer(classify, d)
	end
end)

local prefs: { [string]: any } = { music = true, sfx = true, notify = true, masterVolume = 1 }

local function apply()
	local m = prefs.masterVolume
	musicG.Volume = if prefs.music then m else 0
	sfxG.Volume = if prefs.sfx then m else 0
	notifyG.Volume = if prefs.notify then m else 0
end

-- โหลดค่า
task.spawn(function()
	local ok, data = pcall(function()
		return audioGet:InvokeServer()
	end)
	if ok and typeof(data) == "table" then
		prefs.music = data.music ~= false
		prefs.sfx = data.sfx ~= false
		prefs.notify = data.notify ~= false
		prefs.masterVolume = if typeof(data.masterVolume) == "number" then data.masterVolume else 1
	end
	apply()
end)

local function save()
	pcall(function()
		audioSet:FireServer({
			music = prefs.music,
			sfx = prefs.sfx,
			notify = prefs.notify,
			masterVolume = prefs.masterVolume,
		})
	end)
end

----------------------------------------------------------------
-- UI: ปุ่ม 🔊 เปิดแผง · 3 toggle (เพลง/SFX/แจ้งเตือน)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AudioSettingsGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenButton"
openBtn.Size = UDim2.fromOffset(44, 44)
openBtn.Position = UDim2.new(1, -56, 0, 120)
openBtn.AnchorPoint = Vector2.new(0, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
openBtn.BackgroundTransparency = 0.2
openBtn.Text = "🔊"
openBtn.TextScaled = true
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0, 10)
oc.Parent = openBtn

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 180)
panel.Position = UDim2.new(1, -56, 0, 172)
panel.AnchorPoint = Vector2.new(1, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 12)
pc.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "ตั้งค่าเสียง"
title.TextColor3 = Color3.fromRGB(255, 215, 120)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

local function makeToggle(labelText: string, key: string)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.Parent = panel

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.62, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(235, 240, 250)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextScaled = true
	lbl.Font = Enum.Font.Gotham
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.34, 0, 0.82, 0)
	btn.Position = UDim2.new(0.66, 0, 0.09, 0)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Parent = row
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = btn

	local function refresh()
		local on = prefs[key]
		btn.Text = if on then "เปิด" else "ปิด"
		btn.BackgroundColor3 = if on then Color3.fromRGB(60, 170, 110) else Color3.fromRGB(120, 60, 60)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	refresh()

	btn.Activated:Connect(function()
		prefs[key] = not prefs[key]
		apply()
		save()
		refresh()
	end)
end

makeToggle("เพลง (Music)", "music")
makeToggle("เสียงเกม (SFX)", "sfx")
makeToggle("แจ้งเตือน (Notify)", "notify")

openBtn.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
