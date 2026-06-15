--!strict
--[[
	หุบเขามรณะ Mega Dungeon — 5 zones 2→5→10→20→50
	Design: docs/DEATH-VALLEY-MEGA-DUNGEON.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartySizeScaling = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PartySizeScaling"))

export type DungeonRoleId =
	"BossStriker"
	| "AddStriker"
	| "CombatMedic"
	| "PersonalMedic"
	| "HeavyGunner"
	| "AmmoRunner"
	| "Grenadier"

export type RoleContribution = {
	healAllyMin: number?,
	assistAttackMin: number?,
	bossHitMin: number?,
	transferAmmoMin: number?,
	grenadeOrTrapMin: number?,
}

export type ZoneDef = {
	id: string,
	displayName: string,
	zoneIndex: number,
	nominalTeamSize: number,
	minToEnterBoss: number,
	minToSucceed: number,
	rewardMultiplier: number,
	bossName: string,
	bossMaxHp: number?,
	baseShardReward: number?,
	damagePerAssistHit: number?,
}

local PrismDeathValleyDungeonConfig = {}

PrismDeathValleyDungeonConfig.MegaDungeonId = "dv_mega_abyss"
PrismDeathValleyDungeonConfig.DisplayName = "หุบเขามรณะ — Mega Abyss"
PrismDeathValleyDungeonConfig.RewardBonusPerZone = 0.10

PrismDeathValleyDungeonConfig.Zones = {
	{
		id = "duo_depth",
		displayName = "Zone 1 — Duo Depth",
		zoneIndex = 1,
		nominalTeamSize = 2,
		minToEnterBoss = 1,
		minToSucceed = 1, -- solo-viable baseline (PartySizeScaling count=1)
		rewardMultiplier = 1.0,
		bossName = "Wraith Pair",
		bossMaxHp = 240,
		baseShardReward = 10,
		damagePerAssistHit = 15,
	},
	{
		id = "squad_hollow",
		displayName = "Zone 2 — Squad Hollow",
		zoneIndex = 2,
		nominalTeamSize = 5,
		minToEnterBoss = 3,
		minToSucceed = 4,
		rewardMultiplier = 1.1,
		bossName = "Hollow Choir",
		bossMaxHp = 480,
		baseShardReward = 12,
		damagePerAssistHit = 18,
	},
	{
		id = "raid_cavern",
		displayName = "Zone 3 — Raid Cavern",
		zoneIndex = 3,
		nominalTeamSize = 10,
		minToEnterBoss = 5,
		minToSucceed = 8,
		rewardMultiplier = 1.2,
		bossName = "Spirit Colossus",
		bossMaxHp = 1200,
		baseShardReward = 15,
		damagePerAssistHit = 20,
	},
	{
		id = "legion_pass",
		displayName = "Zone 4 — Legion Pass",
		zoneIndex = 4,
		nominalTeamSize = 20,
		minToEnterBoss = 10,
		minToSucceed = 15,
		rewardMultiplier = 1.3,
		bossName = "Legion Warden",
		bossMaxHp = 2400,
		baseShardReward = 18,
		damagePerAssistHit = 22,
	},
	{
		id = "abyss_throne",
		displayName = "Zone 5 — Abyss Throne",
		zoneIndex = 5,
		nominalTeamSize = 50,
		minToEnterBoss = 25,
		minToSucceed = 38,
		rewardMultiplier = 1.4,
		bossName = "Triad Wraith Sovereign",
		bossMaxHp = 6000,
		baseShardReward = 20,
		damagePerAssistHit = 25,
	},
}

PrismDeathValleyDungeonConfig.WeightCap = 50

PrismDeathValleyDungeonConfig.MedicTeamSupply = {
	maxPieces = 50,
	weightPerPiece = 1,
	channelSeconds = 3,
	slowPercent = 0.80,
	lightWeaponsOnly = true,
}

PrismDeathValleyDungeonConfig.MedicPersonalKit = {
	weight = 1,
	channelSeconds = 9,
	slowPercent = 0.50,
	reusable = true,
}

PrismDeathValleyDungeonConfig.RoleContributions = {
	BossStriker = { bossHitMin = 8 },
	AddStriker = { bossHitMin = 6 },
	CombatMedic = { healAllyMin = 5, assistAttackMin = 3 },
	AmmoRunner = { transferAmmoMin = 5, assistAttackMin = 3 },
	Grenadier = { grenadeOrTrapMin = 5, assistAttackMin = 3 },
	HeavyGunner = { bossHitMin = 10 },
	PersonalMedic = { healAllyMin = 3, assistAttackMin = 2 },
}

PrismDeathValleyDungeonConfig.KeyPerZone = {
	keysPerPlayerPerZone = 1,
	requireFullPresence = true,
	requireRoleContribution = true,
	requireZoneClear = true,
}

export type LoadoutItemId =
	"medic_supply"
	| "personal_medic_kit"
	| "light_weapon"
	| "heavy_weapon"
	| "ammo_pack"
	| "grenade"
	| "trap"

export type LoadoutItemDef = {
	id: LoadoutItemId,
	displayName: string,
	weightPerUnit: number,
	maxCount: number,
	category: string,
}

export type PlayerLoadout = {
	role: DungeonRoleId,
	items: { [LoadoutItemId]: number },
	weaponSkins: {
		light: string?,
		heavy: string?,
	}?,
}

PrismDeathValleyDungeonConfig.LoadoutItems = {
	{ id = "medic_supply", displayName = "Team Medic Supply", weightPerUnit = 1, maxCount = 50, category = "medic" },
	{ id = "personal_medic_kit", displayName = "Personal Medic Kit", weightPerUnit = 1, maxCount = 1, category = "medic" },
	{ id = "light_weapon", displayName = "Light Weapon", weightPerUnit = 10, maxCount = 2, category = "weapon" },
	{ id = "heavy_weapon", displayName = "Heavy Weapon", weightPerUnit = 30, maxCount = 1, category = "weapon" },
	{ id = "ammo_pack", displayName = "Ammo Pack", weightPerUnit = 3, maxCount = 10, category = "ammo" },
	{ id = "grenade", displayName = "Spirit Grenade", weightPerUnit = 4, maxCount = 5, category = "explosive" },
	{ id = "trap", displayName = "Wraith Trap", weightPerUnit = 4, maxCount = 5, category = "explosive" },
}

PrismDeathValleyDungeonConfig.RoleLabels = {
	BossStriker = "Boss Striker",
	AddStriker = "Add Striker",
	CombatMedic = "Combat Medic",
	PersonalMedic = "Personal Medic",
	HeavyGunner = "Heavy Gunner",
	AmmoRunner = "Ammo Runner",
	Grenadier = "Grenadier",
}

PrismDeathValleyDungeonConfig.Zone1Roles = {
	"BossStriker",
	"AddStriker",
	"CombatMedic",
	"PersonalMedic",
}

function PrismDeathValleyDungeonConfig.getZone(zoneId: string): ZoneDef?
	for _, z in PrismDeathValleyDungeonConfig.Zones do
		if z.id == zoneId then
			return z
		end
	end
	return nil
end

function PrismDeathValleyDungeonConfig.getRewardMultiplier(zoneIndex: number): number
	return 1 + PrismDeathValleyDungeonConfig.RewardBonusPerZone * (zoneIndex - 1)
end

function PrismDeathValleyDungeonConfig.getBaseBossHp(zoneDef: ZoneDef): number
	return zoneDef.bossMaxHp or 240
end

function PrismDeathValleyDungeonConfig.getBaseClearShardReward(zoneDef: ZoneDef): number
	local base = zoneDef.baseShardReward or 10
	return math.floor(base * zoneDef.rewardMultiplier)
end

--[[
	Scale boss HP / clear reward from instance participant set (zonePlayers).
	Solo count=1 → hpMult=1, rewardMult=1 (baseline soloable).
]]
function PrismDeathValleyDungeonConfig.scaleBossHp(zoneDef: ZoneDef, participants: { [number]: boolean }): number
	local count = PartySizeScaling.countInSet(participants)
	return PartySizeScaling.scaleHp(PrismDeathValleyDungeonConfig.getBaseBossHp(zoneDef), count)
end

function PrismDeathValleyDungeonConfig.scaleClearReward(zoneDef: ZoneDef, participants: { [number]: boolean }): number
	local count = PartySizeScaling.countInSet(participants)
	local baseReward = PrismDeathValleyDungeonConfig.getBaseClearShardReward(zoneDef)
	return PartySizeScaling.scaleReward(baseReward, count)
end

return PrismDeathValleyDungeonConfig
