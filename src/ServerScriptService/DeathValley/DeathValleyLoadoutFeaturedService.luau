--!strict
--[[
	Phase P/Q — Featured preset carousel (curated listings + seasonal pack rotation).
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DeathValleyLoadoutPresetMarketService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetMarketService"))
local DeathValleyLoadoutPresetPackService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetPackService"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))

local DeathValleyLoadoutFeaturedService = {}

local FEATURED_MAP_NAME = "UtopiaDV_FeaturedCarousel_v1"
local FEATURED_TTL = 604800
local MAX_CAROUSEL = 6

local featuredMap: any = nil
do
	local ok, result = pcall(function()
		return MemoryStoreService:GetSortedMap(FEATURED_MAP_NAME)
	end)
	if ok then
		featuredMap = result
	else
		warn("[DeathValley] MemoryStore GetSortedMap failed (FeaturedService):", result)
	end
end

local function getRotationService()
	return require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedRotationService"))
end

function DeathValleyLoadoutFeaturedService.featureListing(listingId: string, score: number?)
	local boost = if typeof(score) == "number" then score else os.time()
	pcall(function()
		featuredMap:SetAsync(listingId, boost, FEATURED_TTL)
	end)
	return true
end

function DeathValleyLoadoutFeaturedService.adminFeatureListing(player: Player, listingId: string): (boolean, string)
	if not RunService:IsStudio() then
		return false, "Studio only"
	end
	if typeof(listingId) ~= "string" or listingId == "" then
		return false, "Invalid listing"
	end
	DeathValleyLoadoutFeaturedService.featureListing(listingId, os.time() + 1000000)
	return true, "Listing featured on carousel"
end

local function packToCarouselEntry(pack: any, userId: number): { [string]: any }
	return {
		id = pack.id,
		displayName = pack.displayName,
		description = pack.description,
		robux = pack.robux,
		featured = true,
		seasonTag = pack.seasonTag,
		shopChannel = pack.shopChannel,
		owned = DeathValleyLoadoutPresetPackService.hasPurchased(userId, pack.id),
	}
end

function DeathValleyLoadoutFeaturedService.getCarouselPayload(player: Player): { [string]: any }
	local rotation = getRotationService().getRotationPayload()
	local listings: { { [string]: any } } = {}
	local seen: { [string]: boolean } = {}

	local ok, entries = pcall(function()
		return featuredMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_CAROUSEL, 0)
	end)
	if ok and entries then
		for _, entry in entries do
			local listing = DeathValleyLoadoutPresetMarketService.getListingById(entry.key, player.UserId)
			if listing and not seen[entry.key] then
				listing.featured = true
				table.insert(listings, listing)
				seen[entry.key] = true
			end
		end
	end

	local dvConfig = GameConfig.DeathValley :: any
	local curated = if dvConfig and typeof(dvConfig.FeaturedListingIds) == "table"
		then dvConfig.FeaturedListingIds
		else {}
	for _, listingId in curated do
		if typeof(listingId) == "string" and not seen[listingId] then
			local listing = DeathValleyLoadoutPresetMarketService.getListingById(listingId, player.UserId)
			if listing then
				listing.featured = true
				table.insert(listings, listing)
				seen[listingId] = true
			end
		end
		if #listings >= MAX_CAROUSEL then
			break
		end
	end

	if #listings < 3 then
		local browse = DeathValleyLoadoutPresetMarketService.browseMarket(player, 1)
		if typeof(browse.items) == "table" then
			for _, item in browse.items do
				if typeof(item) == "table" and typeof(item.listingId) == "string" and not seen[item.listingId] then
					table.insert(listings, item)
					seen[item.listingId] = true
					if #listings >= MAX_CAROUSEL then
						break
					end
				end
			end
		end
	end

	local featuredPacks: { { [string]: any } } = {}
	local packSeen: { [string]: boolean } = {}
	for _, packId in rotation.packIds do
		local pack = DeathValleyLoadoutPresetPackService.resolvePack(packId)
		if pack and not packSeen[pack.id] then
			table.insert(featuredPacks, packToCarouselEntry(pack, player.UserId))
			packSeen[pack.id] = true
		end
	end
	if #featuredPacks == 0 then
		local packCatalog = DeathValleyLoadoutPresetPackService.getCatalogPayload(player)
		for _, pack in packCatalog.items do
			if pack.featured == true and not packSeen[tostring(pack.id)] then
				table.insert(featuredPacks, pack)
				packSeen[tostring(pack.id)] = true
			end
		end
	end
	if #featuredPacks == 0 then
		for _, pack in PrismPresetPackCatalog.listFeatured() do
			if not packSeen[pack.id] then
				table.insert(featuredPacks, packToCarouselEntry(pack, player.UserId))
			end
		end
	end

	return {
		listings = listings,
		packs = featuredPacks,
		rotation = rotation,
	}
end

return DeathValleyLoadoutFeaturedService
