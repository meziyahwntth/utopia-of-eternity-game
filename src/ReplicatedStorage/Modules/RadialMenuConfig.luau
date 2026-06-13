--!strict
--[[
	RadialMenuConfig (P3-C+ Mobile) — 8-direction player interaction wheel
]]
local RadialMenuConfig = {}

export type ActionId =
	"Trade"
	| "Whisper"
	| "Party"
	| "Clan"
	| "Follow"
	| "Carry"
	| "Block"
	| "Report"

export type RadialAction = {
	id: ActionId,
	label: string,
	icon: string,
	angleDeg: number,
	color: Color3,
}

RadialMenuConfig.ButtonSize = 48
RadialMenuConfig.Radius = 92
RadialMenuConfig.WheelSize = 240
RadialMenuConfig.OpenTweenDuration = 0.18
RadialMenuConfig.HubBackground = Color3.fromRGB(10, 15, 30)
RadialMenuConfig.HubTransparency = 0.12

-- 0° = top, clockwise (mobile thumb zones)
RadialMenuConfig.Actions = {
	{
		id = "Trade",
		label = "Trade",
		icon = "💼",
		angleDeg = 0,
		color = Color3.fromRGB(160, 230, 255),
	},
	{
		id = "Whisper",
		label = "Whisper",
		icon = "💬",
		angleDeg = 45,
		color = Color3.fromRGB(255, 220, 100),
	},
	{
		id = "Party",
		label = "Party",
		icon = "🎉",
		angleDeg = 90,
		color = Color3.fromRGB(100, 200, 255),
	},
	{
		id = "Clan",
		label = "Clan",
		icon = "⚔",
		angleDeg = 135,
		color = Color3.fromRGB(130, 255, 160),
	},
	{
		id = "Follow",
		label = "Follow",
		icon = "🏃",
		angleDeg = 180,
		color = Color3.fromRGB(200, 200, 255),
	},
	{
		id = "Carry",
		label = "Carry",
		icon = "🫂",
		angleDeg = 225,
		color = Color3.fromRGB(220, 180, 255),
	},
	{
		id = "Block",
		label = "Block",
		icon = "🚫",
		angleDeg = 270,
		color = Color3.fromRGB(255, 100, 100),
	},
	{
		id = "Report",
		label = "Report",
		icon = "🚩",
		angleDeg = 315,
		color = Color3.fromRGB(255, 80, 80),
	},
} :: { RadialAction }

return RadialMenuConfig
