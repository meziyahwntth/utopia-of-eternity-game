--!strict
--[[
	CardConfig — card/rune socket stat bonuses
]]
export type StatBonus = {
	atkBonus: number?,
	defBonus: number?,
	luckBonus: number?,
	expBonus: number?,
}

export type CardDef = {
	id: string,
	nameTH: string,
	rarity: "Common" | "Rare" | "Legendary",
	bonus: StatBonus,
	iconText: string,
}

local CardConfig = {}

CardConfig.Cards = {
	CardCommon = {
		id = "CardCommon",
		nameTH = "การ์ดทองแดง",
		rarity = "Common",
		bonus = { atkBonus = 0.05, expBonus = 0.05 },
		iconText = "🃏",
	},
	CardRare = {
		id = "CardRare",
		nameTH = "การ์ดเงิน",
		rarity = "Rare",
		bonus = { atkBonus = 0.12, defBonus = 0.08, luckBonus = 0.05 },
		iconText = "🃏",
	},
	CardLegendary = {
		id = "CardLegendary",
		nameTH = "การ์ดทอง",
		rarity = "Legendary",
		bonus = { atkBonus = 0.25, defBonus = 0.20, luckBonus = 0.15, expBonus = 0.15 },
		iconText = "✨",
	},
} :: { [string]: CardDef }

CardConfig.MAX_SOCKETS = 2

return CardConfig
