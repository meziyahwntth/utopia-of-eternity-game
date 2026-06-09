--!strict
--[[
	Phase O — Friend join teleport, join digest delivery bootstrap.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DeathValleyFriendJoinService = require(script.Parent:WaitForChild("DeathValleyFriendJoinService"))
local DeathValleyJoinDataService = require(script.Parent:WaitForChild("DeathValleyJoinDataService"))
local DeathValleySocialNotifyService = require(script.Parent:WaitForChild("DeathValleySocialNotifyService"))

local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local teleportToFriend = remotes:WaitForChild("TeleportToFriend") :: RemoteFunction
local getFriendJoinPreview = remotes:WaitForChild("GetFriendJoinPreview") :: RemoteFunction
local getSocialNotifyPreview = remotes:WaitForChild("GetSocialNotifyPreview") :: RemoteFunction
local setSocialNotifyPrefs = remotes:WaitForChild("SetSocialNotifyPrefs") :: RemoteFunction

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

teleportToFriend.OnServerInvoke = function(player: Player, friendUserId: number)
	if not allow(player, "TeleportToFriend", 3, 60) then
		return false, "Rate limited"
	end
	if typeof(friendUserId) ~= "number" then
		return false, "Invalid friend"
	end
	return DeathValleyFriendJoinService.teleportToFriend(player, friendUserId)
end

getFriendJoinPreview.OnServerInvoke = function(player: Player, friendUserId: number)
	if typeof(friendUserId) ~= "number" then
		return { canJoin = false, reason = "Invalid friend" }
	end
	return DeathValleyFriendJoinService.getJoinPreview(player, friendUserId)
end

getSocialNotifyPreview.OnServerInvoke = function(player: Player)
	return {
		queue = DeathValleySocialNotifyService.getQueuePreview(player),
		prefs = DeathValleySocialNotifyService.getPrefs(player.UserId),
	}
end

setSocialNotifyPrefs.OnServerInvoke = function(player: Player, prefs: { [string]: any })
	if typeof(prefs) ~= "table" then
		return false, "Invalid prefs"
	end
	local current = DeathValleySocialNotifyService.getPrefs(player.UserId)
	local merged = {
		presetShare = if typeof(prefs.presetShare) == "boolean" then prefs.presetShare else current.presetShare,
		friendOnline = if typeof(prefs.friendOnline) == "boolean" then prefs.friendOnline else current.friendOnline,
		marketFeatured = if typeof(prefs.marketFeatured) == "boolean"
			then prefs.marketFeatured
			else current.marketFeatured,
		pushOptIn = if typeof(prefs.pushOptIn) == "boolean" then prefs.pushOptIn else current.pushOptIn,
	}
	local ok = DeathValleySocialNotifyService.setPrefs(player.UserId, merged)
	return ok, if ok then "Notification preferences saved" else "Could not save preferences"
end

DeathValleyJoinDataService.start()

print("[DeathValley] Social handlers online")
