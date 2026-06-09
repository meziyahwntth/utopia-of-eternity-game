--!strict
--[[
	Phase K — Season title inventory, equip, and DataStore persistence.
]]

local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))

local DeathValleyTitleService = {}

local function syncTitleAttributes(player: Player, earnedTitles: { [string]: string })
	for seasonId, title in earnedTitles do
		player:SetAttribute("DV_SeasonTitle_" .. seasonId, title)
	end
end

function DeathValleyTitleService.syncFromStore(player: Player)
	local data = DeathValleyPlayerStore.load(player.UserId)
	local earnedTitles = if data and data.earnedTitles then data.earnedTitles else {}
	syncTitleAttributes(player, earnedTitles)

	local equippedSeasonId = DeathValleyPlayerStore.getEquippedTitleSeasonId(player.UserId)
	if equippedSeasonId and earnedTitles[equippedSeasonId] then
		player:SetAttribute("DV_EquippedTitle", earnedTitles[equippedSeasonId])
	else
		player:SetAttribute("DV_EquippedTitle", "")
	end
end

function DeathValleyTitleService.grantTitle(player: Player, seasonId: string, title: string)
	if title == "" then
		return
	end
	DeathValleyPlayerStore.saveEarnedTitle(player.UserId, seasonId, title)
	player:SetAttribute("DV_SeasonTitle_" .. seasonId, title)
	DeathValleyTitleService.equipTitle(player, seasonId)
end

function DeathValleyTitleService.equipTitle(player: Player, seasonId: string): (boolean, string)
	if seasonId == "" then
		return DeathValleyTitleService.unequipTitle(player)
	end
	local data = DeathValleyPlayerStore.load(player.UserId)
	local earnedTitles = if data and data.earnedTitles then data.earnedTitles else {}
	local title = earnedTitles[seasonId]
	if not title then
		return false, "You have not earned a title for that season"
	end

	player:SetAttribute("DV_EquippedTitle", title)
	DeathValleyPlayerStore.setEquippedTitleSeasonId(player.UserId, seasonId)
	return true, "Equipped title: " .. title
end

function DeathValleyTitleService.unequipTitle(player: Player): (boolean, string)
	player:SetAttribute("DV_EquippedTitle", "")
	DeathValleyPlayerStore.setEquippedTitleSeasonId(player.UserId, nil)
	return true, "Title unequipped"
end

function DeathValleyTitleService.getInventoryPayload(player: Player): { [string]: any }
	local data = DeathValleyPlayerStore.load(player.UserId)
	local earnedTitles = if data and data.earnedTitles then data.earnedTitles else {}
	local equippedSeasonId = DeathValleyPlayerStore.getEquippedTitleSeasonId(player.UserId)
	if typeof(player:GetAttribute("DV_EquippedTitle")) == "string" and player:GetAttribute("DV_EquippedTitle") ~= "" then
		equippedSeasonId = equippedSeasonId or DeathValleyTitleService.inferEquippedSeasonId(player, earnedTitles)
	end

	local items: { { [string]: any } } = {}
	for _, season in DeathValleySeasonService.listHistoricalSeasons(12) do
		local title = earnedTitles[season.seasonId]
		if title then
			table.insert(items, {
				seasonId = season.seasonId,
				seasonName = season.seasonName,
				year = season.year,
				title = title,
				equipped = season.seasonId == equippedSeasonId,
			})
		end
	end

	return {
		equippedSeasonId = equippedSeasonId,
		items = items,
		count = #items,
	}
end

function DeathValleyTitleService.inferEquippedSeasonId(
	player: Player,
	earnedTitles: { [string]: string }
): string?
	local equippedTitle = player:GetAttribute("DV_EquippedTitle")
	if typeof(equippedTitle) ~= "string" or equippedTitle == "" then
		return nil
	end
	for seasonId, title in earnedTitles do
		if title == equippedTitle then
			return seasonId
		end
	end
	return nil
end

return DeathValleyTitleService
