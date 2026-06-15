--!strict
--[[
	ClassConfig (Class/Job system) — data-driven สายอาชีพ
	อิง CLASS-JOB-SYSTEM-BLUEPRINT.md · ต่อยอด CombatConfig (skill ids/multiplier/cooldown/meta)
	- 3 Base class (Warrior/Mage/Hunter = Sword/Staff/Bow) unlockLevel 10
	- 9 Sub-class unlockLevel 40 (baseClass ชี้ base)
	- statMods เบา (hp/atk/cdMult) — balance ใน config; ทุก sub-class solo-viable
	- skills = list of skill id (ต้องมีใน CombatConfig.SkillMultiplier/SkillCooldown/SkillMeta)
	- เผ่า affinity อ้าง class id เหล่านี้ (RaceConfig)
]]

local ClassConfig = {}

export type StatMods = { hp: number, atk: number, cdMult: number }
export type ClassDef = {
	id: string,
	label: string,
	labelTH: string,
	weaponType: "Sword" | "Bow" | "Staff",
	baseClass: string?, -- nil = base class; ไม่ nil = sub-class ของ id นี้
	unlockLevel: number,
	statMods: StatMods,
	skills: { string },
	desc: string,
}

local defs: { ClassDef } = {
	-- ───────── Base (Lv10) ─────────
	{
		id = "Warrior", label = "Warrior", labelTH = "นักรบ",
		weaponType = "Sword", baseClass = nil, unlockLevel = 10,
		statMods = { hp = 1.3, atk = 1.1, cdMult = 1.0 },
		skills = { "BasicAttack", "PowerSlash", "AoeSpin", "ShieldBash" },
		desc = "นักรบประชิด HP สูง อึด — ตีระยะใกล้",
	},
	{
		id = "Mage", label = "Mage", labelTH = "เมจ",
		weaponType = "Staff", baseClass = nil, unlockLevel = 10,
		statMods = { hp = 0.85, atk = 1.3, cdMult = 1.0 },
		skills = { "BasicAttack", "Fireball", "FrostNova", "AoeSpin" },
		desc = "เวทระยะไกล ดาเมจสูง HP น้อย (PvE)",
	},
	{
		id = "Hunter", label = "Hunter", labelTH = "นักล่า",
		weaponType = "Bow", baseClass = nil, unlockLevel = 10,
		statMods = { hp = 1.0, atk = 1.2, cdMult = 0.95 },
		skills = { "BasicAttack", "PiercingArrow", "MultiShot", "AoeSpin" },
		desc = "ธนูระยะไกล สมดุล ยิงต่อเนื่อง (PvE)",
	},
	-- ───────── Warrior sub (Lv40) ─────────
	{
		id = "Guardian", label = "Guardian", labelTH = "ผู้พิทักษ์",
		weaponType = "Sword", baseClass = "Warrior", unlockLevel = 40,
		statMods = { hp = 1.6, atk = 0.9, cdMult = 1.1 },
		skills = { "BasicAttack", "PowerSlash", "ShieldBash", "IronGuard" },
		desc = "แทงค์ HP สูงสุด ทนทาน",
	},
	{
		id = "Berserker", label = "Berserker", labelTH = "คลั่งสงคราม",
		weaponType = "Sword", baseClass = "Warrior", unlockLevel = 40,
		statMods = { hp = 1.1, atk = 1.4, cdMult = 0.9 },
		skills = { "BasicAttack", "PowerSlash", "AoeSpin", "Rampage" },
		desc = "ดาเมจประชิดสูง เสี่ยงสูง",
	},
	{
		id = "Paladin", label = "Paladin", labelTH = "อัศวินศักดิ์สิทธิ์",
		weaponType = "Sword", baseClass = "Warrior", unlockLevel = 40,
		statMods = { hp = 1.4, atk = 1.0, cdMult = 1.0 },
		skills = { "BasicAttack", "PowerSlash", "ShieldBash", "HolyStrike" },
		desc = "ครึ่งแทงค์ครึ่งซัพพอร์ต ยืนระยะยาว (solo ได้)",
	},
	-- ───────── Mage sub (Lv40) ─────────
	{
		id = "Elementalist", label = "Elementalist", labelTH = "ผู้ควบคุมธาตุ",
		weaponType = "Staff", baseClass = "Mage", unlockLevel = 40,
		statMods = { hp = 0.8, atk = 1.5, cdMult = 1.0 },
		skills = { "BasicAttack", "Fireball", "FrostNova", "Meteor" },
		desc = "นิวก์ AoE แรงสุด",
	},
	{
		id = "Sage", label = "Sage", labelTH = "ปราชญ์",
		weaponType = "Staff", baseClass = "Mage", unlockLevel = 40,
		statMods = { hp = 1.1, atk = 1.0, cdMult = 0.9 },
		skills = { "BasicAttack", "Fireball", "Smite", "AoeSpin" },
		desc = "ซัพพอร์ต HP สูงกว่าเมจ — solo-viable (self-sustain ผ่าน stat)",
	},
	{
		id = "Warlock", label = "Warlock", labelTH = "พ่อมดมืด",
		weaponType = "Staff", baseClass = "Mage", unlockLevel = 40,
		statMods = { hp = 0.95, atk = 1.3, cdMult = 1.0 },
		skills = { "BasicAttack", "Fireball", "CurseBolt", "FrostNova" },
		desc = "เวทมืด/สาป ดาเมจต่อเนื่อง",
	},
	-- ───────── Hunter sub (Lv40) ─────────
	{
		id = "Ranger", label = "Ranger", labelTH = "เรนเจอร์",
		weaponType = "Bow", baseClass = "Hunter", unlockLevel = 40,
		statMods = { hp = 1.0, atk = 1.25, cdMult = 0.85 },
		skills = { "BasicAttack", "PiercingArrow", "MultiShot", "RapidFire" },
		desc = "ยิงต่อเนื่อง DPS ยืนระยะ",
	},
	{
		id = "Assassin", label = "Assassin", labelTH = "นักลอบสังหาร",
		weaponType = "Bow", baseClass = "Hunter", unlockLevel = 40,
		statMods = { hp = 0.9, atk = 1.5, cdMult = 1.0 },
		skills = { "BasicAttack", "PiercingArrow", "Backstab", "PowerSlash" },
		desc = "เบิร์สต์สูง ไฮบริดประชิด",
	},
	{
		id = "Trickster", label = "Trickster", labelTH = "จอมกล",
		weaponType = "Bow", baseClass = "Hunter", unlockLevel = 40,
		statMods = { hp = 1.05, atk = 1.1, cdMult = 0.9 },
		skills = { "BasicAttack", "PiercingArrow", "TrapShot", "MultiShot" },
		desc = "ยูทิลิตี้/กับดัก ควบคุมสนาม",
	},
}

