--!strict
--[[
	Per-place world build profiles — Hybrid microcurve pipeline.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuildConfig = {}

export type PlaceKey = "Hub" | "Solhaven" | "Nocturne" | "EternityCity" | "DeathValley" | "NeonUtopia"

export type PlaceProfile = {
	PlaceKey: PlaceKey,
	Theme: string,
	VoxelStuds: number,
	MaxParts: number,
	LodDistanceStuds: number,
	MicroTrimDistanceStuds: number,
	StreamingTargetRadius: number,
	GroundSizeStuds: number,
	-- V2: ยกเมืองลอยฟ้าเหนือเมฆ (0 = ไม่ลอย). EternityCity = สรวงสวรรค์ลอยฟ้า
	SkyAltitude: number,
	Palette: {
		Pearl: Color3,
		Gold: Color3,
		Cyan: Color3,
		Twilight: Color3,
		Amber: Color3,
		Steel: Color3,
		Slate: Color3,
		Midnight: Color3,
		Teal: Color3,
	},
}

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Twilight = Color3.fromRGB(10, 22, 40),
	Amber = Color3.fromRGB(255, 179, 71),
	Steel = Color3.fromRGB(90, 105, 125),
	Slate = Color3.fromRGB(55, 68, 88),
	Midnight = Color3.fromRGB(25, 35, 50),
	Teal = Color3.fromRGB(45, 115, 135),
}

WorldBuildConfig.Profiles = {
	Hub = {
		PlaceKey = "Hub",
		Theme = "organic_plaza",
		VoxelStuds = 0.15,
		MaxParts = 8000,
		LodDistanceStuds = 512,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 512,
		GroundSizeStuds = 512,
		SkyAltitude = 0,
		Palette = PALETTE,
	},
	Solhaven = {
		PlaceKey = "Solhaven",
		Theme = "garden_terraces",
		VoxelStuds = 0.12,
		MaxParts = 8000,
		LodDistanceStuds = 512,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 512,
		GroundSizeStuds = 480,
		SkyAltitude = 0,
		Palette = PALETTE,
	},
	Nocturne = {
		PlaceKey = "Nocturne",
		Theme = "twilight_arches",
		VoxelStuds = 0.12,
		MaxParts = 8000,
		LodDistanceStuds = 480,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 480,
		GroundSizeStuds = 400,
		SkyAltitude = 0,
		Palette = PALETTE,
	},
	EternityCity = {
		PlaceKey = "EternityCity",
		Theme = "solarpunk_flagship",
		VoxelStuds = 0.1,
		-- ~19.7k measured (greybox + heroes + shop units 336); headroom for Phase B decals
		MaxParts = 20500,
		LodDistanceStuds = 640,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 640,
		GroundSizeStuds = 1024,
		-- V2: เมืองสรวงสวรรค์ลอยฟ้าเหนือเมฆ
		SkyAltitude = 2000,
		Palette = PALETTE,
	},
	DeathValley = {
		PlaceKey = "DeathValley",
		Theme = "cave_beacon",
		VoxelStuds = 0.15,
		MaxParts = 7000,
		LodDistanceStuds = 480,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 480,
		GroundSizeStuds = 400,
		SkyAltitude = 0,
		Palette = PALETTE,
	},
	-- V2: เมืองมนุษย์ neon — จุดเกิดแรกของผู้เล่นใหม่ (ก่อนขึ้นเครื่องบินไป Utopia ลอยฟ้า)
	NeonUtopia = {
		PlaceKey = "NeonUtopia",
		Theme = "neon_luxe_coastal",
		VoxelStuds = 0.12,
		MaxParts = 8000,
		LodDistanceStuds = 512,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 512,
		GroundSizeStuds = 640,
		SkyAltitude = 0,
		Palette = PALETTE,
	},
} :: { [PlaceKey]: PlaceProfile }

function WorldBuildConfig:GetProfile(placeKey: PlaceKey): PlaceProfile
	local profile = self.Profiles[placeKey]
	if placeKey == "EternityCity" then
		local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
		local cityPalette = GameConfig.CityPalette
		return {
			PlaceKey = profile.PlaceKey,
			Theme = profile.Theme,
			VoxelStuds = profile.VoxelStuds,
			MaxParts = profile.MaxParts,
			LodDistanceStuds = profile.LodDistanceStuds,
			MicroTrimDistanceStuds = profile.MicroTrimDistanceStuds,
			StreamingTargetRadius = profile.StreamingTargetRadius,
			GroundSizeStuds = profile.GroundSizeStuds,
			SkyAltitude = profile.SkyAltitude,
			Palette = {
				Pearl = cityPalette.Pearl,
				Gold = cityPalette.Gold,
				Cyan = cityPalette.Cyan,
				Twilight = cityPalette.Twilight,
				Amber = cityPalette.Amber,
				Steel = cityPalette.Steel,
				Slate = cityPalette.Slate,
				Midnight = cityPalette.Midnight,
				Teal = cityPalette.Teal,
			},
		}
	end
	return profile
end

return WorldBuildConfig
