--!strict
--[[
	Phase K/L — Cross-place loadout sync (titles + cosmetics + presets from DataStore).
]]

local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyLoadoutPresetService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetService"))
local DeathValleyLoadoutPresetShareService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetShareService"))
local DeathValleyLoadoutPresetMarketService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetMarketService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))

local DeathValleyLoadoutService = {}

function DeathValleyLoadoutService.syncFromStore(player: Player)
	local legacyOwned = player:GetAttribute("OwnedCosmetics")
	if typeof(legacyOwned) == "string" and legacyOwned ~= "" then
		DeathValleyPlayerStore.migrateOwnedFromAttribute(player.UserId, legacyOwned)
	end
	DeathValleyCosmeticService.syncFromStore(player)
	DeathValleyTitleService.syncFromStore(player)
end

function DeathValleyLoadoutService.getSummaryPayload(player: Player): { [string]: any }
	local cosmetic = DeathValleyCosmeticService.getInventoryPayload(player)
	local titles = DeathValleyTitleService.getInventoryPayload(player)
	return {
		equippedCosmeticId = cosmetic.equippedCosmeticId,
		equippedSeasonId = titles.equippedSeasonId,
		equippedTitle = player:GetAttribute("DV_EquippedTitle"),
		cosmeticCount = cosmetic.count,
		titleCount = titles.count,
	}
end

function DeathValleyLoadoutService.getFullPayload(player: Player): { [string]: any }
	return {
		summary = DeathValleyLoadoutService.getSummaryPayload(player),
		titles = DeathValleyTitleService.getInventoryPayload(player),
		cosmetics = DeathValleyCosmeticService.getInventoryPayload(player),
		presets = DeathValleyLoadoutPresetService.getPresetsPayload(player),
		shared = DeathValleyLoadoutPresetShareService.getSharedPresetsPayload(player),
		shareCodes = DeathValleyLoadoutPresetShareService.getActiveShareCodesPayload(player),
		market = DeathValleyLoadoutPresetMarketService.getMarketPayload(player),
	}
end

return DeathValleyLoadoutService
