--!strict
--[[
	All 20 countries × Heritage + Modern fashion sets.
	Concept images: docs/visual-ref/fashion/national/
]]
local NationalFashionSets = {}

export type NationalSetPiece = { id: string, displayName: string, slot: string, robux: number }
export type NationalSetPieces = { NationalSetPiece }

export type NationalSetDef = {
	id: string,
	displayName: string,
	category: "NationalHeritage" | "NationalModern",
	countryCode: string,
	countryName: string,
	bundleRobux: number,
	refConceptImage: string,
	pieces: NationalSetPieces,
}

local NATIONAL_DIR = "docs/visual-ref/fashion/national"

local function heritage(
	id: string,
	name: string,
	code: string,
	country: string,
	image: string,
	pieces: NationalSetPieces
): NationalSetDef
	return {
		id = id,
		displayName = name,
		category = "NationalHeritage",
		countryCode = code,
		countryName = country,
		bundleRobux = 1499,
		refConceptImage = `{NATIONAL_DIR}/{image}`,
		pieces = pieces,
	}
end

local function modern(
	id: string,
	name: string,
	code: string,
	country: string,
	image: string,
	pieces: NationalSetPieces
): NationalSetDef
	return {
		id = id,
		displayName = name,
		category = "NationalModern",
		countryCode = code,
		countryName = country,
		bundleRobux = 1299,
		refConceptImage = `{NATIONAL_DIR}/{image}`,
		pieces = pieces,
	}
end

local shirt = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Shirt", robux = robux }
end
local pants = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Pants", robux = robux }
end
local shoes = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Shoes", robux = robux }
end
local hair = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Hair", robux = robux }
end
local hat = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Hat", robux = robux }
end
local back = function(id: string, name: string, robux: number)
	return { id = id, displayName = name, slot = "Back", robux = robux }
end

