--!strict
--[[
	30 teen-trend outfit sets — research-backed (DTI, Brookhaven, Royale High, Gen Z 2026).
	Doc: docs/TEEN-TREND-FASHION-RESEARCH.md
]]
local TeenTrendFashionSets = {}

export type TrendSetPiece = { id: string, displayName: string, slot: string, robux: number }
export type TrendSetPieces = { TrendSetPiece }

export type TrendSetDef = {
	id: string,
	displayName: string,
	trendTag: string,
	bundleRobux: number,
	refConceptImage: string,
	pieces: TrendSetPieces,
}

local CONCEPT_DIR = "docs/visual-ref/fashion/teen-trend"

local function conceptPath(id: string): string
	return `{CONCEPT_DIR}/teen-{id:gsub("_", "-")}.png`
end

local function set(
	id: string,
	name: string,
	tag: string,
	robux: number,
	pieces: TrendSetPieces
): TrendSetDef
	return {
		id = id,
		displayName = name,
		trendTag = tag,
		bundleRobux = robux,
		refConceptImage = conceptPath(id),
		pieces = pieces,
	}
end

local S = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Shirt", robux = r }
end
local P = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Pants", robux = r }
end
local H = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Hat", robux = r }
end
local R = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Hair", robux = r }
end
local F = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Face", robux = r }
end
local N = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Neck", robux = r }
end
local B = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Back", robux = r }
end
local W = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Shoes", robux = r }
end
local A = function(id: string, n: string, r: number)
	return { id = id, displayName = n, slot = "Aura", robux = r }
end

