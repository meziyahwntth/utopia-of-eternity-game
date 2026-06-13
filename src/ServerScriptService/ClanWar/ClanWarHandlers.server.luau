--!strict
-- ClanWarHandlers (P5) — wire SocialRemotes → ClanWarService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClanWarService = require(script.Parent:WaitForChild("ClanWarService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
ClanWarService.init(remotes)

local function RF(name: string): RemoteFunction
	return remotes:WaitForChild(name) :: RemoteFunction
end

RF("WarRegister").OnServerInvoke = function(player: Player, zoneId: any)
	if typeof(zoneId) ~= "string" then
		return false, "invalid"
	end
	return ClanWarService.registerClan(player, zoneId)
end

RF("ClaimDividend").OnServerInvoke = function(player: Player, zoneId: any)
	if typeof(zoneId) ~= "string" then
		return false, "invalid", 0
	end
	return ClanWarService.claimDividend(player, zoneId)
end

RF("SetTaxRate").OnServerInvoke = function(player: Player, zoneId: any, rate: any)
	if typeof(zoneId) ~= "string" or typeof(rate) ~= "number" then
		return false, "invalid"
	end
	return ClanWarService.setTaxRate(player, zoneId, rate)
end

RF("GetTerritoryStatus").OnServerInvoke = function(_player: Player)
	return ClanWarService.getTerritoryStatus()
end

print("[ClanWar] ClanWarHandlers online (P5)")
