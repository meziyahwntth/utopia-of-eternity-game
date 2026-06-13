--!strict
--[[
	FusionConfig — fuse 2 duplicate items → upgraded output (glow tier)
]]
export type FusionRecipe = {
	inputItem: string,
	outputItem: string,
	creditCost: number,
}

local FusionConfig = {}

FusionConfig.Recipes = {
	{ inputItem = "StoneFragment", outputItem = "IronOre", creditCost = 50 },
	{ inputItem = "IronOre", outputItem = "MagicCrystal", creditCost = 100 },
	{ inputItem = "StarSword2", outputItem = "StarSword3", creditCost = 300 },
	{ inputItem = "StarSword3", outputItem = "StarSword4", creditCost = 800 },
	{ inputItem = "CardCommon", outputItem = "CardRare", creditCost = 200 },
	{ inputItem = "CardRare", outputItem = "CardLegendary", creditCost = 500 },
} :: { FusionRecipe }

return FusionConfig
