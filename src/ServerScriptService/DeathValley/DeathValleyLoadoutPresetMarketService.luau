--!strict
--[[
	Phase O — Public preset marketplace (browse / publish / acquire / like).
]]

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLoadoutPresetShareService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetShareService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleySocialNotifyService = require(script.Parent:WaitForChild("DeathValleySocialNotifyService"))
local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

export type MarketListing = {
	listingId: string,
	authorUserId: number,
	authorDisplayName: string,
	titleSeasonId: string?,
	cosmeticId: string?,
	titleText: string?,
	cosmeticName: string?,
	tags: { string }?,
	likes: number,
	downloads: number,
	shareCode: string?,
	shareLink: string?,
	createdAt: number,
}

local DeathValleyLoadoutPresetMarketService = {}

local SORTED_MAP_NAME = "UtopiaDV_PresetMarket_v1"
local DETAIL_MAP_NAME = "UtopiaDV_PresetMarketDetail_v1"
local LISTING_TTL = 604800
local MAX_PUBLISH = 3
local PAGE_SIZE = 12

local sortedMap: any = nil
local detailMap: any = nil
do
	local ok1, r1 = pcall(function()
		return MemoryStoreService:GetSortedMap(SORTED_MAP_NAME)
	end)
	if ok1 then
		sortedMap = r1
	else
		warn("[DeathValley] MemoryStore GetSortedMap failed (PresetMarketService/sortedMap):", r1)
	end

	local ok2, r2 = pcall(function()
		return MemoryStoreService:GetHashMap(DETAIL_MAP_NAME)
	end)
	if ok2 then
		detailMap = r2
	else
		warn("[DeathValley] MemoryStore GetHashMap failed (PresetMarketService/detailMap):", r2)
	end
end

local function resolveTitleText(userId: number, seasonId: string?): string?
	if not seasonId or seasonId == "" then
		return nil
	end
	local data = DeathValleyPlayerStore.load(userId)
	if data and data.earnedTitles then
		return data.earnedTitles[seasonId]
	end
	return nil
end

local function resolveCosmeticName(cosmeticId: string?): string?
	if not cosmeticId or cosmeticId == "" then
		return nil
	end
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	return if def then def.displayName else cosmeticId
end

local function enrichListing(listing: MarketListing, viewerUserId: number?): { [string]: any }
	local earned = {}
	if viewerUserId then
		local data = DeathValleyPlayerStore.load(viewerUserId)
		if data and data.earnedTitles then
			earned = data.earnedTitles
		end
	end
	local titleSeasonId = listing.titleSeasonId
	local cosmeticId = listing.cosmeticId
	return {
		listingId = listing.listingId,
		authorUserId = listing.authorUserId,
		authorDisplayName = listing.authorDisplayName,
		titleSeasonId = titleSeasonId,
		cosmeticId = cosmeticId,
		titleText = listing.titleText,
		cosmeticName = listing.cosmeticName,
		tags = listing.tags or {},
		likes = listing.likes or 0,
		downloads = listing.downloads or 0,
		shareCode = listing.shareCode,
		shareLink = listing.shareLink,
		createdAt = listing.createdAt,
		canApplyTitle = typeof(titleSeasonId) == "string"
			and titleSeasonId ~= ""
			and earned[titleSeasonId] ~= nil,
		canApplyCosmetic = viewerUserId ~= nil
			and typeof(cosmeticId) == "string"
			and cosmeticId ~= ""
			and DeathValleyPlayerStore.hasOwnedCosmetic(viewerUserId, cosmeticId),
	}
end

function DeathValleyLoadoutPresetMarketService.getListingById(
	listingId: string,
	viewerUserId: number?
): { [string]: any }?
	local ok, listing = pcall(function()
		return detailMap:GetAsync(listingId)
	end)
	if ok and typeof(listing) == "table" then
		return enrichListing(listing :: MarketListing, viewerUserId)
	end
	return nil
end

function DeathValleyLoadoutPresetMarketService.browseMarket(player: Player, pageIndex: number?): { [string]: any }
	local page = if typeof(pageIndex) == "number" and pageIndex >= 1 then math.floor(pageIndex) else 1
	local offset = (page - 1) * PAGE_SIZE
	local items: { { [string]: any } } = {}
	local ok, entries = pcall(function()
		return sortedMap:GetRangeAsync(Enum.SortDirection.Descending, PAGE_SIZE, offset)
	end)
	if ok and entries then
		for _, entry in entries do
			local listingId = entry.key
			local detailOk, listing = pcall(function()
				return detailMap:GetAsync(listingId)
			end)
			if detailOk and typeof(listing) == "table" then
				table.insert(items, enrichListing(listing :: MarketListing, player.UserId))
			end
		end
	end
	return {
		page = page,
		pageSize = PAGE_SIZE,
		count = #items,
		items = items,
	}
end

