--!strict
-- InteractionHandlers (P3-C) — wire Interaction remotes → InteractionService
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InteractionService = require(ServerScriptService:WaitForChild("Social"):WaitForChild("InteractionService"))
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")

local function RF(name: string): RemoteFunction
	return remotes:WaitForChild(name) :: RemoteFunction
end
local function RE(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

RF("DuelSend").OnServerInvoke = function(player: Player, targetUserId: any)
	if typeof(targetUserId) ~= "number" then return false, "invalid" end
	return InteractionService.duelRequest(player, targetUserId)
end

RF("DuelAccept").OnServerInvoke = function(player: Player, fromUserId: any)
	if typeof(fromUserId) ~= "number" then return false, "invalid" end
	return InteractionService.duelAccept(player, fromUserId)
end

RF("TradeSend").OnServerInvoke = function(player: Player, targetUserId: any)
	if typeof(targetUserId) ~= "number" then return false, "invalid" end
	return InteractionService.tradeRequest(player, targetUserId)
end

RF("CarryRequest").OnServerInvoke = function(player: Player, targetUserId: any)
	if typeof(targetUserId) ~= "number" then return false, "invalid" end
	return InteractionService.carry(player, targetUserId)
end

RE("UncarryRequest").OnServerEvent:Connect(function(player: Player)
	InteractionService.uncarry(player)
end)

RF("BlockPlayer").OnServerInvoke = function(player: Player, targetUserId: any)
	if typeof(targetUserId) ~= "number" then return false, "invalid" end
	return InteractionService.block(player, targetUserId)
end

RF("UnblockPlayer").OnServerInvoke = function(player: Player, targetUserId: any)
	if typeof(targetUserId) ~= "number" then return false, "invalid" end
	return InteractionService.unblock(player, targetUserId)
end

RF("InteractionPartyInvite").OnServerInvoke = function(player: Player, targetName: any)
	if typeof(targetName) ~= "string" then return false, "invalid" end
	return InteractionService.partyInvite(player, targetName)
end

RF("InteractionClanInvite").OnServerInvoke = function(player: Player, targetName: any)
	if typeof(targetName) ~= "string" then return false, "invalid" end
	return InteractionService.clanInvite(player, targetName)
end

print("[Social] InteractionHandlers online (P3-C)")
