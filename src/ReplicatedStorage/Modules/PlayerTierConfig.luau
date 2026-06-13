--!strict
--[[
	PlayerTierConfig (P7) — level bands → tier name/color/aura
]]
local PlayerTierConfig = {}

export type TierInfo = {
	tier: number,
	name: string,
	nameTH: string,
	minLevel: number,
	maxLevel: number,
	color: Color3,
	auraColor: Color3,
	auraEnabled: boolean,
	glowIntensity: number,
}

local tiers: { TierInfo } = {
	{
		tier = 1,
		name = "Newbie",
		nameTH = "ผู้เล่นใหม่",
		minLevel = 1,
		maxLevel = 15,
		color = Color3.fromRGB(180, 180, 180),
		auraColor = Color3.new(1, 1, 1),
		auraEnabled = false,
		glowIntensity = 0,
	},
	{
		tier = 2,
		name = "Apprentice",
		nameTH = "ผู้ฝึกหัด",
		minLevel = 16,
		maxLevel = 25,
		color = Color3.fromRGB(100, 220, 100),
		auraColor = Color3.new(1, 1, 1),
		auraEnabled = false,
		glowIntensity = 0,
	},
	{
		tier = 3,
		name = "Adept",
		nameTH = "ชำนาญการ",
		minLevel = 26,
		maxLevel = 40,
		color = Color3.fromRGB(80, 180, 255),
		auraColor = Color3.fromRGB(80, 200, 255),
		auraEnabled = false,
		glowIntensity = 0,
	},
	{
		tier = 4,
		name = "Veteran",
		nameTH = "ผู้เจนสนาม",
		minLevel = 41,
		maxLevel = 60,
		color = Color3.fromRGB(255, 200, 50),
		auraColor = Color3.fromRGB(255, 220, 80),
		auraEnabled = true,
		glowIntensity = 1,
	},
	{
		tier = 5,
		name = "Expert",
		nameTH = "ผู้เชี่ยวชาญ",
		minLevel = 61,
		maxLevel = 80,
		color = Color3.fromRGB(255, 120, 0),
		auraColor = Color3.fromRGB(255, 140, 30),
		auraEnabled = true,
		glowIntensity = 2,
	},
	{
		tier = 6,
		name = "Master",
		nameTH = "ปรมาจารย์",
		minLevel = 81,
		maxLevel = 99,
		color = Color3.fromRGB(200, 80, 255),
		auraColor = Color3.fromRGB(200, 100, 255),
		auraEnabled = true,
		glowIntensity = 3,
	},
	{
		tier = 7,
		name = "Hero",
		nameTH = "วีรบุรุษ",
		minLevel = 100,
		maxLevel = 149,
		color = Color3.fromRGB(255, 220, 0),
		auraColor = Color3.fromRGB(255, 240, 100),
		auraEnabled = true,
		glowIntensity = 5,
	},
}

function PlayerTierConfig.getTierForLevel(level: number): TierInfo
	for i = #tiers, 1, -1 do
		if level >= tiers[i].minLevel then
			return tiers[i]
		end
	end
	return tiers[1]
end

function PlayerTierConfig.getAll(): { TierInfo }
	return tiers
end

return PlayerTierConfig
