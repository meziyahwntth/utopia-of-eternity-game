--!strict
--[[
	Phase O — Teleport to a Roblox friend using cross-place presence (jobId + placeKey).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local DeathValleyFriendPresenceService = require(script.Parent:WaitForChild("DeathValleyFriendPresenceService"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))

export type FriendJoinPreview = {
	canJoin: boolean,
	reason: string?,
	friendUserId: number,
	displayName: string?,
	placeKey: string?,
	placeDisplayName: string?,
	inThisServer: boolean,
	sameInstance: boolean,
}

local DeathValleyFriendJoinService = {}

local COOLDOWN_SECONDS = 45

local function verifyFriendship(player: Player, friendUserId: number): (boolean, string?)
	if friendUserId == player.UserId then
		return false, "Cannot join yourself"
	end
	local ok, isFriend = pcall(function()
		return player:IsFriendsWith(friendUserId)
	end)
	if not ok or not isFriend then
		return false, "Player is not on your friends list"
	end
	return true, nil
end

local function buildPreview(player: Player, friendUserId: number): FriendJoinPreview
	local friend = Players:GetPlayerByUserId(friendUserId)
	local presence = DeathValleyFriendPresenceService.getPresence(friendUserId)
	local displayName = if friend then friend.DisplayName
		elseif presence then presence.displayName
		else "Friend"
	if not presence then
		return {
			canJoin = false,
			reason = "Friend is offline",
			friendUserId = friendUserId,
			displayName = displayName,
			inThisServer = false,
			sameInstance = false,
		}
	end
	local inThisServer = friend ~= nil
	local sameInstance = inThisServer and presence.jobId == game.JobId
	return {
		canJoin = not sameInstance,
		reason = if sameInstance then "Already on the same server" else nil,
		friendUserId = friendUserId,
		displayName = displayName,
		placeKey = presence.placeKey,
		placeDisplayName = presence.placeDisplayName,
		inThisServer = inThisServer,
		sameInstance = sameInstance,
	}
end

function DeathValleyFriendJoinService.getJoinPreview(player: Player, friendUserId: number): FriendJoinPreview
	local ok, err = verifyFriendship(player, friendUserId)
	if not ok then
		return {
			canJoin = false,
			reason = err,
			friendUserId = friendUserId,
			inThisServer = false,
			sameInstance = false,
		}
	end
	return buildPreview(player, friendUserId)
end

function DeathValleyFriendJoinService.teleportToFriend(player: Player, friendUserId: number): (boolean, string)
	local okFriend, friendErr = verifyFriendship(player, friendUserId)
	if not okFriend then
		return false, friendErr or "Not friends"
	end

	local lastJoinAt = player:GetAttribute("DV_LastFriendJoinAt")
	if typeof(lastJoinAt) == "number" and os.clock() - lastJoinAt < COOLDOWN_SECONDS then
		return false, "Friend join cooling down — wait a moment"
	end

	local preview = buildPreview(player, friendUserId)
	if not preview.canJoin then
		return false, preview.reason or "Cannot join friend right now"
	end

	local presence = DeathValleyFriendPresenceService.getPresence(friendUserId)
	if not presence then
		return false, "Friend presence expired — try again"
	end

	local placeKey = presence.placeKey :: PlaceTeleport.PlaceKey
	local placeId = PlaceTeleport:GetPlaceId(placeKey)
	if not placeId or placeId <= 0 then
		return false, "Friend's city is not configured — edit PlaceSecrets.luau"
	end

	if presence.jobId == game.JobId then
		return false, "Already on the same server as your friend"
	end

	player:SetAttribute("DV_LastFriendJoinAt", os.clock())
	local teleportOk, teleportErr = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, presence.jobId, { player }, nil, {
			dvFriendJoin = {
				friendUserId = friendUserId,
				friendDisplayName = preview.displayName,
				placeDisplayName = preview.placeDisplayName,
			},
		})
	end)
	if not teleportOk then
		return false, tostring(teleportErr)
	end
	return true, string.format("Teleporting to %s in %s...", preview.displayName or "friend", preview.placeDisplayName or placeKey)
end

function DeathValleyFriendJoinService.handleArrival(player: Player)
	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData
	if typeof(teleportData) ~= "table" or typeof(teleportData.dvFriendJoin) ~= "table" then
		return
	end
	local payload = teleportData.dvFriendJoin
	local friendName = if typeof(payload.friendDisplayName) == "string"
		then payload.friendDisplayName
		else "your friend"
	local placeName = if typeof(payload.placeDisplayName) == "string"
		then payload.placeDisplayName
		else "Utopia"
	player:SetAttribute("DV_FriendJoinMsg", string.format("Joined %s in %s", friendName, placeName))
end

return DeathValleyFriendJoinService
