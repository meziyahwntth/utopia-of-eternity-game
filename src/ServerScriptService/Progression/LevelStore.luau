--!strict
--[[
	LevelStore (Progression) — DataStore player level + XP
]]
local DataStoreService = game:GetService("DataStoreService")

export type LevelData = {
	level: number,
	xp: number,
}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaLevel_v1")
end)

local memory: { [number]: LevelData } = {}

local function defaultData(): LevelData
	return { level = 1, xp = 0 }
end

local function cloneData(data: LevelData): LevelData
	return { level = data.level, xp = data.xp }
end

local LevelStore = {}

function LevelStore.get(userId: number): LevelData
	if memory[userId] then
		return cloneData(memory[userId])
	end
	if not ds then
		return defaultData()
	end
	local ok, result = pcall(function()
		return (ds :: GlobalDataStore):GetAsync("lv_" .. tostring(userId))
	end)
	if ok and typeof(result) == "table" then
		local data = result :: LevelData
		memory[userId] = cloneData(data)
		return cloneData(data)
	end
	return defaultData()
end

function LevelStore.save(userId: number, data: LevelData)
	memory[userId] = cloneData(data)
	if not ds then
		return
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):SetAsync("lv_" .. tostring(userId), cloneData(data))
	end)
	if not ok then
		warn("[LevelStore] save failed:", err)
	end
end

return LevelStore
