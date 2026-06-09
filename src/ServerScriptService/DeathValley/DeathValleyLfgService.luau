--!strict
--[[
	Phase D/E/F — LFG listings, cross-server merge, queue match party formation.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))
local DeathValleyLfgCrossServerService = require(script.Parent:WaitForChild("DeathValleyLfgCrossServerService"))

export type LfgListing = {
	id: string,
	ownerUserId: number,
	ownerName: string,
	zoneId: string,
	displayName: string,
	nominalTeamSize: number,
	needed: number,
	members: { number },
	createdAt: number,
	crossServer: boolean?,
	jobId: string?,
	placeId: number?,
	matchMade: boolean?,
}

local DeathValleyLfgService = {}

local listings: { [string]: LfgListing } = {}
local playerListing: { [number]: string } = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local lfgChanged = remotes:WaitForChild("LfgListingsChanged") :: RemoteEvent

DeathValleyLfgCrossServerService.ensureSubscribed()

local function buildPayload(): { LfgListing | DeathValleyLfgCrossServerService.CrossLfgListing }
	local payload: { any } = {}
	for _, listing in listings do
		table.insert(payload, listing)
	end
	for _, remote in DeathValleyLfgCrossServerService.getRemoteListings() do
		table.insert(payload, remote)
	end
	return payload
end

local function broadcast()
	lfgChanged:FireAllClients(buildPayload())
end

local function syncCrossServer(listing: LfgListing)
	DeathValleyLfgCrossServerService.publishListing({
		id = listing.id,
		ownerUserId = listing.ownerUserId,
		ownerName = listing.ownerName,
		zoneId = listing.zoneId,
		displayName = listing.displayName,
		nominalTeamSize = listing.nominalTeamSize,
		needed = listing.needed,
		memberCount = #listing.members,
	})
end

local function assignPlayerToListing(player: Player, listing: LfgListing)
	playerListing[player.UserId] = listing.id
	player:SetAttribute("DV_LfgListingId", listing.id)
	player:SetAttribute("DV_LfgZoneId", listing.zoneId)
end

local function findListingByOwner(ownerUserId: number, zoneId: string): LfgListing?
	for _, listing in listings do
		if listing.ownerUserId == ownerUserId and listing.zoneId == zoneId then
			return listing
		end
	end
	return nil
end

function DeathValleyLfgService.getListings(): { any }
	return buildPayload()
end

function DeathValleyLfgService.postListing(player: Player, zoneId: string): (boolean, string)
	local zone = PrismDeathValleyDungeonConfig.getZone(zoneId)
	if not zone then
		return false, "Unknown zone"
	end
	if playerListing[player.UserId] then
		DeathValleyLfgService.leaveListing(player)
	end

	local id = HttpService:GenerateGUID(false)
	local listing: LfgListing = {
		id = id,
		ownerUserId = player.UserId,
		ownerName = player.DisplayName,
		zoneId = zoneId,
		displayName = zone.displayName,
		nominalTeamSize = zone.nominalTeamSize,
		needed = zone.nominalTeamSize,
		members = { player.UserId },
		createdAt = os.clock(),
		crossServer = false,
		matchMade = false,
	}
	listings[id] = listing
	assignPlayerToListing(player, listing)
	syncCrossServer(listing)
	broadcast()
	return true, string.format("LFG posted — %s (%d players)", zone.displayName, zone.nominalTeamSize)
end

