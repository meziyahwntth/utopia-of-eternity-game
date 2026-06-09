--!strict
--[[
	Phase H — Top-25 auto-distribute at season rollover + pending delivery on join.
]]

local DataStoreService = game:GetService("DataStoreService")

local DeathValleyLeaderboardGlobalService = require(script.Parent:WaitForChild("DeathValleyLeaderboardGlobalService"))
local DeathValleySeasonRewardService = require(script.Parent:WaitForChild("DeathValleySeasonRewardService"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))

local DeathValleySeasonRolloverService = {}

local STATE_STORE = "UtopiaDV_RolloverState_v1"
local AUTO_REWARD_STORE = "UtopiaDV_AutoReward_v1"
local TOP_AUTO_COUNT = 25

local stateStore: GlobalDataStore? = nil
local autoRewardStore: GlobalDataStore? = nil
pcall(function()
	stateStore = DataStoreService:GetDataStore(STATE_STORE)
	autoRewardStore = DataStoreService:GetDataStore(AUTO_REWARD_STORE)
end)

local rolloverStarted = false
local endedSeasonIds: { [string]: boolean } = {}

local function loadGlobalState(): { activeSeasonId: string?, endedSeasonIds: { string }? }?
	if not stateStore then
		return nil
	end
	local ok, data = pcall(function()
		return stateStore:GetAsync("global")
	end)
	if ok and typeof(data) == "table" then
		if typeof(data.endedSeasonIds) == "table" then
			for _, seasonId in data.endedSeasonIds do
				if typeof(seasonId) == "string" then
					endedSeasonIds[seasonId] = true
				end
			end
		end
		return data
	end
	return nil
end

local function saveGlobalState(activeSeasonId: string, appendEnded: string?)
	local endedList: { string } = {}
	for seasonId in endedSeasonIds do
		table.insert(endedList, seasonId)
	end
	if appendEnded and not endedSeasonIds[appendEnded] then
		endedSeasonIds[appendEnded] = true
		table.insert(endedList, appendEnded)
	end
	if not stateStore then
		return
	end
	pcall(function()
		stateStore:SetAsync("global", {
			activeSeasonId = activeSeasonId,
			endedSeasonIds = endedList,
			updatedAt = os.time(),
		})
	end)
end

local function autoRewardKey(userId: number, seasonId: string): string
	return tostring(userId) .. ":" .. seasonId
end

local function loadActiveSeasonId(): string?
	local data = loadGlobalState()
	if data and typeof(data.activeSeasonId) == "string" then
		return data.activeSeasonId
	end
	return nil
end

local function queueAutoReward(userId: number, seasonId: string, rank: number, nights: number)
	if not autoRewardStore then
		return
	end
	pcall(function()
		autoRewardStore:SetAsync(autoRewardKey(userId, seasonId), {
			rank = rank,
			nights = nights,
			queuedAt = os.time(),
			auto = true,
		})
	end)
end

function DeathValleySeasonRolloverService.processSeasonEnd(endedSeasonId: string)
	local entries = DeathValleyLeaderboardGlobalService.getTopEntries(endedSeasonId)
	for _, entry in entries do
		if entry.userId and entry.rank <= TOP_AUTO_COUNT then
			queueAutoReward(entry.userId, endedSeasonId, entry.rank, entry.nightsSurvived)
		end
	end
	warn("[DeathValley] Season rollover processed:", endedSeasonId, "top", math.min(#entries, TOP_AUTO_COUNT))
end

function DeathValleySeasonRolloverService.tryProcessRollover()
	if rolloverStarted then
		return
	end
	rolloverStarted = true

	task.spawn(function()
		loadGlobalState()
		local current = DeathValleySeasonService.getCurrentSeasonId()
		local stored = loadActiveSeasonId()

		if not stored then
			saveGlobalState(current, nil)
			return
		end

		if stored == current then
			return
		end

		DeathValleySeasonRolloverService.processSeasonEnd(stored)
		saveGlobalState(current, stored)
	end)
end

function DeathValleySeasonRolloverService.deliverPendingForPlayer(player: Player)
	if not autoRewardStore then
		return
	end
	for _, season in DeathValleySeasonService.listHistoricalSeasons(12) do
		if season.isCurrent and not DeathValleySeasonRolloverService.isSeasonEnded(season.seasonId) then
			continue
		end
		local ok, pending = pcall(function()
			return autoRewardStore:GetAsync(autoRewardKey(player.UserId, season.seasonId))
		end)
		if not ok or typeof(pending) ~= "table" then
			continue
		end
		if pending.auto ~= true then
			continue
		end

		local rank = if typeof(pending.rank) == "number" then pending.rank else nil
		local nights = if typeof(pending.nights) == "number" then pending.nights else 0
		local granted, msg = DeathValleySeasonRewardService.grantAutoRolloverReward(
			player,
			season.seasonId,
			rank,
			nights
		)
		if granted then
			pcall(function()
				autoRewardStore:RemoveAsync(autoRewardKey(player.UserId, season.seasonId))
			end)
			player:SetAttribute("DV_RolloverRewardMsg", msg)
		end
	end
end

function DeathValleySeasonRolloverService.isSeasonEnded(seasonId: string): boolean
	if seasonId ~= DeathValleySeasonService.getCurrentSeasonId() then
		return true
	end
	return endedSeasonIds[seasonId] == true
end

function DeathValleySeasonRolloverService.toPublicPayload(): { [string]: any }
	return {
		activeSeasonId = DeathValleySeasonService.getCurrentSeasonId(),
		storedSeasonId = loadActiveSeasonId(),
		topAutoCount = TOP_AUTO_COUNT,
	}
end

function DeathValleySeasonRolloverService.adminForceRollover(): (boolean, string)
	local endedSeasonId = DeathValleySeasonService.getCurrentSeasonId()
	DeathValleySeasonRolloverService.processSeasonEnd(endedSeasonId)
	local nextSeasonId = DeathValleySeasonService.getNextSeasonId(endedSeasonId)
	saveGlobalState(nextSeasonId, endedSeasonId)
	return true, string.format("Studio rollover: ended %s → active %s (top %d queued)", endedSeasonId, nextSeasonId, TOP_AUTO_COUNT)
end

function DeathValleySeasonRolloverService.adminResetSeasonPointer(): (boolean, string)
	local current = DeathValleySeasonService.getCurrentSeasonId()
	table.clear(endedSeasonIds)
	pcall(function()
		stateStore:SetAsync("global", {
			activeSeasonId = current,
			endedSeasonIds = {},
			updatedAt = os.time(),
		})
	end)
	return true, "Season pointer reset to " .. current .. " (ended flags cleared)"
end

return DeathValleySeasonRolloverService
