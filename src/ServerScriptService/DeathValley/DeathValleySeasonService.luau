--!strict
--[[
	Phase D/G — Season rotation from GameConfig.Seasons (UTC month) + history.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

export type SeasonInfo = {
	seasonId: string,
	seasonName: string,
	year: string,
	isCurrent: boolean,
}

local DeathValleySeasonService = {}

local function seasonNameForMonth(month: number): string
	local seasons = GameConfig.Seasons
	local index = ((month - 1) % #seasons) + 1
	return seasons[index]
end

function DeathValleySeasonService.getCurrentSeasonName(): string
	local month = tonumber(os.date("!%m")) or 1
	return seasonNameForMonth(month)
end

function DeathValleySeasonService.getCurrentSeasonId(): string
	return os.date("!%Y") .. "-" .. DeathValleySeasonService.getCurrentSeasonName()
end

function DeathValleySeasonService.buildSeasonId(year: number, month: number): string
	return tostring(year) .. "-" .. seasonNameForMonth(month)
end

function DeathValleySeasonService.isPastSeason(seasonId: string): boolean
	if seasonId ~= DeathValleySeasonService.getCurrentSeasonId() then
		return true
	end
	local DeathValleySeasonRolloverService = require(script.Parent:WaitForChild("DeathValleySeasonRolloverService"))
	return DeathValleySeasonRolloverService.isSeasonEnded(seasonId)
end

function DeathValleySeasonService.getSeasonPayloadForId(seasonId: string): SeasonInfo
	local yearStr, seasonName = string.match(seasonId, "^(%d+)%-(.+)$")
	local isCurrent = seasonId == DeathValleySeasonService.getCurrentSeasonId()
	return {
		seasonId = seasonId,
		seasonName = seasonName or seasonId,
		year = yearStr or os.date("!%Y"),
		isCurrent = isCurrent,
	}
end

function DeathValleySeasonService.listHistoricalSeasons(maxCount: number?): { SeasonInfo }
	local count = maxCount or 12
	local result: { SeasonInfo } = {}
	local year = tonumber(os.date("!%Y")) or 2026
	local month = tonumber(os.date("!%m")) or 1

	for i = 0, count - 1 do
		local m = month - i
		local y = year
		while m <= 0 do
			m += 12
			y -= 1
		end
		local seasonId = DeathValleySeasonService.buildSeasonId(y, m)
		table.insert(result, DeathValleySeasonService.getSeasonPayloadForId(seasonId))
	end
	return result
end

function DeathValleySeasonService.getNextSeasonId(fromSeasonId: string?): string
	local baseId = fromSeasonId or DeathValleySeasonService.getCurrentSeasonId()
	if baseId == DeathValleySeasonService.getCurrentSeasonId() then
		local year = tonumber(os.date("!%Y")) or 2026
		local month = (tonumber(os.date("!%m")) or 1) + 1
		if month > 12 then
			month = 1
			year += 1
		end
		return DeathValleySeasonService.buildSeasonId(year, month)
	end

	local yearStr, _seasonName = string.match(baseId, "^(%d+)%-(.+)$")
	local year = tonumber(yearStr) or tonumber(os.date("!%Y")) or 2026
	for month = 1, 12 do
		if DeathValleySeasonService.buildSeasonId(year, month) == baseId then
			local nextMonth = month + 1
			local nextYear = year
			if nextMonth > 12 then
				nextMonth = 1
				nextYear += 1
			end
			return DeathValleySeasonService.buildSeasonId(nextYear, nextMonth)
		end
	end
	return DeathValleySeasonService.getCurrentSeasonId()
end

function DeathValleySeasonService.toPublicPayload(): { [string]: any }
	return DeathValleySeasonService.getSeasonPayloadForId(DeathValleySeasonService.getCurrentSeasonId())
end

return DeathValleySeasonService
