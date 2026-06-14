--!strict
--[[
	TargetingController (Next-Gen Mobile RPG) — client-shared target lock-on.
	Single source of truth for current target + lock state + visuals
	(Highlight outline + BillboardGui name/HP). Required by both
	TargetingClient (input + update loop + lock button) and
	AutoBattleClient (auto-acquire + attack). Required from a LocalScript
	context the module is cached per-client, so both share one instance.

	Server stays authoritative: attacks are validated in CombatService by
	npcId (range / alive / rate / line-of-sight). This controller only
	chooses which npcId the client fires at + draws the indicator.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatConfig"))

local NPC_ATTR = CombatConfig.NpcIdAttribute
local SOFT_COLOR = Color3.fromRGB(255, 200, 80) -- auto/soft target
local LOCK_COLOR = Color3.fromRGB(255, 70, 70) -- manually locked

local TargetingController = {}

local target: Model? = nil
local locked = false
local highlight: Highlight? = nil
local billboard: BillboardGui? = nil
local hpFill: Frame? = nil
local nameLabel: TextLabel? = nil
local hpLabel: TextLabel? = nil
local changedListeners: { (Model?, boolean) -> () } = {}

local function getRoot(model: Model): BasePart?
	local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if r and r:IsA("BasePart") then r else nil
end

function TargetingController.isEnemy(model: Instance?): boolean
	if not model or not model:IsA("Model") then
		return false
	end
	if typeof(model:GetAttribute(NPC_ATTR)) ~= "number" then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

function TargetingController.onChanged(fn: (Model?, boolean) -> ())
	table.insert(changedListeners, fn)
end

local function notify()
	for _, fn in changedListeners do
		task.spawn(fn, target, locked)
	end
end

local function destroyVisuals()
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	if billboard then
		billboard:Destroy()
		billboard = nil
	end
	hpFill = nil
	nameLabel = nil
	hpLabel = nil
end

local function applyColor()
	if highlight then
		highlight.OutlineColor = if locked then LOCK_COLOR else SOFT_COLOR
	end
end

local function buildVisuals(model: Model)
	destroyVisuals()
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.8
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model
	hl.Parent = model
	highlight = hl

	local root = getRoot(model)
	if root then
		local bb = Instance.new("BillboardGui")
		bb.Name = "TargetIndicator"
		bb.Size = UDim2.fromOffset(132, 40)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = root
		bb.Parent = root
		billboard = bb

		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, 0, 0, 16)
		nm.BackgroundTransparency = 1
		nm.Font = Enum.Font.GothamBold
		nm.TextSize = 14
		nm.TextColor3 = Color3.fromRGB(255, 235, 160)
		nm.TextStrokeTransparency = 0.4
		nm.Text = model.Name
		nm.Parent = bb
		nameLabel = nm

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 0, 11)
		bg.Position = UDim2.fromOffset(0, 18)
		bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		bg.BorderSizePixel = 0
		bg.Parent = bb
		local bgc = Instance.new("UICorner")
		bgc.CornerRadius = UDim.new(0, 4)
		bgc.Parent = bg

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
		fill.BorderSizePixel = 0
		fill.Parent = bg
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 4)
		fc.Parent = fill
		hpFill = fill

		local hp = Instance.new("TextLabel")
		hp.Size = UDim2.fromScale(1, 1)
		hp.BackgroundTransparency = 1
		hp.Font = Enum.Font.GothamBold
		hp.TextSize = 9
		hp.TextColor3 = Color3.fromRGB(255, 255, 255)
		hp.TextStrokeTransparency = 0.5
		hp.Parent = bg
		hpLabel = hp
	end
	applyColor()
end

function TargetingController.get(): Model?
	return target
end

function TargetingController.getNpcId(): number?
	if not target then
		return nil
	end
	local id = target:GetAttribute(NPC_ATTR)
	return if typeof(id) == "number" then id else nil
end

function TargetingController.isLocked(): boolean
	return locked
end

-- Set (or clear) the active target. lockIt: true=lock, false=soft, nil=keep.
function TargetingController.setTarget(model: Model?, lockIt: boolean?)
	if model and not TargetingController.isEnemy(model) then
		return
	end
	target = model
	if lockIt ~= nil then
		locked = lockIt == true and model ~= nil
	end
	if model then
		buildVisuals(model)
	else
		destroyVisuals()
		locked = false
	end
	notify()
end

function TargetingController.lock()
	if target then
		locked = true
		applyColor()
		notify()
	end
end

function TargetingController.unlock()
	locked = false
	applyColor()
	notify()
end

function TargetingController.toggleLock()
	if locked then
		TargetingController.unlock()
	elseif target then
		TargetingController.lock()
	end
end

function TargetingController.clear()
	if not target and not locked then
		return
	end
	target = nil
	locked = false
	destroyVisuals()
	notify()
end

-- Auto-pick nearest enemy within range. Only switches the active target
-- when NOT locked. Returns the nearest enemy (for the caller to attack).
function TargetingController.acquireNearest(originRoot: BasePart, range: number): Model?
	local best: Model? = nil
	local bestDist = range
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("Model") and typeof(inst:GetAttribute(NPC_ATTR)) == "number" then
			local hum = inst:FindFirstChildOfClass("Humanoid")
			local r = getRoot(inst)
			if hum and hum.Health > 0 and r then
				local d = (r.Position - originRoot.Position).Magnitude
				if d <= bestDist then
					bestDist = d
					best = inst
				end
			end
		end
	end
	if best and not locked and best ~= target then
		TargetingController.setTarget(best, false)
	end
	return best
end

-- Refresh HP bar + auto-clear dead / despawned / (soft) out-of-range targets.
function TargetingController.update(maxKeepRange: number?, originRoot: BasePart?)
	if not target then
		return
	end
	if not target.Parent then
		TargetingController.clear()
		return
	end
	local hum = target:FindFirstChildOfClass("Humanoid")
	local root = getRoot(target)
	if not hum or hum.Health <= 0 or not root then
		TargetingController.clear()
		return
	end
	if not locked and maxKeepRange and originRoot then
		local d = (root.Position - originRoot.Position).Magnitude
		if d > maxKeepRange then
			TargetingController.clear()
			return
		end
	end
	if nameLabel then
		nameLabel.Text = target.Name
	end
	if hpFill then
		local pct = if hum.MaxHealth > 0 then hum.Health / hum.MaxHealth else 0
		hpFill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
	end
	if hpLabel then
		hpLabel.Text = string.format("%d / %d", math.floor(hum.Health), math.ceil(hum.MaxHealth))
	end
end

return TargetingController
