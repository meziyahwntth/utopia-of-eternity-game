--!strict
--[[
	Phase D/F — OrderedDataStore leaderboard (delegates to global cross-place service).
]]

local Players = game:GetService("Players")

local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyLeaderboardGlobalService = require(script.Parent:WaitForChild("DeathValleyLeaderboardGlobalService"))

local DeathValleyLeaderboardService = {}

function DeathValleyLeaderboardService.recordNightSurvived(player: Player, nightsSurvived: number)
	if nightsSurvived <= 0 then
		return
	end
	local seasonId = DeathValleySeasonService.getCurrentSeasonId()
	DeathValleyPlayerStore.updateBestNights(player.UserId, seasonId, nightsSurvived)
	player:SetAttribute("DV_SeasonBestNights", nightsSurvived)
	player:SetAttribute("DV_SeasonId", seasonId)
	DeathValleyLeaderboardGlobalService.recordScore(player, seasonId, nightsSurvived)
end

function DeathValleyLeaderboardService.getTopEntries(seasonId: string?): { { [string]: any } }
	local sid = seasonId or DeathValleySeasonService.getCurrentSeasonId()
	local entries = DeathValleyLeaderboardGlobalService.getTopEntries(sid)
	local payload: { { [string]: any } } = {}
	for _, entry in entries do
		table.insert(payload, entry)
	end
	return payload
end

function DeathValleyLeaderboardService.getPlayerRank(player: Player, seasonId: string?): (number?, number)
	local sid = seasonId or DeathValleySeasonService.getCurrentSeasonId()
	local score = DeathValleyLeaderboardGlobalService.getPlayerScore(player.UserId, sid)
	if not score or score <= 0 then
		local data = DeathValleyPlayerStore.load(player.UserId)
		if data and data.seasonBests and data.seasonBests[sid] then
			score = data.seasonBests[sid]
		end
	end
	if not score or score <= 0 then
		return nil, 0
	end

	local entries = DeathValleyLeaderboardGlobalService.getTopEntries(sid)
	for _, entry in entries do
		if entry.userId == player.UserId then
			return entry.rank, score
		end
	end

	local rank = DeathValleyLeaderboardGlobalService.computeRank(player.UserId, sid, score)
	return rank, score
end

function DeathValleyLeaderboardService.toPublicPayload(player: Player?, seasonId: string?): { [string]: any }
	return DeathValleyLeaderboardGlobalService.toPublicPayload(player, seasonId)
end

return DeathValleyLeaderboardService
