--!strict
--[[
	TerritoryStore (P5) — DataStore wrapper for territory ownership + tax state
]]
local DataStoreService = game:GetService("DataStoreService")

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaTerritory_v1")
end)

export type MemberDividends = { [string]: number }

export type TerritoryData = {
	ownerClanId: string,
	taxRate: number,
	maintenanceCost: number,
	fortHp: number,
	weeksClaimed: number,
	lastWarCycleId: string,
	clanVaultBalance: number,
	memberDividends: MemberDividends,
	serverBuffActive: boolean,
	lastDistributedAt: number,
}

local memory: { [string]: TerritoryData } = {}

local function defaultTerritory(_zoneId: string): TerritoryData
	return {
		ownerClanId = "",
		taxRate = 1,
		maintenanceCost = 100,
		fortHp = 100,
		weeksClaimed = 0,
		lastWarCycleId = "",
		clanVaultBalance = 0,
		memberDividends = {},
		serverBuffActive = false,
		lastDistributedAt = os.time(),
	}
end

local TerritoryStore = {}

function TerritoryStore.get(zoneId: string): TerritoryData
	if memory[zoneId] then
		return memory[zoneId]
	end
	if ds then
		local ok, result = pcall(function()
			return (ds :: GlobalDataStore):GetAsync("territory_" .. zoneId)
		end)
		if ok and typeof(result) == "table" then
			local data = result :: TerritoryData
			memory[zoneId] = data
			return data
		end
	end
	local data = defaultTerritory(zoneId)
	memory[zoneId] = data
	return data
end

function TerritoryStore.save(zoneId: string, data: TerritoryData)
	memory[zoneId] = data
	if not ds then
		return
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):SetAsync("territory_" .. zoneId, data)
	end)
	if not ok then
		warn("[TerritoryStore] save failed:", err)
	end
end

return TerritoryStore
