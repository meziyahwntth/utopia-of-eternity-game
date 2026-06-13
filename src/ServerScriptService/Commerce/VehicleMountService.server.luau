--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VehicleConfig"))
local MountConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MountConfig"))

local vmStore = DataStoreService:GetDataStore("UtopiaVehicleMount_v1")

export type PlayerVehicleMountData = {
	ownedVehicles: { [string]: boolean },
	ownedMounts: { [string]: boolean },
	equippedVehicle: string?,
	equippedMount: string?,
}

local VehicleMountService = {}

local playerData: { [number]: PlayerVehicleMountData } = {}
local spawnedModels: { [number]: Model? } = {}

local BASE_WALKSPEED = 16

local function applySpeed(player: Player, boost: number)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	hum.WalkSpeed = BASE_WALKSPEED + boost
end

local function removeSpeed(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	hum.WalkSpeed = BASE_WALKSPEED
end

local function despawnModel(player: Player)
	local m = spawnedModels[player.UserId]
	if m then
		m:Destroy()
	end
	spawnedModels[player.UserId] = nil
end

local function spawnVehicleModel(player: Player, def: VehicleConfig.VehicleDef)
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local box = Instance.new("Part")
	box.Name = "VehiclePlaceholder_" .. def.id
	box.Size = Vector3.new(6, 2.5, 12)
	box.Color = Color3.fromRGB(240, 230, 180)
	box.Anchored = false
	box.CanCollide = false
	box.Parent = workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = box
	weld.Parent = box
	box.CFrame = root.CFrame * CFrame.new(0, -2, 0)

	local m = Instance.new("Model")
	m.Name = "VehicleModel"
	box.Parent = m
	m.Parent = workspace

	spawnedModels[player.UserId] = m
end

local function spawnMountModel(player: Player, def: MountConfig.MountDef)
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local box = Instance.new("Part")
	box.Name = "MountPlaceholder_" .. def.id
	box.Size = Vector3.new(4, 3, 5)
	box.Color = Color3.fromRGB(255, 255, 240)
	box.Anchored = false
	box.CanCollide = false
	box.Parent = workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = box
	weld.Parent = box
	box.CFrame = root.CFrame * CFrame.new(0, -3, 0)

	local m = Instance.new("Model")
	m.Name = "MountModel"
	box.Parent = m
	m.Parent = workspace

	spawnedModels[player.UserId] = m
end

local function reapplyEquipped(player: Player)
	local d = playerData[player.UserId]
	if not d then
		return
	end
	if d.equippedVehicle then
		local def = VehicleConfig.getById(d.equippedVehicle)
		if def then
			applySpeed(player, def.speedBoost)
			spawnVehicleModel(player, def)
		end
	elseif d.equippedMount then
		local def = MountConfig.getById(d.equippedMount)
		if def then
			applySpeed(player, def.speedBoost)
			spawnMountModel(player, def)
		end
	end
end

function VehicleMountService.load(player: Player)
	local userId = player.UserId
	local ok, data = pcall(function()
		return vmStore:GetAsync("vm_" .. userId)
	end)
	if ok and typeof(data) == "table" then
		playerData[userId] = {
			ownedVehicles = if typeof(data.ownedVehicles) == "table" then data.ownedVehicles else {},
			ownedMounts = if typeof(data.ownedMounts) == "table" then data.ownedMounts else {},
			equippedVehicle = if typeof(data.equippedVehicle) == "string" then data.equippedVehicle else nil,
			equippedMount = if typeof(data.equippedMount) == "string" then data.equippedMount else nil,
		}
	else
		playerData[userId] = {
			ownedVehicles = {},
			ownedMounts = {},
			equippedVehicle = nil,
			equippedMount = nil,
		}
	end
end

function VehicleMountService.save(player: Player)
	local userId = player.UserId
	local d = playerData[userId]
	if not d then
		return
	end
	pcall(function()
		vmStore:SetAsync("vm_" .. userId, d)
	end)
end

function VehicleMountService.grantVehicle(player: Player, vehicleId: string): boolean
	local d = playerData[player.UserId]
	if not d then
		return false
	end
	if not VehicleConfig.getById(vehicleId) then
		return false
	end
	d.ownedVehicles[vehicleId] = true
	VehicleMountService.save(player)
	return true
end

function VehicleMountService.grantMount(player: Player, mountId: string): boolean
	local d = playerData[player.UserId]
	if not d then
		return false
	end
	if not MountConfig.getById(mountId) then
		return false
	end
	d.ownedMounts[mountId] = true
	VehicleMountService.save(player)
	return true
end

function VehicleMountService.hasVehicle(player: Player, vehicleId: string): boolean
	local d = playerData[player.UserId]
	return d ~= nil and d.ownedVehicles[vehicleId] == true
end

function VehicleMountService.hasMount(player: Player, mountId: string): boolean
	local d = playerData[player.UserId]
	return d ~= nil and d.ownedMounts[mountId] == true
end

function VehicleMountService.equipVehicle(player: Player, vehicleId: string): (boolean, string)
	local d = playerData[player.UserId]
	if not d then
		return false, "not_loaded"
	end
	if not d.ownedVehicles[vehicleId] then
		return false, "not_owned"
	end
	local def = VehicleConfig.getById(vehicleId)
	if not def then
		return false, "invalid_id"
	end

	despawnModel(player)
	removeSpeed(player)
	d.equippedVehicle = nil
	d.equippedMount = nil

	d.equippedVehicle = vehicleId
	applySpeed(player, def.speedBoost)
	spawnVehicleModel(player, def)
	VehicleMountService.save(player)
	return true, "ok"
end

function VehicleMountService.equipMount(player: Player, mountId: string): (boolean, string)
	local d = playerData[player.UserId]
	if not d then
		return false, "not_loaded"
	end
	if not d.ownedMounts[mountId] then
		return false, "not_owned"
	end
	local def = MountConfig.getById(mountId)
	if not def then
		return false, "invalid_id"
	end

	despawnModel(player)
	removeSpeed(player)
	d.equippedVehicle = nil
	d.equippedMount = nil

	d.equippedMount = mountId
	applySpeed(player, def.speedBoost)
	spawnMountModel(player, def)
	VehicleMountService.save(player)
	return true, "ok"
end

function VehicleMountService.unequip(player: Player)
	local d = playerData[player.UserId]
	if not d then
		return
	end
	despawnModel(player)
	removeSpeed(player)
	d.equippedVehicle = nil
	d.equippedMount = nil
	VehicleMountService.save(player)
end

function VehicleMountService.getState(player: Player): PlayerVehicleMountData?
	local d = playerData[player.UserId]
	if not d then
		return nil
	end
	return {
		ownedVehicles = d.ownedVehicles,
		ownedMounts = d.ownedMounts,
		equippedVehicle = d.equippedVehicle,
		equippedMount = d.equippedMount,
	}
end

local function onPlayerAdded(player: Player)
	VehicleMountService.load(player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			reapplyEquipped(player)
		end)
	end)
	player.CharacterRemoving:Connect(function()
		despawnModel(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player: Player)
	despawnModel(player)
	VehicleMountService.save(player)
	playerData[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

return VehicleMountService
