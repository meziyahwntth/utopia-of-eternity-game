--!strict
--[[
	VoidRecovery — เจ้าของเดียวของการกู้คนตกเหว (Blueprint §4.4)
	แยกจาก SpawnService: ทำงานเสมอ (Studio + cloud)

	แก้ root cause E: recover() teleport ทันที ไม่ block 60s-wait ในล็อก
	  - เจ้าของ FallenPartsDestroyHeight
	  - Heartbeat watch เดียว (throttle 0.35s)
	  - characterLocks กัน re-entrancy ต่อ character
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VoidRecovery = {}

local VOID_Y = -80
local WATCH_INTERVAL = 0.35

local started = false
local watchConnection: RBXScriptConnection? = nil
local characterLocks: { [Model]: boolean } = {}

local WORLD_MODEL_NAMES = {
	"UtopiaHubWorld",
	"UtopiaSolhaven",
	"UtopiaNocturne",
	"UtopiaEternityCity",
	"UtopiaDeathValley",
}

local function findSpawnLocation(): SpawnLocation?
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("SpawnLocation") and string.find(inst.Name, "SanctuarySpawn") then
			return inst
		end
	end
	return nil
end

function VoidRecovery.ensureEmergencyFloor(): BasePart
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

-- หา CFrame ปลอดภัยจากสิ่งที่ "มีอยู่ตอนนี้" — ไม่รอ build (no waitReady)
function VoidRecovery.getSafeSpawnCFrame(): CFrame
	local spawnLocation = findSpawnLocation()
	if spawnLocation then
		return spawnLocation.CFrame + Vector3.new(0, 4, 0)
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

	local floor = VoidRecovery.ensureEmergencyFloor()
	return floor.CFrame + Vector3.new(0, 5, 0)
end

-- กู้ character ทันที — ไม่ block, ไม่ถือ lock ข้าม wait ยาว (แก้ root cause E)
function VoidRecovery.recover(character: Model)
	if characterLocks[character] then
		return
	end
	characterLocks[character] = true

	local ok, err = pcall(function()
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			root = character:WaitForChild("HumanoidRootPart", 8) :: BasePart?
		end
		if not root then
			return
		end

		local cf = VoidRecovery.getSafeSpawnCFrame()
		if cf.Position.Y < 2 then
			local floor = VoidRecovery.ensureEmergencyFloor()
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
	end)

	characterLocks[character] = nil
	if not ok then
		warn("[VoidRecovery] recover error:", err)
	end
end

function VoidRecovery.start()
	if started then
		return
	end
	started = true

	pcall(function()
		Workspace.FallenPartsDestroyHeight = -2048
	end)

	local accum = 0
	watchConnection = RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < WATCH_INTERVAL then
			return
		end
		accum = 0
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if character and root and root.Position.Y < VOID_Y then
				VoidRecovery.recover(character)
			end
		end
	end)

	-- ล้าง lock เมื่อ character ถูกถอด
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character.AncestryChanged:Connect(function(_, parent)
				if not parent then
					characterLocks[character] = nil
				end
			end)
		end)
	end)
end

function VoidRecovery.stop()
	if watchConnection then
		watchConnection:Disconnect()
		watchConnection = nil
	end
	started = false
end

return VoidRecovery
