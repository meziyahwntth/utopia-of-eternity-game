--!strict
-- CardHandlers — wire SocialRemotes → CardService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CardService = require(script.Parent:WaitForChild("CardService"))
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local GetEquippedCardsRF = ensure("RemoteFunction", "GetEquippedCards") :: RemoteFunction
local EquipCardRF = ensure("RemoteFunction", "EquipCard") :: RemoteFunction
local UnequipCardRF = ensure("RemoteFunction", "UnequipCard") :: RemoteFunction

GetEquippedCardsRF.OnServerInvoke = function(player: Player)
	return CardService.getEquipped(player)
end

EquipCardRF.OnServerInvoke = function(player: Player, cardId: any, slot: any)
	if typeof(cardId) ~= "string" or typeof(slot) ~= "number" then
		return false, "invalid args"
	end
	return CardService.equipCard(player, cardId, math.floor(slot))
end

UnequipCardRF.OnServerInvoke = function(player: Player, slot: any)
	if typeof(slot) ~= "number" then
		return false, "invalid slot"
	end
	return CardService.unequipCard(player, math.floor(slot))
end

Players.PlayerAdded:Connect(function(player)
	CardService.init(player)
end)

for _, p in Players:GetPlayers() do
	CardService.init(p)
end

print("[Progression] CardHandlers online")
