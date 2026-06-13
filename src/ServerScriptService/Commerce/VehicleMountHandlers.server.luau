--!strict
-- VehicleMountHandlers — wire CommerceRemotes → VehicleMountService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local VehicleMountService = require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("VehicleMountService"))

local CommerceRemotes = ReplicatedStorage:WaitForChild("CommerceRemotes") :: Folder

local openGarage = ReplicatedStorage:FindFirstChild("OpenGarage")
if not openGarage then
	openGarage = Instance.new("BindableEvent")
	openGarage.Name = "OpenGarage"
	openGarage.Parent = ReplicatedStorage
end

local getStateRF = CommerceRemotes:WaitForChild("GetVehicleMountState") :: RemoteFunction
local equipVehicleRE = CommerceRemotes:WaitForChild("EquipVehicle") :: RemoteEvent
local equipMountRE = CommerceRemotes:WaitForChild("EquipMount") :: RemoteEvent
local unequipRE = CommerceRemotes:WaitForChild("UnequipVehicleMount") :: RemoteEvent

getStateRF.OnServerInvoke = function(player: Player)
	return VehicleMountService.getState(player)
end

equipVehicleRE.OnServerEvent:Connect(function(player: Player, vehicleId: any)
	if typeof(vehicleId) ~= "string" then
		return
	end
	VehicleMountService.equipVehicle(player, vehicleId)
end)

equipMountRE.OnServerEvent:Connect(function(player: Player, mountId: any)
	if typeof(mountId) ~= "string" then
		return
	end
	VehicleMountService.equipMount(player, mountId)
end)

unequipRE.OnServerEvent:Connect(function(player: Player)
	VehicleMountService.unequip(player)
end)

print("[Commerce] VehicleMountHandlers online")
