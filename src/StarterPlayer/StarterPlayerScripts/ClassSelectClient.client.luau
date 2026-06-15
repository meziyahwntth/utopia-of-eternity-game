--!strict
--[[
	ClassSelectClient (Class/Job system) — UI เลือก/เปลี่ยนอาชีพ (mobile-first)
	- เปิดอัตโนมัติเมื่อผู้เล่นยังไม่มีคลาส (ถึง Lv10)
	- ปุ่ม 🎓 มุมซ้ายบนเปิดเมนูได้ตลอด (จำลอง trainer; ของจริงผูก NPC ที่ EternityCity ภายหลัง)
	- แสดงคลาสที่เลือกได้ (canChange) + ความต้องการเลเวล; ยืนยัน → RequestClassChange
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local ClassConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClassConfig"))

local remotes = ReplicatedStorage:WaitForChild("ClassRemotes")
local requestChange = remotes:WaitForChild("RequestClassChange") :: RemoteFunction
local getMyClass = remotes:WaitForChild("GetMyClass") :: RemoteFunction

local currentClassId: string? = nil

local function level(): number
	local a = localPlayer:GetAttribute("PlayerLevel")
	return if typeof(a) == "number" then a else 1
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ClassSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.Enabled = false
gui.Parent = playerGui

-- ปุ่มเปิดเมนู (🎓)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenClass"
openBtn.AnchorPoint = Vector2.new(0, 0)
openBtn.Position = UDim2.new(0, 12, 0.30, 0)
openBtn.Size = UDim2.fromScale(0.07, 0.05)
openBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 70)
openBtn.BackgroundTransparency = 0.2
openBtn.Text = "🎓"
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
panel.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
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
title.TextColor3 = Color3.fromRGB(245, 240, 255)
title.Text = "เลือกอาชีพ (Class)"
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
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0.02, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
end

local function statText(d: ClassConfig.ClassDef): string
	return string.format("HP×%.2f · ATK×%.2f · CD×%.2f", d.statMods.hp, d.statMods.atk, d.statMods.cdMult)
end

local function skillIcons(d: ClassConfig.ClassDef): string
	local meta: { [string]: { label: string, icon: string } } = (require(ReplicatedStorage.Modules.CombatConfig) :: any).SkillMeta
	local s = ""
	for _, id in d.skills do
		local m = meta and meta[id]
		s ..= (if m then m.icon else "•") .. " "
	end
	return s
end

local function rebuildList()
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local lv = level()
	for i, d in ClassConfig.all() do
		local can, msg = ClassConfig.canChange(currentClassId, d.id, lv)
		local isCurrent = currentClassId == d.id

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.BackgroundColor3 = if isCurrent then Color3.fromRGB(40, 70, 50) else Color3.fromRGB(34, 38, 56)
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
		name.TextColor3 = Color3.fromRGB(255, 240, 200)
		name.TextSize = 18
		name.Text = string.format("%s (%s) %s", d.labelTH, d.label, skillIcons(d))
		name.Parent = row

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, 0, 0, 30)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.Gotham
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextWrapped = true
		info.TextColor3 = Color3.fromRGB(200, 205, 220)
		info.TextSize = 13
		info.Text = d.desc .. "  ·  " .. statText(d)
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
			act.BackgroundColor3 = Color3.fromRGB(60, 110, 70)
			act.Text = "อาชีพปัจจุบัน"
			act.Active = false
		elseif can then
			act.BackgroundColor3 = Color3.fromRGB(54, 86, 140)
			act.Text = "เลือกอาชีพนี้"
			act.Activated:Connect(function()
				act.Text = "..."
				local ok, resultMsg = pcall(function()
					return requestChange:InvokeServer(d.id)
				end)
				if ok then
					-- ok อาจเป็น (true,msg) — refresh
					currentClassId = d.id
					rebuildList()
				else
					act.Text = "ลองใหม่"
				end
				local _ = resultMsg
			end)
		else
			act.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			act.Text = msg
			act.Active = false
		end
	end
end

local function open()
	rebuildList()
	gui.Enabled = true
end
local function close()
	gui.Enabled = false
end

openBtn.Activated:Connect(open)
closeBtn.Activated:Connect(close)

-- init: ดึงคลาสปัจจุบัน; ถ้ายังไม่มี + ถึง Lv10 → เปิดอัตโนมัติ
task.spawn(function()
	local ok, classId = pcall(function()
		return getMyClass:InvokeServer()
	end)
	if ok and typeof(classId) == "string" then
		currentClassId = classId
	end
	if not currentClassId and level() >= 10 then
		open()
	end
end)
