--!strict
--[[
	PrismFashionCatalog — cosmetic-only wardrobe definitions for Utopia of Eternity City.
	Design doc: docs/FASHION-AND-SHOPS-DESIGN.md
	MVP: metadata + shop routing; UGC asset IDs wired at deploy.
]]

export type FashionSlot =
	"Shirt"
	| "Pants"
	| "Dress"
	| "Shoes"
	| "Hat"
	| "Hair"
	| "Face"
	| "Neck"
	| "Wrist"
	| "Back"
	| "Aura"

export type FashionCategory = "Signature" | "Seasonal" | "NationalHeritage" | "NationalModern" | "TeenTrend" | "UGC"

export type FashionPiece = {
	id: string,
	displayName: string,
	slot: FashionSlot,
	robux: number,
	refImage: string?,
	assetId: number?, -- Roblox catalog id when published
}

export type FashionSet = {
	id: string,
	displayName: string,
	category: FashionCategory,
	pieces: { FashionPiece },
	bundleRobux: number,
	season: string?, -- GameConfig.Seasons value
	countryCode: string?, -- ISO-style tag for national sets
	trendTag: string?, -- Teen trend label (Coquette, Y2K, etc.)
	limited: boolean,
	legacyAfterMonths: number?,
	refConceptImage: string?,
}

export type ShopType =
	"PrismWardrobe"
	| "AccessoryLane"
	| "WorldCulturePavilion"
	| "SeasonalPopUp"
	| "StellarSalon"
	| "PrismBeauty"
	| "EternityAesthetics"
	| "PrismMotors"
	| "PrismServiceCenter"
	| "NeonAlleyTune"
	| "MountEmporium"
	| "StableCare"
	| "LuminlingPetClinic"
	| "PrismWeaponGallery"
	| "PhotoBoutique"
	| "EmoteStage"

local PrismFashionCatalog = {}

PrismFashionCatalog.Slots = {
	"Shirt",
	"Pants",
	"Dress",
	"Shoes",
	"Hat",
	"Hair",
	"Face",
	"Neck",
	"Wrist",
	"Back",
	"Aura",
} :: { FashionSlot }

-- Signature line (always on sale)
PrismFashionCatalog.SignatureSets = {
	{
		id = "prismwake_gala",
		displayName = "Prismwake Gala",
		category = "Signature",
		bundleRobux = 1299,
		limited = false,
		refConceptImage = "docs/visual-ref/fashion/concepts/prismwake-gala-concept.png",
		pieces = {
			{ id = "prismwake_gala_coat", displayName = "Prismwake Coat", slot = "Shirt", robux = 349 },
			{ id = "prismwake_gala_pants", displayName = "Gala Trousers", slot = "Pants", robux = 249 },
			{ id = "prismwake_gala_boots", displayName = "Filigree Boots", slot = "Shoes", robux = 199 },
			{ id = "prismwake_gala_crown", displayName = "Crystal Crown", slot = "Hat", robux = 299 },
			{ id = "prismwake_gala_aura", displayName = "Prismwake Aura", slot = "Aura", robux = 399 },
		},
	},
	{
		id = "canal_cruise",
		displayName = "Canal Cruise",
		category = "Signature",
		bundleRobux = 899,
		limited = false,
		pieces = {
			{ id = "canal_cruise_shirt", displayName = "Linen Cruise Shirt", slot = "Shirt", robux = 199 },
			{ id = "canal_cruise_pants", displayName = "Wide Canal Pants", slot = "Pants", robux = 199 },
			{ id = "canal_cruise_sandals", displayName = "Boardwalk Sandals", slot = "Shoes", robux = 149 },
			{ id = "canal_cruise_hat", displayName = "Sun Canal Hat", slot = "Hat", robux = 149 },
			{ id = "canal_cruise_tote", displayName = "Marina Tote", slot = "Back", robux = 249 },
		},
	},
}

