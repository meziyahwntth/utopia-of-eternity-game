--!strict
--[[
	Developer Product ID map + UGC asset placeholders.
	Replace productId with Creator Dashboard IDs before publish.
	See docs/ugc/BLOCKBENCH-PIPELINE.md
]]
local PrismCatalogAssets = {}

-- 0 = dev mode free grant via CommerceShopService
PrismCatalogAssets.DeveloperProducts = {} :: { [string]: number }

-- Legendary weapons — ChatGPT concept art catalog (see PrismLegendaryWeaponsCatalog.luau)
PrismCatalogAssets.Weapons = (function()
	local catalog = require(script.Parent:WaitForChild("PrismLegendaryWeaponsCatalog"))
	return catalog.toCommerceEntries()
end)()

PrismCatalogAssets.Vehicles = {
	{ id = "big_bike", displayName = "Big Bike", robux = 799, category = "land" },
	{ id = "sports_car", displayName = "Sports Car", robux = 999, category = "land" },
	{ id = "sedan", displayName = "Sedan", robux = 899, category = "land" },
	{ id = "pickup_truck", displayName = "Pickup Truck", robux = 899, category = "land" },
	{ id = "pegasus_mount", displayName = "Pegasus", robux = 1999, category = "mount" },
	{ id = "griffin_mount", displayName = "Griffin", robux = 2499, category = "mount" },
	{ id = "dragon_mount", displayName = "Dragon", robux = 2999, category = "mount" },
}

PrismCatalogAssets.VehiclePaints = {
	{ id = "paint_premium_pearl", displayName = "Pearl Prism Coat", robux = 699, tier = "premium" },
	{ id = "paint_premium_aurora", displayName = "Aurora Gradient", robux = 899, tier = "premium" },
	{ id = "paint_budget_red", displayName = "Street Red", robux = 149, tier = "budget" },
	{ id = "paint_budget_blue", displayName = "Street Blue", robux = 149, tier = "budget" },
}

PrismCatalogAssets.BeautyServices = {
	{ id = "hair_cut_basic", displayName = "Hair Restyle", robux = 199, shopType = "StellarSalon" },
	{ id = "hair_extension", displayName = "Hair Extension Pack", robux = 399, shopType = "StellarSalon" },
	{ id = "skin_tone_pack", displayName = "Skin Tone Palette", robux = 299, shopType = "PrismBeauty" },
	{ id = "makeup_glow", displayName = "Prism Makeup Glow", robux = 249, shopType = "PrismBeauty" },
	{ id = "face_morph_preset", displayName = "Face Morph Preset", robux = 999, shopType = "EternityAesthetics" },
}

-- UGC mesh asset IDs (0 until uploaded to Roblox catalog)
PrismCatalogAssets.UgcMeshes = {} :: { [string]: number }

for _, weapon in PrismCatalogAssets.Weapons do
	PrismCatalogAssets.UgcMeshes[weapon.id] = 0
end

function PrismCatalogAssets.getProductId(itemId: string): number
	return PrismCatalogAssets.DeveloperProducts[itemId] or 0
end

function PrismCatalogAssets.getMeshId(itemId: string): number
	return PrismCatalogAssets.UgcMeshes[itemId] or 0
end

function PrismCatalogAssets.registerProduct(itemId: string, developerProductId: number)
	PrismCatalogAssets.DeveloperProducts[itemId] = developerProductId
end

function PrismCatalogAssets.registerMesh(itemId: string, assetId: number)
	PrismCatalogAssets.UgcMeshes[itemId] = assetId
end

-- Tier S Blockbench queue — see assets/ugc/blockbench/tier-s/manifest.json
PrismCatalogAssets.TierSMeshIds = {
	"coquette_lace_dress",
	"coquette_bow_hair",
	"coquette_mary_janes",
	"coquette_ribbon_choker",
	"oldmoney_linen_blazer",
	"oldmoney_tailored_pants",
	"oldmoney_pearl_stack",
	"oldmoney_loafers",
	"oldmoney_clutch",
	"gothic_corset_top",
	"gothic_layer_skirt",
	"gothic_choker_stack",
	"gothic_platform_boots",
	"preppy_sweater_vest",
	"preppy_plaid_skirt",
	"preppy_mary_janes",
	"preppy_ribbon_bow",
	"preppy_designer_bag",
}

return PrismCatalogAssets
