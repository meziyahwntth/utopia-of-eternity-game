--!strict
--[[
	Phase H — Friend-list LFG invites via Players:GetFriendsAsync.
	Phase N — Cross-place online status + city name.
]]

local Players = game:GetService("Players")

local DeathValleyFriendPresenceService = require(script.Parent:WaitForChild("DeathValleyFriendPresenceService"))
local DeathValleyLfgInviteService = require(script.Parent:WaitForChild("DeathValleyLfgInviteService"))

export type FriendEntry = {
	userId: number,
	username: string,
	displayName: string,
	inThisServer: boolean,
	online: boolean,
	placeKey: string?,
	placeDisplayName: string?,
}

local DeathValleyLfgFriendsService = {}

local MAX_FRIENDS = 50

function DeathValleyLfgFriendsService.getFriendsList(player: Player): { FriendEntry }
	local entries: { FriendEntry } = {}
	local inServer: { [number]: boolean } = {}
	for _, other in Players:GetPlayers() do
		inServer[other.UserId] = true
	end

	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if not ok or not pages then
		return entries
	end

	local friendIds: { number } = {}
	local nameById: { [number]: { username: string, displayName: string } } = {}
	local collected = 0
	while collected < MAX_FRIENDS do
		for _, item in pages:GetCurrentPage() do
			table.insert(friendIds, item.Id)
			nameById[item.Id] = { username = item.Username, displayName = item.DisplayName }
			collected += 1
			if collected >= MAX_FRIENDS then
				break
			end
		end
		if collected >= MAX_FRIENDS or pages.IsFinished then
			break
		end
		local advanced, err = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advanced then
			warn("[DeathValley] Friends list pagination failed:", err)
			break
		end
	end

	local presenceBatch = DeathValleyFriendPresenceService.getPresenceBatch(friendIds)
	for _, userId in friendIds do
		local inThisServer = inServer[userId] == true
		local presence = presenceBatch[userId]
		local names = nameById[userId]
		table.insert(entries, {
			userId = userId,
			username = if names then names.username else "",
			displayName = if names then names.displayName else "",
			inThisServer = inThisServer,
			online = inThisServer or presence ~= nil,
			placeKey = if presence then presence.placeKey else nil,
			placeDisplayName = if presence then presence.placeDisplayName else nil,
		})
	end

	return entries
end

function DeathValleyLfgFriendsService.sendFriendInvite(sender: Player, targetUserId: number): (boolean, string)
	if targetUserId == sender.UserId then
		return false, "Cannot invite yourself"
	end
	local ok, isFriend = pcall(function()
		return sender:IsFriendsWith(targetUserId)
	end)
	if not ok or not isFriend then
		return false, "Player is not on your friends list"
	end
	return DeathValleyLfgInviteService.sendInvite(sender, targetUserId)
end

return DeathValleyLfgFriendsService
