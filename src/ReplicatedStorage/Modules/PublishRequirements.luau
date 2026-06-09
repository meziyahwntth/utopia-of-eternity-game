--!strict
--[[
	P0 publish checklist — Place keys + Developer Product keys required before live Robux.
	See docs/P0-PUBLISH-SETUP.md
]]

local PublishRequirements = {}

PublishRequirements.PlaceKeys = {
	"Hub",
	"Solhaven",
	"Nocturne",
	"EternityCity",
	"DeathValley",
}

-- Minimum Developer Products for Death Valley monetization (Phase P/R/S)
PublishRequirements.P0DeveloperProductKeys = {
	"dv_pack_survivor_starter",
	"dv_pack_hellbound_elite",
	"dv_pack_veteran_trail",
	"dv_pack_style_only",
	"dv_pack_commerce_luxury",
	"dv_pack_commerce_creator_spotlight",
	"dv_pack_ugc_generic",
}

-- Register before full commerce soft launch
PublishRequirements.OptionalDeveloperProductKeys = {
	"hellbound_private_jet",
	"hellbound_public_airplane",
}

return PublishRequirements
