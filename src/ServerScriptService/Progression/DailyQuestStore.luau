--!strict
--[[
	Festival Phase 2 — Daily Quest DataStore (follows PrismKeyPlayerStore pattern)
	Key: UtopiaDailyQuests_v1 — separate from all other DataStore keys
]]
local DataStoreService = game:GetService("DataStoreService")

export type QuestProgress = {
	id: string,
	progress: number,
	goal: number,
	claimed: boolean,
}

export type QuestSaveData = {
	dateDay: number,
	assignedQuests: { QuestProgress },
	completedAll: boolean,
	version: number,
}

local DailyQuestStore = {}

local STORE_NAME = "UtopiaDailyQuests_v1"
local SAVE_VERSION = 1

local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
local memoryCache: { [number]: QuestSaveData } = {}

local function keyFor(userId: number): string
	return "player:" .. tostring(userId)
end

function DailyQuestStore.load(userId: number): QuestSaveData?
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
		local qd = data :: QuestSaveData
		memoryCache[userId] = qd
		return qd
	end
	return nil
end

function DailyQuestStore.save(userId: number, payload: QuestSaveData): boolean
	payload.version = SAVE_VERSION
	memoryCache[userId] = payload
	if not store then
		return true
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), payload)
	end)
	if not ok then
		warn("[DailyQuest] DataStore save failed:", err)
		return false
	end
	return true
end

function DailyQuestStore.clearMemory(userId: number)
	memoryCache[userId] = nil
end

return DailyQuestStore