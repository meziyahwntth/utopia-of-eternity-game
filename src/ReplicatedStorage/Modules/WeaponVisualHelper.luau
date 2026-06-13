--!strict
-- WeaponVisualHelper — map visualTier → particle effect + color theme
local WeaponVisualHelper = {}

export type VisualTheme = {
	particleEffect: string,
	primaryColor: Color3,
	secondaryColor: Color3,
	glowIntensity: number,
}

local TIER_THEME: { [number]: VisualTheme } = {
	[1] = {
		particleEffect = "None",
		primaryColor = Color3.fromRGB(160, 160, 170),
		secondaryColor = Color3.fromRGB(120, 120, 130),
		glowIntensity = 0,
	},
	[2] = {
		particleEffect = "BlueShimmer",
		primaryColor = Color3.fromRGB(80, 120, 255),
		secondaryColor = Color3.fromRGB(40, 60, 180),
		glowIntensity = 0.3,
	},
	[3] = {
		particleEffect = "PurpleGoldAura",
		primaryColor = Color3.fromRGB(160, 80, 255),
		secondaryColor = Color3.fromRGB(255, 190, 40),
		glowIntensity = 0.6,
	},
	[4] = {
		particleEffect = "DragonArcane",
		primaryColor = Color3.fromRGB(200, 100, 255),
		secondaryColor = Color3.fromRGB(255, 160, 40),
		glowIntensity = 1.0,
	},
	[5] = {
		particleEffect = "PrismEternal",
		primaryColor = Color3.fromRGB(255, 255, 240),
		secondaryColor = Color3.fromRGB(100, 200, 255),
		glowIntensity = 1.5,
	},
}

function WeaponVisualHelper.getTheme(visualTier: number): VisualTheme
	return TIER_THEME[visualTier] or TIER_THEME[1]
end

return WeaponVisualHelper
