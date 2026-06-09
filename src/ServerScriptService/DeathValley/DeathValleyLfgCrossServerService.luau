--!strict
--[[
	Phase E — Cross-server LFG via MessagingService.
]]

local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")

export type CrossLfgListing = {
	id: string,
	ownerUserId: number,
	ownerName: string,
	zoneId: string,
	displayName: string,
	nominalTeamSize: number,
	needed: number,
	memberCount: number,
	jobId: string,
	placeId: number,
	crossServer: boolean,
	updatedAt: number,
}

local DeathValleyLfgCrossServerService = {}

local TOPIC = "UtopiaDV_LFG_v1"
local remoteListings: { [string]: CrossLfgListing } = {}
local subscribed = false

local function pruneExpired()
	local now = os.clock()
	for id, listing in remoteListings do
		if now - listing.updatedAt > 120 then
			remoteListings[id] = nil
		end
	end
end

function DeathValleyLfgCrossServerService.ensureSubscribed()
	if subscribed then
		return
	end
	subscribed = true
	task.spawn(function()
		local ok, conn = pcall(function()
			return MessagingService:SubscribeAsync(TOPIC, function(message)
				local data = message.Data
				if typeof(data) ~= "table" then
					return
				end
				if data.jobId == game.JobId then
					return
				end
				if data.action == "remove" and typeof(data.id) == "string" then
					remoteListings[data.id] = nil
					return
				end
				if data.action == "upsert" and typeof(data.listing) == "table" then
					local listing = data.listing :: CrossLfgListing
					listing.crossServer = true
					listing.updatedAt = os.clock()
					remoteListings[listing.id] = listing
				end
			end)
		end)
		if not ok then
			warn("[DeathValley] LFG MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		elseif conn then
			conn:Disconnect()
		end
	end)
end

function DeathValleyLfgCrossServerService.publishListing(payload: {
	id: string,
	ownerUserId: number,
	ownerName: string,
	zoneId: string,
	displayName: string,
	nominalTeamSize: number,
	needed: number,
	memberCount: number,
})
	DeathValleyLfgCrossServerService.ensureSubscribed()
	local listing: CrossLfgListing = {
		id = payload.id,
		ownerUserId = payload.ownerUserId,
		ownerName = payload.ownerName,
		zoneId = payload.zoneId,
		displayName = payload.displayName,
		nominalTeamSize = payload.nominalTeamSize,
		needed = payload.needed,
		memberCount = payload.memberCount,
		jobId = game.JobId,
		placeId = game.PlaceId,
		crossServer = false,
		updatedAt = os.clock(),
	}
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = "upsert",
				jobId = game.JobId,
				listing = listing,
			})
		end)
	end)
end

function DeathValleyLfgCrossServerService.removeListing(listingId: string)
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = "remove",
				id = listingId,
				jobId = game.JobId,
			})
		end)
	end)
end

function DeathValleyLfgCrossServerService.getRemoteListings(): { CrossLfgListing }
	pruneExpired()
	local list: { CrossLfgListing } = {}
	for _, listing in remoteListings do
		table.insert(list, listing)
	end
	return list
end

function DeathValleyLfgCrossServerService.teleportToListing(player: Player, listing: CrossLfgListing): (boolean, string)
	if listing.jobId == game.JobId then
		return false, "Already on this server"
	end
	if listing.placeId <= 0 then
		return false, "Place not configured"
	end
	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(listing.placeId, listing.jobId, { player })
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, "Teleporting to party server..."
end

return DeathValleyLfgCrossServerService
