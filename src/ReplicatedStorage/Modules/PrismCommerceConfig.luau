--!strict
--[[
	Commerce districts, peace zones, and shop registry for Eternity City.
	Design: docs/FASHION-AND-SHOPS-DESIGN.md
]]

export type PeaceZoneRule = {
	noPvP: boolean,
	noCombatTools: boolean,
	noVehicleRam: boolean,
	emoteBonus: boolean,
	griefingGuard: string,
}

export type CommerceTier = "luxury" | "street"

export type ShopEntry = {
	id: string,
	displayName: string,
	shopType: string,
	district: string,
	floor: number?,
	peaceZoneRadiusStuds: number,
	services: { string },
	commerceTier: CommerceTier,
	priceMultiplier: number,
	minPrismKeys: number,
}

local PrismCommerceConfig = {}

PrismCommerceConfig.PeaceZone = {
	noPvP = true,
	noCombatTools = true,
	noVehicleRam = true,
	emoteBonus = true,
	griefingGuard = "strict",
}

PrismCommerceConfig.Districts = {
	"AuroraMegaMall",
	"CanalBoutiqueRow",
	"MarinaShowroomStrip",
	"SkyRailPlaza",
	"WorldCulturePavilion",
	"TwilightOverpass",
	"HellboundTerminal",
}

-- Luxury mall in building: 3× Robux · ไม่ต้องมี Prism Key · ซื้อได้ทันทีถ้า Robux พอ
-- Street / outdoor shops: ราคาปกติ · ต้องผ่านเควส/กุญแจตาม minPrismKeys
PrismCommerceConfig.LuxuryMall = {
	Tier = "luxury" :: CommerceTier,
	PriceMultiplier = 3,
	MinPrismKeys = 0,
	DisplayName = "Eternity Luxury Galleria",
	Description = "ห้างในอาคาร — ราคา 3× · ไม่ต้องทำเควส · ซื้อได้ทันทีถ้า Robux พอ",
}

