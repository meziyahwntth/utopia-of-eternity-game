--!strict
--[[
	Phase R — UGC-linked creator packs bound to live Bazaar listings.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLoadoutFeaturedRotationService =
	require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedRotationService"))
local DeathValleyLoadoutPresetMarketService =
	require(script.Parent:WaitForChild("DeathValleyLoadoutPresetMarketService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))

export type UgcPackRecord = {
	packId: string,
	listingId: string,
	authorUserId: number,
	authorDisplayName: string,
	displayName: string,
	description: string,
	robux: number,
	shareCode: string,
	cosmeticId: string?,
	titleSeasonId: string?,
	seasonTag: string?,
	createdAt: number,
}

local DeathValleyUgcCreatorPackService = {}

local UGC_MAP_NAME = "UtopiaDV_UgcCreatorPacks_v1"
local UGC_INDEX_NAME = "UtopiaDV_UgcCreatorPacksIndex_v1"
local UGC_TTL = 604800

local ugcMap: any = nil
local ugcIndex: any = nil
do
	local ok1, r1 = pcall(function()
		return MemoryStoreService:GetHashMap(UGC_MAP_NAME)
	end)
	if ok1 then
		ugcMap = r1
	else
		warn("[DeathValley] MemoryStore GetHashMap failed (UgcCreatorPackService/ugcMap):", r1)
	end

	local ok2, r2 = pcall(function()
		return MemoryStoreService:GetSortedMap(UGC_INDEX_NAME)
	end)
	if ok2 then
		ugcIndex = r2
	else
		warn("[DeathValley] MemoryStore GetSortedMap failed (UgcCreatorPackService/ugcIndex):", r2)
	end
end

local function getUgcConfig(): any
	local dv = GameConfig.DeathValley :: any
	if dv and typeof(dv.UgcCreatorPack) == "table" then
		return dv.UgcCreatorPack
	end
	return {}
end

function DeathValleyUgcCreatorPackService.getMinRobux(): number
	local config = getUgcConfig()
	if typeof(config.minRobux) == "number" and config.minRobux > 0 then
		return math.floor(config.minRobux)
	end
	return 49
end

function DeathValleyUgcCreatorPackService.getMaxRobux(): number
	local config = getUgcConfig()
	if typeof(config.maxRobux) == "number" and config.maxRobux > 0 then
		return math.floor(config.maxRobux)
	end
	return 499
end

function DeathValleyUgcCreatorPackService.getMaxLinkedPerPlayer(): number
	local config = getUgcConfig()
	if typeof(config.maxLinkedPerPlayer) == "number" and config.maxLinkedPerPlayer > 0 then
		return math.floor(config.maxLinkedPerPlayer)
	end
	return 3
end

function DeathValleyUgcCreatorPackService.getPriceTiers(): { number }
	local config = getUgcConfig()
	if typeof(config.priceTiers) == "table" and #config.priceTiers > 0 then
		return config.priceTiers
	end
	return { 49, 99, 149, 199, 249, 299, 399, 499 }
end

function DeathValleyUgcCreatorPackService.getPackIdPrefix(): string
	return PrismPresetPackCatalog.UGC_PACK_PREFIX
end

function DeathValleyUgcCreatorPackService.isUgcPackId(packId: string): boolean
	return PrismPresetPackCatalog.isUgcPackId(packId)
end

function DeathValleyUgcCreatorPackService.makePackId(listingId: string): string
	local compact = string.gsub(listingId, "-", "")
	return PrismPresetPackCatalog.UGC_PACK_PREFIX .. string.sub(compact, 1, 16)
end

function DeathValleyUgcCreatorPackService.getRecord(packId: string): UgcPackRecord?
	local ok, record = pcall(function()
		return ugcMap:GetAsync(packId)
	end)
	if ok and typeof(record) == "table" then
		return record :: UgcPackRecord
	end
	return nil
end

function DeathValleyUgcCreatorPackService.getRecordByListingId(listingId: string): UgcPackRecord?
	return DeathValleyUgcCreatorPackService.getRecord(DeathValleyUgcCreatorPackService.makePackId(listingId))
end

function DeathValleyUgcCreatorPackService.listLinkedForAuthor(userId: number): { UgcPackRecord }
	local linked = DeathValleyPlayerStore.listLinkedUgcPackIds(userId)
	local result: { UgcPackRecord } = {}
	for _, packId in linked do
		local record = DeathValleyUgcCreatorPackService.getRecord(packId)
		if record then
			table.insert(result, record)
		end
	end
	return result
end

function DeathValleyUgcCreatorPackService.listForSeason(seasonName: string, limit: number?): { UgcPackRecord }
	local maxItems = limit or 12
	local result: { UgcPackRecord } = {}
	local ok, entries = pcall(function()
		return ugcIndex:GetRangeAsync(Enum.SortDirection.Descending, maxItems, 0)
	end)
	if not ok or not entries then
		return result
	end
	for _, entry in entries do
		local record = DeathValleyUgcCreatorPackService.getRecord(entry.key)
		if record and (record.seasonTag == seasonName or record.seasonTag == nil) then
			table.insert(result, record)
		end
	end
	return result
end

function DeathValleyUgcCreatorPackService.listSeasonPopUpRecords(): { UgcPackRecord }
	local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()
	return DeathValleyUgcCreatorPackService.listForSeason(seasonName, 8)
end

function DeathValleyUgcCreatorPackService.toPackDef(record: UgcPackRecord): PrismPresetPackCatalog.PresetPackDef
	return {
		id = record.packId,
		displayName = record.displayName,
		description = record.description,
		robux = record.robux,
		cosmeticId = record.cosmeticId,
		titleSeasonId = record.titleSeasonId,
		grantCosmetic = false,
		featured = true,
		sortOrder = 50,
		shopChannel = "both",
		creatorUserId = record.authorUserId,
		creatorSharePercent = 70,
		seasonTag = record.seasonTag,
		ugcListingId = record.listingId,
	}
end

function DeathValleyUgcCreatorPackService.resolvePack(packId: string): PrismPresetPackCatalog.PresetPackDef?
	local staticPack = PrismPresetPackCatalog.getPack(packId)
	if staticPack then
		return staticPack
	end
	if not DeathValleyUgcCreatorPackService.isUgcPackId(packId) then
		return nil
	end
	local record = DeathValleyUgcCreatorPackService.getRecord(packId)
	if record then
		return DeathValleyUgcCreatorPackService.toPackDef(record)
	end
	return nil
end

function DeathValleyUgcCreatorPackService.getShareCode(packId: string): string?
	local record = DeathValleyUgcCreatorPackService.getRecord(packId)
	return if record then record.shareCode else nil
end

function DeathValleyUgcCreatorPackService.createFromListing(
	player: Player,
	listingId: string,
	robux: number?
): (boolean, string | { [string]: any })
	if typeof(listingId) ~= "string" or listingId == "" then
		return false, "Invalid listing"
	end
	local minRobux = DeathValleyUgcCreatorPackService.getMinRobux()
	local maxRobux = DeathValleyUgcCreatorPackService.getMaxRobux()
	local price = if typeof(robux) == "number" then math.floor(robux) else 99
	if price < minRobux or price > maxRobux then
		return false, string.format("Price must be %d–%d Robux", minRobux, maxRobux)
	end

	local listing = DeathValleyLoadoutPresetMarketService.getListingById(listingId, player.UserId)
	if not listing then
		return false, "Listing not found"
	end
	if listing.authorUserId ~= player.UserId then
		return false, "You can only link your own listings"
	end
	if typeof(listing.shareCode) ~= "string" or listing.shareCode == "" then
		return false, "Listing has no share code"
	end

	local maxLinked = DeathValleyUgcCreatorPackService.getMaxLinkedPerPlayer()
	local linked = DeathValleyPlayerStore.listLinkedUgcPackIds(player.UserId)
	if #linked >= maxLinked then
		return false, string.format("UGC pack limit reached (%d)", maxLinked)
	end

	local packId = DeathValleyUgcCreatorPackService.makePackId(listingId)
	if DeathValleyUgcCreatorPackService.getRecord(packId) then
		return false, "This listing already has a UGC pack"
	end

	local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()
	local record: UgcPackRecord = {
		packId = packId,
		listingId = listingId,
		authorUserId = player.UserId,
		authorDisplayName = player.DisplayName,
		displayName = string.format("%s Loadout Pack", listing.cosmeticName or listing.titleText or "Creator"),
		description = string.format("UGC preset by %s · 70%% to creator", player.DisplayName),
		robux = price,
		shareCode = listing.shareCode,
		cosmeticId = listing.cosmeticId,
		titleSeasonId = listing.titleSeasonId,
		seasonTag = seasonName,
		createdAt = os.time(),
	}

	local wroteDetail, detailErr = pcall(function()
		ugcMap:SetAsync(packId, record, UGC_TTL)
	end)
	if not wroteDetail then
		return false, tostring(detailErr)
	end
	local wroteIndex, indexErr = pcall(function()
		ugcIndex:SetAsync(packId, record.createdAt, UGC_TTL)
	end)
	if not wroteIndex then
		return false, tostring(indexErr)
	end

	DeathValleyPlayerStore.addLinkedUgcPackId(player.UserId, packId, maxLinked)
	return true, {
		packId = packId,
		listingId = listingId,
		robux = price,
		displayName = record.displayName,
	}
end

return DeathValleyUgcCreatorPackService
