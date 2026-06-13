--!strict
--[[
	Prism Weapon catalog — Key 20 free choice + Eternity Premium Shop.
	Wraps PrismLegendaryWeaponsCatalog (13 user-named ChatGPT concepts).
]]

local PrismLegendaryWeaponsCatalog = require(script.Parent:WaitForChild("PrismLegendaryWeaponsCatalog"))

export type WeaponTier = "Legendary" | "Premium"
export type WeaponClass = "Dagger" | "AssaultRifle" | "LMG" | "Launcher" | "Hammer" | "Greatsword" | "Longsword" | "Spear" | "Fan" | "Bow" | "Staff"
export type UnlockKind = "Key20Choice" | "RobuxShop" | "HellboundLoadout"

export type WeaponEntry = {
	id: string,
	displayName: string,
	weaponClass: WeaponClass,
	tier: WeaponTier,
	refImage: string,
	loadoutSlot: PrismLegendaryWeaponsCatalog.WeaponSlot,
	element: string,
	robux: number,
	unlock: UnlockKind,
	cosmeticOnly: boolean,
	damagePerHit: number?,
}

local PrismWeaponCatalog = {}

local CLASS_MAP: { [string]: WeaponClass } = {
	Dagger = "Dagger",
	AssaultRifle = "AssaultRifle",
	LMG = "LMG",
	Launcher = "Launcher",
	Hammer = "Hammer",
	Greatsword = "Greatsword",
	Longsword = "Longsword",
	Spear = "Spear",
	Fan = "Fan",
	Bow = "Bow",
	Staff = "Staff",
}

local function toEntry(def: PrismLegendaryWeaponsCatalog.LegendaryWeaponDef): WeaponEntry
	return {
		id = def.id,
		displayName = def.displayName,
		weaponClass = CLASS_MAP[def.kind] or "Longsword",
		tier = "Legendary",
		refImage = "prism-weapons/" .. def.conceptArtFile,
		loadoutSlot = def.loadoutSlot,
		element = def.element,
		robux = def.robux,
		unlock = "RobuxShop",
		cosmeticOnly = true,
		damagePerHit = def.damagePerHit,
	}
end

local function buildWeapons(): { WeaponEntry }
	local list: { WeaponEntry } = {}
	for _, def in PrismLegendaryWeaponsCatalog.Weapons do
		table.insert(list, toEntry(def))
	end
	return list
end

PrismWeaponCatalog.Weapons = buildWeapons()

function PrismWeaponCatalog.getWeapon(id: string): WeaponEntry?
	for _, w in PrismWeaponCatalog.Weapons do
		if w.id == id then
			return w
		end
	end
	return nil
end

function PrismWeaponCatalog.getKey20Choices(): { WeaponEntry }
	return PrismWeaponCatalog.Weapons
end

function PrismWeaponCatalog.getShopWeapons(): { WeaponEntry }
	return PrismWeaponCatalog.Weapons
end

return PrismWeaponCatalog
