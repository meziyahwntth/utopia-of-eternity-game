--!strict
--[[
	RaceSelectClient (Race system) — UI เลือกเผ่าตอนสร้างตัว (mobile-first)
	- เปิดอัตโนมัติเมื่อผู้เล่นยังไม่มีเผ่า (ครั้งแรก)
	- ปุ่ม 🧬 มุมซ้ายเปิดได้ตลอด (re-select; v1 ฟรี+debounce)
	- แสดง 4 เผ่า + lore/affinity/stat/เมืองบ้านเกิด → ยืนยัน → RequestRaceSelect
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RaceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RaceConfig"))

local remotes = ReplicatedStorage:WaitForChild("RaceRemotes")
local requestSelect = remotes:WaitForChild("RequestRaceSelect") :: RemoteFunction
local getMyRace = remotes:WaitForChild("GetMyRace") :: RemoteFunction

local currentRaceId: string? = nil

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RaceSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 41
gui.Enabled = false
gui.Parent = playerGui

-- ปุ่มเปิดเมนู (🧬)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenRace"
openBtn.AnchorPoint = Vector2.new(0, 0)
openBtn.Position = UDim2.new(0, 12, 0.37, 0)
openBtn.Size = UDim2.fromScale(0.07, 0.05)
openBtn.BackgroundColor3 = Color3.fromRGB(34, 50, 60)
openBtn.BackgroundTransparency = 0.2
openBtn.Text = "🧬"
openBtn.TextScaled = true
openBtn.Parent = playerGui
do
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = openBtn
	local sz = Instance.new("UISizeConstraint")
	sz.MinSize = Vector2.new(40, 40)
	sz.MaxSize = Vector2.new(72, 72)
	sz.Parent = openBtn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = openBtn
end

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.4
dim.BorderSizePixel = 0
dim.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.82, 0.74)
panel.BackgroundColor3 = Color3.fromRGB(20, 26, 34)
panel.BorderSizePixel = 0
panel.Parent = dim
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.04, 0)
	c.Parent = panel
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1.35
	ar.Parent = panel
end

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(235, 245, 255)
title.Text = "เลือกเผ่า (Race)"
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.fromScale(0.98, 0.02)
closeBtn.Size = UDim2.fromScale(0.09, 0.08)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = panel
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = closeBtn
end

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromScale(0.04, 0.12)
list.Size = UDim2.fromScale(0.92, 0.84)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.02, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
end

local function statText(d: RaceConfig.RaceDef): string
	return string.format("HP×%.2f · ATK×%.2f · SPD×%.2f · บ้านเกิด: %s", d.statMods.hp, d.statMods.atk, d.statMods.walkSpeed, d.homeCityKey)
end

local function rebuildList()
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, d in RaceConfig.all() do
		local isCurrent = currentRaceId == d.id

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.BackgroundColor3 = if isCurrent then Color3.fromRGB(40, 60, 70) else Color3.fromRGB(30, 38, 48)
		row.BorderSizePixel = 0
		row.Parent = list
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0.1, 0)
		rc.Parent = row
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = row
		local rl = Instance.new("UIListLayout")
		rl.Padding = UDim.new(0, 2)
		rl.Parent = row

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 22)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.fromRGB(200, 235, 255)
		name.TextSize = 18
		name.Text = string.format("%s (%s)", d.labelTH, d.label)
		name.Parent = row

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, 0, 0, 44)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.Gotham
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextWrapped = true
		info.TextColor3 = Color3.fromRGB(195, 205, 215)
		info.TextSize = 13
		info.Text = d.lore .. "\n" .. statText(d) .. "  ·  " .. d.racialPassive
		info.Parent = row

		local act = Instance.new("TextButton")
		act.Size = UDim2.new(1, 0, 0, 30)
		act.Font = Enum.Font.GothamBold
		act.TextScaled = true
		act.TextColor3 = Color3.fromRGB(255, 255, 255)
		act.Parent = row
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0.2, 0)
		ac.Parent = act
		if isCurrent then
			act.BackgroundColor3 = Color3.fromRGB(50, 90, 80)
			act.Text = "เผ่าปัจจุบัน"
			act.Active = false
		else
			act.BackgroundColor3 = Color3.fromRGB(46, 78, 100)
			act.Text = "เลือกเผ่านี้"
			act.Activated:Connect(function()
				act.Text = "..."
				local ok = pcall(function()
					return requestSelect:InvokeServer(d.id)
				end)
				if ok then
					currentRaceId = d.id
					rebuildList()
				else
					act.Text = "ลองใหม่"
				end
			end)
		end
	end
end

local function open()
	rebuildList()
	gui.Enabled = true
end
openBtn.Activated:Connect(open)
closeBtn.Activated:Connect(function()
	gui.Enabled = false
end)

-- init: ดึงเผ่าปัจจุบัน; ถ้ายังไม่มี → เปิดอัตโนมัติ (เลือกตอนสร้างตัว)
task.spawn(function()
	local ok, raceId = pcall(function()
		return getMyRace:InvokeServer()
	end)
	if ok and typeof(raceId) == "string" then
		currentRaceId = raceId
	end
	if not currentRaceId then
		open()
	end
end)
