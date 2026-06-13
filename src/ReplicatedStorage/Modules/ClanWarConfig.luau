--!strict
--[[
	ClanWarConfig (P5) — territory siege, tax split, maintenance, fatigue, war schedule
]]
local ClanWarConfig = {}

export type ZoneDef = {
	id: string,
	displayName: string,
}

ClanWarConfig.TaxSplit = {
	ClanVault = 0.50,
	MemberShare = 0.30,
	ServerBuff = 0.20,
}

ClanWarConfig.MaintenanceMultiplier = {
	[1] = 1.0,
	[2] = 1.5,
	[3] = 2.5,
	[4] = 4.0,
	[5] = 6.5,
} :: { [number]: number }

ClanWarConfig.BaseMaintenanceCost = 100
ClanWarConfig.FortHpDecayPerWeek = 5
ClanWarConfig.FortHpMinimum = 40
ClanWarConfig.FortHpMax = 100

-- Saturday 20:00 Thai (UTC+7) = 13:00 UTC
ClanWarConfig.WarDayOfWeek = 6
ClanWarConfig.WarStartHourUTC = 13
ClanWarConfig.WarDurationSecs = 45 * 60

ClanWarConfig.Zones = {
	{ id = "marina", displayName = "Marina District" },
	{ id = "aurora", displayName = "Aurora Spire" },
	{ id = "canal", displayName = "Canal Promenade" },
} :: { ZoneDef }

ClanWarConfig.MinClanLevelForWar = 3
ClanWarConfig.ServerBuffDurationDays = 7
ClanWarConfig.ServerBuffDropRateBonus = 0.05

return ClanWarConfig