-- Seasonal (limited → legacy shop)
PrismFashionCatalog.SeasonalSets = {
	{
		id = "lotus_splash",
		displayName = "Lotus Splash",
		category = "Seasonal",
		season = "Songkran",
		bundleRobux = 1199,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/lotus-splash-songkran-concept.png",
		pieces = {
			{ id = "lotus_splash_top", displayName = "Water-Silk Top", slot = "Shirt", robux = 299 },
			{ id = "lotus_splash_sash", displayName = "Lotus Sash", slot = "Neck", robux = 199 },
			{ id = "lotus_splash_sandals", displayName = "Splash Sandals", slot = "Shoes", robux = 199 },
			{ id = "lotus_splash_garland", displayName = "Flower Garland", slot = "Hat", robux = 249 },
			{ id = "lotus_splash_aura", displayName = "Water Splash Aura", slot = "Aura", robux = 349 },
		},
	},
	{
		id = "aurora_noel",
		displayName = "Aurora Noel",
		category = "Seasonal",
		season = "Christmas",
		bundleRobux = 1399,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/aurora-noel-christmas-concept.png",
		pieces = {
			{ id = "aurora_noel_coat", displayName = "Fur-Trim Coat", slot = "Shirt", robux = 399 },
			{ id = "aurora_noel_dress", displayName = "Emerald Gown", slot = "Dress", robux = 349 },
			{ id = "aurora_noel_boots", displayName = "Snow Boots", slot = "Shoes", robux = 249 },
			{ id = "aurora_noel_tiara", displayName = "Snowflake Tiara", slot = "Hat", robux = 299 },
			{ id = "aurora_noel_clutch", displayName = "Gift Clutch", slot = "Back", robux = 199 },
		},
	},
	{
		id = "lantern_redream",
		displayName = "Lantern Redream",
		category = "Seasonal",
		season = "ChineseNewYear",
		bundleRobux = 1299,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/lantern-redream-cny-concept.png",
		pieces = {
			{ id = "lantern_redream_top", displayName = "Brocade Top", slot = "Shirt", robux = 349 },
			{ id = "lantern_redream_pants", displayName = "Silk Festival Pants", slot = "Pants", robux = 249 },
			{ id = "lantern_redream_shoes", displayName = "Embroidered Shoes", slot = "Shoes", robux = 199 },
			{ id = "lantern_redream_lantern", displayName = "Lantern Back", slot = "Back", robux = 299 },
		},
	},
	{
		id = "riverlight_offering",
		displayName = "Riverlight Offering",
		category = "Seasonal",
		season = "LoyKrathong",
		bundleRobux = 1199,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/riverlight-offering-loykrathong-concept.png",
		pieces = {
			{ id = "riverlight_wrap", displayName = "Riverlight Wrap", slot = "Dress", robux = 349 },
			{ id = "riverlight_krathong_bag", displayName = "Krathong Clutch", slot = "Back", robux = 249 },
			{ id = "riverlight_crown", displayName = "Candle Crown", slot = "Hat", robux = 299 },
			{ id = "riverlight_aura", displayName = "River Glow Aura", slot = "Aura", robux = 349 },
		},
	},
	{
		id = "spark_cascade",
		displayName = "Spark Cascade",
		category = "Seasonal",
		season = "NewYear",
		bundleRobux = 1099,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/spark-cascade-newyear-concept.png",
		pieces = {
			{ id = "spark_cascade_suit", displayName = "Sequin Suit", slot = "Shirt", robux = 349 },
			{ id = "spark_cascade_shoes", displayName = "Party Heels", slot = "Shoes", robux = 249 },
			{ id = "spark_cascade_hat", displayName = "Confetti Top Hat", slot = "Hat", robux = 249 },
			{ id = "spark_cascade_aura", displayName = "Spark Aura", slot = "Aura", robux = 299 },
		},
	},
	{
		id = "prism_phantom",
		displayName = "Prism Phantom",
		category = "Seasonal",
		season = "Halloween",
		bundleRobux = 999,
		limited = true,
		legacyAfterMonths = 6,
		refConceptImage = "docs/visual-ref/fashion/concepts/prism-phantom-halloween-concept.png",
		pieces = {
			{ id = "prism_phantom_suit", displayName = "Glow Phantom Suit", slot = "Shirt", robux = 299 },
			{ id = "prism_phantom_pumpkin", displayName = "Pumpkin Hat", slot = "Hat", robux = 199 },
			{ id = "prism_phantom_wings", displayName = "Bat Wings", slot = "Back", robux = 349 },
		},
	},
}