function DeathValleyLoadoutPresetMarketService.publishToMarket(
	player: Player,
	slotIndex: number,
	tags: { string }?
): (boolean, string | { [string]: any })
	local stored = DeathValleyPlayerStore.getLoadoutPresets(player.UserId)
	local preset = stored[slotIndex]
	if not preset then
		return false, "Preset slot is empty"
	end
	if (not preset.titleSeasonId or preset.titleSeasonId == "") and (not preset.cosmeticId or preset.cosmeticId == "") then
		return false, "Nothing to publish in that slot"
	end

	local published = DeathValleyPlayerStore.listPublishedMarketListings(player.UserId)
	if #published >= MAX_PUBLISH then
		return false, string.format("Market limit reached (%d listings)", MAX_PUBLISH)
	end

	local codeOk, codeResult = DeathValleyLoadoutPresetShareService.generateShareCode(player, slotIndex)
	if not codeOk or typeof(codeResult) ~= "table" then
		return false, if typeof(codeResult) == "string" then codeResult else "Could not create share code"
	end

	local listingId = HttpService:GenerateGUID(false)
	local createdAt = os.time()
	local listing: MarketListing = {
		listingId = listingId,
		authorUserId = player.UserId,
		authorDisplayName = player.DisplayName,
		titleSeasonId = preset.titleSeasonId,
		cosmeticId = preset.cosmeticId,
		titleText = resolveTitleText(player.UserId, preset.titleSeasonId),
		cosmeticName = resolveCosmeticName(preset.cosmeticId),
		tags = tags or {},
		likes = 0,
		downloads = 0,
		shareCode = codeResult.code,
		shareLink = codeResult.shareLink,
		createdAt = createdAt,
	}

	local wroteDetail, detailErr = pcall(function()
		detailMap:SetAsync(listingId, listing, LISTING_TTL)
	end)
	if not wroteDetail then
		return false, tostring(detailErr)
	end
	local wroteSort, sortErr = pcall(function()
		sortedMap:SetAsync(listingId, createdAt, LISTING_TTL)
	end)
	if not wroteSort then
		return false, tostring(sortErr)
	end

	DeathValleyPlayerStore.addPublishedMarketListing(player.UserId, {
		listingId = listingId,
		slotIndex = slotIndex,
		shareCode = codeResult.code,
		createdAt = createdAt,
		expiresAt = createdAt + LISTING_TTL,
	}, MAX_PUBLISH)

	return true, {
		listingId = listingId,
		shareLink = codeResult.shareLink,
	}
end

function DeathValleyLoadoutPresetMarketService.acquireFromMarket(player: Player, listingId: string): (boolean, string)
	if typeof(listingId) ~= "string" or listingId == "" then
		return false, "Invalid listing"
	end
	local ok, listing = pcall(function()
		return detailMap:GetAsync(listingId)
	end)
	if not ok or typeof(listing) ~= "table" then
		return false, "Listing not found or expired"
	end
	local entry = listing :: MarketListing
	if entry.authorUserId == player.UserId then
		return false, "This is your own listing"
	end
	if entry.shareCode and entry.shareCode ~= "" then
		local redeemOk, redeemMsg = DeathValleyLoadoutPresetShareService.redeemShareCode(player, entry.shareCode)
		if redeemOk then
			entry.downloads = (entry.downloads or 0) + 1
			pcall(function()
				detailMap:SetAsync(listingId, entry, LISTING_TTL)
			end)
			if typeof(entry.authorUserId) == "number" and entry.authorUserId > 0 then
				local DeathValleyCreatorRevenueService =
					require(script.Parent:WaitForChild("DeathValleyCreatorRevenueService"))
				DeathValleyCreatorRevenueService.recordMarketAcquire(entry.authorUserId, player.UserId, listingId)
			end
		end
		return redeemOk, redeemMsg
	end
	return false, "Listing has no share code"
end

function DeathValleyLoadoutPresetMarketService.likeListing(player: Player, listingId: string): (boolean, string)
	if typeof(listingId) ~= "string" or listingId == "" then
		return false, "Invalid listing"
	end
	if DeathValleyPlayerStore.hasMarketLike(player.UserId, listingId) then
		return false, "Already liked"
	end
	local ok, listing = pcall(function()
		return detailMap:GetAsync(listingId)
	end)
	if not ok or typeof(listing) ~= "table" then
		return false, "Listing not found"
	end
	local entry = listing :: MarketListing
	entry.likes = (entry.likes or 0) + 1
	DeathValleyPlayerStore.addMarketLike(player.UserId, listingId)
	pcall(function()
		detailMap:SetAsync(listingId, entry, LISTING_TTL)
	end)
	if (entry.likes or 0) >= 10 then
		local featuredService = require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedService"))
		featuredService.featureListing(listingId, os.time() + (entry.likes or 0))
	end
	return true, "Liked preset"
end

function DeathValleyLoadoutPresetMarketService.getMarketPayload(player: Player): { [string]: any }
	local featuredService = require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedService"))
	local ugcService = require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
	local published = DeathValleyPlayerStore.listPublishedMarketListings(player.UserId)
	local publishedEnriched: { { [string]: any } } = {}
	for _, entry in published do
		local listing = DeathValleyLoadoutPresetMarketService.getListingById(entry.listingId, player.UserId)
		local ugcRecord = ugcService.getRecordByListingId(entry.listingId)
		table.insert(publishedEnriched, {
			listingId = entry.listingId,
			slotIndex = entry.slotIndex,
			shareCode = entry.shareCode,
			listing = listing,
			ugcPackId = if ugcRecord then ugcRecord.packId else nil,
			ugcRobux = if ugcRecord then ugcRecord.robux else nil,
		})
	end
	return {
		browse = DeathValleyLoadoutPresetMarketService.browseMarket(player, 1),
		published = publishedEnriched,
		carousel = featuredService.getCarouselPayload(player),
	}
end

function DeathValleyLoadoutPresetMarketService.notifyFeaturedListing(targetUserId: number, listing: MarketListing)
	DeathValleySocialNotifyService.queueNotify(targetUserId, {
		type = "market_featured",
		title = "Preset Bazaar",
		body = string.format("%s posted a new loadout on the market", listing.authorDisplayName),
		data = {
			listingId = listing.listingId,
			shareLink = listing.shareLink,
		},
	})
end

return DeathValleyLoadoutPresetMarketService
