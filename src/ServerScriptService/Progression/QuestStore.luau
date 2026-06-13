--!strict
--[[
	QuestStore — DataStore daily quest progress per player
]]
local DataStoreService = game:GetService("DataStoreService")

export type QuestProgress = {
	questId: string,
	progress: number,
	completed: boolean,
	claimed: boolean,
}

export type PlayerQuestData = {
	dateKey: string,
	quests: { QuestProgress },
}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaQuest_v1")
end)

local memory: { [number]: PlayerQuestData } = {}

local function emptyData(): PlayerQuestData
	return { dateKey = "", quests = {} }
end

local function cloneData(data: PlayerQuestData): PlayerQuestData
	local quests: { QuestProgress } = {}
	for _, q in data.quests do
		table.insert(quests, {
			questId = q.questId,
			progress = q.progress,
			completed = q.completed,
			claimed = q.claimed,
		})
	end
	return { dateKey = data.dateKey, quests = quests }
end

local QuestStore = {}

function QuestStore.get(userId: number): PlayerQuestData
	if memory[userId] then
		return cloneData(memory[userId])
	end
	if not ds then
		return emptyData()
	end
	local ok, result = pcall(function()
		return (ds :: GlobalDataStore):GetAsync("quest_" .. tostring(userId))
	end)
	if ok and typeof(result) == "table" then
		local data = result :: PlayerQuestData
		memory[userId] = cloneData(data)
		return cloneData(data)
	end
	return emptyData()
end

function QuestStore.save(userId: number, data: PlayerQuestData)
	memory[userId] = cloneData(data)
	if not ds then
		return
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):SetAsync("quest_" .. tostring(userId), cloneData(data))
	end)
	if not ok then
		warn("[QuestStore] save failed:", err)
	end
end

return QuestStore
