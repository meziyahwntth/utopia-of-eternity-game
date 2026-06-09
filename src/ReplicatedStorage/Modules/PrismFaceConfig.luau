--!strict
--[[
	Prism Face Creation — Template Forge + Live Mirror (Key 25).
	Design: docs/FACE-CREATION-SYSTEM.md
]]

export type FaceCreationMode = "TemplateForge" | "PrismLiveMirror"

export type FaceTemplateCategory = "PrismClassic" | "SolarpunkHero" | "GentleSpirit" | "NocturneEdge"

export type FaceTemplate = {
	id: string,
	displayName: string,
	category: FaceTemplateCategory,
	previewImage: string?,
	morphDefaults: { [string]: number },
}

export type LivenessChallenge = "blink" | "turn_left" | "turn_right" | "smile"

local PrismFaceConfig = {}

PrismFaceConfig.UnlockLiveMirrorKeyCount = 25

PrismFaceConfig.LiveMirror = {
	AllowGalleryUpload = false,
	CaptureAppOnly = true,
	AppName = "Utopia of Eternity",
	SessionTtlSeconds = 300,
	MaxAttemptsPerDay = 3,
	StoreRawPhotoOnClient = false,
	StoreEmbeddingOnServer = true,
	ReVerifyOnMajorChange = true,
	MinAgeForLiveMirror = 13,
	LivenessChallenges = { "blink", "turn_left", "turn_right", "smile" } :: { LivenessChallenge },
}

PrismFaceConfig.SliderRanges = {
	skin_tone = { min = 0, max = 1, default = 0.5 },
	eye_size = { min = 0, max = 1, default = 0.5 },
	eyebrow_height = { min = 0, max = 1, default = 0.5 },
	nose_width = { min = 0, max = 1, default = 0.5 },
	nose_height = { min = 0, max = 1, default = 0.5 },
	mouth_width = { min = 0, max = 1, default = 0.5 },
	lip_fullness = { min = 0, max = 1, default = 0.5 },
	ear_size = { min = 0, max = 1, default = 0.5 },
	jaw_width = { min = 0, max = 1, default = 0.5 },
	cheek_fullness = { min = 0, max = 1, default = 0.5 },
}

-- MVP template set (expand to 34+)
PrismFaceConfig.Templates = {
	{
		id = "prism_classic_01",
		displayName = "Prism Oval",
		category = "PrismClassic",
		morphDefaults = { jaw_width = 0.45, cheek_fullness = 0.5, eye_size = 0.52 },
	},
	{
		id = "prism_classic_02",
		displayName = "Prism Heart",
		category = "PrismClassic",
		morphDefaults = { jaw_width = 0.4, cheek_fullness = 0.55, mouth_width = 0.48 },
	},
	{
		id = "solarpunk_hero_01",
		displayName = "Aurora Bold",
		category = "SolarpunkHero",
		morphDefaults = { jaw_width = 0.62, nose_height = 0.55, eye_size = 0.48 },
	},
	{
		id = "gentle_spirit_01",
		displayName = "Canal Soft",
		category = "GentleSpirit",
		morphDefaults = { jaw_width = 0.38, lip_fullness = 0.58, eye_size = 0.55 },
	},
	{
		id = "nocturne_edge_01",
		displayName = "Twilight Sharp",
		category = "NocturneEdge",
		morphDefaults = { jaw_width = 0.58, cheek_fullness = 0.42, eyebrow_height = 0.6 },
	},
}

function PrismFaceConfig.canUseLiveMirror(keyCount: number, accountAgeDays: number): boolean
	if keyCount < PrismFaceConfig.UnlockLiveMirrorKeyCount then
		return false
	end
	if accountAgeDays < PrismFaceConfig.LiveMirror.MinAgeForLiveMirror then
		return false
	end
	return true
end

function PrismFaceConfig.getTemplatesByCategory(category: FaceTemplateCategory): { FaceTemplate }
	local out: { FaceTemplate } = {}
	for _, t in PrismFaceConfig.Templates do
		if t.category == category then
			table.insert(out, t)
		end
	end
	return out
end

return PrismFaceConfig
