--!strict
--[[
	SeasonService (P8) — detect current season + validate seasonal cosmetics
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeasonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SeasonConfig"))

export type Season = SeasonConfig.Season

local SeasonService = {}

function SeasonService.getCurrentSeason(): Season?
	local month = tonumber(os.date("%m")) or 0
	for _, season in SeasonConfig.Seasons do
		if season.startMonth <= season.endMonth then
			if month >= season.startMonth and month <= season.endMonth then
				return season
			end
		else
			if month >= season.startMonth or month <= season.endMonth then
				return season
			end
		end
	end
	return nil
end

function SeasonService.getCurrentSeasonId(): string
	local season = SeasonService.getCurrentSeason()
	if season then
		return season.id
	end
	return SeasonConfig.CurrentSeasonId
end

function SeasonService.isSeasonalItem(itemId: string): boolean
	local season = SeasonService.getCurrentSeason()
	if not season then
		return false
	end
	for _, id in season.cosmeticPool do
		if id == itemId then
			return true
		end
	end
	return false
end

function SeasonService.isItemAvailable(itemId: string): boolean
	return SeasonService.isSeasonalItem(itemId)
end

return SeasonService
