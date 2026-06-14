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
		icon = "rbxassetid://138487953541573",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.05, pickupRadius = 3, luckBonus = 0 },
		obtainMethod = "Drop",
	},
	{
		id = "fox_fire",
		nameTH = "จิ้งจอกไฟ 🦊",
		icon = "rbxassetid://94490112251523",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.10, pickupRadius = 5, luckBonus = 0.03 },
		obtainMethod = "Event",
	},
	{
		id = "dragon_mini",
		nameTH = "มังกรจิ๋ว 🐉",
		icon = "rbxassetid://98499021931067",
		modelId = "rbxassetid://0",
		rarity = "Legendary",
		buff = { expBonus = 0.15, pickupRadius = 8, luckBonus = 0.05 },
		obtainMethod = "Quest",
	},
	-- Wave 2: Common
	{
		id = "crystal_rabbit",
		nameTH = "กระต่ายคริสตัล 💎",
		icon = "rbxassetid://103273831527460",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.05, pickupRadius = 4, luckBonus = 0.01 },
		obtainMethod = "Drop",
	},
	{
		id = "mushroom_sprite",
		nameTH = "ดอกเห็ดอัจฉริยะ 🍄",
		icon = "rbxassetid://126189643034355",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.08, pickupRadius = 2, luckBonus = 0 },
		obtainMethod = "Shop",
	},
	{
		id = "star_chick",
		nameTH = "ลูกไก่ดาว ⭐",
		icon = "rbxassetid://81004155038651",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.06, pickupRadius = 3, luckBonus = 0.01 },
		obtainMethod = "Drop",
	},
	{
		id = "ghost_jellyfish",
		nameTH = "แมงกะพรุนผี 👻",
		icon = "rbxassetid://113290820796207",
		modelId = "rbxassetid://0",
		rarity = "Common",
		buff = { expBonus = 0.04, pickupRadius = 5, luckBonus = 0.02 },
		obtainMethod = "Drop",
	},
	-- Wave 2: Rare
	{
		id = "shadow_wolf_pup",
		nameTH = "ลูกหมาป่าเงา 🐺",
		icon = "rbxassetid://74162290323997",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.10, pickupRadius = 6, luckBonus = 0.04 },
		obtainMethod = "Drop",
	},
	{
		id = "neon_frog",
		nameTH = "กบนีออน 🐸",
		icon = "rbxassetid://134943372981857",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.08, pickupRadius = 5, luckBonus = 0.05 },
		obtainMethod = "Event",
	},
	{
		id = "thunder_hawk",
		nameTH = "เหยี่ยวฟ้าผ่า ⚡",
		icon = "rbxassetid://75483387691040",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.12, pickupRadius = 4, luckBonus = 0.03 },
		obtainMethod = "Quest",
	},
	{
		id = "prism_butterfly",
		nameTH = "ผีเสื้อปริซึม 🦋",
		icon = "rbxassetid://96679716545386",
		modelId = "rbxassetid://0",
		rarity = "Rare",
		buff = { expBonus = 0.10, pickupRadius = 7, luckBonus = 0.04 },
		obtainMethod = "Shop",
	},
	-- Wave 2: Epic
	{
		id = "angel_kitten",
		nameTH = "แมวทูตสวรรค์ 😇",
		icon = "rbxassetid://127689295003888",
		modelId = "rbxassetid://0",
		rarity = "Epic",
		buff = { expBonus = 0.15, pickupRadius = 8, luckBonus = 0.06 },
		obtainMethod = "Event",
	},
	{
		id = "void_cat",
		nameTH = "แมวแห่งความว่าง 🌑",
		icon = "rbxassetid://87992026158397",
		modelId = "rbxassetid://0",
		rarity = "Epic",
		buff = { expBonus = 0.12, pickupRadius = 8, luckBonus = 0.08 },
		obtainMethod = "Drop",
	},
	{
		id = "ice_fox",
		nameTH = "จิ้งจอกน้ำแข็ง ❄",
		icon = "rbxassetid://82556607209146",
		modelId = "rbxassetid://0",
		rarity = "Epic",
		buff = { expBonus = 0.14, pickupRadius = 6, luckBonus = 0.06 },
		obtainMethod = "Quest",
	},
	{
		id = "golden_turtle",
		nameTH = "เต่าทองคำ 🐢",
		icon = "rbxassetid://92494964147160",
		modelId = "rbxassetid://0",
		rarity = "Epic",
		buff = { expBonus = 0.10, pickupRadius = 5, luckBonus = 0.10 },
		obtainMethod = "Shop",
	},
	-- Wave 2: Legendary
	{
		id = "phoenix_chick",
		nameTH = "ลูกนกเพลิง 🔥",
		icon = "rbxassetid://103561676668329",
		modelId = "rbxassetid://0",
		rarity = "Legendary",
		buff = { expBonus = 0.20, pickupRadius = 10, luckBonus = 0.08 },
		obtainMethod = "Quest",
	},
	{
		id = "void_imp",
		nameTH = "ปีศาจความว่าง 👿",
		icon = "rbxassetid://124102144066293",
		modelId = "rbxassetid://0",
		rarity = "Legendary",
		buff = { expBonus = 0.15, pickupRadius = 10, luckBonus = 0.12 },
		obtainMethod = "Drop",
	},
	{
		id = "prism_core_orb",
		nameTH = "ออร์บแกนกลางปริซึม ✨",
		icon = "rbxassetid://121609318249639",
		modelId = "rbxassetid://0",
		rarity = "Legendary",
		buff = { expBonus = 0.25, pickupRadius = 12, luckBonus = 0.10 },
		obtainMethod = "Event",
	},
} :: { PetEntry }

return PetConfig
