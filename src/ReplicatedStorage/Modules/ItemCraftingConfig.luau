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
} :: { [string]: GrandeurRecipe }

return ItemCraftingConfig
