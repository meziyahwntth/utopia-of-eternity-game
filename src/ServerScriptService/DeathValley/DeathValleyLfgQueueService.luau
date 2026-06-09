--!strict
--[[
	Phase F — Cross-server LFG queue matchmaking via MessagingService.
]]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))

export type QueueEntry = {
	userId: number,
	displayName: string,
	zoneId: string,
	jobId: string,
	placeId: number,
	enqueuedAt: number,
}

local DeathValleyLfgQueueService = {}

local TOPIC = "UtopiaDV_LFG_QUEUE_v1"
local MATCH_COOLDOWN = 3

local localQueue: { [string]: { [number]: QueueEntry } } = {}
local remoteQueue: { [string]: { [number]: QueueEntry } } = {}
local playerQueueZone: { [number]: string } = {}
local subscribed = false
local lastMatchAt: { [string]: number } = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local queueChanged = remotes:WaitForChild("LfgQueueStateChanged") :: RemoteEvent

local lfgServiceModule: any = nil

local function countEntries(map: { [number]: QueueEntry }?): number
	if not map then
		return 0
	end
	local total = 0
	for _ in map do
		total += 1
	end
	return total
end

local function getLfgService()
	if not lfgServiceModule then
		lfgServiceModule = require(script.Parent:WaitForChild("DeathValleyLfgService"))
	end
	return lfgServiceModule
end

local function ensureZoneTable(map: { [string]: { [number]: QueueEntry } }, zoneId: string)
	if not map[zoneId] then
		map[zoneId] = {}
	end
end

local function publish(action: string, payload: { [string]: any })
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = action,
				jobId = game.JobId,
				placeId = game.PlaceId,
				zoneId = payload.zoneId,
				entry = payload.entry,
				userId = payload.userId,
				matchId = payload.matchId,
				matchedUserIds = payload.matchedUserIds,
				anchorJobId = payload.anchorJobId,
				anchorPlaceId = payload.anchorPlaceId,
				anchorUserId = payload.anchorUserId,
			})
		end)
	end)
end

function DeathValleyLfgQueueService.ensureSubscribed()
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
				local zoneId = data.zoneId
				if typeof(zoneId) ~= "string" then
					return
				end
				ensureZoneTable(remoteQueue, zoneId)

				if data.action == "enqueue" and typeof(data.entry) == "table" then
					local entry = data.entry :: QueueEntry
					remoteQueue[zoneId][entry.userId] = entry
					DeathValleyLfgQueueService.broadcastState()
					tryMatchZone(zoneId)
				elseif data.action == "dequeue" and typeof(data.userId) == "number" then
					remoteQueue[zoneId][data.userId] = nil
					DeathValleyLfgQueueService.broadcastState()
				elseif data.action == "match" and typeof(data.matchedUserIds) == "table" then
					for _, uid in data.matchedUserIds do
						if typeof(uid) == "number" then
							remoteQueue[zoneId][uid] = nil
						end
					end
					if typeof(data.anchorJobId) == "string" and data.anchorJobId ~= game.JobId then
						local matchPayload = {
							dvLfgQueueMatch = {
								zoneId = zoneId,
								matchId = data.matchId,
								members = data.matchedUserIds,
								anchorUserId = if typeof(data.anchorUserId) == "number"
									then data.anchorUserId
									elseif typeof(data.matchedUserIds[1]) == "number"
									then data.matchedUserIds[1]
									else nil,
							},
						}
						for _, uid in data.matchedUserIds do
							if typeof(uid) == "number" and playerQueueZone[uid] == zoneId then
								removeLocal(uid, zoneId)
								local member = Players:GetPlayerByUserId(uid)
								if member and typeof(data.anchorPlaceId) == "number" then
									member:SetAttribute("DV_LfgMatchMsg", "Match found — teleporting to party...")
									teleportToAnchor(member, data.anchorPlaceId, data.anchorJobId, matchPayload)
								end
							end
						end
					end
					DeathValleyLfgQueueService.broadcastState()
				end
			end)
		end)
		if not ok then
			warn("[DeathValley] LFG queue MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

local function collectMerged(zoneId: string): { QueueEntry }
	local merged: { QueueEntry } = {}
	ensureZoneTable(localQueue, zoneId)
	ensureZoneTable(remoteQueue, zoneId)
	for _, entry in localQueue[zoneId] do
		table.insert(merged, entry)
	end
	for _, entry in remoteQueue[zoneId] do
		table.insert(merged, entry)
	end
	table.sort(merged, function(a, b)
		return a.enqueuedAt < b.enqueuedAt
	end)
	return merged
end

function DeathValleyLfgQueueService.getQueueSnapshot(): { [string]: any }
	local snapshot: { [string]: any } = {}
	for _, zone in PrismDeathValleyDungeonConfig.Zones do
		local merged = collectMerged(zone.id)
		snapshot[zone.id] = {
			zoneId = zone.id,
			displayName = zone.displayName,
			needed = zone.nominalTeamSize,
			waiting = #merged,
			localWaiting = countEntries(localQueue[zone.id]),
		}
	end
	return snapshot
end

function DeathValleyLfgQueueService.broadcastState()
	queueChanged:FireAllClients({
		queues = DeathValleyLfgQueueService.getQueueSnapshot(),
	})
end

local function removeLocal(userId: number, zoneId: string)
	if localQueue[zoneId] then
		localQueue[zoneId][userId] = nil
	end
	playerQueueZone[userId] = nil
	local player = Players:GetPlayerByUserId(userId)
	if player then
		player:SetAttribute("DV_LfgQueueZoneId", nil)
	end
	publish("dequeue", { zoneId = zoneId, userId = userId })
end

local function teleportToAnchor(player: Player, anchorPlaceId: number, anchorJobId: string, matchPayload: { [string]: any })
	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(anchorPlaceId, anchorJobId, { player }, nil, matchPayload)
	end)
	if not ok then
		warn("[DeathValley] LFG queue teleport failed:", err)
		player:SetAttribute("DV_LfgMatchMsg", tostring(err))
	end