TeenTrendFashionSets.All = {
	set("coquette_ribbon_dream", "Coquette Ribbon Dream", "Coquette", 1199, {
		S("coquette_lace_dress", "Lace Dream Dress", 349),
		R("coquette_bow_hair", "Ribbon Bow Hair", 249),
		W("coquette_mary_janes", "Pearl Mary Janes", 199),
		N("coquette_ribbon_choker", "Satin Ribbon Choker", 149),
		A("coquette_soft_aura", "Soft Pink Aura", 299),
	}),
	set("marina_old_money", "Marina Old Money", "OldMoney", 1299, {
		S("oldmoney_linen_blazer", "Linen Blazer", 379),
		P("oldmoney_tailored_pants", "Tailored Trousers", 299),
		N("oldmoney_pearl_stack", "Pearl Necklace Stack", 249),
		W("oldmoney_loafers", "Classic Loafers", 219),
		B("oldmoney_clutch", "Leather Clutch", 199),
	}),
	set("twilight_gothic_rose", "Twilight Gothic Rose", "Gothic", 1399, {
		S("gothic_corset_top", "Velvet Corset Top", 349),
		P("gothic_layer_skirt", "Layered Midi Skirt", 299),
		N("gothic_choker_stack", "Choker Stack", 199),
		W("gothic_platform_boots", "Platform Boots", 279),
		A("gothic_dark_aura", "Twilight Aura", 349),
	}),
	set("canal_dark_academia", "Canal Dark Academia", "DarkAcademia", 1199, {
		S("academia_turtleneck", "Wool Turtleneck", 299),
		P("academia_plaid_skirt", "Plaid Pleated Skirt", 279),
		F("academia_round_glasses", "Round Glasses", 149),
		W("academia_loafers", "Oxford Loafers", 219),
		B("academia_book_pack", "Leather Book Bag", 249),
	}),
	set("butterfly_y2k_cruise", "Butterfly Y2K Cruise", "Y2K", 1099, {
		S("y2k_crochet_crop", "Crochet Crop Top", 249),
		P("y2k_lowrise_pants", "Low-Rise Flare Pants", 249),
		R("y2k_butterfly_clips", "Butterfly Clips Hair", 179),
		N("y2k_chunky_belt", "Chunky Y2K Belt", 149),
		W("y2k_platform_sandals", "Platform Sandals", 229),
	}),
	set("neon_cyber_y2k", "Neon Cyber Y2K", "CyberY2K", 1199, {
		S("cyber_holo_jacket", "Holographic Jacket", 329),
		H("cyber_trucker_hat", "Neon Trucker Hat", 179),
		P("cyber_cargo_pants", "Tech Cargo Pants", 249),
		W("cyber_chunky_sneakers", "Chunky Sneakers", 249),
		A("cyber_glitch_aura", "Glitch Aura", 299),
	}),
	set("meadow_cottagecore", "Meadow Cottagecore", "Cottagecore", 999, {
		S("cottage_gingham_dress", "Gingham Picnic Dress", 299),
		H("cottage_straw_hat", "Straw Sun Hat", 179),
		R("cottage_flower_crown", "Flower Crown", 199),
		B("cottage_picnic_basket", "Picnic Basket", 199),
		W("cottage_sandals", "Woven Sandals", 149),
	}),
	set("harajuku_prism_pop", "Harajuku Prism Pop", "Harajuku", 1299, {
		S("harajuku_crop_jacket", "Prism Crop Jacket", 329),
		P("harajuku_layer_skirt", "Layered Pop Skirt", 279),
		W("harajuku_platform_boots", "Platform Pop Boots", 269),
		B("harajuku_plush_bag", "Plush Street Bag", 229),
		A("harajuku_pop_aura", "Pop Color Aura", 299),
	}),
	set("gyaru_sunset_flash", "Gyaru Sunset Flash", "Gyaru", 1199, {
		F("gyaru_bold_blush", "Bold Gyaru Blush", 199),
		S("gyaru_plaid_mini_top", "Plaid Mini Top", 279),
		P("gyaru_arm_warmers", "Arm Warmers Layer", 179),
		W("gyaru_platform_heels", "Flash Platform Heels", 249),
		B("gyaru_plush_backpack", "Plush Mini Backpack", 229),
	}),
	set("stage_idol_kwave", "Stage Idol K-Wave", "KPopIdol", 1399, {
		S("idol_stage_jacket", "Stage Prism Jacket", 379),
		P("idol_coord_pants", "Two-Tone Coord Pants", 299),
		B("idol_lightstick", "Prism Lightstick", 299),
		R("idol_stage_hair", "Stage Layer Hair", 249),
		A("idol_spotlight_aura", "Spotlight Aura", 349),
	}),
	set("minimal_clean_girl", "Minimal Clean Girl", "CleanGirl", 899, {
		S("clean_neutral_coord_top", "Neutral Co-ord Top", 249),
		P("clean_neutral_coord_pants", "Neutral Co-ord Pants", 229),
		R("clean_slick_bun", "Sleek Bun Hair", 179),
		N("clean_gold_hoops", "Tiny Gold Hoops", 129),
		W("clean_minimal_slides", "Minimal Slides", 149),
	}),
	set("academy_preppy_pink", "Academy Preppy Pink", "Preppy", 1099, {
		S("preppy_sweater_vest", "Pink Sweater Vest", 279),
		P("preppy_plaid_skirt", "Plaid Mini Skirt", 249),
		W("preppy_mary_janes", "Mary Jane Shoes", 199),
		R("preppy_ribbon_bow", "Ribbon Bow Hair", 179),
		B("preppy_designer_bag", "Designer School Bag", 249),
	}),
	set("street_baddie_gold", "Street Baddie Gold", "Baddie", 1099, {
		S("baddie_crop_top", "Gold Chain Crop", 249),
		N("baddie_gold_chain", "Chunky Gold Chain", 199),
		F("baddie_shades", "Oversized Shades", 179),
		W("baddie_chunky_boots", "Chunky Street Boots", 279),
		A("baddie_glow_aura", "Gold Street Aura", 249),
	}),
	set("petal_fairycore", "Petal Fairycore", "Fairycore", 1199, {
		S("fairy_petal_top", "Petal Sheer Top", 279),
		P("fairy_petal_skirt", "Petal Layer Skirt", 279),
		B("fairy_sheer_wings", "Sheer Fairy Wings", 349),
		A("fairy_glitter_aura", "Glitter Fairy Aura", 299),
	}),
	set("lace_dark_coquette", "Lace Dark Coquette", "DarkCoquette", 1199, {
		S("darkcoquette_lace_dress", "Black Lace Dress", 329),
		N("darkcoquette_velvet_bow", "Velvet Bow Choker", 179),
		R("darkcoquette_dark_bow", "Dark Satin Bow Hair", 199),
		W("darkcoquette_velvet_heels", "Velvet Heels", 229),
		A("darkcoquette_mood_aura", "Moody Rose Aura", 279),
	}),
	set("spire_met_gala", "Spire Met Gala", "MetGala", 1599, {
		S("gala_stacked_gown", "Stacked Gala Gown", 449),
		B("gala_dramatic_cape", "Dramatic Prism Cape", 399),
		N("gala_crystal_neck", "Crystal Statement Neck", 299),
		W("gala_stiletto", "Gala Stilettos", 279),
		A("gala_flash_aura", "Paparazzi Aura", 349),
	}),
	set("cloud_soft_girl", "Cloud Soft Girl", "SoftGirl", 899, {
		S("soft_oversized_cardi", "Cloud Cardigan", 249),
		P("soft_pastel_skirt", "Pastel Flare Skirt", 219),
		B("soft_plush_backpack", "Cloud Plush Backpack", 199),
		R("soft_wavy_hair", "Soft Wavy Hair", 179),
	}),
	set("night_emo_prism", "Night Emo Prism", "Emo", 999, {
		S("emo_flannel_layer", "Plaid Flannel Layer", 249),
		S("emo_band_tee", "Prism Band Tee", 199),
		N("emo_spiked_collar", "Spiked Collar", 179),
		W("emo_combat_boots", "Combat Boots", 249),
		A("emo_night_aura", "Midnight Aura", 199),
	}),
	set("alley_grunge_tune", "Alley Grunge Tune", "Grunge", 999, {
		S("grunge_distressed_hoodie", "Distressed Hoodie", 269),
		N("grunge_chain_belt", "Chain Belt", 149),
		P("grunge_ripped_jeans", "Ripped Wide Jeans", 249),
		W("grunge_combat_boots", "Scuffed Combat Boots", 229),
	}),
	set("sky_athleisure_run", "Sky Athleisure Run", "Athleisure", 899, {
		S("athleisure_crop_top", "Performance Crop", 219),
		P("athleisure_joggers", "Sky Joggers", 219),
		H("athleisure_visor", "Prism Visor", 149),
		W("athleisure_runners", "Cloud Runners", 229),
	}),
	set("ibiza_beach_sand", "Ibiza Beach Sand", "Beach", 999, {
		S("beach_sarong_wrap", "Sarong Wrap Top", 249),
		P("beach_bikini_layer", "Bikini Layer Bottom", 199),
		N("beach_shell_neck", "Shell Necklace", 149),
		H("beach_sun_hat", "Wide Sun Hat", 179),
		W("beach_slide_sandals", "Ibiza Slides", 149),
	}),
	set("ceo_power_suit", "CEO Power Suit", "PowerSuit", 1299, {
		S("ceo_tailored_suit", "Tailored Power Suit", 399),
		N("ceo_watch_chain", "Gold Watch Chain", 199),
		B("ceo_briefcase", "Executive Briefcase", 279),
		W("ceo_power_heels", "Power Heels", 249),
	}),
	set("siren_mermaid_bay", "Siren Mermaid Bay", "Mermaidcore", 1199, {
		S("mermaid_scale_top", "Iridescent Scale Top", 299),
		P("mermaid_scale_leggings", "Scale Leggings", 279),
		H("mermaid_shell_crown", "Shell Crown", 249),
		A("mermaid_iridescent_aura", "Siren Aura", 349),
	}),
	set("rainbow_decora_stack", "Rainbow Decora Stack", "Decora", 1099, {
		R("decora_clip_stack", "Rainbow Clip Stack Hair", 299),
		S("decora_rainbow_layers", "Rainbow Layer Top", 279),
		B("decora_plush_bag", "Decora Plush Bag", 249),
		A("decora_sparkle_aura", "Rainbow Sparkle Aura", 299),
	}),
	set("roller_90s_vintage", "Roller 90s Vintage", "Vintage90s", 999, {
		S("vintage90_denim_jacket", "Denim Jacket", 269),
		P("vintage90_wide_jeans", "Wide 90s Jeans", 229),
		H("vintage90_bucket_hat", "Bucket Hat", 149),
		W("vintage90_roller_shoes", "Roller Sneakers", 249),
	}),
	set("aurora_prom_night", "Aurora Prom Night", "Prom", 1399, {
		S("prom_ball_gown", "Aurora Ball Gown", 399),
		N("prom_corsage_wrist", "Corsage Wrist", 179),
		W("prom_heels", "Prom Heels", 249),
		A("prom_dance_aura", "Dance Floor Aura", 349),
	}),
	set("pastel_kawaii_gamer", "Pastel Kawaii Gamer", "KawaiiGamer", 999, {
		S("gamer_pastel_hoodie", "Pastel Gamer Hoodie", 269),
		P("gamer_pastel_skirt", "Pastel Pleat Skirt", 219),
		H("gamer_cat_earset", "Cat Ear Headset", 249),
		B("gamer_plush_controller", "Plush Controller Bag", 199),
	}),
	set("glitch_glam_max", "Glitch Glam Max", "GlitchGlam", 1299, {
		S("glitch_layer_coat", "Max Layer Coat", 349),
		F("glitch_statement_shades", "Statement Shades", 199),
		B("glitch_chain_bag", "Chain Glam Bag", 279),
		A("glitch_max_aura", "Glitch Max Aura", 399),
	}),
	set("solarpunk_street_tech", "Solarpunk Street Tech", "Solarpunk", 1299, {
		S("solar_techwear_jacket", "Pearl Techwear Jacket", 359),
		P("solar_tech_pants", "Cyan Trim Tech Pants", 279),
		H("solar_visorglass", "Solar Visor Glass", 229),
		W("solar_glow_sneakers", "Glow Trim Sneakers", 249),
		A("solar_prism_aura", "Solarpunk Aura", 349),
	}),
	set("rooftop_influencer", "Rooftop Influencer", "Influencer", 1199, {
		S("influencer_crop_blazer", "Crop Blazer Top", 299),
		B("influencer_designer_bag", "Designer Crossbody", 299),
		F("influencer_oversized_shades", "Oversized Influencer Shades", 199),
		{ id = "influencer_phone_prop", displayName = "Selfie Phone Prop", slot = "Wrist", robux = 149 },
		A("influencer_golden_hour", "Golden Hour Aura", 299),
	}),
}

function TeenTrendFashionSets.getByTag(tag: string): { TrendSetDef }
	local out: { TrendSetDef } = {}
	for _, s in TeenTrendFashionSets.All do
		if s.trendTag == tag then
			table.insert(out, s)
		end
	end
	return out
end

return TeenTrendFashionSets
