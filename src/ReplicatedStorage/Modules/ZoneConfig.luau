--!strict
--[[
	ZoneConfig — Eternity City visit zones for daily quest proximity checks
	World Y = SkyAltitude(2000) + localFloor(4) = 2004
]]
export type ZoneEntry = {
	id: string,
	nameTH: string,
	center: Vector3,
	radius: number,
}

local SKY_Y = 2004

local ZoneConfig = {}

ZoneConfig.Zones = {
	{
		id = "marina",
		nameTH = "Marina District",
		center = Vector3.new(180, SKY_Y, -80),
		radius = 120,
	},
	{
		id = "aurora",
		nameTH = "Aurora Spire",
		center = Vector3.new(0, SKY_Y, -120),
		radius = 100,
	},
	{
		id = "canal",
		nameTH = "Canal Promenade",
		center = Vector3.new(-100, SKY_Y, 80),
		radius = 120,
	},
	{
		id = "skyrail",
		nameTH = "Sky Rail Plaza",
		center = Vector3.new(0, SKY_Y, 40),
		radius = 100,
	},
} :: { ZoneEntry }

ZoneConfig.CHECK_INTERVAL = 2.0

return ZoneConfig
