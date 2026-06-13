--!strict
-- MountConfig.luau
-- Legendary mounts — visual refs: white-gold fantasy creatures

export type MountDef = {
	id: string,
	displayName: string,
	mountType: "Ground" | "Flying",
	speedBoost: number,
	flyHeight: number,
	robuxPrice: number,
	creditPrice: number,
	modelId: number,
	auraEffect: string,
	rarity: "Epic" | "Legendary" | "Mythic",
	loreDesc: string,
}

local MountConfig = {}

MountConfig.All: { MountDef } = {
	{
		id = "white_timber_wolf",
		displayName = "White Timber Wolf",
		mountType = "Ground",
		speedBoost = 22,
		flyHeight = 0,
		robuxPrice = 799,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "FrostBreath",
		rarity = "Epic",
		loreDesc = "สัตว์ผู้พิทักษ์แห่งป่า Prism เชื่องได้ด้วยผู้ที่มีความกล้าหาญ",
	},
	{
		id = "golden_lion_king",
		displayName = "Golden Lion King",
		mountType = "Ground",
		speedBoost = 26,
		flyHeight = 0,
		robuxPrice = 1299,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "SolarMane",
		rarity = "Legendary",
		loreDesc = "ราชาแห่งสัตว์บนเมฆ ผู้สวมมงกุฎทองแห่ง Eternity City",
	},
	{
		id = "celestial_white_deer",
		displayName = "Celestial White Deer",
		mountType = "Ground",
		speedBoost = 20,
		flyHeight = 0,
		robuxPrice = 999,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "StardustHoof",
		rarity = "Epic",
		loreDesc = "กวางศักดิ์สิทธิ์ที่โขลงมาจากเมฆ มีเขาทองคำจากแสงดาว",
	},
	{
		id = "red_gold_phoenix",
		displayName = "Red-Gold Phoenix",
		mountType = "Flying",
		speedBoost = 30,
		flyHeight = 50,
		robuxPrice = 1499,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "FlameTail",
		rarity = "Legendary",
		loreDesc = "นกเพลิงที่ฟื้นจากเถ้าถ่านของ Hellbound ทุก 1000 ปี",
	},
	{
		id = "white_pegasus",
		displayName = "White Pegasus",
		mountType = "Flying",
		speedBoost = 28,
		flyHeight = 40,
		robuxPrice = 1399,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "WindMane",
		rarity = "Legendary",
		loreDesc = "ม้าปีกขาวแห่งท้องฟ้า บรรพบุรุษของฝูงม้าที่โบยบินรอบ Aurora Spire",
	},
	{
		id = "prism_white_dragon",
		displayName = "Prism White Dragon",
		mountType = "Flying",
		speedBoost = 35,
		flyHeight = 60,
		robuxPrice = 0,
		creditPrice = 150000,
		modelId = 0,
		auraEffect = "PrismScales",
		rarity = "Mythic",
		loreDesc = "มังกรแห่ง Prism Covenant ผู้เก็บรักษา Key #1 ไว้บนร่างกาย",
	},
	{
		id = "golden_griffin",
		displayName = "Golden Griffin",
		mountType = "Flying",
		speedBoost = 32,
		flyHeight = 55,
		robuxPrice = 1699,
		creditPrice = 0,
		modelId = 0,
		auraEffect = "RegalWing",
		rarity = "Mythic",
		loreDesc = "กริฟฟินสวมมงกุฎทองแห่งสกาย — ผู้พิทักษ์ท้องฟ้าของ Utopia",
	},
}

function MountConfig.getById(id: string): MountDef?
	for _, m in MountConfig.All do
		if m.id == id then
			return m
		end
	end
	return nil
end

return MountConfig
