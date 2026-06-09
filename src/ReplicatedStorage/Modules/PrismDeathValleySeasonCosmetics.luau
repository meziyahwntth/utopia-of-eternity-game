--!strict
--[[
	Phase I — Season cosmetic visual definitions for client FX.
]]

export type CosmeticFxDef = {
	id: string,
	displayName: string,
	style: "aura" | "trail" | "badge",
	color: Color3,
	secondaryColor: Color3?,
	particleRate: number,
	lightBrightness: number,
	lightRange: number,
}

local PrismDeathValleySeasonCosmetics = {}

PrismDeathValleySeasonCosmetics.Definitions = {
	dv_aura_echo_champion = {
		id = "dv_aura_echo_champion",
		displayName = "Echo Champion Aura",
		style = "aura",
		color = Color3.fromRGB(255, 200, 80),
		secondaryColor = Color3.fromRGB(255, 140, 40),
		particleRate = 28,
		lightBrightness = 1.4,
		lightRange = 10,
	},
	dv_aura_hellbound_elite = {
		id = "dv_aura_hellbound_elite",
		displayName = "Hellbound Elite Aura",
		style = "aura",
		color = Color3.fromRGB(180, 80, 255),
		secondaryColor = Color3.fromRGB(80, 200, 255),
		particleRate = 22,
		lightBrightness = 1.1,
		lightRange = 9,
	},
	dv_trail_night_veteran = {
		id = "dv_trail_night_veteran",
		displayName = "Night Veteran Trail",
		style = "trail",
		color = Color3.fromRGB(100, 200, 255),
		secondaryColor = Color3.fromRGB(40, 80, 160),
		particleRate = 18,
		lightBrightness = 0.8,
		lightRange = 7,
	},
	dv_badge_valley_survivor = {
		id = "dv_badge_valley_survivor",
		displayName = "Valley Survivor Badge",
		style = "badge",
		color = Color3.fromRGB(120, 220, 140),
		secondaryColor = Color3.fromRGB(60, 120, 80),
		particleRate = 10,
		lightBrightness = 0.6,
		lightRange = 6,
	},
	dv_badge_echo_participant = {
		id = "dv_badge_echo_participant",
		displayName = "Echo Participant Badge",
		style = "badge",
		color = Color3.fromRGB(160, 170, 220),
		secondaryColor = Color3.fromRGB(80, 90, 140),
		particleRate = 8,
		lightBrightness = 0.45,
		lightRange = 5,
	},
}

function PrismDeathValleySeasonCosmetics.getDef(cosmeticId: string): CosmeticFxDef?
	return PrismDeathValleySeasonCosmetics.Definitions[cosmeticId]
end

return PrismDeathValleySeasonCosmetics
