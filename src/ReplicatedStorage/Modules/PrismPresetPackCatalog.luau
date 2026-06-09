--!strict
--[[
	Phase P/Q — Robux preset pack catalog.
]]

export type ShopChannel = "wardrobe" | "commerce" | "both" | "seasonal"

export type PresetPackDef = {
	id: string,
	displayName: string,
	description: string,
	robux: number,
	cosmeticId: string?,
	titleSeasonId: string?,
	titleText: string?,
	grantCosmetic: boolean,
	featured: boolean?,
	sortOrder: number?,
	shopChannel: ShopChannel?,
	creatorUserId: number?,
	creatorSharePercent: number?,
	seasonTag: string?,
	ugcListingId: string?,
}

local PrismPresetPackCatalog = {}

PrismPresetPackCatalog.UGC_PACK_PREFIX = "dv_ugc_"

PrismPresetPackCatalog.Packs = {
	{
		id = "dv_pack_survivor_starter",
		displayName = "Survivor Starter Pack",
		description = "Echo Champion aura + survivor loadout preset",
		robux = 99,
		cosmeticId = "dv_aura_echo_champion",
		grantCosmetic = true,
		featured = true,
		sortOrder = 1,
		shopChannel = "both",
		creatorUserId = 0,
		seasonTag = "Halloween",
	},
	{
		id = "dv_pack_hellbound_elite",
		displayName = "Hellbound Elite Pack",
		description = "Elite aura + night veteran trail combo preset",
		robux = 149,
		cosmeticId = "dv_aura_hellbound_elite",
		titleSeasonId = "dv_season_echo",
		titleText = "Hellbound Elite",
		grantCosmetic = true,
		featured = true,
		sortOrder = 2,
		shopChannel = "both",
		creatorUserId = 0,
		seasonTag = "Christmas",
	},
	{
		id = "dv_pack_veteran_trail",
		displayName = "Night Veteran Pack",
		description = "Trail cosmetic + preset inbox entry",
		robux = 79,
		cosmeticId = "dv_trail_night_veteran",
		grantCosmetic = true,
		featured = false,
		sortOrder = 3,
		shopChannel = "wardrobe",
	},
	{
		id = "dv_pack_style_only",
		displayName = "Style Preset Pack",
		description = "Preset combo only — requires owned cosmetics to equip",
		robux = 49,
		cosmeticId = "dv_badge_valley_survivor",
		grantCosmetic = false,
		featured = false,
		sortOrder = 4,
		shopChannel = "wardrobe",
	},
	{
		id = "dv_pack_commerce_luxury",
		displayName = "Luxury Galleria Loadout",
		description = "Commerce District exclusive · elite aura bundle",
		robux = 199,
		cosmeticId = "dv_aura_hellbound_elite",
		grantCosmetic = true,
		featured = true,
		sortOrder = 5,
		shopChannel = "commerce",
		creatorUserId = 0,
		creatorSharePercent = 70,
		seasonTag = "Songkran",
	},
	{
		id = "dv_pack_commerce_creator_spotlight",
		displayName = "Creator Spotlight Pack",
		description = "Supports community creators · 70% revenue share",
		robux = 129,
		cosmeticId = "dv_badge_echo_participant",
		grantCosmetic = true,
		featured = true,
		sortOrder = 6,
		shopChannel = "commerce",
		creatorUserId = 0,
		creatorSharePercent = 70,
		seasonTag = "LoyKrathong",
	},
}

function PrismPresetPackCatalog.getPack(packId: string): PresetPackDef?
	for _, pack in PrismPresetPackCatalog.Packs do
		if pack.id == packId then
			return pack
		end
	end
	return nil
end

function PrismPresetPackCatalog.isUgcPackId(packId: string): boolean
	return string.sub(packId, 1, #PrismPresetPackCatalog.UGC_PACK_PREFIX)
		== PrismPresetPackCatalog.UGC_PACK_PREFIX
end

function PrismPresetPackCatalog.matchesChannel(pack: PresetPackDef, channel: ShopChannel): boolean
	local packChannel = pack.shopChannel or "both"
	return packChannel == "both" or packChannel == channel
end

function PrismPresetPackCatalog.listForChannel(channel: ShopChannel): { PresetPackDef }
	local list: { PresetPackDef } = {}
	for _, pack in PrismPresetPackCatalog.Packs do
		if PrismPresetPackCatalog.matchesChannel(pack, channel) then
			table.insert(list, pack)
		end
	end
	table.sort(list, function(a, b)
		return (a.sortOrder or 99) < (b.sortOrder or 99)
	end)
	return list
end

function PrismPresetPackCatalog.listFeatured(): { PresetPackDef }
	local list: { PresetPackDef } = {}
	for _, pack in PrismPresetPackCatalog.Packs do
		if pack.featured == true then
			table.insert(list, pack)
		end
	end
	table.sort(list, function(a, b)
		return (a.sortOrder or 99) < (b.sortOrder or 99)
	end)
	return list
end

function PrismPresetPackCatalog.listAll(): { PresetPackDef }
	local list = table.clone(PrismPresetPackCatalog.Packs)
	table.sort(list, function(a, b)
		return (a.sortOrder or 99) < (b.sortOrder or 99)
	end)
	return list
end

return PrismPresetPackCatalog
