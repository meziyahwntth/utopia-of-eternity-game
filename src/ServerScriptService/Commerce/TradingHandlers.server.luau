--!strict
-- TradingHandlers (P4) — wire CommerceRemotes → TradingService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TradingService = require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("TradingService"))
local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")

local function RF(name: string): RemoteFunction
	return remotes:WaitForChild(name) :: RemoteFunction
end

RF("TradeAccept").OnServerInvoke = function(player: Player, partnerUserId: any)
	if typeof(partnerUserId) ~= "number" then
		return false, "invalid"
	end
	return TradingService.startSession(player, partnerUserId)
end

RF("TradeUpdateOffer").OnServerInvoke = function(player: Player, offer: any)
	if typeof(offer) ~= "table" then
		return false, "invalid"
	end
	local typed: TradingService.TradeOffer = {}
	for k, v in offer :: { [any]: any } do
		if typeof(k) == "string" and typeof(v) == "number" then
			typed[k] = v
		end
	end
	return TradingService.updateOffer(player, typed)
end

RF("TradeLock").OnServerInvoke = function(player: Player)
	return TradingService.lockOffer(player)
end

RF("TradeConfirm").OnServerInvoke = function(player: Player)
	return TradingService.confirmTrade(player)
end

RF("TradeCancel").OnServerInvoke = function(player: Player)
	return TradingService.cancel(player)
end

RF("TradeGetInventory").OnServerInvoke = function(player: Player)
	local Progression = ServerScriptService:WaitForChild("Progression")
	local PlayerItemStore = require(Progression:WaitForChild("PlayerItemStore"))
	return PlayerItemStore.getInventory(player.UserId)
end

print("[Commerce] TradingHandlers online (P4)")
