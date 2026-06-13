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
	{ inputItem = "StarBow1", outputItem = "StarBow2", creditCost = 400 },
	{ inputItem = "StarBow2", outputItem = "StarBow3", creditCost = 1200 },
	{ inputItem = "StarBow3", outputItem = "StarBow4", creditCost = 3000 },
	{ inputItem = "StarStaff1", outputItem = "StarStaff2", creditCost = 400 },
	{ inputItem = "StarStaff2", outputItem = "StarStaff3", creditCost = 1200 },
	{ inputItem = "StarStaff3", outputItem = "StarStaff4", creditCost = 3000 },
	{ inputItem = "CardCommon", outputItem = "CardRare", creditCost = 200 },
	{ inputItem = "CardRare", outputItem = "CardLegendary", creditCost = 500 },
} :: { FusionRecipe }

return FusionConfig
