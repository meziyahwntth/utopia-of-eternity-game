--!strict
--[[
	NpcDropConfig — drop table per CombatNpcId + base XP per profile
]]
export type DropEntry = {
	itemId: string,
	minQty: number,
	maxQty: number,
	chance: number,
}

export type NpcDropProfile = {
	npcId: number,
	nameTH: string,
	dropTable: { DropEntry },
	baseXP: number,
}

local NpcDropConfig = {}

NpcDropConfig.Profiles = {
	[1] = {
		npcId = 1,
		nameTH = "หุ่นฝึกหัด",
		baseXP = 25,
		dropTable = {
			{ itemId = "StoneFragment", minQty = 1, maxQty = 3, chance = 0.70 },
			{ itemId = "IronOre", minQty = 1, maxQty = 1, chance = 0.20 },
		},
	},
	[2] = {
		npcId = 2,
		nameTH = "ทหารซอมบี้",
		baseXP = 35,
		dropTable = {
			{ itemId = "StoneFragment", minQty = 2, maxQty = 5, chance = 0.65 },
			{ itemId = "IronOre", minQty = 1, maxQty = 2, chance = 0.30 },
			{ itemId = "MagicCrystal", minQty = 1, maxQty = 1, chance = 0.05 },
		},
	},
	[3] = {
		npcId = 3,
		nameTH = "อัศวินมืด",
		baseXP = 50,
		dropTable = {
			{ itemId = "StoneFragment", minQty = 3, maxQty = 8, chance = 0.60 },
			{ itemId = "IronOre", minQty = 2, maxQty = 4, chance = 0.40 },
			{ itemId = "MagicCrystal", minQty = 1, maxQty = 2, chance = 0.10 },
		},
	},
	[4] = {
		npcId = 4,
		nameTH = "นักเวทย์ผีดิบ",
		baseXP = 65,
		dropTable = {
			{ itemId = "IronOre", minQty = 3, maxQty = 6, chance = 0.50 },
			{ itemId = "MagicCrystal", minQty = 1, maxQty = 3, chance = 0.25 },
			{ itemId = "StoneFragment", minQty = 5, maxQty = 10, chance = 0.40 },
		},
	},
	[5] = {
		npcId = 5,
		nameTH = "ราชาหุ่น (BOSS)",
		baseXP = 120,
		dropTable = {
			{ itemId = "MagicCrystal", minQty = 3, maxQty = 8, chance = 0.70 },
			{ itemId = "IronOre", minQty = 5, maxQty = 10, chance = 0.80 },
			{ itemId = "StoneFragment", minQty = 10, maxQty = 20, chance = 0.90 },
		},
	},
} :: { [number]: NpcDropProfile }

NpcDropConfig.DefaultProfile = {
	npcId = 0,
	nameTH = "ศัตรูไม่รู้จัก",
	baseXP = 15,
	dropTable = {
		{ itemId = "StoneFragment", minQty = 1, maxQty = 2, chance = 0.50 },
	},
} :: NpcDropProfile

return NpcDropConfig
