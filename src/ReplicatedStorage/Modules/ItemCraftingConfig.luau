--!strict
--[[
	ItemCraftingConfig (P4) — low-tier material sink recipes (grandeur upgrades)
]]
local ItemCraftingConfig = {}

export type MaterialReq = {
	id: string,
	qty: number,
}

export type GrandeurRecipe = {
	baseItem: string,
	materials: { MaterialReq },
	creditCost: number,
	outputItem: string,
}

ItemCraftingConfig.Grandeur = {
	["StarSword2"] = {
		baseItem = "StarSword1",
		materials = {
			{ id = "StoneFragment", qty = 100 },
			{ id = "IronOre", qty = 30 },
		},
		creditCost = 200,
		outputItem = "StarSword2",
	},
	["StarSword3"] = {
		baseItem = "StarSword2",
		materials = {
			{ id = "StoneFragment", qty = 500 },
			{ id = "IronOre", qty = 200 },
			{ id = "MagicCrystal", qty = 50 },
		},
		creditCost = 1000,
		outputItem = "StarSword3",
	},
	["IronArmor1"] = {
		baseItem = "LeatherArmor",
		materials = {
			{ id = "IronOre", qty = 50 },
			{ id = "StoneFragment", qty = 20 },
		},
		creditCost = 150,
		outputItem = "IronArmor1",
	},
} :: { [string]: GrandeurRecipe }

return ItemCraftingConfig
