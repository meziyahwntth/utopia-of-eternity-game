--!strict
--[[
	CombatConfig (P3-C+) — weapon ranges, attack cadence, damage tables.
	See docs/BLUEPRINT-V2-WORLD-PROGRESSION.md §J3
]]
local CombatConfig = {}

export type WeaponType = "Sword" | "Bow" | "Staff"
export type WeaponTier = "T1" | "T2" | "T3" | "T4" | "T5"

CombatConfig.MaxRange = {
	Sword = 10,
	Bow = 50,
	Staff = 30,
} :: { [WeaponType]: number }

CombatConfig.AttackSpeed = {
	T1 = 1.0,
	T2 = 0.9,
	T3 = 0.8,
	T4 = 0.7,
	T5 = 0.6,
} :: { [WeaponTier]: number }

CombatConfig.BaseDamage = {
	T1 = 10,
	T2 = 20,
	T3 = 35,
	T4 = 55,
	T5 = 80,
} :: { [WeaponTier]: number }

CombatConfig.SkillMultiplier = {
	-- shared / starter
	BasicAttack = 1.0,
	PowerSlash = 1.8,
	AoeSpin = 1.2,
	-- Warrior line (Sword)
	ShieldBash = 1.4,
	IronGuard = 1.0,
	Rampage = 2.4,
	HolyStrike = 1.7,
	-- Mage line (Staff)
	Fireball = 1.6,
	FrostNova = 1.3,
	Meteor = 2.6,
	Smite = 1.6,
	CurseBolt = 1.8,
	-- Hunter line (Bow)
	PiercingArrow = 1.6,
	MultiShot = 1.3,
	RapidFire = 2.2,
	Backstab = 2.5,
	TrapShot = 1.5,
} :: { [string]: number }

-- Per-skill cooldown (seconds). BasicAttack=0 uses weapon AttackSpeed cadence.
-- Enforced BOTH client-side (Skill Bar UI gating) and server-side (CombatService).
CombatConfig.SkillCooldown = {
	BasicAttack = 0,
	PowerSlash = 4,
	AoeSpin = 7,
	ShieldBash = 6,
	IronGuard = 10,
	Rampage = 12,
	HolyStrike = 8,
	Fireball = 5,
	FrostNova = 8,
	Meteor = 14,
	Smite = 7,
	CurseBolt = 9,
	PiercingArrow = 5,
	MultiShot = 8,
	RapidFire = 12,
	Backstab = 11,
	TrapShot = 9,
} :: { [string]: number }

export type SkillDef = { id: string, label: string, icon: string, cooldown: number }

-- Ordered list shown on the mobile Skill Bar (bottom-right) — default (ผู้เล่นที่ยังไม่เลือกคลาส)
CombatConfig.Skills = {
	{ id = "BasicAttack", label = "Attack", icon = "⚔", cooldown = 0 },
	{ id = "PowerSlash", label = "Power", icon = "💥", cooldown = 4 },
	{ id = "AoeSpin", label = "Spin", icon = "🌀", cooldown = 7 },
} :: { SkillDef }

-- Metadata (icon/label) ต่อ skill id — ใช้ render Skill Bar ตามคลาส (ClassConfig.skills อ้าง id เหล่านี้)
CombatConfig.SkillMeta = {
	BasicAttack = { label = "Attack", icon = "⚔" },
	PowerSlash = { label = "Power", icon = "💥" },
	AoeSpin = { label = "Spin", icon = "🌀" },
	ShieldBash = { label = "Bash", icon = "🛡" },
	IronGuard = { label = "Guard", icon = "🛡️" },
	Rampage = { label = "Rampage", icon = "🔥" },
	HolyStrike = { label = "Holy", icon = "✨" },
	Fireball = { label = "Fire", icon = "🔥" },
	FrostNova = { label = "Frost", icon = "❄" },
	Meteor = { label = "Meteor", icon = "☄" },
	Smite = { label = "Smite", icon = "🌟" },
	CurseBolt = { label = "Curse", icon = "💀" },
	PiercingArrow = { label = "Pierce", icon = "🏹" },
	MultiShot = { label = "Multi", icon = "🎯" },
	RapidFire = { label = "Rapid", icon = "💨" },
	Backstab = { label = "Backstab", icon = "🗡" },
	TrapShot = { label = "Trap", icon = "🪤" },
} :: { [string]: { label: string, icon: string } }

CombatConfig.DefaultWeaponType = "Sword" :: WeaponType
CombatConfig.DefaultWeaponTier = "T1" :: WeaponTier
CombatConfig.DefaultSkillId = "BasicAttack"

-- NPC models use attribute CombatNpcId (number) + Humanoid
CombatConfig.NpcIdAttribute = "CombatNpcId"

CombatConfig.UI = {
	ToggleSize = 44,
	ToggleAnchor = Vector2.new(0, 1),
	TogglePosition = UDim2.new(0, 16, 1, -16),
}

return CombatConfig
