--!strict
--[[
	MvpBossConfig — rotating world bosses in Eternity City (4h interval)
]]
export type BossReward = {
	xp: number,
	credits: number,
	itemId: string?,
	mvpItemId: string?,
	mvpPetId: string?,
	mvpPetChance: number?,
}

export type MvpBossDef = {
	id: string,
	nameTH: string,
	emoji: string,
	baseHp: number,
	hpPerPlayer: number,
	damagePerHit: number,
	spawnPos: Vector3,
	reward: BossReward,
}

local FLOOR_Y = 2004

local MvpBossConfig = {}

MvpBossConfig.Bosses = {
	{
		id = "void_colossus",
		nameTH = "ยักษ์ว่างเปล่า",
		emoji = "👁️",
		baseHp = 5000,
		hpPerPlayer = 500,
		damagePerHit = 100,
		spawnPos = Vector3.new(0, FLOOR_Y + 10, 0),
		reward = {
			xp = 800,
			credits = 300,
			itemId = "MagicCrystal",
			mvpItemId = "CardLegendary",
		},
	},
	{
		id = "storm_titan",
		nameTH = "ไทแทนพายุ",
		emoji = "⚡",
		baseHp = 7000,
		hpPerPlayer = 700,
		damagePerHit = 120,
		spawnPos = Vector3.new(100, FLOOR_Y + 10, -80),
		reward = {
			xp = 1000,
			credits = 400,
			itemId = "CardRare",
			mvpItemId = "GrailFragment",
		},
	},
	{
		id = "eternal_warden",
		nameTH = "ผู้พิทักษ์นิรันดร์",
		emoji = "⚔️",
		baseHp = 10000,
		hpPerPlayer = 1000,
		damagePerHit = 80,
		spawnPos = Vector3.new(-80, FLOOR_Y + 10, 100),
		reward = {
			xp = 1500,
			credits = 600,
			itemId = "CardRare",
			mvpItemId = "EternityGrail",
			mvpPetId = "void_imp",
			mvpPetChance = 0.10,
		},
	},
} :: { MvpBossDef }

MvpBossConfig.SPAWN_INTERVAL_SECONDS = 4 * 60 * 60
MvpBossConfig.MVP_TOP_N = 3

return MvpBossConfig