-- National culture — 20 countries × 2 (40 sets) from NationalFashionSets.luau
local NationalFashionSets = require(script.Parent.NationalFashionSets)
local TeenTrendFashionSets = require(script.Parent.TeenTrendFashionSets)

PrismFashionCatalog.NationalSets = {} :: { FashionSet }

for _, def in NationalFashionSets.All do
	local pieces: { FashionPiece } = {}
	for _, p in def.pieces do
		table.insert(pieces, {
			id = p.id,
			displayName = p.displayName,
			slot = p.slot :: FashionSlot,
			robux = p.robux,
		})
	end
	table.insert(PrismFashionCatalog.NationalSets, {
		id = def.id,
		displayName = def.displayName,
		category = def.category,
		countryCode = def.countryCode,
		bundleRobux = def.bundleRobux,
		limited = false,
		refConceptImage = def.refConceptImage,
		pieces = pieces,
	})
end

PrismFashionCatalog.TeenTrendSets = {} :: { FashionSet }

for _, def in TeenTrendFashionSets.All do
	local pieces: { FashionPiece } = {}
	for _, p in def.pieces do
		table.insert(pieces, {
			id = p.id,
			displayName = p.displayName,
			slot = p.slot :: FashionSlot,
			robux = p.robux,
		})
	end
	table.insert(PrismFashionCatalog.TeenTrendSets, {
		id = def.id,
		displayName = def.displayName,
		category = "TeenTrend",
		trendTag = def.trendTag,
		bundleRobux = def.bundleRobux,
		limited = false,
		refConceptImage = def.refConceptImage,
		pieces = pieces,
	})
end

-- Shop → which set categories appear
PrismFashionCatalog.ShopInventory = {
	PrismWardrobe = { "Signature", "TeenTrend" },
	AccessoryLane = { "Signature" },
	WorldCulturePavilion = { "NationalHeritage", "NationalModern" },
	SeasonalPopUp = { "Seasonal" },
	StellarSalon = {},
	PrismBeauty = {},
	EternityAesthetics = {},
	PrismMotors = {},
	PrismServiceCenter = {},
	NeonAlleyTune = {},
	MountEmporium = {},
	StableCare = {},
	LuminlingPetClinic = {},
	PrismWeaponGallery = {},
	PhotoBoutique = {},
	EmoteStage = {},
}

function PrismFashionCatalog.getAllSets(): { FashionSet }
	local all: { FashionSet } = {}
	for _, set in PrismFashionCatalog.SignatureSets do
		table.insert(all, set)
	end
	for _, set in PrismFashionCatalog.SeasonalSets do
		table.insert(all, set)
	end
	for _, set in PrismFashionCatalog.NationalSets do
		table.insert(all, set)
	end
	for _, set in PrismFashionCatalog.TeenTrendSets do
		table.insert(all, set)
	end
	return all
end

function PrismFashionCatalog.getSetsForTrend(trendTag: string): { FashionSet }
	local out: { FashionSet } = {}
	for _, set in PrismFashionCatalog.TeenTrendSets do
		if set.trendTag == trendTag then
			table.insert(out, set)
		end
	end
	return out
end

function PrismFashionCatalog.getSetById(id: string): FashionSet?
	for _, set in PrismFashionCatalog.getAllSets() do
		if set.id == id then
			return set
		end
	end
	return nil
end

function PrismFashionCatalog.getSetsForSeason(season: string): { FashionSet }
	local out: { FashionSet } = {}
	for _, set in PrismFashionCatalog.SeasonalSets do
		if set.season == season then
			table.insert(out, set)
		end
	end
	return out
end

function PrismFashionCatalog.getSetsForCountry(countryCode: string): { FashionSet }
	local out: { FashionSet } = {}
	for _, set in PrismFashionCatalog.NationalSets do
		if set.countryCode == countryCode then
			table.insert(out, set)
		end
	end
	return out
end

return PrismFashionCatalog
