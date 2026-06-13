--!strict
-- PetHandlers (Backlog B) — wire SocialRemotes → PetService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PetService = require(script.Parent:WaitForChild("PetService"))
local QuestService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("QuestService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
PetService.init(remotes)

local equipPetRF = remotes:WaitForChild("EquipPet") :: RemoteFunction
local unequipPetRF = remotes:WaitForChild("UnequipPet") :: RemoteFunction
local getCollectionRF = remotes:WaitForChild("GetPetCollection") :: RemoteFunction

equipPetRF.OnServerInvoke = function(player: Player, petId: any)
	if typeof(petId) ~= "string" then
		return false, "invalid"
	end
	local ok, msg = PetService.equipPet(player, petId)
	if ok then
		QuestService.recordProgress(player, "equip_pet", 1)
	end
	return ok, msg
end

unequipPetRF.OnServerInvoke = function(player: Player)
	PetService.unequipPet(player)
	return true, "unequipped"
end

getCollectionRF.OnServerInvoke = function(player: Player)
	return PetService.getCollection(player)
end

print("[Commerce] PetHandlers online (Backlog B)")
