--!strict
--[[
	SeasonConfig (P8) — seasonal limited cosmetic pools
]]
export type Season = {
	id: string,
	nameTH: string,
	startMonth: number,
	endMonth: number,
	cosmeticPool: { string },
	themeColor: Color3,
}

local SeasonConfig = {}

SeasonConfig.Seasons = {
	{
		id = "summer",
		nameTH = "ฤดูร้อน ☀️",
		startMonth = 3,
		endMonth = 5,
		cosmeticPool = { "SummerHat", "BeachBoard", "SunglassesSet" },
		themeColor = Color3.fromRGB(255, 220, 80),
	},
	{
		id = "monsoon",
		nameTH = "ฤดูฝน 🌧️",
		startMonth = 6,
		endMonth = 9,
		cosmeticPool = { "RaincoatBlue", "UmbrellaRed", "CloudAura" },
		themeColor = Color3.fromRGB(80, 150, 255),
	},
	{
		id = "winter",
		nameTH = "ฤดูหนาว ❄️",
		startMonth = 12,
		endMonth = 2,
		cosmeticPool = { "SantaHat", "SnowboardWhite", "IceAura" },
		themeColor = Color3.fromRGB(200, 230, 255),
	},
} :: { Season }

SeasonConfig.CurrentSeasonId = "summer"

return SeasonConfig
