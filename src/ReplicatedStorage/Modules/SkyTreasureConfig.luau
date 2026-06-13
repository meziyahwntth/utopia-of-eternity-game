--!strict
--[[
	SkyTreasureConfig (P6) — live-ops sky treasure spawn + reward pool
]]
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

SkyTreasureConfig.SpawnPoints = {
	{ id = "marina_dock", position = Vector3.new(120, 2010, -80), displayName = "Marina Dock" },
	{ id = "aurora_plaza", position = Vector3.new(-40, 2010, 200), displayName = "Aurora Plaza" },
	{ id = "canal_bridge", position = Vector3.new(60, 2010, 350), displayName = "Canal Bridge" },
	{ id = "sky_rail_north", position = Vector3.new(-200, 2010, 0), displayName = "Sky Rail North" },
	{ id = "market_square", position = Vector3.new(0, 2010, -200), displayName = "Market Square" },
} :: { SpawnPoint }

SkyTreasureConfig.Rewards = {
	{ type = "credits", amount = 5000, weight = 40, label = "💰 5,000 Credits" },
	{ type = "credits", amount = 20000, weight = 20, label = "💰 20,000 Credits" },
	{ type = "item", itemId = "StoneFragment", weight = 25, label = "✨ Grandeur Fragment" },
	{ type = "item", itemId = "MagicCrystal", weight = 10, label = "🔑 Rare Key Bundle" },
	{ type = "item", itemId = "IronOre", weight = 5, label = "🪙 Lucky Gold Coin" },
} :: { RewardEntry }

return SkyTreasureConfig
