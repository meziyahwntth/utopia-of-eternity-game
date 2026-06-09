--!strict
--[[
	Per-place world build profiles — Hybrid microcurve pipeline.
]]
local WorldBuildConfig = {}

export type PlaceKey = "Hub" | "Solhaven" | "Nocturne" | "EternityCity" | "DeathValley"

export type PlaceProfile = {
	PlaceKey: PlaceKey,
	Theme: string,
	VoxelStuds: number,
	MaxParts: number,
	LodDistanceStuds: number,
	MicroTrimDistanceStuds: number,
	StreamingTargetRadius: number,
	GroundSizeStuds: number,
	Palette: {
		Pearl: Color3,
		Gold: Color3,
		Cyan: Color3,
		Twilight: Color3,
		Amber: Color3,
	},
}

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Twilight = Color3.fromRGB(10, 22, 40),
	Amber = Color3.fromRGB(255, 179, 71),
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
		Palette = PALETTE,
	},
	EternityCity = {
		PlaceKey = "EternityCity",
		Theme = "solarpunk_flagship",
		VoxelStuds = 0.1,
		MaxParts = 16000,
		LodDistanceStuds = 640,
		MicroTrimDistanceStuds = 128,
		StreamingTargetRadius = 640,
		GroundSizeStuds = 1024,
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
		Palette = PALETTE,
	},
} :: { [PlaceKey]: PlaceProfile }

function WorldBuildConfig:GetProfile(placeKey: PlaceKey): PlaceProfile
	return self.Profiles[placeKey]
end

return WorldBuildConfig
