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
	BasicAttack = 1.0,
	PowerSlash = 1.8,
	AoeSpin = 1.2,
} :: { [string]: number }

-- Per-skill cooldown (seconds). BasicAttack=0 uses weapon AttackSpeed cadence.
-- Enforced BOTH client-side (Skill Bar UI gating) and server-side (CombatService).
CombatConfig.SkillCooldown = {
	BasicAttack = 0,
	PowerSlash = 4,
	AoeSpin = 7,
} :: { [string]: number }

export type SkillDef = { id: string, label: string, icon: string, cooldown: number }

-- Ordered list shown on the mobile Skill Bar (bottom-right).
CombatConfig.Skills = {
	{ id = "BasicAttack", label = "Attack", icon = "⚔", cooldown = 0 },
	{ id = "PowerSlash", label = "Power", icon = "💥", cooldown = 4 },
	{ id = "AoeSpin", label = "Spin", icon = "🌀", cooldown = 7 },
} :: { SkillDef }

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
