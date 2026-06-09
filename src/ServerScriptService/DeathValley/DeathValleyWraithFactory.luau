--!strict
--[[
	Greybox Shadow Wraith NPCs — Whisper, Stalker, Legion Echo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyBeaconService = require(script.Parent:WaitForChild("DeathValleyBeaconService"))

local DeathValleyWraithFactory = {}

local activeFolder: Folder? = nil
local activeWraiths: { Model } = {}
local aiConnection: RBXScriptConnection? = nil

local function getSpawnPosition(): Vector3
	local angle = math.random() * math.pi * 2
	local dist = DeathValleyBeaconService.getRadius() + 25 + math.random() * 35
	return PrismDeathValleySurvivalConfig.BeaconOrigin + Vector3.new(math.cos(angle) * dist, 3, math.sin(angle) * dist)
end

local function findTarget(origin: Vector3): Player?
	local best: Player? = nil
	local bestDist = math.huge
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 and not player:GetAttribute("DV_Downed") then
			if not DeathValleyBeaconService.isInsideSanctuary(root.Position) then
				local d = (root.Position - origin).Magnitude
				if d < bestDist then
					bestDist = d
					best = player
				end
			end
		end
	end
	return best
end

function DeathValleyWraithFactory.spawn(
	kind: PrismDeathValleySurvivalConfig.WraithKind,
	parent: Instance,
	modifier: PrismDeathValleySurvivalConfig.NightModifierDef?
): Model
	local def = PrismDeathValleySurvivalConfig.Wraiths[kind]
	local mod = modifier or {
		wraithSpeedMultiplier = 1,
		wraithHealthMultiplier = 1,
	} :: PrismDeathValleySurvivalConfig.NightModifierDef
	local model = Instance.new("Model")
	model.Name = "Wraith_" .. kind

	local core = Instance.new("Part")
	core.Name = "HumanoidRootPart"
	core.Size = def.size
	core.Color = def.color
	core.Material = Enum.Material.Neon
	core.Anchored = false
	core.CanCollide = true
	core.CFrame = CFrame.new(getSpawnPosition())
	core.Parent = model
	model.PrimaryPart = core

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = math.floor(def.maxHealth * mod.wraithHealthMultiplier)
	hum.Health = hum.MaxHealth
	hum.WalkSpeed = def.walkSpeed * mod.wraithSpeedMultiplier
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	local touchDebounce: { [number]: number } = {}
	core.Touched:Connect(function(hit)
		local char = hit:FindFirstAncestorOfClass("Model")
		if not char then
			return
		end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end
		local now = os.clock()
		if touchDebounce[player.UserId] and now - touchDebounce[player.UserId] < 1.2 then
			return
		end
		touchDebounce[player.UserId] = now
		if DeathValleyBeaconService.isInsideSanctuary(core.Position) then
			return
		end
		local targetHum = char:FindFirstChildOfClass("Humanoid")
		if targetHum and targetHum.Health > 0 then
			targetHum:TakeDamage(def.touchDamage)
		end
	end)

	model:SetAttribute("WraithKind", kind)
	model.Parent = parent
	table.insert(activeWraiths, model)
	return model
end

function DeathValleyWraithFactory.spawnWave(
	nightNumber: number,
	partySize: number,
	parent: Instance,
	modifier: PrismDeathValleySurvivalConfig.NightModifierDef?
): number
	DeathValleyWraithFactory.ensureFolder(parent)
	local mod = modifier or PrismDeathValleySurvivalConfig.getNightModifier(nightNumber)
	local kinds = PrismDeathValleySurvivalConfig.getWraithKindsForNight(nightNumber)
	local total = PrismDeathValleySurvivalConfig.computeWraithCount(nightNumber, partySize, mod)
	local spawned = 0
	for i = 1, total do
		local kind = kinds[((i - 1) % #kinds) + 1]
		if kind == "LegionEcho" and nightNumber % 3 == 0 and i % 2 == 0 then
			kind = "LegionEcho"
		elseif kind == "LegionEcho" and nightNumber % 3 ~= 0 then
			kind = kinds[1]
		end
		if mod.extraLegion > 0 and i == total then
			kind = "LegionEcho"
		elseif mod.extraStalkers > 0 and i > total - mod.extraStalkers then
			kind = "Stalker"
		elseif mod.extraWhispers > 0 and i <= mod.extraWhispers then
			kind = "Whisper"
		end
		DeathValleyWraithFactory.spawn(kind, activeFolder :: Folder, mod)
		spawned += 1
	end
	DeathValleyWraithFactory.startAi()
	return spawned
end

function DeathValleyWraithFactory.ensureFolder(parent: Instance)
	if activeFolder and activeFolder.Parent then
		return
	end
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "ActiveWraiths"
	activeFolder.Parent = parent
end

function DeathValleyWraithFactory.startAi()
	if aiConnection then
		return
	end
	aiConnection = RunService.Heartbeat:Connect(function(dt)
		for i = #activeWraiths, 1, -1 do
			local model = activeWraiths[i]
			if not model.Parent then
				table.remove(activeWraiths, i)
				continue
			end
			local core = model.PrimaryPart
			local hum = model:FindFirstChildOfClass("Humanoid")
			if not core or not hum or hum.Health <= 0 then
				model:Destroy()
				table.remove(activeWraiths, i)
				continue
			end
			local target = findTarget(core.Position)
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				local goal = (target.Character.HumanoidRootPart :: BasePart).Position
				local dir = (goal - core.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 2 then
					core.CFrame = core.CFrame + dir.Unit * hum.WalkSpeed * dt
				end
			end
		end
		if #activeWraiths == 0 and aiConnection then
			aiConnection:Disconnect()
			aiConnection = nil
		end
	end)
end

function DeathValleyWraithFactory.clearAll()
	for _, model in activeWraiths do
		if model.Parent then
			model:Destroy()
		end
	end
	table.clear(activeWraiths)
	if aiConnection then
		aiConnection:Disconnect()
		aiConnection = nil
	end
end

function DeathValleyWraithFactory.getActiveCount(): number
	return #activeWraiths
end

return DeathValleyWraithFactory
