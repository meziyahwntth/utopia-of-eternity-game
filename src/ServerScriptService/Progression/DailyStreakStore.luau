--!strict
--[[
	Festival Phase 2 — Daily Streak DataStore (follows PrismKeyPlayerStore pattern)
	Key: UtopiaDailyStreak_v1 — separate from PrismKeys and DeathValley stores
]]
local DataStoreService = game:GetService("DataStoreService")

export type StreakData = {
	lastLoginDay: number,
	streak: number,
	claimedDays: { [number]: boolean },
	version: number,
}

local DailyStreakStore = {}

local STORE_NAME = "UtopiaDailyStreak_v1"
local SAVE_VERSION = 1

local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
local memoryCache: { [number]: StreakData } = {}

local function keyFor(userId: number): string
	return "player:" .. tostring(userId)
end

function DailyStreakStore.load(userId: number): StreakData?
	if memoryCache[userId] then
		return memoryCache[userId]
	end
	if not store then
		return nil
	end
	local ok, data = pcall(function()
		return store:GetAsync(keyFor(userId))
	end)
	if ok and typeof(data) == "table" then
		local sd = data :: StreakData
		memoryCache[userId] = sd
		return sd
	end
	return nil
end

function DailyStreakStore.save(userId: number, payload: StreakData): boolean
	payload.version = SAVE_VERSION
	memoryCache[userId] = payload
	if not store then
		return true
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), payload)
	end)
	if not ok then
		warn("[DailyStreak] DataStore save failed:", err)
		return false
	end
	return true
end

function DailyStreakStore.createDefault(userId: number): StreakData
	return {
		lastLoginDay = 0,
		streak = 0,
		claimedDays = {},
		version = SAVE_VERSION,
	}
end

function DailyStreakStore.clearMemory(userId: number)
	memoryCache[userId] = nil
end

return DailyStreakStore