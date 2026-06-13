--!strict
--[[
	ItemTierConfig (P4) — item tier, grandeur rank, weight, weapon type gating
]]
local ItemTierConfig = {}

export type WeaponType = "Sword" | "Bow" | "Staff" | "None"

export type ItemDef = {
	id: string,
	name: string,
	requiredLevel: number,
	grandeurRank: number,
	weight: number,
	weaponType: WeaponType,
	tradeable: boolean,
}

ItemTierConfig.Items = {
	StoneFragment = {
		id = "StoneFragment",
		name = "เศษหิน",
		requiredLevel = 1,
		grandeurRank = 0,
		weight = 0.1,
		weaponType = "None",
		tradeable = true,
	},
	IronOre = {
		id = "IronOre",
		name = "แร่เหล็ก",
		requiredLevel = 16,
		grandeurRank = 0,
		weight = 0.5,
		weaponType = "None",
		tradeable = true,
	},
	MagicCrystal = {
		id = "MagicCrystal",
		name = "คริสตัลเวท",
		requiredLevel = 30,
		grandeurRank = 1,
		weight = 0.3,
		weaponType = "None",
		tradeable = true,
	},
	StarSword2 = {
		id = "StarSword2",
		name = "★★ Sword",
		requiredLevel = 20,
		grandeurRank = 2,
		weight = 8,
		weaponType = "Sword",
		tradeable = true,
	},
	StarSword3 = {
		id = "StarSword3",
		name = "★★★ Sword",
		requiredLevel = 40,
		grandeurRank = 3,
		weight = 10,
		weaponType = "Sword",
		tradeable = true,
	},
} :: { [string]: ItemDef }

function ItemTierConfig.get(itemId: string): ItemDef?
	return ItemTierConfig.Items[itemId]
end

return ItemTierConfig
