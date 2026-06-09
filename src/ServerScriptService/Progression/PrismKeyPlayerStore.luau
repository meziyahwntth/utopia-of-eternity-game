--!strict
--[[
	P1 — Cross-place Prism Key persistence (owned keys, zone claims, milestones, pickups).
]]

local DataStoreService = game:GetService("DataStoreService")

export type PrismKeySaveData = {
	ownedKeys: { number }?,
	zoneClaims: { [string]: boolean }?,
	milestonesClaimed: { [string]: boolean }?,
	pickupsClaimed: { [string]: boolean }?,
	liveMirrorUnlocked: boolean?,
	milestonePending: number?,
	version: number,
}

local PrismKeyPlayerStore = {}

local STORE_NAME = "UtopiaPrismKeys_v1"
local SAVE_VERSION = 1

local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
local memoryCache: { [number]: PrismKeySaveData } = {}

local function keyFor(userId: number): string
	return "player:" .. tostring(userId)
end

function PrismKeyPlayerStore.load(userId: number): PrismKeySaveData?
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
		memoryCache[userId] = data :: PrismKeySaveData
		return data :: PrismKeySaveData
	end

	return nil
end

function PrismKeyPlayerStore.save(userId: number, payload: PrismKeySaveData): boolean
	payload.version = SAVE_VERSION
	memoryCache[userId] = payload

	if not store then
		return true
	end

	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), payload)
	end)

	if not ok then
		warn("[PrismKey] DataStore save failed:", err)
		return false
	end
	return true
end

function PrismKeyPlayerStore.clearCache(userId: number)
	memoryCache[userId] = nil
end

return PrismKeyPlayerStore
