--!strict
--[[
	Phase E — Ring 4 seasonal shrine rewards tied to DeathValleySeasonService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyExpansionService = require(script.Parent:WaitForChild("DeathValleyExpansionService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleySeasonalRingService = {}

function DeathValleySeasonalRingService.canAccessRing4(): boolean
	return DeathValleyExpansionService.getUnlockedRing() >= PrismDeathValleySurvivalConfig.SeasonalRingMinRing
end

function DeathValleySeasonalRingService.claimShrineReward(player: Player): (boolean, string)
	if not DeathValleySeasonalRingService.canAccessRing4() then
		local required = PrismDeathValleySurvivalConfig.getRingDef(PrismDeathValleySurvivalConfig.SeasonalRingMinRing)
		local nights = if required then required.minNightsSurvived else 30
		return false, string.format("Unlock Ring 4 — survive %d nights", nights)
	end

	local seasonId = DeathValleySeasonService.getCurrentSeasonId()
	if DeathValleyPlayerStore.hasSeasonalClaim(player.UserId, seasonId) then
		return false, "Seasonal reward already claimed this season"
	end

	local reward = PrismDeathValleySurvivalConfig.SeasonalShrineShardReward
	DeathValleyPlayerStore.markSeasonalClaim(player.UserId, seasonId)
	local shards = player:GetAttribute("DV_LuminiteShards")
	if typeof(shards) ~= "number" then
		shards = 0
	end
	player:SetAttribute("DV_LuminiteShards", shards + reward)
	player:SetAttribute("DV_SeasonalClaim_" .. seasonId, true)
	return true, string.format("Seasonal Echo — +%d Luminite shards (%s)", reward, DeathValleySeasonService.getCurrentSeasonName())
end

function DeathValleySeasonalRingService.toPublicPayload(): { [string]: any }
	return {
		ring4Unlocked = DeathValleySeasonalRingService.canAccessRing4(),
		seasonName = DeathValleySeasonService.getCurrentSeasonName(),
		shardReward = PrismDeathValleySurvivalConfig.SeasonalShrineShardReward,
		minRing = PrismDeathValleySurvivalConfig.SeasonalRingMinRing,
	}
end

return DeathValleySeasonalRingService
