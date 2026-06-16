--!strict
--[[
	RaceLeaderboardStore — best time ต่อ track ต่อผู้เล่น (DataStore + memory fallback)
]]
local DataStoreService = game:GetService("DataStoreService")

local RaceLeaderboardStore = {}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaRaceBest_v1")
end)

-- memory[userId][trackId] = bestSeconds
local memory: { [number]: { [string]: number } } = {}

local function key(userId: number, trackId: string): string
	return string.format("best_%d_%s", userId, trackId)
end

function RaceLeaderboardStore.getBest(userId: number, trackId: string): number?
	local m = memory[userId]
	if m and m[trackId] ~= nil then
		return m[trackId]
	end
	if not ds then
		return nil
	end
	local ok, value = pcall(function()
		return (ds :: GlobalDataStore):GetAsync(key(userId, trackId))
	end)
	if ok and typeof(value) == "number" then
		memory[userId] = memory[userId] or {}
		memory[userId][trackId] = value
		return value
	end
	return nil
end

-- บันทึกเฉพาะเมื่อเร็วกว่าเดิม; คืน true ถ้าเป็น best ใหม่
function RaceLeaderboardStore.saveBest(userId: number, trackId: string, timeSeconds: number): boolean
	local current = RaceLeaderboardStore.getBest(userId, trackId)
	if current ~= nil and current <= timeSeconds then
		return false
	end
	memory[userId] = memory[userId] or {}
	memory[userId][trackId] = timeSeconds
	if ds then
		task.spawn(function()
			pcall(function()
				(ds :: GlobalDataStore):SetAsync(key(userId, trackId), timeSeconds)
			end)
		end)
	end
	return true
end

function RaceLeaderboardStore.clearUser(userId: number)
	memory[userId] = nil
end

return RaceLeaderboardStore
