--!strict
--[[
	SkillBarClient (Next-Gen Mobile RPG) — bottom-right skill bar + Jump.
	- One button per CombatConfig.Skills (Attack / Power / Spin) + a Jump button
	- Tap a skill -> fires it at the locked/soft target (or auto-acquires nearest)
	- Per-skill client cooldown wipe (server also enforces cooldown: anti-exploit)
	- Mobile-first: Scale sizing + UIAspectRatioConstraint + UISizeConstraint
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CombatConfig = require(Modules:WaitForChild("CombatConfig"))
local Targeting = require(Modules:WaitForChild("TargetingController"))
local CombatState = require(Modules:WaitForChild("CombatStateController"))

local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local attackRequest = remotes:WaitForChild("CombatAttackRequest") :: RemoteEvent

type WeaponType = CombatConfig.WeaponType

local function weaponType(): WeaponType
	local raw = localPlayer:GetAttribute("WeaponType")
	if typeof(raw) == "string" and (raw == "Bow" or raw == "Staff" or raw == "Sword") then
		return raw :: WeaponType
	end
	return CombatConfig.DefaultWeaponType :: WeaponType
end

local function maxRange(): number
	local ranges: { [WeaponType]: number } = CombatConfig.MaxRange
	return ranges[weaponType()]
end

local function getRoot(model: Instance?): BasePart?
	if not model or not model:IsA("Model") then
		return nil
	end
	local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if r and r:IsA("BasePart") then r else nil
end

-- choose the enemy to hit: locked/soft target, else auto-acquire nearest
local function currentEnemy(): Model?
	local t = Targeting.get()
	if Targeting.isEnemy(t) then
		return t
	end
	local root = getRoot(localPlayer.Character)
	if root then
		return Targeting.acquireNearest(root, maxRange())
	end
	return nil
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SkillBarGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(1, 1)
bar.Position = UDim2.new(1, -12, 1, -12)
bar.Size = UDim2.new(0.66, 0, 0.12, 0)
bar.BackgroundTransparency = 1
bar.Parent = gui
do
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0.02, 0)
	list.Parent = bar
end

local cooldownEnd: { [string]: number } = {}
local overlays: { { id: string, cd: number, frame: Frame, label: TextLabel } } = {}

local function makeButton(order: number, text: string, color: Color3): (TextButton, Frame, TextLabel)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.new(0, 0, 1, 0) -- width follows height via aspect ratio
	btn.BackgroundColor3 = color
	btn.AutoButtonColor = true
	btn.Text = text
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(245, 245, 255)
	btn.Parent = bar
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = btn
	local sz = Instance.new("UISizeConstraint")
	sz.MinSize = Vector2.new(46, 46)
	sz.MaxSize = Vector2.new(92, 92)
	sz.Parent = btn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.22, 0)
	c.Parent = btn

	-- cooldown wipe overlay (covers button while cooling down)
	local ov = Instance.new("Frame")
	ov.Name = "Cooldown"
	ov.AnchorPoint = Vector2.new(0.5, 1)
	ov.Position = UDim2.new(0.5, 0, 1, 0)
	ov.Size = UDim2.new(1, 0, 0, 0)
	ov.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	ov.BackgroundTransparency = 0.45
	ov.BorderSizePixel = 0
	ov.ZIndex = 2
	ov.Parent = btn
	local oc = Instance.new("UICorner")
	oc.CornerRadius = UDim.new(0.22, 0)
	oc.Parent = ov

	local cdText = Instance.new("TextLabel")
	cdText.Size = UDim2.fromScale(1, 1)
	cdText.BackgroundTransparency = 1
	cdText.Font = Enum.Font.GothamBold
	cdText.TextScaled = true
	cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cdText.ZIndex = 3
	cdText.Text = ""
	cdText.Parent = btn

	return btn, ov, cdText
end

-- แปลง list of skill id → SkillDef (icon/label/cooldown) ผ่าน CombatConfig.SkillMeta/SkillCooldown
local function skillDefsFromIds(ids: { string }): { CombatConfig.SkillDef }
	local out: { CombatConfig.SkillDef } = {}
	local meta: { [string]: { label: string, icon: string } } = (CombatConfig :: any).SkillMeta
	local cds: { [string]: number } = CombatConfig.SkillCooldown
	for _, id in ids do
		local m = meta and meta[id]
		local cd = cds[id]
		table.insert(out, {
			id = id,
			label = if m then m.label else id,
			icon = if m then m.icon else "•",
			cooldown = if typeof(cd) == "number" then cd else 0,
		})
	end
	return out
end

local function clearButtons()
	for _, child in bar:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	table.clear(overlays)
	table.clear(cooldownEnd)
end

-- สร้างแถบสกิล (ตามคลาส; default = CombatConfig.Skills) — เรียกซ้ำได้เมื่อเปลี่ยนคลาส
local function buildBar(skillDefs: { CombatConfig.SkillDef })
	clearButtons()
	for i, def in skillDefs do
		local btn, ov, cdText = makeButton(i, def.icon, Color3.fromRGB(46, 58, 92))
		table.insert(overlays, { id = def.id, cd = def.cooldown, frame = ov, label = cdText })
		btn.Activated:Connect(function()
			local cdEnd = cooldownEnd[def.id]
			if cdEnd and os.clock() < cdEnd then
				return
			end
			local enemy = currentEnemy()
			if not enemy then
				return
			end
			local npcId = enemy:GetAttribute(CombatConfig.NpcIdAttribute)
			if typeof(npcId) ~= "number" then
				return
			end
			attackRequest:FireServer(npcId, def.id)
			CombatState.EnterCombat("skill")
			if def.cooldown > 0 then
				cooldownEnd[def.id] = os.clock() + def.cooldown
			end
		end)
	end
	-- Jump button (rightmost)
	local jumpBtn = makeButton(#skillDefs + 1, "⤴", Color3.fromRGB(70, 100, 60))
	jumpBtn.Activated:Connect(function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Jump = true
		end
	end)
end

-- เริ่มด้วย default แล้วลองดึงสกิลตามคลาส + ฟังการเปลี่ยนคลาส
buildBar(CombatConfig.Skills)
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("ClassRemotes", 10)
	if not remotes then
		return
	end
	local getMyClass = remotes:FindFirstChild("GetMyClass")
	if getMyClass and getMyClass:IsA("RemoteFunction") then
		local ok, _classId, classSkills = pcall(function()
			return getMyClass:InvokeServer()
		end)
		if ok and typeof(classSkills) == "table" then
			buildBar(skillDefsFromIds(classSkills))
		end
	end
	local changed = remotes:FindFirstChild("ClassChanged")
	if changed and changed:IsA("RemoteEvent") then
		changed.OnClientEvent:Connect(function(_classId: any, classSkills: any)
			if typeof(classSkills) == "table" then
				buildBar(skillDefsFromIds(classSkills))
			end
		end)
	end
end)

----------------------------------------------------------------
-- cooldown wipe update
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for _, o in overlays do
		local cdEnd = cooldownEnd[o.id]
		if cdEnd and now < cdEnd and o.cd > 0 then
			local frac = (cdEnd - now) / o.cd
			o.frame.Size = UDim2.new(1, 0, math.clamp(frac, 0, 1), 0)
			o.label.Text = string.format("%.0f", math.ceil(cdEnd - now))
		else
			o.frame.Size = UDim2.new(1, 0, 0, 0)
			o.label.Text = ""
		end
	end
end)
