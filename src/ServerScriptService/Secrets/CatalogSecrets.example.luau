--!strict
--[[
	Copy to CatalogSecrets.luau (gitignored).
	Register each Developer Product in Roblox Creator Dashboard, then paste numeric IDs here.
	See docs/P0-PUBLISH-SETUP.md
]]
return {
	-- P0 — Death Valley preset packs (robux prices in PrismPresetPackCatalog.luau)
	dv_pack_survivor_starter = 0,
	dv_pack_hellbound_elite = 0,
	dv_pack_veteran_trail = 0,
	dv_pack_style_only = 0,
	dv_pack_commerce_luxury = 0,
	dv_pack_commerce_creator_spotlight = 0,
	-- Single receipt handler for all dynamic UGC creator packs (Phase R)
	dv_pack_ugc_generic = 0,

	-- Optional — Hellbound travel
	hellbound_private_jet = 0,
	hellbound_public_airplane = 0,

	-- Shop rental Phase A — create on Creator Dashboard then paste IDs
	shop_rent_7d = 0,
	shop_rent_30d = 0,
}
