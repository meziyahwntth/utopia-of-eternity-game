--!strict
--[[
	AutoBattleClient (P3-C+) — auto-battle toggle, target lock, attack loop, damage VFX.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CombatConfig = require(Modules:WaitForChild("CombatConfig"))

local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local attackRequest = remotes:WaitForChild("CombatAttackRequest") :: RemoteEvent
local resultClient = remotes:WaitForChild("CombatResultClient") :: RemoteEvent
local autoToggle = remotes:WaitForChild("AutoBattleToggle") :: RemoteFunction

type WeaponType = CombatConfig.WeaponType
type WeaponTier = CombatConfig.WeaponTier

local autoEnabled = false
local lockedTarget: Model? = nil
local lockHighlight: Highlight? = nil
local lockBillboard: BillboardGui? = nil
local nextAttackAt = 0

local function weaponType(): WeaponType
	local raw = localPlayer:GetAttribute("WeaponType")
	if typeof(raw) == "string" then
		if raw == "Bow" or raw == "Staff" or raw == "Sword" then
			return raw :: WeaponType
		end
	end
	return CombatConfig.DefaultWeaponType :: WeaponType
end

local function weaponTier(): WeaponTier
	local raw = localPlayer:GetAttribute("WeaponTier")
	if typeof(raw) == "string" then
		if raw == "T1" or raw == "T2" or raw == "T3" or raw == "T4" or raw == "T5" then
			return raw :: WeaponTier
		end
	end
	return CombatConfig.DefaultWeaponTier :: WeaponTier
end

local function attackSpeed(): number
	local speeds: { [WeaponTier]: number } = CombatConfig.AttackSpeed
	return speeds[weaponTier()]
end

local function maxRange(): number
	local ranges: { [WeaponType]: number } = CombatConfig.MaxRange
	return ranges[weaponType()]
end

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function clearLock()
	if lockHighlight then
		lockHighlight:Destroy()
		lockHighlight = nil
	end
	if lockBillboard then
		lockBillboard:Destroy()
		lockBillboard = nil
	end
	lockedTarget = nil
end

local function updateLockBillboard(npc: Model)
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if not lockBillboard then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(120, 36)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		lockBillboard = bb
	end
	local root = getRoot(npc)
	if not root or not lockBillboard then
		return
	end
	lockBillboard.Adornee = root
	lockBillboard.Parent = root

	for _, c in lockBillboard:GetChildren() do
		c:Destroy()
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npc.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = lockBillboard

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.Position = UDim2.fromOffset(0, 18)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBg.BorderSizePixel = 0
	barBg.Parent = lockBillboard

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	local pct = if hum.MaxHealth > 0 then hum.Health / hum.MaxHealth else 0
	barFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
end

local function setLock(npc: Model?)
	clearLock()
	if not npc then
		return
	end
	lockedTarget = npc
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.7
	hl.OutlineColor = Color3.fromRGB(255, 200, 80)
	hl.Adornee = npc
	hl.Parent = npc
	lockHighlight = hl
	updateLockBillboard(npc)
end

local function findNearestEnemy(range: number): Model?
	local char = localPlayer.Character
	local root = if char then getRoot(char) else nil
	if not root then
		return nil
	end
	local best: Model? = nil
	local bestDist = range
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("Model") and typeof(inst:GetAttribute(CombatConfig.NpcIdAttribute)) == "number" then
			local hum = inst:FindFirstChildOfClass("Humanoid")
			local nroot = getRoot(inst)
			if hum and hum.Health > 0 and nroot then
				local d = (nroot.Position - root.Position).Magnitude
				if d <= bestDist then
					bestDist = d
					best = inst
				end
			end
		end
	end
	return best
end

local function spawnDamageNumber(worldPos: Vector3, amount: number)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(worldPos + Vector3.new(0, 2, 0))
	part.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 28)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(amount)
	lbl.TextColor3 = Color3.fromRGB(255, 240, 120)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 18
	lbl.Parent = bb

	task.delay(0.8, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

----------------------------------------------------------------
-- HUD toggle
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AutoBattleGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "AutoBattleToggle"
toggleBtn.Size = UDim2.fromOffset(CombatConfig.UI.ToggleSize, CombatConfig.UI.ToggleSize)
toggleBtn.AnchorPoint = CombatConfig.UI.ToggleAnchor
toggleBtn.Position = CombatConfig.UI.TogglePosition
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 45, 70)
toggleBtn.Text = "⚔"
toggleBtn.TextScaled = true
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleBtn

local function refreshToggle()
	toggleBtn.BackgroundColor3 = if autoEnabled
		then Color3.fromRGB(60, 120, 70)
		else Color3.fromRGB(30, 45, 70)
end

local function setAuto(enabled: boolean)
	autoEnabled = enabled
	refreshToggle()
	if not enabled then
		clearLock()
	end
end

toggleBtn.Activated:Connect(function()
	local next = not autoEnabled
	local ok, _msg = autoToggle:InvokeServer(next, nil)
	if ok then
		setAuto(next)
	end
end)

resultClient.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" or payload.ok ~= true then
		return
	end
	local dmg = payload.damage
	if typeof(dmg) == "number" and lockedTarget then
		local root = getRoot(lockedTarget)
		if root then
			spawnDamageNumber(root.Position, dmg)
		end
		updateLockBillboard(lockedTarget)
	end
end)

RunService.Heartbeat:Connect(function()
	if not autoEnabled then
		return
	end

	local target = findNearestEnemy(maxRange())
	if target ~= lockedTarget then
		setLock(target)
	end

	if not target then
		return
	end

	local npcId = target:GetAttribute(CombatConfig.NpcIdAttribute)
	if typeof(npcId) ~= "number" then
		return
	end

	local now = os.clock()
	if now < nextAttackAt then
		return
	end
	nextAttackAt = now + attackSpeed()
	attackRequest:FireServer(npcId, CombatConfig.DefaultSkillId)
end)

refreshToggle()