end

local function tryMatchZone(zoneId: string)
	local zone = PrismDeathValleyDungeonConfig.getZone(zoneId)
	if not zone then
		return
	end
	if os.clock() - (lastMatchAt[zoneId] or 0) < MATCH_COOLDOWN then
		return
	end

	local merged = collectMerged(zoneId)
	while #merged >= zone.nominalTeamSize do
		local batch: { QueueEntry } = {}
		for i = 1, zone.nominalTeamSize do
			table.insert(batch, merged[i])
		end

		local anchor = batch[1]
		local matchId = HttpService:GenerateGUID(false)
		local matchedUserIds: { number } = {}
		for _, entry in batch do
			table.insert(matchedUserIds, entry.userId)
		end

		lastMatchAt[zoneId] = os.clock()

		for _, entry in batch do
			removeLocal(entry.userId, zoneId)
			if remoteQueue[zoneId] then
				remoteQueue[zoneId][entry.userId] = nil
			end
		end

		publish("match", {
			zoneId = zoneId,
			matchId = matchId,
			matchedUserIds = matchedUserIds,
			anchorJobId = anchor.jobId,
			anchorPlaceId = anchor.placeId,
			anchorUserId = anchor.userId,
		})

		local matchPayload = {
			dvLfgQueueMatch = {
				zoneId = zoneId,
				matchId = matchId,
				members = matchedUserIds,
				anchorUserId = anchor.userId,
			},
		}

		if anchor.jobId == game.JobId then
			local owner = Players:GetPlayerByUserId(anchor.userId)
			if owner then
				local ok, msg = getLfgService().createMatchedListing(owner, zoneId, matchedUserIds)
				for _, uid in matchedUserIds do
					local member = Players:GetPlayerByUserId(uid)
					if member then
						member:SetAttribute("DV_LfgQueueMatched", true)
						member:SetAttribute("DV_LfgMatchMsg", if ok then "Match found — party ready!" else msg)
					end
				end
			end
		else
			for _, entry in batch do
				if entry.jobId == game.JobId then
					local batchPlayer = Players:GetPlayerByUserId(entry.userId)
					if batchPlayer then
						batchPlayer:SetAttribute("DV_LfgMatchMsg", "Match found — teleporting to party...")
						teleportToAnchor(batchPlayer, anchor.placeId, anchor.jobId, matchPayload)
					end
				end
			end
		end

		merged = collectMerged(zoneId)
	end
end

function DeathValleyLfgQueueService.enqueue(player: Player, zoneId: string): (boolean, string)
	local zone = PrismDeathValleyDungeonConfig.getZone(zoneId)
	if not zone then
		return false, "Unknown zone"
	end

	DeathValleyLfgQueueService.ensureSubscribed()

	if playerQueueZone[player.UserId] then
		DeathValleyLfgQueueService.dequeue(player)
	end

	ensureZoneTable(localQueue, zoneId)
	local entry: QueueEntry = {
		userId = player.UserId,
		displayName = player.DisplayName,
		zoneId = zoneId,
		jobId = game.JobId,
		placeId = game.PlaceId,
		enqueuedAt = os.time(),
	}
	localQueue[zoneId][player.UserId] = entry
	playerQueueZone[player.UserId] = zoneId
	player:SetAttribute("DV_LfgQueueZoneId", zoneId)
	player:SetAttribute("DV_LfgMatchMsg", string.format("Queued for %s...", zone.displayName))

	publish("enqueue", { zoneId = zoneId, entry = entry })
	DeathValleyLfgQueueService.broadcastState()
	tryMatchZone(zoneId)

	local waiting = #collectMerged(zoneId)
	return true, string.format("In queue — %s (%d/%d waiting globally)", zone.displayName, waiting, zone.nominalTeamSize)
end

function DeathValleyLfgQueueService.dequeue(player: Player): (boolean, string)
	local zoneId = playerQueueZone[player.UserId]
	if not zoneId then
		return false, "Not in queue"
	end
	removeLocal(player.UserId, zoneId)
	player:SetAttribute("DV_LfgMatchMsg", "Left matchmaking queue")
	DeathValleyLfgQueueService.broadcastState()
	return true, "Left queue"
end

function DeathValleyLfgQueueService.handleArrival(player: Player)
	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData
	if typeof(teleportData) ~= "table" or typeof(teleportData.dvLfgQueueMatch) ~= "table" then
		return
	end
	local match = teleportData.dvLfgQueueMatch
	if typeof(match.zoneId) ~= "string" or typeof(match.members) ~= "table" then
		return
	end
	task.defer(function()
		local ok, msg = getLfgService().joinMatchedListing(player, match.zoneId, match.members, match.anchorUserId)
		player:SetAttribute("DV_LfgMatchMsg", msg)
		if not ok then
			warn("[DeathValley] LFG match arrival:", msg)
		end
	end)
end

function DeathValleyLfgQueueService.onPlayerRemoving(player: Player)
	if playerQueueZone[player.UserId] then
		DeathValleyLfgQueueService.dequeue(player)
	end
end

return DeathValleyLfgQueueService
