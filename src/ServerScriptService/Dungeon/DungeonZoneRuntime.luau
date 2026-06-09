--!strict
--[[
	Shared Mega Dungeon zone runtime — boss HP, contribution, Prism Key grant.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonContributionChecker = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DungeonContributionChecker"))
local DungeonLoadoutCalculator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DungeonLoadoutCalculator"))
local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))

export type ZonePlayerState = {
	joinedAt: number,
	healCount: number,
	assistCount: number,
	ammoTransferCount: number,
	grenadeCount: number,
	bossHitCount: number,
}

export type ZoneRuntime = {
	zoneDef: PrismDeathValleyDungeonConfig.ZoneDef,
	zonePlayers: { [number]: ZonePlayerState },
	bossActive: boolean,
	bossCleared: boolean,
	bossHp: number,
	bossMaxHp: number,
	lastOutcomeMessage: string?,
}

local DungeonZoneRuntime = {}

local DEFAULT_BOSS_HP = {
	duo_depth = 240,
	squad_hollow = 480,
	raid_cavern = 1200,
	legion_pass = 2400,
	abyss_throne = 6000,
}

function DungeonZoneRuntime.create(zoneDef: PrismDeathValleyDungeonConfig.ZoneDef): ZoneRuntime
	local maxHp = zoneDef.bossMaxHp or DEFAULT_BOSS_HP[zoneDef.id] or 240
	return {
		zoneDef = zoneDef,
		zonePlayers = {},
		bossActive = false,
		bossCleared = false,
		bossHp = 0,
		bossMaxHp = maxHp,
		lastOutcomeMessage = nil,
	}
end

function DungeonZoneRuntime.getPlayersInZone(runtime: ZoneRuntime): { Player }
	local list: { Player } = {}
	for userId, _ in runtime.zonePlayers do
		local p = Players:GetPlayerByUserId(userId)
		if p then
			table.insert(list, p)
		end
	end
	return list
end

function DungeonZoneRuntime.buildPublicState(runtime: ZoneRuntime): { [string]: any }
	local zoneDef = runtime.zoneDef
	local count = #DungeonZoneRuntime.getPlayersInZone(runtime)
	return {
		zoneId = zoneDef.id,
		zoneIndex = zoneDef.zoneIndex,
		displayName = zoneDef.displayName,
		playerCount = count,
		nominalTeamSize = zoneDef.nominalTeamSize,
		minToEnterBoss = zoneDef.minToEnterBoss,
		minToSucceed = zoneDef.minToSucceed,
		bossActive = runtime.bossActive,
		bossCleared = runtime.bossCleared,
		bossHp = runtime.bossHp,
		bossMaxHp = runtime.bossMaxHp,
		bossName = zoneDef.bossName,
		canEnterBoss = count >= zoneDef.minToEnterBoss,
		canSucceed = count >= zoneDef.minToSucceed,
		bossOutcomeMessage = runtime.lastOutcomeMessage,
	}
end

function DungeonZoneRuntime.syncContributionAttributes(player: Player, state: ZonePlayerState)
	player:SetAttribute("DungeonHealCount", state.healCount)
	player:SetAttribute("DungeonAssistCount", state.assistCount)
	player:SetAttribute("DungeonBossHitCount", state.bossHitCount)
	player:SetAttribute("DungeonAmmoTransferCount", state.ammoTransferCount)
	player:SetAttribute("DungeonGrenadeCount", state.grenadeCount)
end

function DungeonZoneRuntime.initContribution(runtime: ZoneRuntime, player: Player)
	runtime.zonePlayers[player.UserId] = {
		joinedAt = os.clock(),
		healCount = 0,
		assistCount = 0,
		ammoTransferCount = 0,
		grenadeCount = 0,
		bossHitCount = 0,
	}
	player:SetAttribute("DungeonZoneId", runtime.zoneDef.id)
	DungeonZoneRuntime.syncContributionAttributes(player, runtime.zonePlayers[player.UserId])
end

function DungeonZoneRuntime.clearContribution(runtime: ZoneRuntime, player: Player)
	runtime.zonePlayers[player.UserId] = nil
	if player:GetAttribute("DungeonZoneId") == runtime.zoneDef.id then
		player:SetAttribute("DungeonZoneId", nil)
	end
end

function DungeonZoneRuntime.grantKeysAfterClear(
	runtime: ZoneRuntime,
	grantKeyFn: (Player, string, number) -> (boolean, string)
)
	local zoneDef = runtime.zoneDef
	local playersInZone = DungeonZoneRuntime.getPlayersInZone(runtime)
	if #playersInZone < zoneDef.minToSucceed then
		return
	end

	for _, p in playersInZone do
		local state = runtime.zonePlayers[p.UserId]
		local role = p:GetAttribute("DungeonRole")
		local contributionMet = true
		local contributionReason: string? = nil

		if typeof(role) == "string" and state then
			contributionMet, contributionReason = DungeonContributionChecker.meetsThreshold(role, state)
		end

		local granted = false
		local message = contributionReason or "Contribution not met"

		if contributionMet then
			granted, message = grantKeyFn(p, zoneDef.id, zoneDef.zoneIndex)
		end

		p:SetAttribute("DungeonZone" .. zoneDef.zoneIndex .. "Cleared", true)
	end
end

function DungeonZoneRuntime.finishBoss(
	runtime: ZoneRuntime,
	success: boolean,
	grantKeyFn: (Player, string, number) -> (boolean, string)
)
	runtime.bossActive = false
	local zoneDef = runtime.zoneDef

	if success then
		runtime.bossCleared = true
		runtime.bossHp = 0
		runtime.lastOutcomeMessage = nil
		DungeonZoneRuntime.grantKeysAfterClear(runtime, grantKeyFn)
	else
		runtime.bossHp = runtime.bossMaxHp
		runtime.lastOutcomeMessage = string.format(
			"Boss down but need %d players in zone — no key (had %d)",
			zoneDef.minToSucceed,
			#DungeonZoneRuntime.getPlayersInZone(runtime)
		)
		task.delay(8, function()
			if runtime.lastOutcomeMessage and not runtime.bossCleared then
				runtime.lastOutcomeMessage = nil
			end
		end)
	end
end

function DungeonZoneRuntime.applyBossDamage(
	runtime: ZoneRuntime,
	attacker: Player,
	state: ZonePlayerState,
	loadout: PrismDeathValleyDungeonConfig.PlayerLoadout?,
	defaultDamage: number
): boolean
	if not runtime.bossActive or runtime.bossCleared then
		return false
	end

	state.bossHitCount += 1
	state.assistCount += 1
	DungeonZoneRuntime.syncContributionAttributes(attacker, state)

	local damage = if loadout
		then DungeonLoadoutCalculator.getBossHitDamage(loadout)
		else defaultDamage

	runtime.bossHp = math.max(0, runtime.bossHp - damage)

	if runtime.bossHp <= 0 then
		local count = #DungeonZoneRuntime.getPlayersInZone(runtime)
		return count >= runtime.zoneDef.minToSucceed
	end
	return false
end

return DungeonZoneRuntime
