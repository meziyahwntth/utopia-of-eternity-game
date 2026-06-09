--!strict
--[[
	Phase L — Save/apply title+cosmetic preset slots (max 3).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))
local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

export type PresetSlotPayload = {
	slot: number,
	titleSeasonId: string?,
	cosmeticId: string?,
	titleText: string?,
	cosmeticName: string?,
	savedAt: number?,
}

local DeathValleyLoadoutPresetService = {}

local MAX_SLOTS = 3

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

function DeathValleyLoadoutPresetService.getPresetsPayload(player: Player): { [string]: any }
	local stored = DeathValleyPlayerStore.getLoadoutPresets(player.UserId)
	local slots: { PresetSlotPayload } = {}
	for slotIndex = 1, MAX_SLOTS do
		local entry = stored[slotIndex]
		table.insert(slots, {
			slot = slotIndex,
			titleSeasonId = if entry then entry.titleSeasonId else nil,
			cosmeticId = if entry then entry.cosmeticId else nil,
			titleText = if entry then resolveTitleText(player.UserId, entry.titleSeasonId) else nil,
			cosmeticName = if entry then resolveCosmeticName(entry.cosmeticId) else nil,
			savedAt = if entry then entry.savedAt else nil,
		})
	end
	return {
		maxSlots = MAX_SLOTS,
		slots = slots,
	}
end

function DeathValleyLoadoutPresetService.savePreset(
	player: Player,
	slotIndex: number,
	titleSeasonId: string?,
	cosmeticId: string?
): (boolean, string)
	if slotIndex < 1 or slotIndex > MAX_SLOTS then
		return false, "Invalid preset slot"
	end

	if titleSeasonId and titleSeasonId ~= "" then
		local data = DeathValleyPlayerStore.load(player.UserId)
		local earned = if data and data.earnedTitles then data.earnedTitles else {}
		if not earned[titleSeasonId] then
			return false, "Title not owned for that season"
		end
	end

	if cosmeticId and cosmeticId ~= "" then
		if not DeathValleyPlayerStore.hasOwnedCosmetic(player.UserId, cosmeticId) then
			return false, "Cosmetic not owned"
		end
		if not PrismDeathValleySeasonCosmetics.getDef(cosmeticId) then
			return false, "Unknown cosmetic"
		end
	end

	if (not titleSeasonId or titleSeasonId == "") and (not cosmeticId or cosmeticId == "") then
		return false, "Save at least a title or cosmetic"
	end

	DeathValleyPlayerStore.saveLoadoutPreset(player.UserId, slotIndex, titleSeasonId, cosmeticId)
	return true, string.format("Preset %d saved", slotIndex)
end

function DeathValleyLoadoutPresetService.saveCurrentLoadout(player: Player, slotIndex: number): (boolean, string)
	local titleSeasonId = DeathValleyPlayerStore.getEquippedTitleSeasonId(player.UserId)
	local cosmeticId = DeathValleyPlayerStore.getEquippedCosmetic(player.UserId)
	return DeathValleyLoadoutPresetService.savePreset(player, slotIndex, titleSeasonId, cosmeticId)
end

function DeathValleyLoadoutPresetService.applyPreset(player: Player, slotIndex: number): (boolean, string)
	if slotIndex < 1 or slotIndex > MAX_SLOTS then
		return false, "Invalid preset slot"
	end
	local stored = DeathValleyPlayerStore.getLoadoutPresets(player.UserId)
	local entry = stored[slotIndex]
	if not entry then
		return false, "Preset slot empty"
	end

	local messages: { string } = {}
	if entry.titleSeasonId and entry.titleSeasonId ~= "" then
		local ok, msg = DeathValleyTitleService.equipTitle(player, entry.titleSeasonId)
		if not ok then
			return false, msg
		end
		table.insert(messages, msg)
	elseif entry.cosmeticId == nil or entry.cosmeticId == "" then
		DeathValleyTitleService.unequipTitle(player)
	end

	if entry.cosmeticId and entry.cosmeticId ~= "" then
		local ok, msg = DeathValleyCosmeticService.equipCosmetic(player, entry.cosmeticId)
		if not ok then
			return false, msg
		end
		table.insert(messages, msg)
	else
		DeathValleyCosmeticService.unequipCosmetic(player)
	end

	return true, "Applied preset " .. tostring(slotIndex)
end

function DeathValleyLoadoutPresetService.clearPreset(player: Player, slotIndex: number): (boolean, string)
	if slotIndex < 1 or slotIndex > MAX_SLOTS then
		return false, "Invalid preset slot"
	end
	DeathValleyPlayerStore.clearLoadoutPreset(player.UserId, slotIndex)
	return true, "Preset " .. tostring(slotIndex) .. " cleared"
end

return DeathValleyLoadoutPresetService
