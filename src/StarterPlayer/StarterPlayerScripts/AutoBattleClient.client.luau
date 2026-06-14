--!strict
--[[
	AutoBattleClient (P3-C+ → Next-Gen) — auto-battle toggle + attack loop + damage VFX.
	Targeting/lock visuals now live in the shared TargetingController:
	  - if a target is locked (or soft-selected), Auto-Battle attacks it
	  - otherwise it auto-acquires the nearest enemy (soft target)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CombatConfig = require(Modules:WaitForChild("CombatConfig"))
local Targeting = require(Modules:WaitForChild("TargetingController"))

local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local attackRequest = remotes:WaitForChild("CombatAttackRequest") :: RemoteEvent
local resultClient = remotes:WaitForChild("CombatResultClient") :: RemoteEvent
local autoToggle = remotes:WaitForChild("AutoBattleToggle") :: RemoteFunction

type WeaponType = CombatConfig.WeaponType
type WeaponTier = CombatConfig.WeaponTier

local autoEnabled = false
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
end

toggleBtn.Activated:Connect(function()
	local nextState = not autoEnabled
	local ok, _msg = autoToggle:InvokeServer(nextState, nil)
	if ok then
		setAuto(nextState)
	end
end)

resultClient.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" or payload.ok ~= true then
		return
	end
	local dmg = payload.damage
	local tgt = Targeting.get()
	if typeof(dmg) == "number" and tgt then
		local root = getRoot(tgt)
		if root then
			spawnDamageNumber(root.Position, dmg)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not autoEnabled then
		return
	end
	local char = localPlayer.Character
	local root = if char then getRoot(char) else nil
	if not root then
		return
	end

	-- prefer the player's locked/soft target; else auto-acquire nearest
	local target = Targeting.get()
	if not Targeting.isEnemy(target) then
		target = Targeting.acquireNearest(root, maxRange())
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
