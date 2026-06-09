--!strict
--[[
	Phase G — Direct LFG party invites (same-server + cross-server via MessagingService).
]]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

export type PendingInvite = {
	id: string,
	listingId: string,
	zoneId: string,
	fromUserId: number,
	fromName: string,
	jobId: string,
	placeId: number,
	expiresAt: number,
}

local DeathValleyLfgInviteService = {}

local TOPIC = "UtopiaDV_LFG_INVITE_v1"
local INVITE_TTL = 120

local pendingByTarget: { [number]: { [string]: PendingInvite } } = {}
local subscribed = false

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local inviteReceived = remotes:WaitForChild("LfgInviteReceived") :: RemoteEvent

local lfgServiceModule: any = nil

local function getLfgService()
	if not lfgServiceModule then
		lfgServiceModule = require(script.Parent:WaitForChild("DeathValleyLfgService"))
	end
	return lfgServiceModule
end

local function ensurePending(userId: number)
	if not pendingByTarget[userId] then
		pendingByTarget[userId] = {}
	end
end

local function pruneExpired(userId: number)
	local bucket = pendingByTarget[userId]
	if not bucket then
		return
	end
	local now = os.clock()
	for id, invite in bucket do
		if now > invite.expiresAt then
			bucket[id] = nil
		end
	end
end

local function deliverInvite(target: Player, invite: PendingInvite)
	ensurePending(target.UserId)
	pruneExpired(target.UserId)
	pendingByTarget[target.UserId][invite.id] = invite
	target:SetAttribute("DV_LfgInvitePending", true)
	inviteReceived:FireClient(target, invite)
end

function DeathValleyLfgInviteService.ensureSubscribed()
	if subscribed then
		return
	end
	subscribed = true
	task.spawn(function()
		local ok = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				local data = message.Data
				if typeof(data) ~= "table" or data.jobId == game.JobId then
					return
				end
				if data.action ~= "invite" or typeof(data.invite) ~= "table" then
					return
				end
				local invite = data.invite :: PendingInvite
				local targetUserId = if typeof(data.targetUserId) == "number"
					then data.targetUserId
					else nil
				if not targetUserId then
					return
				end
				local target = Players:GetPlayerByUserId(targetUserId)
				if target then
					deliverInvite(target, invite)
				end
			end)
		end)
		if not ok then
			warn("[DeathValley] LFG invite MessagingService subscribe failed")
			subscribed = false
		end
	end)
end

function DeathValleyLfgInviteService.getPendingInvites(player: Player): { PendingInvite }
	pruneExpired(player.UserId)
	local bucket = pendingByTarget[player.UserId]
	if not bucket then
		return {}
	end
	local list: { PendingInvite } = {}
	for _, invite in bucket do
		table.insert(list, invite)
	end
	return list
end

function DeathValleyLfgInviteService.sendInvite(sender: Player, targetUserId: number): (boolean, string)
	if targetUserId == sender.UserId then
		return false, "Cannot invite yourself"
	end
	local listing = getLfgService().getOwnerListing(sender)
	if not listing then
		return false, "Post a party listing first"
	end
	if #listing.members >= listing.needed then
		return false, "Party is full"
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if target and getLfgService().getPlayerListingId(target) then
		return false, "Player already in a party"
	end

	local invite: PendingInvite = {
		id = HttpService:GenerateGUID(false),
		listingId = listing.id,
		zoneId = listing.zoneId,
		fromUserId = sender.UserId,
		fromName = sender.DisplayName,
		jobId = game.JobId,
		placeId = game.PlaceId,
		expiresAt = os.clock() + INVITE_TTL,
	}

	if target then
		deliverInvite(target, invite)
		return true, string.format("Invite sent to %s", target.DisplayName)
	end

	DeathValleyLfgInviteService.ensureSubscribed()
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = "invite",
				jobId = game.JobId,
				targetUserId = targetUserId,
				invite = invite,
			})
		end)
	end)
	return true, "Invite sent (cross-server if online)"
end

function DeathValleyLfgInviteService.acceptInvite(player: Player, inviteId: string): (boolean, string)
	pruneExpired(player.UserId)
	local bucket = pendingByTarget[player.UserId]
	if not bucket or not bucket[inviteId] then
		return false, "Invite expired or not found"
	end
	local invite = bucket[inviteId]
	bucket[inviteId] = nil
	player:SetAttribute("DV_LfgInvitePending", false)

	if invite.jobId == game.JobId then
		return getLfgService().joinListing(player, invite.listingId)
	end

	if invite.placeId <= 0 then
		return false, "Party server unavailable"
	end

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(invite.placeId, invite.jobId, { player }, nil, {
			dvLfgInviteJoin = {
				listingId = invite.listingId,
				zoneId = invite.zoneId,
			},
		})
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, "Teleporting to party..."
end

function DeathValleyLfgInviteService.declineInvite(player: Player, inviteId: string): (boolean, string)
	local bucket = pendingByTarget[player.UserId]
	if not bucket or not bucket[inviteId] then
		return false, "Invite not found"
	end
	bucket[inviteId] = nil
	player:SetAttribute("DV_LfgInvitePending", false)
	return true, "Invite declined"
end

function DeathValleyLfgInviteService.handleArrival(player: Player)
	local teleportData = player:GetJoinData().TeleportData
	if typeof(teleportData) ~= "table" or typeof(teleportData.dvLfgInviteJoin) ~= "table" then
		return
	end
	local join = teleportData.dvLfgInviteJoin
	if typeof(join.listingId) ~= "string" then
		return
	end
	task.defer(function()
		local ok, msg = getLfgService().joinListing(player, join.listingId)
		player:SetAttribute("DV_LfgMatchMsg", msg)
		if not ok then
			warn("[DeathValley] LFG invite arrival:", msg)
		end
	end)
end

function DeathValleyLfgInviteService.onPlayerRemoving(player: Player)
	pendingByTarget[player.UserId] = nil
end

return DeathValleyLfgInviteService
