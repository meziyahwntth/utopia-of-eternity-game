--!strict
-- CraftingHandlers — wire SocialRemotes → CraftingService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CraftingService = require(script.Parent:WaitForChild("CraftingService"))
local PlayerItemStore = require(script.Parent:WaitForChild("PlayerItemStore"))
local CurrencyService = require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local getAllRecipesRF = remotes:WaitForChild("GetAllRecipes") :: RemoteFunction
local craftItemRF = remotes:WaitForChild("CraftItem") :: RemoteFunction
local getInventoryRF = remotes:WaitForChild("GetInventory") :: RemoteFunction
local getCreditsRF = remotes:WaitForChild("GetCredits") :: RemoteFunction

getAllRecipesRF.OnServerInvoke = function(_player: Player)
	return CraftingService.getAllRecipes()
end

craftItemRF.OnServerInvoke = function(player: Player, outputItem: any)
	if typeof(outputItem) ~= "string" then
		return { ok = false, reason = "invalid", output = nil }
	end
	return CraftingService.craft(player, outputItem)
end

getInventoryRF.OnServerInvoke = function(player: Player)
	return PlayerItemStore.getInventory(player.UserId)
end

getCreditsRF.OnServerInvoke = function(player: Player)
	return CurrencyService.getBalance(player.UserId)
end

print("[Progression] CraftingHandlers online")
