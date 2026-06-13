--!strict
--[[
	PetConfig (Backlog B) — pet catalog: buff, rarity, obtain method
]]
export type PetBuff = {
	expBonus: number,
	pickupRadius: number,
	luckBonus: number,
}

export type PetRarity = "Common" | "Rare" | "Epic" | "Legendary"
export type PetObtainMethod = "Event" | "Drop" | "Shop" | "Quest"

export type PetEntry = {
	id: string,
	nameTH: string,
	icon: string,
	modelId: string,
	rarity: PetRarity,
	buff: PetBuff,
	obtainMethod: PetObtainMethod,
}

local PetConfig = {}

PetConfig.Pets = {
	{
		id = "slime_blue",
		nameTH = "สไลม์ฟ้า 💧",
		icon = "💧",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.05, pickupRadius = 3, luckBonus = 0 },
		obtainMethod = "Drop",
	},
	{
		id = "fox_fire",
		nameTH = "จิ้งจอกไฟ 🦊",
		icon = "🦊",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.10, pickupRadius = 5, luckBonus = 0.03 },
		obtainMethod = "Event",
	},
	{
		id = "dragon_mini",
		nameTH = "มังกรจิ๋ว 🐉",
		icon = "🐉",
		modelId = "rbxassetid://0",
		rarity = "Legendary",
		buff = { expBonus = 0.15, pickupRadius = 8, luckBonus = 0.05 },
		obtainMethod = "Quest",
	},
} :: { PetEntry }

return PetConfig
