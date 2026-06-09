--!strict
--[[
	Phase G/H — End-of-season ranked rewards with titles, cosmetics, auto-rollover delivery.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLeaderboardGlobalService = require(script.Parent:WaitForChild("DeathValleyLeaderboardGlobalService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

export type RewardTier = PrismDeathValleySurvivalConfig.SeasonRankRewardTier

local DeathValleySeasonRewardService = {}

local function grantCosmetic(player: Player, cosmeticId: string?)
	DeathValleyCosmeticService.grantCosmetic(player, cosmeticId)
end

local function grantTitle(player: Player, seasonId: string, tier: RewardTier)
	if tier.displayTitle then
		DeathValleyTitleService.grantTitle(player, seasonId, tier.displayTitle)
	end
end

function DeathValleySeasonRewardService.getTierForRank(rank: number?, nights: number): RewardTier?
	if nights <= 0 then
		return nil
	end
	for _, tier in PrismDeathValleySurvivalConfig.SeasonRankRewards do
		if rank and rank <= tier.maxRank then
			return tier
		end
	end
	for _, tier in PrismDeathValleySurvivalConfig.SeasonRankRewards do
		if tier.maxRank >= 999 and nights >= (tier.minNights or 1) then
			return tier
		end
	end
	return nil
end

function DeathValleySeasonRewardService.grantTierRewards(
	player: Player,
	seasonId: string,
	tier: RewardTier,
	rank: number?,
	autoDelivered: boolean
): string
	local shards = player:GetAttribute("DV_LuminiteShards")
	if typeof(shards) ~= "number" then
		shards = 0
	end
	player:SetAttribute("DV_LuminiteShards", shards + tier.shards)
	player:SetAttribute("DV_SeasonReward_" .. seasonId, tier.label)
	grantTitle(player, seasonId, tier)
	grantCosmetic(player, tier.cosmeticId)

	if autoDelivered then
		player:SetAttribute("DV_SeasonAutoReward_" .. seasonId, true)
	end

	local rankText = if rank then ("#" .. tostring(rank)) else "Participant"
	local deliveryTag = if autoDelivered then " · Auto" else ""
	return string.format(
		"%s — %s · +%d shards · %s%s (%s)",
		seasonId,
		tier.label,
		tier.shards,
		tier.displayTitle or tier.label,
		deliveryTag,
		rankText
	)
end

function DeathValleySeasonRewardService.getPlayerSeasonStats(player: Player, seasonId: string): (number?, number)
	local score = DeathValleyLeaderboardGlobalService.getPlayerScore(player.UserId, seasonId)
	if not score or score <= 0 then
		local data = DeathValleyPlayerStore.load(player.UserId)
		if data and data.seasonBests and data.seasonBests[seasonId] then
			score = data.seasonBests[seasonId]
		end
	end
	if not score or score <= 0 then
		return nil, 0
	end
	local rank = DeathValleyLeaderboardGlobalService.computeRank(player.UserId, seasonId, score)
	local entries = DeathValleyLeaderboardGlobalService.getTopEntries(seasonId)
	for _, entry in entries do
		if entry.userId == player.UserId then
			rank = entry.rank
			break
		end
	end
	return rank, score
end

function DeathValleySeasonRewardService.getClaimStatus(player: Player, seasonId: string): { [string]: any }
	local isPast = DeathValleySeasonService.isPastSeason(seasonId)
	local claimed = DeathValleyPlayerStore.hasSeasonRewardClaim(player.UserId, seasonId)
	local autoDelivered = player:GetAttribute("DV_SeasonAutoReward_" .. seasonId) == true
	local rank, nights = DeathValleySeasonRewardService.getPlayerSeasonStats(player, seasonId)
	local tier = DeathValleySeasonRewardService.getTierForRank(rank, nights or 0)

	return {
		seasonId = seasonId,
		isPastSeason = isPast,
		claimed = claimed,
		autoDelivered = autoDelivered,
		rank = rank,
		nightsSurvived = nights,
		tier = if tier then tier.label else nil,
		displayTitle = if tier then tier.displayTitle else nil,
		cosmeticId = if tier then tier.cosmeticId else nil,
		shards = if tier then tier.shards else 0,
		claimable = isPast and not claimed and tier ~= nil and not autoDelivered,
		top25AutoEligible = rank ~= nil and rank <= 25,
	}
end

function DeathValleySeasonRewardService.claimReward(player: Player, seasonId: string): (boolean, string)
	if not DeathValleySeasonService.isPastSeason(seasonId) then
		return false, "Rewards unlock when the season ends"
	end
	if DeathValleyPlayerStore.hasSeasonRewardClaim(player.UserId, seasonId) then
		return false, "Reward already claimed for this season"
	end
	if player:GetAttribute("DV_SeasonAutoReward_" .. seasonId) == true then
		return false, "Top-25 reward already auto-delivered"
	end

	local rank, nights = DeathValleySeasonRewardService.getPlayerSeasonStats(player, seasonId)
	local tier = DeathValleySeasonRewardService.getTierForRank(rank, nights or 0)
	if not tier then
		return false, "No ranked reward — survive at least 1 night that season"
	end

	DeathValleyPlayerStore.markSeasonRewardClaim(player.UserId, seasonId)
	local msg = DeathValleySeasonRewardService.grantTierRewards(player, seasonId, tier, rank, false)
	return true, msg
end

function DeathValleySeasonRewardService.grantAutoRolloverReward(
	player: Player,
	seasonId: string,
	rank: number?,
	nights: number
): (boolean, string)
	if DeathValleyPlayerStore.hasSeasonRewardClaim(player.UserId, seasonId) then
		return false, "Already claimed"
	end
	if player:GetAttribute("DV_SeasonAutoReward_" .. seasonId) == true then
		return false, "Already auto-delivered"
	end
	if not rank or rank > 25 then
		return false, "Not in top 25 auto pool"
	end

	local tier = DeathValleySeasonRewardService.getTierForRank(rank, nights)
	if not tier then
		return false, "No tier for rank"
	end

	DeathValleyPlayerStore.markSeasonRewardClaim(player.UserId, seasonId)
	local msg = DeathValleySeasonRewardService.grantTierRewards(player, seasonId, tier, rank, true)
	return true, msg
end

return DeathValleySeasonRewardService
