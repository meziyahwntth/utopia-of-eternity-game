--!strict
--[[
	RaceConfig (Race system) — data-driven เผ่า
	อิง RACE-SYSTEM-BLUEPRINT.md + RACES-AND-HELLBOUND-LORE-2026-06.md
	- 4 เผ่าเล่นได้: Human/Elf/DarkElf/Alien (Orc = สูญพันธุ์ ไม่เล่นได้ใน v1)
	- statMods เบามาก (1.0±0.05) — กัน power creep + no-P2W; ทุกเผ่า solo-viable
	- classAffinity อ้าง class id จาก ClassConfig (โบนัสเบา/แนะนำ ไม่ lock)
	- homeCityKey ตรง GameConfig.Places · meshBodyId = placeholder (Next-Gen Art)
]]

local RaceConfig = {}

export type RaceId = "Human" | "Elf" | "DarkElf" | "Alien"
export type RaceStatMods = { hp: number, atk: number, walkSpeed: number }
export type RaceDef = {
	id: RaceId,
	label: string,
	labelTH: string,
	homeCityKey: string,
	statMods: RaceStatMods,
	classAffinity: { string },
	racialPassive: string,
	meshBodyId: string?, -- placeholder Next-Gen Art (custom skinned mesh ต่อเผ่า)
	lore: string,
}

local defs: { RaceDef } = {
	{
		id = "Human", label = "Human", labelTH = "มนุษย์",
		homeCityKey = "NeonUtopia",
		statMods = { hp = 1.0, atk = 1.0, walkSpeed = 1.0 },
		classAffinity = { "Warrior", "Mage", "Hunter" }, -- ยืดหยุ่นทุกสาย
		racialPassive = "Versatile: รับ EXP +3% (ปรับสมดุลง่าย รอบด้าน)",
		lore = "เผ่ามนุษย์แห่งมหานคร Neon — เทคโนโลยีล้ำ ปรับตัวเก่ง จุดเริ่มต้นของผู้เล่นใหม่",
	},
	{
		id = "Elf", label = "Elf", labelTH = "เอลฟ์",
		homeCityKey = "Solhaven",
		statMods = { hp = 0.95, atk = 1.05, walkSpeed = 1.0 },
		classAffinity = { "Mage", "Hunter" },
		racialPassive = "Attunement: คูลดาวน์สกิลเวท/ธนูสั้นลงเล็กน้อย (flavor)",
		lore = "เผ่าเอลฟ์แห่ง Solhaven แดนแสงทอง — ผูกพันธรรมชาติและเวทมนตร์",
	},
	{
		id = "DarkElf", label = "Dark Elf", labelTH = "ดาร์คเอลฟ์",
		homeCityKey = "Nocturne",
		statMods = { hp = 0.95, atk = 1.05, walkSpeed = 1.02 },
		classAffinity = { "Assassin", "Warlock" },
		racialPassive = "Nightborn: ว่องไวขึ้นเล็กน้อยในที่มืด (flavor)",
		lore = "เผ่าดาร์คเอลฟ์แห่งตรอกสนธยา Nocturne — เงา ลอบเร้น เวทมืด",
	},
	{
		id = "Alien", label = "Alien", labelTH = "เอเลี่ยน",
		homeCityKey = "EternityCity",
		statMods = { hp = 1.0, atk = 1.05, walkSpeed = 0.98 },
		classAffinity = { "Mage", "Elementalist" },
		racialPassive = "Psionic: จิตพลัง/เทคขั้นสูง — สกิลเวทแรงขึ้นเล็กน้อย (flavor)",
		lore = "เผ่าเอเลี่ยนแห่งนครลอยฟ้า EternityCity — อารยธรรมก้าวหน้า ข้ามมิติ",
	},
}

local byId: { [string]: RaceDef } = {}
for _, d in defs do
	byId[d.id] = d
end

function RaceConfig.all(): { RaceDef }
	return defs
end

function RaceConfig.get(id: string?): RaceDef?
	if typeof(id) ~= "string" then
		return nil
	end
	return byId[id]
end

function RaceConfig.isPlayable(id: string?): boolean
	return RaceConfig.get(id) ~= nil
end

return RaceConfig
