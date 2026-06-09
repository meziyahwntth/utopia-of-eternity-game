--!strict
--[[
	Death Valley mega dungeon — role contribution thresholds for Prism Key grant.
]]

local PrismDeathValleyDungeonConfig = require(script.Parent:WaitForChild("PrismDeathValleyDungeonConfig"))

export type ContributionState = {
	healCount: number,
	assistCount: number,
	ammoTransferCount: number,
	grenadeCount: number,
	bossHitCount: number,
}

export type ContributionProgress = {
	role: string,
	met: boolean,
	missing: string?,
	healCount: number,
	healRequired: number?,
	assistCount: number,
	assistRequired: number?,
	bossHitCount: number,
	bossHitRequired: number?,
	ammoTransferCount: number,
	ammoRequired: number?,
	grenadeCount: number,
	grenadeRequired: number?,
}

local DungeonContributionChecker = {}

local function getRequirements(role: string): PrismDeathValleyDungeonConfig.RoleContribution?
	return PrismDeathValleyDungeonConfig.RoleContributions[role :: PrismDeathValleyDungeonConfig.DungeonRoleId]
end

function DungeonContributionChecker.meetsThreshold(
	role: string,
	state: ContributionState
): (boolean, string?)
	local req = getRequirements(role)
	if not req then
		return true, nil
	end

	if req.healAllyMin and state.healCount < req.healAllyMin then
		return false, string.format("Need %d heals (have %d)", req.healAllyMin, state.healCount)
	end
	if req.assistAttackMin and state.assistCount < req.assistAttackMin then
		return false, string.format("Need %d assists (have %d)", req.assistAttackMin, state.assistCount)
	end
	if req.bossHitMin and state.bossHitCount < req.bossHitMin then
		return false, string.format("Need %d boss hits (have %d)", req.bossHitMin, state.bossHitCount)
	end
	if req.transferAmmoMin and state.ammoTransferCount < req.transferAmmoMin then
		return false, string.format("Need %d ammo transfers (have %d)", req.transferAmmoMin, state.ammoTransferCount)
	end
	if req.grenadeOrTrapMin and state.grenadeCount < req.grenadeOrTrapMin then
		return false, string.format("Need %d grenades/traps (have %d)", req.grenadeOrTrapMin, state.grenadeCount)
	end

	return true, nil
end

function DungeonContributionChecker.getProgress(role: string, state: ContributionState): ContributionProgress
	local req = getRequirements(role) or {}
	local met, missing = DungeonContributionChecker.meetsThreshold(role, state)

	return {
		role = role,
		met = met,
		missing = missing,
		healCount = state.healCount,
		healRequired = req.healAllyMin,
		assistCount = state.assistCount,
		assistRequired = req.assistAttackMin,
		bossHitCount = state.bossHitCount,
		bossHitRequired = req.bossHitMin,
		ammoTransferCount = state.ammoTransferCount,
		ammoRequired = req.transferAmmoMin,
		grenadeCount = state.grenadeCount,
		grenadeRequired = req.grenadeOrTrapMin,
	}
end

return DungeonContributionChecker