function DeathValleyLfgService.createMatchedListing(owner: Player, zoneId: string, memberUserIds: { number }): (boolean, string)
	local zone = PrismDeathValleyDungeonConfig.getZone(zoneId)
	if not zone then
		return false, "Unknown zone"
	end
	if playerListing[owner.UserId] then
		DeathValleyLfgService.leaveListing(owner)
	end

	local members: { number } = {}
	local seen: { [number]: boolean } = {}
	for _, uid in memberUserIds do
		if not seen[uid] and Players:GetPlayerByUserId(uid) then
			seen[uid] = true
			table.insert(members, uid)
		end
	end
	if not seen[owner.UserId] then
		table.insert(members, owner.UserId)
	end

	local id = HttpService:GenerateGUID(false)
	local listing: LfgListing = {
		id = id,
		ownerUserId = owner.UserId,
		ownerName = owner.DisplayName,
		zoneId = zoneId,
		displayName = zone.displayName,
		nominalTeamSize = zone.nominalTeamSize,
		needed = zone.nominalTeamSize,
		members = members,
		createdAt = os.clock(),
		crossServer = false,
		matchMade = true,
	}
	listings[id] = listing
	for _, uid in members do
		local member = Players:GetPlayerByUserId(uid)
		if member then
			assignPlayerToListing(member, listing)
		end
	end
	syncCrossServer(listing)
	broadcast()
	return true, string.format("Match party — %s (%d/%d)", zone.displayName, #members, zone.nominalTeamSize)
end

function DeathValleyLfgService.joinMatchedListing(
	player: Player,
	zoneId: string,
	memberUserIds: { number },
	anchorUserId: number?
): (boolean, string)
	local anchorId = anchorUserId or player.UserId
	local listing = findListingByOwner(anchorId, zoneId)
	if not listing then
		if anchorId == player.UserId then
			return DeathValleyLfgService.createMatchedListing(player, zoneId, memberUserIds)
		end
		return false, "Waiting for party host..."
	end

	for _, uid in listing.members do
		if uid == player.UserId then
			return true, "Already in matched party"
		end
	end
	if #listing.members >= listing.needed then
		return false, "Party full"
	end

	table.insert(listing.members, player.UserId)
	assignPlayerToListing(player, listing)
	syncCrossServer(listing)
	broadcast()
	return true, string.format("Joined match — %s (%d/%d)", listing.displayName, #listing.members, listing.needed)
end

function DeathValleyLfgService.joinListing(player: Player, listingId: string): (boolean, string)
	local listing = listings[listingId]
	if listing then
		for _, uid in listing.members do
			if uid == player.UserId then
				return true, "Already in party"
			end
		end
		if #listing.members >= listing.needed then
			return false, "Party full"
		end
		table.insert(listing.members, player.UserId)
		assignPlayerToListing(player, listing)
		syncCrossServer(listing)
		broadcast()
		return true, string.format("Joined %s (%d/%d)", listing.displayName, #listing.members, listing.needed)
	end

	for _, remote in DeathValleyLfgCrossServerService.getRemoteListings() do
		if remote.id == listingId then
			return DeathValleyLfgCrossServerService.teleportToListing(player, remote)
		end
	end

	return false, "Listing not found"
end

function DeathValleyLfgService.leaveListing(player: Player): (boolean, string)
	local listingId = playerListing[player.UserId]
	if not listingId then
		return false, "Not in a listing"
	end
	local listing = listings[listingId]
	if not listing then
		playerListing[player.UserId] = nil
		player:SetAttribute("DV_LfgListingId", nil)
		return true, "Left listing"
	end

	for i, uid in listing.members do
		if uid == player.UserId then
			table.remove(listing.members, i)
			break
		end
	end
	playerListing[player.UserId] = nil
	player:SetAttribute("DV_LfgListingId", nil)
	player:SetAttribute("DV_LfgZoneId", nil)

	if #listing.members == 0 or listing.ownerUserId == player.UserId then
		listings[listingId] = nil
		DeathValleyLfgCrossServerService.removeListing(listingId)
		for uid, lid in playerListing do
			if lid == listingId then
				playerListing[uid] = nil
				local p = Players:GetPlayerByUserId(uid)
				if p then
					p:SetAttribute("DV_LfgListingId", nil)
					p:SetAttribute("DV_LfgZoneId", nil)
				end
			end
		end
	else
		syncCrossServer(listing)
	end
	broadcast()
	return true, "Left LFG listing"
end

function DeathValleyLfgService.onPlayerRemoving(player: Player)
	if playerListing[player.UserId] then
		DeathValleyLfgService.leaveListing(player)
	end
end

function DeathValleyLfgService.getOwnerListing(player: Player): LfgListing?
	local listingId = playerListing[player.UserId]
	if not listingId then
		return nil
	end
	local listing = listings[listingId]
	if listing and listing.ownerUserId == player.UserId then
		return listing
	end
	return nil
end

function DeathValleyLfgService.getPlayerListingId(player: Player): string?
	return playerListing[player.UserId]
end

return DeathValleyLfgService
