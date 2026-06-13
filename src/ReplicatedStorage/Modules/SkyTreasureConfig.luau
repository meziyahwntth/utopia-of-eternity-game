--!strict
--[[
	SkyTreasureConfig (P6) — live-ops sky treasure spawn + reward pool
	Spawn Y = EternityCity SkyAltitude (2000) + walkable floor offset (~4 studs)
]]
local WorldBuildConfig = require(script.Parent:WaitForChild("WorldBuildConfig"))

type PlaceKey = WorldBuildConfig.PlaceKey
local eternityProfile = WorldBuildConfig.Profiles[("EternityCity" :: PlaceKey)]
local SKY_ALTITUDE = eternityProfile.SkyAltitude
local FLOOR_OFFSET = 4

local function skyPos(x: number, localY: number, z: number): Vector3
	return Vector3.new(x, SKY_ALTITUDE + localY + FLOOR_OFFSET, z)
end

local SkyTreasureConfig = {}

export type SpawnPoint = {
	id: string,
	position: Vector3,
	displayName: string,
}

export type RewardEntry = {
	type: "credits" | "item",
	amount: number?,
	itemId: string?,
	weight: number,
	label: string,
}

SkyTreasureConfig.IntervalSeconds = 7200
SkyTreasureConfig.DefendSeconds = 180
SkyTreasureConfig.ChestsPerEvent = 3
SkyTreasureConfig.ClaimRadius = 20
SkyTreasureConfig.SkyAltitude = SKY_ALTITUDE
SkyTreasureConfig.FloorOffset = FLOOR_OFFSET

-- Landmark XZ from EternityCityWorldBuilder greybox anchors (local Y baked per site)
SkyTreasureConfig.SpawnPoints = {
	{ id = "marina_dock", position = skyPos(180, 0, -80), displayName = "Marina Dock" },
	{ id = "aurora_plaza", position = skyPos(0, 0, -120), displayName = "Aurora Plaza" },
	{ id = "canal_bridge", position = skyPos(80, 3, -40), displayName = "Canal Bridge" },
	{ id = "sky_rail_north", position = skyPos(-40, 6, 60), displayName = "Sky Rail North" },
	{ id = "market_square", position = skyPos(0, 0, 42), displayName = "Market Square" },
} :: { SpawnPoint }

SkyTreasureConfig.Rewards = {
	{ type = "credits", amount = 5000, weight = 40, label = "💰 5,000 Credits" },
	{ type = "credits", amount = 20000, weight = 20, label = "💰 20,000 Credits" },
	{ type = "item", itemId = "StoneFragment", weight = 25, label = "✨ Grandeur Fragment" },
	{ type = "item", itemId = "MagicCrystal", weight = 10, label = "🔑 Rare Key Bundle" },
	{ type = "item", itemId = "IronOre", weight = 5, label = "🪙 Lucky Gold Coin" },
} :: { RewardEntry }

return SkyTreasureConfig
