--!strict
--[[
	Studio: defer CharacterAutoLoads until world builders finish, then spawn on sanctuary.
	Breaks void fall → death → respawn loops on cloud places (PlaceId != 0) and local rbxlx.

	Re-entrancy fix (มิ.ย. 2026):
	  - characterLocks ป้องกัน VoidGuard spawn stabilizeCharacter ซ้อนกันบน character เดิม
	  - WorldBuildState.waitReady() แทน poll loop — unblock ทันทีเมื่อ build เสร็จหรือ fail
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldBuildState = require(script.Parent:WaitForChild("WorldBuildState"))

local WorldStudioSpawnGuard = {}

-- Lock map: ป้องกัน coroutine ซ้อนกันบน character เดิว
local characterLocks: { [Model]: boolean } = {}

local PLACE_WORLD_MODELS: { [string]: string } = {
	Hub = "UtopiaHubWorld",
	Solhaven = "UtopiaSolhaven",
	Nocturne = "UtopiaNocturne",
	EternityCity = "UtopiaEternityCity",
	DeathValley = "UtopiaDeathValley",
}

local WORLD_MODEL_NAMES = {
	"UtopiaDeathValley",
	"UtopiaHubWorld",
	"UtopiaSolhaven",
	"UtopiaNocturne",
	"UtopiaEternityCity",
}

local voidGuardConnection: RBXScriptConnection? = nil

local function getCurrentPlaceKey(): string
	local guard = require(script.Parent:WaitForChild("WorldPlaceGuard"))
	return guard:GetCurrentPlaceKey()
end

local function findSpawnLocation(): SpawnLocation?
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("SpawnLocation") and string.find(inst.Name, "SanctuarySpawn") then
			return inst
		end
	end
	return nil
end

function WorldStudioSpawnGuard.waitForWorldReady(timeoutSeconds: number?): boolean
	local timeout = timeoutSeconds or 45

	-- ใช้ WorldBuildState event แทน poll loop
	local status = WorldBuildState.getStatus()
	if status == "ready" then
		return true
	end
	if status == "failed" then
		-- Build ล้มเหลว — ตรวจ workspace fallback
		for _, name in WORLD_MODEL_NAMES do
			if Workspace:FindFirstChild(name) then
				return true
			end
		end
		return false
	end

	-- รอ event (block thread ไม่เกิน timeout วินาที)
	local ok = WorldBuildState.waitReady(timeout)
	if ok then
		return true
	end

	-- Timeout หรือ failed — fallback ตรวจ workspace
	for _, name in WORLD_MODEL_NAMES do
		if Workspace:FindFirstChild(name) then
			return true
		end
	end
	return false
end

function WorldStudioSpawnGuard.getSanctuarySpawnCFrame(): CFrame
	local spawn = findSpawnLocation()
	if spawn then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end

	for _, modelName in WORLD_MODEL_NAMES do
		local model = Workspace:FindFirstChild(modelName)
		if model then
			local ground = model:FindFirstChild("WorldGround", true)
			if ground and ground:IsA("BasePart") then
				return ground.CFrame + Vector3.new(0, 6, 0)
			end
		end
	end

	local floor = WorldStudioSpawnGuard.ensureEmergencyFloor()
	return floor.CFrame + Vector3.new(0, 5, 0)
end

function WorldStudioSpawnGuard.ensureEmergencyFloor(): BasePart
	local existing = Workspace:FindFirstChild("StudioEmergencySpawn")
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local floor = Instance.new("Part")
	floor.Name = "StudioEmergencySpawn"
	floor.Size = Vector3.new(120, 2, 120)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(40, 40, 50)
	floor.Material = Enum.Material.Slate
	floor.CFrame = CFrame.new(0, 10, 0)
	floor.Parent = Workspace
	return floor
end

function WorldStudioSpawnGuard.teleportCharacterToSanctuary(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		root = character:WaitForChild("HumanoidRootPart", 8) :: BasePart?
	end
	if not root then
		return
	end

	local cf = WorldStudioSpawnGuard.getSanctuarySpawnCFrame()
	if cf.Position.Y < 2 then
		local floor = WorldStudioSpawnGuard.ensureEmergencyFloor()
		cf = floor.CFrame + Vector3.new(0, 5, 0)
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = cf

	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = hum.MaxHealth
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		task.defer(function()
			if hum.Parent then
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			end
		end)
	end
end

local function stabilizeCharacter(character: Model)
	-- Re-entrancy guard: ถ้า coroutine อื่นกำลัง stabilize character นี้อยู่ → skip
	if characterLocks[character] then
		return
	end
	characterLocks[character] = true

	local ok, err = pcall(function()
		WorldStudioSpawnGuard.waitForWorldReady(60)
		WorldStudioSpawnGuard.ensureEmergencyFloor()
		for _ = 1, 8 do
			if not character.Parent then
				break
			end
			WorldStudioSpawnGuard.teleportCharacterToSanctuary(character)
			task.wait(0.2)
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and root.Position.Y > -20 then
				break
			end
		end
	end)

	characterLocks[character] = nil
	if not ok then
		warn("[WorldStudioSpawnGuard] stabilizeCharacter error:", err)
	end
end

function WorldStudioSpawnGuard.bindPlayerSpawn(player: Player)
	player.CharacterAdded:Connect(function(character)
		-- ล้าง lock ของ character เก่าเมื่อ respawn
		character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				characterLocks[character] = nil
			end
		end)
		task.spawn(function()
			stabilizeCharacter(character)
		end)
	end)
end

local function startVoidGuard()
	if voidGuardConnection then
		return
	end
	local accum = 0
	voidGuardConnection = RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < 0.35 then
			return
		end
		accum = 0
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and root.Position.Y < -80 then
				stabilizeCharacter(character)
			end
		end
	end)
end

function WorldStudioSpawnGuard.start()
	pcall(function()
		Workspace.FallenPartsDestroyHeight = -2048
	end)
	startVoidGuard()
	for _, player in Players:GetPlayers() do
		WorldStudioSpawnGuard.bindPlayerSpawn(player)
	end
	Players.PlayerAdded:Connect(function(player)
		WorldStudioSpawnGuard.bindPlayerSpawn(player)
	end)
end

function WorldStudioSpawnGuard.loadDeferredCharacters()
	for _, player in Players:GetPlayers() do
		if not player.Character then
			player:LoadCharacter()
		end
	end
end

function WorldStudioSpawnGuard.respawnPlayer(player: Player)
	player:SetAttribute("DV_Downed", false)
	WorldStudioSpawnGuard.waitForWorldReady(15)
	WorldStudioSpawnGuard.ensureEmergencyFloor()

	local existing = player.Character
	if existing and existing:FindFirstChildOfClass("Humanoid") then
		stabilizeCharacter(existing)
		return
	end

	player:LoadCharacter()
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	stabilizeCharacter(character)
end

return WorldStudioSpawnGuard