NationalFashionSets.All = {
	-- Thailand (concept exists)
	heritage("silk_horizon", "Silk Horizon", "TH", "Thailand", "thai-heritage-line-concept.png", {
		shirt("silk_horizon_blouse", "Gold Brocade Blouse", 399),
		pants("silk_horizon_skirt", "Pha Sin Pattern Skirt", 399),
		hair("silk_horizon_pin", "Jasmine Hair Pin", 249),
		shoes("silk_horizon_sandals", "Heritage Sandals", 199),
	}),
	modern("bangkok_prism", "Bangkok Prism", "TH", "Thailand", "thai-heritage-line-concept.png", {
		shirt("bangkok_prism_jacket", "Temple-Arch Jacket", 349),
		pants("bangkok_prism_pants", "Wide Street Pants", 249),
		shoes("bangkok_prism_sneakers", "Gold-Trim Sneakers", 249),
	}),
	-- Laos
	heritage("mekong_silk", "Mekong Silk", "LA", "Laos", "national-laos-concept.png", {
		shirt("mekong_silk_top", "Sinh Silk Top", 379),
		pants("mekong_silk_sinh", "Pha Biang Wrap Skirt", 379),
		shoes("mekong_silk_sandals", "Mekong Sandals", 199),
		hair("mekong_silk_pin", "Silver Pin", 229),
	}),
	modern("vientiane_glow", "Vientiane Glow", "LA", "Laos", "national-laos-concept.png", {
		shirt("vientiane_glow_jacket", "Prism River Jacket", 329),
		pants("vientiane_glow_pants", "Glow Wide Pants", 249),
		shoes("vientiane_glow_shoes", "City Sneakers", 229),
	}),
	-- Vietnam
	heritage("lotus_ao", "Lotus Ao", "VN", "Vietnam", "national-vietnam-concept.png", {
		shirt("lotus_ao_tunic", "Lotus Ao Tunic", 399),
		pants("lotus_ao_trousers", "Silk Trousers", 299),
		shoes("lotus_ao_slippers", "Lotus Slippers", 199),
		hat("lotus_ao_conical", "Festival Conical Hat", 249),
	}),
	modern("saigon_neon", "Saigon Neon", "VN", "Vietnam", "national-vietnam-concept.png", {
		shirt("saigon_neon_jacket", "Neon Saigon Jacket", 349),
		pants("saigon_neon_pants", "Urban Wide Pants", 249),
		shoes("saigon_neon_kicks", "Neon Kicks", 249),
	}),
	-- Indonesia
	heritage("batik_archipelago", "Batik Archipelago", "ID", "Indonesia", "national-indonesia-concept.png", {
		shirt("batik_kebaya", "Kebaya Batik Top", 389),
		pants("batik_sarong", "Batik Sarong", 349),
		shoes("batik_sandals", "Archipelago Sandals", 199),
	}),
	modern("jakarta_prism", "Jakarta Prism", "ID", "Indonesia", "national-indonesia-concept.png", {
		shirt("jakarta_prism_bomber", "Batik Bomber", 349),
		pants("jakarta_prism_joggers", "City Joggers", 229),
		shoes("jakarta_prism_sneakers", "Prism Sneakers", 229),
	}),
	-- Malaysia
	heritage("golden_songket", "Golden Songket", "MY", "Malaysia", "national-malaysia-concept.png", {
		shirt("songket_kurung", "Songket Kurung", 399),
		pants("songket_skirt", "Golden Skirt Panel", 349),
		hat("songket_tudung", "Songket Headscarf", 249),
		shoes("songket_heels", "Golden Heels", 229),
	}),
	modern("kl_skyline", "KL Skyline", "MY", "Malaysia", "national-malaysia-concept.png", {
		shirt("kl_skyline_coat", "Skyline Coat", 349),
		pants("kl_skyline_pants", "Modest Wide Pants", 249),
		shoes("kl_skyline_loafers", "Metallic Loafers", 229),
	}),
	-- Philippines
	heritage("pearl_barong", "Pearl Barong", "PH", "Philippines", "national-philippines-concept.png", {
		shirt("pearl_barong_top", "Pearl Barong Top", 399),
		pants("pearl_barong_trousers", "Formal Trousers", 299),
		shoes("pearl_barong_loafers", "Pearl Loafers", 229),
	}),
	modern("manila_bay_chic", "Manila Bay Chic", "PH", "Philippines", "national-philippines-concept.png", {
		shirt("manila_bay_blouse", "Bay Chic Blouse", 329),
		pants("manila_bay_skirt", "Resort Skirt", 249),
		shoes("manila_bay_sandals", "Bay Sandals", 199),
	}),
	-- China
	heritage("cloud_han", "Cloud Han", "CN", "China", "national-china-concept.png", {
		shirt("cloud_han_robe", "Cloud Han Robe", 429),
		pants("cloud_han_skirt", "Festival Skirt Panel", 349),
		hair("cloud_han_pin", "Jade Hair Pin", 279),
		shoes("cloud_han_shoes", "Embroidered Shoes", 229),
	}),
	modern("shanghai_lumen", "Shanghai Lumen", "CN", "China", "national-china-concept.png", {
		shirt("shanghai_lumen_coat", "Lumen Coat", 379),
		pants("shanghai_lumen_pants", "Tailored Pants", 269),
		shoes("shanghai_lumen_boots", "Lumen Boots", 249),
	}),
	-- Korea
	heritage("han_river_bloom", "Han River Bloom", "KR", "Korea", "national-korea-concept.png", {
		shirt("han_river_jeogori", "Bloom Jeogori", 399),
		pants("han_river_chima", "Silk Chima", 349),
		hair("han_river_ribbon", "Ribbon Daenggi", 249),
		shoes("han_river_shoes", "Flower Shoes", 219),
	}),
	modern("seoul_prism_wave", "Seoul Prism Wave", "KR", "Korea", "national-korea-concept.png", {
		shirt("seoul_wave_jacket", "Wave Jacket", 359),
		pants("seoul_wave_pants", "Wide Cargo Pants", 259),
		shoes("seoul_wave_sneakers", "Prism Sneakers", 239),
	}),
	-- Japan
	heritage("sakura_yukata", "Sakura Yukata Line", "JP", "Japan", "national-japan-concept.png", {
		shirt("sakura_yukata_top", "Sakura Yukata", 399),
		pants("sakura_yukata_hakama", "Summer Hakama Panel", 329),
		hair("sakura_kanzashi", "Kanzashi Pin", 269),
		shoes("sakura_geta", "Festival Geta", 219),
	}),
	modern("tokyo_solarpunk", "Tokyo Solarpunk", "JP", "Japan", "national-japan-concept.png", {
		shirt("tokyo_sp_jacket", "Tech-Kimono Jacket", 369),
		pants("tokyo_sp_pants", "Urban Hakama Pants", 259),
		shoes("tokyo_sp_boots", "Solarpunk Boots", 249),
	}),
	-- UK
	heritage("thames_heritage", "Thames Heritage", "GB", "United Kingdom", "national-uk-concept.png", {
		shirt("thames_tweed_coat", "Tweed Gala Coat", 399),
		pants("thames_tweed_pants", "Heritage Trousers", 299),
		hat("thames_fascinator", "Pearl Fascinator", 279),
		shoes("thames_oxfords", "Oxford Shoes", 229),
	}),
	modern("london_prism_mod", "London Prism Mod", "GB", "United Kingdom", "national-uk-concept.png", {
		shirt("london_mod_coat", "Mod Prism Coat", 359),
		pants("london_mod_pants", "Slim Trousers", 249),
		shoes("london_mod_boots", "Chelsea Boots", 239),
	}),
	-- Germany
	heritage("rhine_festival", "Rhine Festival", "DE", "Germany", "national-germany-concept.png", {
		shirt("rhine_dirndl_top", "Festival Dirndl Top", 379),
		pants("rhine_dirndl_skirt", "Rhine Skirt", 329),
		hat("rhine_flower_crown", "Alpine Flower Crown", 249),
		shoes("rhine_shoes", "Festival Shoes", 219),
	}),
	modern("berlin_edge", "Berlin Edge", "DE", "Germany", "national-germany-concept.png", {
		shirt("berlin_edge_jacket", "Edge Bomber", 349),
		pants("berlin_edge_pants", "Street Pants", 249),
		shoes("berlin_edge_sneakers", "Edge Sneakers", 229),
	}),
	-- Greece
	heritage("aegean_white_blue", "Aegean White Blue", "GR", "Greece", "national-greece-concept.png", {
		shirt("aegean_chiton", "Aegean Chiton Top", 369),
		pants("aegean_pleated", "White Pleated Skirt", 299),
		hat("aegean_wreath", "Olive Wreath", 249),
		shoes("aegean_sandals", "Aegean Sandals", 199),
	}),
	modern("athens_prism", "Athens Prism", "GR", "Greece", "national-greece-concept.png", {
		shirt("athens_prism_blouse", "Prism Blouse", 329),
		pants("athens_prism_pants", "Coastal Pants", 239),
		shoes("athens_prism_sandals", "Marble Sandals", 209),
	}),
	-- Roman (festival toga — not gladiator)
	heritage("forum_toga", "Forum Toga", "RM", "Roman", "national-roman-concept.png", {
		shirt("forum_toga_wrap", "Festival Toga Wrap", 379),
		pants("forum_tunic", "Forum Tunic", 279),
		hat("forum_laurel", "Laurel Crown", 259),
		shoes("forum_sandals", "Forum Sandals", 199),
	}),
	modern("roma_futura", "Roma Futura", "RM", "Roman", "national-roman-concept.png", {
		shirt("roma_futura_tunic", "Futura Tunic Jacket", 349),
		pants("roma_futura_pants", "Column Weave Pants", 249),
		shoes("roma_futura_boots", "Marble Boots", 229),
	}),
	-- Norway
	heritage("fjord_bunad", "Fjord Bunad Glow", "NO", "Norway", "national-norway-concept.png", {
		shirt("fjord_bunad_top", "Bunad Embroidered Top", 399),
		pants("fjord_bunad_skirt", "Fjord Skirt", 349),
		hat("fjord_bunad_cape", "Wool Cape", 279),
		shoes("fjord_bunad_shoes", "Bunad Shoes", 219),
	}),
	modern("oslo_prism", "Oslo Prism", "NO", "Norway", "national-norway-concept.png", {
		shirt("oslo_prism_parka", "Prism Parka", 359),
		pants("oslo_prism_pants", "Thermal Pants", 249),
		shoes("oslo_prism_boots", "Fjord Boots", 239),
	}),
	-- Bulgaria
	heritage("rose_embroidery", "Rose Embroidery Folk", "BG", "Bulgaria", "national-bulgaria-concept.png", {
		shirt("rose_folk_blouse", "Rose Embroidered Blouse", 379),
		pants("rose_folk_skirt", "Folk Skirt", 329),
		hat("rose_headscarf", "Rose Headscarf", 229),
		shoes("rose_folk_shoes", "Folk Shoes", 209),
	}),
	modern("sofia_lumen", "Sofia Lumen", "BG", "Bulgaria", "national-bulgaria-concept.png", {
		shirt("sofia_lumen_coat", "Lumen Coat", 339),
		pants("sofia_lumen_pants", "City Pants", 239),
		shoes("sofia_lumen_heels", "Rose Heels", 219),
	}),
	-- Romania
	heritage("carpathian_blouse", "Carpathian Blouse", "RO", "Romania", "national-romania-concept.png", {
		shirt("carpathian_ie", "Ie Embroidered Blouse", 389),
		pants("carpathian_skirt", "Carpathian Skirt", 329),
		hat("carpathian_beads", "Beaded Headband", 239),
		shoes("carpathian_shoes", "Folk Shoes", 209),
	}),
	modern("bucharest_prism", "Bucharest Prism", "RO", "Romania", "national-romania-concept.png", {
		shirt("bucharest_prism_jacket", "Prism Jacket", 349),
		pants("bucharest_prism_pants", "Urban Pants", 249),
		shoes("bucharest_prism_boots", "City Boots", 229),
	}),
	-- Hawaii
	heritage("aloha_horizon", "Aloha Horizon", "HI", "Hawaii", "national-hawaii-concept.png", {
		shirt("aloha_horizon_shirt", "Aloha Horizon Shirt", 349),
		pants("aloha_horizon_skirt", "Hibiscus Skirt", 279),
		hat("aloha_lei", "Flower Lei", 229),
		shoes("aloha_sandals", "Island Sandals", 189),
	}),
	modern("island_prism", "Island Prism", "HI", "Hawaii", "national-hawaii-concept.png", {
		shirt("island_prism_top", "Resort Prism Top", 329),
		pants("island_prism_shorts", "Board Shorts", 219),
		shoes("island_prism_slides", "Prism Slides", 179),
	}),
	-- Guatemala
	heritage("huipil_star", "Huipil Star Weave", "GT", "Guatemala", "national-guatemala-concept.png", {
		shirt("huipil_star_top", "Star Huipil Top", 379),
		pants("huipil_woven_skirt", "Woven Skirt", 319),
		hat("huipil_headband", "Textile Headband", 219),
		shoes("huipil_sandals", "Woven Sandals", 199),
	}),
	modern("guatemala_glow", "Guatemala City Glow", "GT", "Guatemala", "national-guatemala-concept.png", {
		shirt("guatemala_glow_jacket", "Glow Jacket", 329),
		pants("guatemala_glow_pants", "City Pants", 239),
		shoes("guatemala_glow_sneakers", "Glow Sneakers", 209),
	}),
	-- Peru
	heritage("andes_textile", "Andes Textile Crown", "PE", "Peru", "national-peru-concept.png", {
		shirt("andes_poncho", "Andes Poncho Top", 389),
		pants("andes_woven_pants", "Woven Pants", 299),
		hat("andes_crown_hat", "Textile Crown Hat", 259),
		shoes("andes_boots", "Andes Boots", 219),
	}),
	modern("lima_prism", "Lima Prism", "PE", "Peru", "national-peru-concept.png", {
		shirt("lima_prism_coat", "Coastal Coat", 339),
		pants("lima_prism_pants", "Urban Pants", 239),
		shoes("lima_prism_sneakers", "Prism Sneakers", 209),
	}),
	-- India
	heritage("monsoon_lehenga", "Monsoon Lehenga", "IN", "India", "national-india-concept.png", {
		shirt("monsoon_choli", "Monsoon Choli", 399),
		pants("monsoon_lehenga_skirt", "Lehenga Skirt", 399),
		hair("monsoon_maang", "Maang Tikka", 269),
		shoes("monsoon_juttis", "Embroidered Juttis", 229),
	}),
	modern("mumbai_prism", "Mumbai Prism", "IN", "India", "national-india-concept.png", {
		shirt("mumbai_prism_kurta", "Prism Kurta Jacket", 349),
		pants("mumbai_prism_pants", "Tailored Pants", 249),
		shoes("mumbai_prism_loafers", "Metallic Loafers", 219),
	}),
}

function NationalFashionSets.getByCountry(code: string): { NationalSetDef }
	local out: { NationalSetDef } = {}
	for _, set in NationalFashionSets.All do
		if set.countryCode == code then
			table.insert(out, set)
		end
	end
	return out
end

return NationalFashionSets