PrismCommerceConfig.Shops = {
	{
		id = "eternity_luxury_galleria",
		displayName = "Eternity Luxury Galleria",
		shopType = "LuxuryGalleria",
		district = "AuroraMegaMall",
		floor = 1,
		peaceZoneRadiusStuds = 120,
		services = { "all_catalog" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "prism_wardrobe",
		displayName = "Prism Wardrobe",
		shopType = "PrismWardrobe",
		district = "AuroraMegaMall",
		floor = 3,
		peaceZoneRadiusStuds = 80,
		services = { "clothing", "shoes", "hats", "bundles" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "accessory_lane",
		displayName = "Accessory & Jewelry Lane",
		shopType = "AccessoryLane",
		district = "CanalBoutiqueRow",
		peaceZoneRadiusStuds = 60,
		services = { "neck", "wrist", "face", "back" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 3,
	},
	{
		id = "world_culture_pavilion",
		displayName = "World Culture Pavilion",
		shopType = "WorldCulturePavilion",
		district = "AuroraMegaMall",
		floor = 15,
		peaceZoneRadiusStuds = 100,
		services = { "national_heritage", "national_modern" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "seasonal_pop_up",
		displayName = "Seasonal Pop-Up",
		shopType = "SeasonalPopUp",
		district = "SkyRailPlaza",
		peaceZoneRadiusStuds = 50,
		services = { "seasonal_sets" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 11,
	},
	{
		id = "stellar_salon",
		displayName = "Stellar Salon",
		shopType = "StellarSalon",
		district = "AuroraMegaMall",
		floor = 23,
		peaceZoneRadiusStuds = 40,
		services = { "hair", "hair_extension", "hair_dye" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "prism_beauty",
		displayName = "Prism Beauty Studio",
		shopType = "PrismBeauty",
		district = "AuroraMegaMall",
		floor = 22,
		peaceZoneRadiusStuds = 40,
		services = { "skin_tone", "makeup" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "eternity_aesthetics",
		displayName = "Eternity Aesthetics Clinic",
		shopType = "EternityAesthetics",
		district = "AuroraMegaMall",
		floor = 22,
		peaceZoneRadiusStuds = 40,
		services = { "face_morph_preset" },
		commerceTier = "luxury",
		priceMultiplier = 3,
		minPrismKeys = 0,
	},
	{
		id = "prism_motors",
		displayName = "Prism Motors Showroom",
		shopType = "PrismMotors",
		district = "MarinaShowroomStrip",
		peaceZoneRadiusStuds = 120,
		services = { "vehicle_purchase" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 10,
	},
	{
		id = "prism_service_center",
		displayName = "Prism Service Center",
		shopType = "PrismServiceCenter",
		district = "MarinaShowroomStrip",
		peaceZoneRadiusStuds = 80,
		services = { "vehicle_paint_premium", "vehicle_maintenance_cosmetic", "underglow" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 18,
	},
	{
		id = "neon_alley_tune",
		displayName = "Neon Alley Tune Shop",
		shopType = "NeonAlleyTune",
		district = "MarinaShowroomStrip",
		peaceZoneRadiusStuds = 60,
		services = { "vehicle_paint_budget", "stickers", "spoiler" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 5,
	},
	{
		id = "mount_emporium",
		displayName = "Mount Emporium",
		shopType = "MountEmporium",
		district = "SkyRailPlaza",
		peaceZoneRadiusStuds = 80,
		services = { "mount_purchase" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 15,
	},
	{
		id = "stable_care",
		displayName = "Stable Care",
		shopType = "StableCare",
		district = "SkyRailPlaza",
		peaceZoneRadiusStuds = 50,
		services = { "mount_grooming", "mount_food_cosmetic", "mount_nameplate" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 12,
	},
	{
		id = "luminling_clinic",
		displayName = "Luminling Pet Clinic",
		shopType = "LuminlingPetClinic",
		district = "CanalBoutiqueRow",
		peaceZoneRadiusStuds = 50,
		services = { "pet_heal", "pet_accessory" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 1,
	},
	{
		id = "sky_vet",
		displayName = "Sky Vet Wing",
		shopType = "StableCare",
		district = "SkyRailPlaza",
		peaceZoneRadiusStuds = 40,
		services = { "mount_heal_cosmetic" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 12,
	},
	{
		id = "weapon_gallery",
		displayName = "Prism Weapon Gallery",
		shopType = "PrismWeaponGallery",
		district = "SkyRailPlaza",
		peaceZoneRadiusStuds = 60,
		services = { "weapon_skin" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 15,
	},
	{
		id = "photo_boutique",
		displayName = "Photo Mode Boutique",
		shopType = "PhotoBoutique",
		district = "TwilightOverpass",
		peaceZoneRadiusStuds = 40,
		services = { "photo_filter", "frame", "watermark" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 8,
	},
	{
		id = "emote_stage_shop",
		displayName = "Emote Stage Shop",
		shopType = "EmoteStage",
		district = "TwilightOverpass",
		peaceZoneRadiusStuds = 50,
		services = { "emote", "dance_prop" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 5,
	},
	{
		id = "hellbound_terminal",
		displayName = "Hellbound Interstellar Terminal",
		shopType = "HellboundTerminal",
		district = "HellboundTerminal",
		peaceZoneRadiusStuds = 100,
		services = { "public_airplane", "private_jet", "hyperspace_travel" },
		commerceTier = "street",
		priceMultiplier = 1,
		minPrismKeys = 0,
	},
	{
		id = "preset_bazaar",
		displayName = "Preset Bazaar — Commerce District",
		shopType = "PresetBazaar",
		district = "CanalPromenade",
		peaceZoneRadiusStuds = 45,
		services = { "loadout_preset_pack", "creator_spotlight" },
		commerceTier = "mall",
		priceMultiplier = 1,
		minPrismKeys = 0,
	},
}

PrismCommerceConfig.DeployGate = {
	minSignatureSets = 6,
	minSeasonalSets = 2,
	minNationalCountries = 10,
	minTotalShopsOpen = 4,
	targetCosmeticsYear1 = 500,
}

PrismCommerceConfig.PaintPricing = {
	ServiceCenter = { minRobux = 499, maxRobux = 999, quality = "premium" },
	TuneShop = { minRobux = 99, maxRobux = 249, quality = "budget" },
}

function PrismCommerceConfig.getShop(shopId: string): ShopEntry?
	for _, shop in PrismCommerceConfig.Shops do
		if shop.id == shopId then
			return shop
		end
	end
	return nil
end

function PrismCommerceConfig.applyPrice(baseRobux: number, shop: ShopEntry): number
	return math.max(1, math.floor(baseRobux * shop.priceMultiplier + 0.5))
end

function PrismCommerceConfig.playerCanPurchase(playerKeyCount: number, shop: ShopEntry): boolean
	if shop.commerceTier == "luxury" then
		return true
	end
	return playerKeyCount >= shop.minPrismKeys
end

return PrismCommerceConfig
