--!strict
--[[
	Phase R — Seasonal pop-up shop catalog (fashion + rotated preset + UGC packs).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLoadoutFeaturedRotationService =
	require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedRotationService"))
local DeathValleyLoadoutPresetPackService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetPackService"))
local DeathValleyUgcCreatorPackService = require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))

local DeathValleySeasonalPopUpShopService = {}

export type PopUpCatalogItem = {
	id: string,
	displayName: string,
	kind: "set" | "piece" | "service",
	robux: number,
	owned: boolean?,
	seasonTag: string?,
	source: string?,
}

function DeathValleySeasonalPopUpShopService.getSeasonLabel(): string
	local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()
	return string.format("Season Pop-Up · %s", seasonName)
end

function DeathValleySeasonalPopUpShopService.getPresetPackItems(player: Player): { PopUpCatalogItem }
	local items: { PopUpCatalogItem } = {}
	local seen: { [string]: boolean } = {}

	for _, packId in DeathValleyLoadoutFeaturedRotationService.getRotatedPackIds() do
		local pack = DeathValleyUgcCreatorPackService.resolvePack(packId)
			or PrismPresetPackCatalog.getPack(packId)
		if pack and not seen[pack.id] then
			table.insert(items, {
				id = pack.id,
				displayName = pack.displayName,
				kind = "service",
				robux = pack.robux,
				owned = DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, pack.id),
				seasonTag = pack.seasonTag,
				source = "season_rotation",
			})
			seen[pack.id] = true
		end
	end

	for _, record in DeathValleyUgcCreatorPackService.listSeasonPopUpRecords() do
		if not seen[record.packId] then
			table.insert(items, {
				id = record.packId,
				displayName = record.displayName,
				kind = "service",
				robux = record.robux,
				owned = DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, record.packId),
				seasonTag = record.seasonTag,
				source = "ugc_creator",
			})
			seen[record.packId] = true
		end
	end

	return items
end

function DeathValleySeasonalPopUpShopService.getPayload(player: Player): { [string]: any }
	return {
		seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName(),
		seasonId = DeathValleyLoadoutFeaturedRotationService.getCurrentSeasonId(),
		label = DeathValleySeasonalPopUpShopService.getSeasonLabel(),
		presetPacks = DeathValleySeasonalPopUpShopService.getPresetPackItems(player),
	}
end

return DeathValleySeasonalPopUpShopService