local byId: { [string]: ClassDef } = {}
for _, d in defs do
	byId[d.id] = d
end

function ClassConfig.all(): { ClassDef }
	return defs
end

function ClassConfig.get(id: string?): ClassDef?
	if typeof(id) ~= "string" then
		return nil
	end
	return byId[id]
end

function ClassConfig.isBase(id: string): boolean
	local d = byId[id]
	return d ~= nil and d.baseClass == nil
end

function ClassConfig.getSubclassesOf(baseId: string): { ClassDef }
	local out: { ClassDef } = {}
	for _, d in defs do
		if d.baseClass == baseId then
			table.insert(out, d)
		end
	end
	return out
end

function ClassConfig.allowsSkill(classId: string?, skillId: string): boolean
	local d = ClassConfig.get(classId)
	if not d then
		return true -- ไม่มีคลาส = default (ไม่ block) — ดูแลโดย CombatService
	end
	for _, s in d.skills do
		if s == skillId then
			return true
		end
	end
	return false
end

-- ตรวจว่าผู้เล่น level X เปลี่ยนเป็น targetClass ได้ไหม (จาก currentClass)
-- base: level >= unlockLevel · sub: level >= unlockLevel + currentClass ต้องเป็น baseClass ของ target
function ClassConfig.canChange(currentClassId: string?, targetClassId: string, level: number): (boolean, string)
	local target = ClassConfig.get(targetClassId)
	if not target then
		return false, "unknown_class"
	end
	if level < target.unlockLevel then
		return false, string.format("ต้องถึงเลเวล %d", target.unlockLevel)
	end
	if target.baseClass == nil then
		return true, "ok" -- base class เลือกได้ถ้าถึงเลเวล
	end
	-- sub-class: ต้องมาจาก base ที่ถูกต้อง
	if currentClassId ~= target.baseClass then
		local b = ClassConfig.get(target.baseClass)
		return false, string.format("ต้องเป็น %s ก่อน", if b then b.labelTH else (target.baseClass or "?"))
	end
	return true, "ok"
end

return ClassConfig
