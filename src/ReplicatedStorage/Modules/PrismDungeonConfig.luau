--!strict
--[[
	Social co-op dungeons — every city · team 2/5/10/20/50
	50% to enter boss · 75% to succeed
	Design: docs/SOCIAL-DUNGEON-SYSTEM.md
]]

export type TeamTierId = "duo" | "squad" | "raid10" | "raid20" | "raid50"

export type TeamTier = {
	id: TeamTierId,
	nominalSize: number,
	minToEnterBoss: number,
	minToSucceed: number,
	label: string,
}

export type DungeonDef = {
	id: string,
	displayName: string,
	placeKey: string,
	theme: string,
	bossName: string,
	gateZoneId: string,
}

local PrismDungeonConfig = {}

PrismDungeonConfig.EntryRatio = 0.50
PrismDungeonConfig.SuccessRatio = 0.75

PrismDungeonConfig.TeamTiers = {
	{ id = "duo", nominalSize = 2, minToEnterBoss = 1, minToSucceed = 2, label = "ทีม 2 คน" },
	{ id = "squad", nominalSize = 5, minToEnterBoss = 3, minToSucceed = 4, label = "ทีม 5 คน" },
	{ id = "raid10", nominalSize = 10, minToEnterBoss = 5, minToSucceed = 8, label = "ทีม 10 คน" },
	{ id = "raid20", nominalSize = 20, minToEnterBoss = 10, minToSucceed = 15, label = "ทีม 20 คน" },
	{ id = "raid50", nominalSize = 50, minToEnterBoss = 25, minToSucceed = 38, label = "ทีม 50 คน" },
}

PrismDungeonConfig.Dungeons = {
	{ id = "hub_museum_vault", displayName = "Museum Vault", placeKey = "Hub", theme = "puzzle_lore", bossName = "Curator Phantom", gateZoneId = "MuseumDome" },
	{ id = "hub_fountain_depths", displayName = "Fountain Depths", placeKey = "Hub", theme = "water_cipher", bossName = "Prism Drowned Echo", gateZoneId = "CentralFountain" },
	{ id = "sol_garden_catacombs", displayName = "Garden Catacombs", placeKey = "Solhaven", theme = "root_maze", bossName = "Bloom Wraith", gateZoneId = "GardenStage_3" },
	{ id = "sol_lighthouse_deep", displayName = "Lighthouse Deep", placeKey = "Solhaven", theme = "light_beam", bossName = "Beacon Keeper Shade", gateZoneId = "Lighthouse" },
	{ id = "noc_jazz_understage", displayName = "Jazz Understage", placeKey = "Nocturne", theme = "rhythm_clue", bossName = "Maestro Shadow", gateZoneId = "JazzLounge" },
	{ id = "noc_clock_undercroft", displayName = "Clock Undercroft", placeKey = "Nocturne", theme = "cipher_333", bossName = "Tick Titan Echo", gateZoneId = "ClockTower" },
	{ id = "et_data_vault_raid", displayName = "Data Vault Raid", placeKey = "EternityCity", theme = "cipher_tower", bossName = "Archive Sentinel", gateZoneId = "AuroraSpireDistrict" },
	{ id = "et_skyrail_maintenance", displayName = "Sky Rail Maintenance", placeKey = "EternityCity", theme = "vertical_rail", bossName = "Conductors' Ghost", gateZoneId = "SkyRailPlaza" },
	{ id = "dv_mega_abyss", displayName = "หุบเขามรณะ Mega Abyss", placeKey = "DeathValley", theme = "progressive_2_to_50", bossName = "Triad Wraith Sovereign", gateZoneId = "DeathValleyCore" },
}

function PrismDungeonConfig.getTier(id: TeamTierId): TeamTier?
	for _, tier in PrismDungeonConfig.TeamTiers do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

function PrismDungeonConfig.getDungeonsForPlace(placeKey: string): { DungeonDef }
	local list: { DungeonDef } = {}
	for _, d in PrismDungeonConfig.Dungeons do
		if d.placeKey == placeKey then
			table.insert(list, d)
		end
	end
	return list
end

function PrismDungeonConfig.canEnterBoss(tier: TeamTier, presentCount: number): boolean
	return presentCount >= tier.minToEnterBoss
end

function PrismDungeonConfig.canSucceed(tier: TeamTier, presentCount: number): boolean
	return presentCount >= tier.minToSucceed
end

function PrismDungeonConfig.computeThresholds(nominalSize: number): (number, number)
	local enter = math.ceil(nominalSize * PrismDungeonConfig.EntryRatio)
	local succeed = math.ceil(nominalSize * PrismDungeonConfig.SuccessRatio)
	return enter, succeed
end

return PrismDungeonConfig
