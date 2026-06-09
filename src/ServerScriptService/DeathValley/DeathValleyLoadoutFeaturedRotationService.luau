--!strict
--[[
	Phase Q — Seasonal featured rotation for carousel + commerce spotlight packs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))

local DeathValleyLoadoutFeaturedRotationService = {}

local function getRotationConfig(): any
	local dv = GameConfig.DeathValley :: any
	if dv and typeof(dv.SeasonalFeaturedRotation) == "table" then
		return dv.SeasonalFeaturedRotation
	end
	return {}
end

function DeathValleyLoadoutFeaturedRotationService.getCurrentSeasonId(): string
	return DeathValleySeasonService.getCurrentSeasonId()
end

function DeathValleyLoadoutFeaturedRotationService.getSeasonName(): string
	return DeathValleySeasonService.getCurrentSeasonName()
end

function DeathValleyLoadoutFeaturedRotationService.getRotatedPackIds(): { string }
	local config = getRotationConfig()
	local seasonId = DeathValleyLoadoutFeaturedRotationService.getCurrentSeasonId()
	local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()

	local bySeasonId = if typeof(config.packIdsBySeasonId) == "table" then config.packIdsBySeasonId else {}
	local bySeasonName = if typeof(config.packIdsBySeasonName) == "table" then config.packIdsBySeasonName else {}

	local ids: { string } = {}
	local fromId = bySeasonId[seasonId]
	if typeof(fromId) == "table" then
		for _, packId in fromId do
			if typeof(packId) == "string" then
				table.insert(ids, packId)
			end
		end
	end
	if #ids == 0 then
		local fromName = bySeasonName[seasonName]
		if typeof(fromName) == "table" then
			for _, packId in fromName do
				if typeof(packId) == "string" then
					table.insert(ids, packId)
				end
			end
		end
	end
	if #ids == 0 then
		for _, pack in PrismPresetPackCatalog.listFeatured() do
			if pack.seasonTag == seasonName or pack.seasonTag == nil then
				table.insert(ids, pack.id)
			end
		end
	end
	return ids
end

function DeathValleyLoadoutFeaturedRotationService.getRotatedListingTags(): { string }
	local config = getRotationConfig()
	local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()
	local tags = if typeof(config.listingTags) == "table" then config.listingTags else {}
	local result: { string } = { seasonName, "community" }
	for _, tag in tags do
		if typeof(tag) == "string" then
			table.insert(result, tag)
		end
	end
	return result
end

function DeathValleyLoadoutFeaturedRotationService.getRotationPayload(): { [string]: any }
	local packIds = DeathValleyLoadoutFeaturedRotationService.getRotatedPackIds()
	local packs: { { [string]: any } } = {}
	local DeathValleyUgcCreatorPackService =
		require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
	for _, packId in packIds do
		local pack = DeathValleyUgcCreatorPackService.resolvePack(packId)
			or PrismPresetPackCatalog.getPack(packId)
		if pack then
			table.insert(packs, {
				id = pack.id,
				displayName = pack.displayName,
				description = pack.description,
				robux = pack.robux,
				shopChannel = pack.shopChannel,
				seasonTag = pack.seasonTag,
				ugcLinked = pack.ugcListingId ~= nil,
			})
		end
	end
	local ugcRecords: { { [string]: any } } = {}
	for _, record in DeathValleyUgcCreatorPackService.listSeasonPopUpRecords() do
		table.insert(ugcRecords, {
			packId = record.packId,
			listingId = record.listingId,
			displayName = record.displayName,
			robux = record.robux,
			authorDisplayName = record.authorDisplayName,
		})
	end
	return {
		seasonId = DeathValleyLoadoutFeaturedRotationService.getCurrentSeasonId(),
		seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName(),
		packIds = packIds,
		packs = packs,
		ugcPacks = ugcRecords,
		listingTags = DeathValleyLoadoutFeaturedRotationService.getRotatedListingTags(),
	}
end

return DeathValleyLoadoutFeaturedRotationService
