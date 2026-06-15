--!strict
--[[
	Death Valley Phase A — Beacon, night cycle, wraith wave tuning.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartySizeScaling = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PartySizeScaling"))

export type WraithKind = "Whisper" | "Stalker" | "LegionEcho"
export type NightPhase = "prep" | "wave" | "intermission"

export type NightModifierId = "echo_raid" | "spirit_breach" | "hollow_surge" | "legion_muster" | "none"

export type NightModifierDef = {
	id: NightModifierId,
	displayName: string,
	description: string,
	extraWhispers: number,
	extraStalkers: number,
	extraLegion: number,
	fuelDrainMultiplier: number,
	waveSecondsBonus: number,
	wraithSpeedMultiplier: number,
	wraithHealthMultiplier: number,
}

export type ExpansionRingDef = {
	ring: number,
	minNightsSurvived: number,
	displayName: string,
	zoneId: string,
}

export type PoiDef = {
	id: string,
	displayName: string,
	ring: number,
	position: Vector3,
	clueText: string?,
	prismKeyHint: number?,
	optInScare: boolean?,
}

export type SeasonRankRewardTier = {
	maxRank: number,
	minNights: number?,
	shards: number,
	label: string,
	displayTitle: string?,
	cosmeticId: string?,
}

export type WeeklyBossDef = {
	id: string,
	displayName: string,
	baseHp: number,
	hpPerPlayer: number,
	damagePerHit: number,
	shardReward: number,
}

export type BeaconLevelDef = {
	level: number,
	radiusStuds: number,
	maxFuel: number,
	upgradeShardCost: number,
}

export type WraithDef = {
	kind: WraithKind,
	displayName: string,
	maxHealth: number,
	touchDamage: number,
	walkSpeed: number,
	color: Color3,
	size: Vector3,
}

local PrismDeathValleySurvivalConfig = {}

PrismDeathValleySurvivalConfig.BeaconOrigin = Vector3.new(0, 0, 0)

PrismDeathValleySurvivalConfig.BeaconLevels = {
	{ level = 1, radiusStuds = 60, maxFuel = 100, upgradeShardCost = 0 },
	{ level = 2, radiusStuds = 90, maxFuel = 150, upgradeShardCost = 25 },
	{ level = 3, radiusStuds = 120, maxFuel = 200, upgradeShardCost = 50 },
}

PrismDeathValleySurvivalConfig.FuelDepositAmount = 15
PrismDeathValleySurvivalConfig.FuelDrainPerSecond = 0.35
PrismDeathValleySurvivalConfig.PrepSeconds = 30
PrismDeathValleySurvivalConfig.WaveSeconds = 90
PrismDeathValleySurvivalConfig.IntermissionSeconds = 8

PrismDeathValleySurvivalConfig.Wraiths = {
	Whisper = {
		kind = "Whisper",
		displayName = "Wraith Whisper",
		maxHealth = 40,
		touchDamage = 12,
		walkSpeed = 12,
		color = Color3.fromRGB(140, 100, 200),
		size = Vector3.new(3, 6, 3),
	},
	Stalker = {
		kind = "Stalker",
		displayName = "Shard Stalker",
		maxHealth = 55,
		touchDamage = 18,
		walkSpeed = 20,
		color = Color3.fromRGB(80, 200, 220),
		size = Vector3.new(3.5, 7, 3.5),
	},
	LegionEcho = {
		kind = "LegionEcho",
		displayName = "Legion Echo",
		maxHealth = 120,
		touchDamage = 25,
		walkSpeed = 10,
		color = Color3.fromRGB(200, 60, 80),
		size = Vector3.new(5, 9, 5),
	},
}

PrismDeathValleySurvivalConfig.BaseWraithsPerWave = 2
PrismDeathValleySurvivalConfig.WraithsPerPartyMember = 1 -- legacy; wave count now uses PartySizeScaling hpMult
PrismDeathValleySurvivalConfig.WraithsPerThreeNights = 1

PrismDeathValleySurvivalConfig.Revive = {
	DownedSeconds = 45,
	ChannelSeconds = 3,
	ReviveHealthPercent = 0.5,
	SoloAutoReviveSeconds = 5,
	MaxReviveDistanceStuds = 18,
}

PrismDeathValleySurvivalConfig.StartingLuminiteShards = 30

-- Combat loop — ผู้เล่นกด strike ใส่ wraith ที่ใกล้สุดในระยะ (no-P2W: ดาเมจคงที่ ไม่ขึ้นกับของซื้อ)
PrismDeathValleySurvivalConfig.Combat = {
	BaseDamage = 20,
	AttackRangeStuds = 16,
	AttackCooldownSeconds = 0.45,
	ShardRewards = {
		Whisper = 2,
		Stalker = 3,
		LegionEcho = 8,
	} :: { [string]: number },
}

PrismDeathValleySurvivalConfig.CheckpointMinBeaconLevel = 3
PrismDeathValleySurvivalConfig.WeeklyBossMinRing = 3
PrismDeathValleySurvivalConfig.SeasonalRingMinRing = 4
PrismDeathValleySurvivalConfig.SeasonalShrineShardReward = 25

PrismDeathValleySurvivalConfig.SeasonRankRewards = {
	{
		maxRank = 1,
		shards = 100,
		label = "Champion",
		displayTitle = "Echo Champion",
		cosmeticId = "dv_aura_echo_champion",
	},
	{
		maxRank = 3,
		shards = 50,
		label = "Elite",
		displayTitle = "Hellbound Elite",
		cosmeticId = "dv_aura_hellbound_elite",
	},
	{
		maxRank = 10,
		shards = 25,
		label = "Veteran",
		displayTitle = "Night Veteran",
		cosmeticId = "dv_trail_night_veteran",
	},
	{
		maxRank = 25,
		shards = 10,
		label = "Survivor",
		displayTitle = "Valley Survivor",
		cosmeticId = "dv_badge_valley_survivor",
	},
	{
		maxRank = 999,
		minNights = 1,
		shards = 5,
		label = "Participant",
		displayTitle = "Echo Participant",
		cosmeticId = "dv_badge_echo_participant",
	},
}

PrismDeathValleySurvivalConfig.WeeklyBosses = {
	{ id = "echo_tyrant", displayName = "Echo Tyrant", baseHp = 800, hpPerPlayer = 120, damagePerHit = 25, shardReward = 15 },
	{ id = "hollow_leviathan", displayName = "Hollow Leviathan", baseHp = 1000, hpPerPlayer = 150, damagePerHit = 22, shardReward = 18 },
	{ id = "legion_avatar", displayName = "Legion Avatar", baseHp = 1200, hpPerPlayer = 180, damagePerHit = 20, shardReward = 20 },
}

PrismDeathValleySurvivalConfig.NightModifiers = {
	{
		id = "echo_raid",
		displayName = "Echo Raid",
		description = "Whispers multiply — fuel burns faster",
		extraWhispers = 2,
		extraStalkers = 0,
		extraLegion = 0,
		fuelDrainMultiplier = 1.15,
		waveSecondsBonus = 0,
		wraithSpeedMultiplier = 1,
		wraithHealthMultiplier = 1,
	},
	{
		id = "spirit_breach",
		displayName = "Spirit Breach",
		description = "Stalkers slip through the light — longer wave",
		extraWhispers = 0,
		extraStalkers = 1,
		extraLegion = 0,
		fuelDrainMultiplier = 1,
		waveSecondsBonus = 15,
		wraithSpeedMultiplier = 1.1,
		wraithHealthMultiplier = 1,
	},
	{
		id = "hollow_surge",
		displayName = "Hollow Surge",
		description = "Shard Stalkers rush — Hollow Lake stirs",
		extraWhispers = 0,
		extraStalkers = 2,
		extraLegion = 0,
		fuelDrainMultiplier = 1.05,
		waveSecondsBonus = 0,
		wraithSpeedMultiplier = 1.25,
		wraithHealthMultiplier = 1.05,
	},
	{
		id = "legion_muster",
		displayName = "Legion Muster",
		description = "Legion Echo awakens — wraiths endure more",
		extraWhispers = 0,
		extraStalkers = 0,
		extraLegion = 1,
		fuelDrainMultiplier = 1.1,
		waveSecondsBonus = 10,
		wraithSpeedMultiplier = 1,
		wraithHealthMultiplier = 1.2,
	},
}

PrismDeathValleySurvivalConfig.ExpansionRings = {
	{ ring = 0, minNightsSurvived = 0, displayName = "Sanctuary Core", zoneId = "SanctuaryCore" },
	{ ring = 1, minNightsSurvived = 5, displayName = "POI Frontier", zoneId = "PoiFrontier" },
	{ ring = 2, minNightsSurvived = 15, displayName = "Deep Wilds", zoneId = "DeepWilds" },
	{ ring = 3, minNightsSurvived = 20, displayName = "Mega Abyss Gate", zoneId = "MegaDungeonGate" },
	{ ring = 4, minNightsSurvived = 30, displayName = "Seasonal Echo Frontier", zoneId = "SeasonalFrontier" },
}

PrismDeathValleySurvivalConfig.POIs = {
	{
		id = "whispering_grove",
		displayName = "Whispering Grove",
		ring = 1,
		position = Vector3.new(-95, 2, -45),
		clueText = "... --- ... · Prism Key #8 hides where whispers gather",
		prismKeyHint = 8,
		optInScare = false,
	},
	{
		id = "hollow_lake",
		displayName = "Hollow Lake",
		ring = 1,
		position = Vector3.new(110, 0, -70),
		clueText = "Prism Key #10 — only the brave descend (opt-in scare)",
		prismKeyHint = 10,
		optInScare = true,
	},
	{
		id = "seasonal_echo_shrine",
		displayName = "Seasonal Echo Shrine",
		ring = 4,
		position = Vector3.new(-130, 2, 90),
		clueText = "Ring 4 — claim seasonal Luminite once per season",
		optInScare = false,
	},
}

function PrismDeathValleySurvivalConfig.getBeaconLevel(level: number): BeaconLevelDef
	for _, def in PrismDeathValleySurvivalConfig.BeaconLevels do
		if def.level == level then
			return def
		end
	end
	return PrismDeathValleySurvivalConfig.BeaconLevels[1]
end

function PrismDeathValleySurvivalConfig.getNightModifier(nightNumber: number): NightModifierDef
	if nightNumber < 5 then
		return {
			id = "none" :: NightModifierId,
			displayName = "Calm Night",
			description = "Standard wraith activity",
			extraWhispers = 0,
			extraStalkers = 0,
			extraLegion = 0,
			fuelDrainMultiplier = 1,
			waveSecondsBonus = 0,
			wraithSpeedMultiplier = 1,
			wraithHealthMultiplier = 1,
		}
	end
	local index = math.floor((nightNumber - 1) / 5) % #PrismDeathValleySurvivalConfig.NightModifiers
	return PrismDeathValleySurvivalConfig.NightModifiers[index + 1]
end

function PrismDeathValleySurvivalConfig.getUnlockedRing(nightsSurvived: number): number
	local ring = 0
	for _, def in PrismDeathValleySurvivalConfig.ExpansionRings do
		if nightsSurvived >= def.minNightsSurvived then
			ring = def.ring
		end
	end
	return ring
end

function PrismDeathValleySurvivalConfig.getRingDef(ring: number): ExpansionRingDef?
	for _, def in PrismDeathValleySurvivalConfig.ExpansionRings do
		if def.ring == ring then
			return def
		end
	end
	return nil
end

function PrismDeathValleySurvivalConfig.getWraithKindsForNight(nightNumber: number): { WraithKind }
	local kinds: { WraithKind } = { "Whisper" }
	if nightNumber >= 3 then
		table.insert(kinds, "Stalker")
	end
	if nightNumber >= 5 and nightNumber % 3 == 0 then
		table.insert(kinds, "LegionEcho")
	end
	return kinds
end

function PrismDeathValleySurvivalConfig.computeWraithCount(nightNumber: number, partySize: number, modifier: NightModifierDef?): number
	local mod = modifier or PrismDeathValleySurvivalConfig.getNightModifier(nightNumber)
	local scale = PartySizeScaling.compute(partySize)
	local core = PrismDeathValleySurvivalConfig.BaseWraithsPerWave
		+ math.floor(nightNumber / 3) * PrismDeathValleySurvivalConfig.WraithsPerThreeNights
	-- Solo: fewer wraiths (core × 1.0). Party: more wraiths via hpMult curve. Night modifier extras unchanged.
	local count = math.floor(core * scale.hpMult)
		+ mod.extraWhispers
		+ mod.extraStalkers
		+ mod.extraLegion
	return math.clamp(count, 2, 28)
end

return PrismDeathValleySurvivalConfig
