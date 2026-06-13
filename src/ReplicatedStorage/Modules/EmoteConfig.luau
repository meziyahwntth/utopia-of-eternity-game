--!strict
--[[
	EmoteConfig (P8) — short animation emotes (Roblox default animation IDs)
]]
export type EmoteEntry = {
	id: string,
	nameTH: string,
	icon: string,
	animationId: string,
	looped: boolean,
	durationSecs: number,
}

local EmoteConfig = {}

EmoteConfig.Emotes = {
	{
		id = "wave",
		nameTH = "โบกมือ",
		icon = "👋",
		animationId = "rbxassetid://507770239",
		looped = false,
		durationSecs = 3,
	},
	{
		id = "dance",
		nameTH = "เต้น",
		icon = "💃",
		animationId = "rbxassetid://507771019",
		looped = true,
		durationSecs = 0,
	},
	{
		id = "laugh",
		nameTH = "หัวเราะ",
		icon = "😂",
		animationId = "rbxassetid://507770818",
		looped = false,
		durationSecs = 3,
	},
	{
		id = "sit",
		nameTH = "นั่ง",
		icon = "🪑",
		animationId = "rbxassetid://507770454",
		looped = true,
		durationSecs = 0,
	},
} :: { EmoteEntry }

return EmoteConfig
