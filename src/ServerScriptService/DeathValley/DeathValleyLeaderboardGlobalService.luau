--!strict
--[[
	Phase F — Season-scoped OrderedDataStore leaderboard with cross-place name cache.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))

export type LeaderboardEntry = {
	rank: number,
	userId: number?,
	displayName: string,
	nightsSurvived: number,
	seasonId: string,
}

local DeathValleyLeaderboardGlobalService = {}

local LEGACY_STORE_NAME = "UtopiaDV_NightsLeaderboard_v1"
local META_STORE_NAME = "UtopiaDV_LBMeta_v1"
local TOP_COUNT = 25

local legacyStore: OrderedDataStore? = nil
local metaStore: GlobalDataStore? = nil
pcall(function()
	legacyStore = DataStoreService:GetOrderedDataStore(LEGACY_STORE_NAME)
	metaStore = DataStoreService:GetDataStore(META_STORE_NAME)
end)

local seasonStores: { [string]: OrderedDataStore } = {}
local nameCache: { [number]: string } = {}

local function sanitizeSeasonId(seasonId: string): string
	local safe = string.gsub(seasonId, "[^%w%-]", "_")
	if #safe > 36 then
		safe = string.sub(safe, 1, 36)
	end
	return safe
end

local function getSeasonStore(seasonId: string): OrderedDataStore?
	if not legacyStore then
		return nil
	end
	local safe = sanitizeSeasonId(seasonId)
	if seasonStores[safe] then
		return seasonStores[safe]
	end
	local ok, ds = pcall(function()
		return DataStoreService:GetOrderedDataStore("UtopiaDV_LB_" .. safe)
	end)
	if ok and ds then
		seasonStores[safe] = ds
		return ds
	end
	return nil
end

local function legacyKey(seasonId: string, userId: number): string
	return seasonId .. ":" .. tostring(userId)
end

function DeathValleyLeaderboardGlobalService.cacheDisplayName(userId: number, displayName: string)
	nameCache[userId] = displayName
	if not metaStore then
		return
	end
	task.spawn(function()
		pcall(function()
			metaStore:SetAsync("n:" .. tostring(userId), {
				name = displayName,
				at = os.time(),
			})
		end)
	end)
end

local function resolveDisplayName(userId: number): string
	local live = Players:GetPlayerByUserId(userId)
	if live then
		return live.DisplayName
	end
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	if not metaStore then
		return "Survivor#" .. tostring(userId % 10000)
	end
	local ok, data = pcall(function()
		return metaStore:GetAsync("n:" .. tostring(userId))
	end)
	if ok and typeof(data) == "table" and typeof(data.name) == "string" then
		nameCache[userId] = data.name
		return data.name
	end
	return "Survivor#" .. tostring(userId % 10000)
end

function DeathValleyLeaderboardGlobalService.recordScore(player: Player, seasonId: string, nightsSurvived: number)
	if nightsSurvived <= 0 then
		return
	end

	DeathValleyLeaderboardGlobalService.cacheDisplayName(player.UserId, player.DisplayName)

	local seasonStore = getSeasonStore(seasonId)
	if not seasonStore then
		return
	end
	local userKey = tostring(player.UserId)

	task.spawn(function()
		local ok, err = pcall(function()
			seasonStore:SetAsync(userKey, nightsSurvived)
		end)
		if not ok then
			warn("[DeathValley] Global LB season write failed:", err)
		end

		if legacyStore then
			pcall(function()
				legacyStore:SetAsync(legacyKey(seasonId, player.UserId), nightsSurvived)
			end)
		end
	end)
end

function DeathValleyLeaderboardGlobalService.getPlayerScore(userId: number, seasonId: string): number?
	local seasonStore = getSeasonStore(seasonId)
	if not seasonStore then
		return nil
	end
	local ok, value = pcall(function()
		return seasonStore:GetAsync(tostring(userId))
	end)
	if ok and typeof(value) == "number" and value > 0 then
		return value
	end
	return nil
end

function DeathValleyLeaderboardGlobalService.computeRank(userId: number, seasonId: string, score: number): number?
	if score <= 0 then
		return nil
	end

	local seasonStore = getSeasonStore(seasonId)
	if not seasonStore then
		return nil
	end
	local ok, pages = pcall(function()
		return seasonStore:GetSortedAsync(false, 100)
	end)
	if not ok or not pages then
		return nil
	end

	local rank = 1
	local found = false
	while true do
		for _, item in pages:GetCurrentPage() do
			if item.value > score then
				rank += 1
			end
			if tostring(item.key) == tostring(userId) then
				found = true
				break
			end
		end
		if found or pages.IsFinished then
			break
		end
		local advanced, err = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advanced then
			warn("[DeathValley] Global LB rank pagination failed:", err)
			break
		end
	end

	if found or rank > 1 then
		return rank
	end
	return nil
end

function DeathValleyLeaderboardGlobalService.getTopEntries(seasonId: string?): { LeaderboardEntry }
	local sid = seasonId or DeathValleySeasonService.getCurrentSeasonId()
	local entries: { LeaderboardEntry } = {}
	local seasonStore = getSeasonStore(sid)
	if not seasonStore then
		return entries
	end

	local ok, pages = pcall(function()
		return seasonStore:GetSortedAsync(false, TOP_COUNT)
	end)
	if not ok or not pages then
		return entries
	end

	for _, item in pages:GetCurrentPage() do
		local userId = tonumber(item.key)
		table.insert(entries, {
			rank = #entries + 1,
			userId = userId,
			displayName = if userId then resolveDisplayName(userId) else "Unknown",
			nightsSurvived = item.value,
			seasonId = sid,
		})
		if #entries >= TOP_COUNT then
			break
		end
	end
	return entries
end

function DeathValleyLeaderboardGlobalService.toPublicPayload(player: Player?, seasonId: string?): { [string]: any }
	local sid = seasonId or DeathValleySeasonService.getCurrentSeasonId()
	local season = DeathValleySeasonService.getSeasonPayloadForId(sid)
	local entries = DeathValleyLeaderboardGlobalService.getTopEntries(sid)

	local myRank: number? = nil
	local myBest = 0
	if player then
		local dataScore = DeathValleyLeaderboardGlobalService.getPlayerScore(player.UserId, sid)
		if dataScore then
			myBest = dataScore
		end
		myRank = DeathValleyLeaderboardGlobalService.computeRank(player.UserId, sid, myBest)
		for _, entry in entries do
			if entry.userId == player.UserId then
				myRank = entry.rank
				break
			end
		end
	end

	return {
		season = season,
		entries = entries,
		myRank = myRank,
		myBestNights = myBest,
		globalSource = "OrderedDataStore",
		crossPlace = true,
		topCount = TOP_COUNT,
		isPastSeason = DeathValleySeasonService.isPastSeason(sid),
	}
end

return DeathValleyLeaderboardGlobalService
