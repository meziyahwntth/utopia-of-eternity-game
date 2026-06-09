--!strict
--[[
	Legendary weapon catalog — ChatGPT-generated concept art by weapon type.
	Source images: assets/weapons/generated/
	Commerce: Prism Weapon Gallery · Hellbound loadout weapon skins (cosmetic PvE)
]]

export type WeaponSlot = "light" | "heavy"
export type WeaponKind =
	"Dagger"
	| "AssaultRifle"
	| "LMG"
	| "Launcher"
	| "Hammer"
	| "Greatsword"
	| "Longsword"
	| "Spear"
	| "Fan"

export type LegendaryWeaponDef = {
	id: string,
	displayName: string,
	kind: WeaponKind,
	loadoutSlot: WeaponSlot,
	robux: number,
	conceptArtFile: string,
	element: string,
	vfxNotes: string,
	damagePerHit: number?,
}

local PrismLegendaryWeaponsCatalog = {}

PrismLegendaryWeaponsCatalog.Weapons = {
	{
		id = "blood_knife",
		displayName = "Blood Knife",
		kind = "Dagger",
		loadoutSlot = "light",
		robux = 999,
		conceptArtFile = "blood-knife.png",
		element = "Arcane",
		vfxNotes = "Purple-gold blade aura · void sparks",
		damagePerHit = 12,
	},
	{
		id = "m16",
		displayName = "M16",
		kind = "AssaultRifle",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "m16.png",
		element = "Draconic",
		vfxNotes = "Celestial dragonforge · starfire muzzle",
		damagePerHit = 15,
	},
	{
		id = "ak47",
		displayName = "AK-47",
		kind = "AssaultRifle",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "ak47.png",
		element = "Celestial",
		vfxNotes = "Empyrean dragon core · celestial flame trail",
		damagePerHit = 15,
	},
	{
		id = "m4a1",
		displayName = "M4A1",
		kind = "AssaultRifle",
		loadoutSlot = "light",
		robux = 1199,
		conceptArtFile = "m4a1.png",
		element = "Prism",
		vfxNotes = "Gold filigree · purple rune magazine",
		damagePerHit = 14,
	},
	{
		id = "goddess_fan",
		displayName = "Goddess Fan",
		kind = "Fan",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "goddess-fan.png",
		element = "Lightning",
		vfxNotes = "War fan blades · arcane lightning wrap",
		damagePerHit = 13,
	},
	{
		id = "demon_slaying_spear",
		displayName = "Demon-Slaying Spear",
		kind = "Spear",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "demon-slaying-spear.png",
		element = "Holy",
		vfxNotes = "Flame crystal head · divine crossguard",
		damagePerHit = 16,
	},
	{
		id = "immortal_sword",
		displayName = "Immortal Sword",
		kind = "Longsword",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "immortal-sword.png",
		element = "Arcane",
		vfxNotes = "Celestial lightning · winged guard star gem · divine hall",
		damagePerHit = 15,
	},
	{
		id = "machine_gun",
		displayName = "Machine Gun",
		kind = "LMG",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "machine-gun.png",
		element = "Prism",
		vfxNotes = "Gradient ammo belt · winged crest magazine",
		damagePerHit = 18,
	},
	{
		id = "bazooka",
		displayName = "Bazooka",
		kind = "Launcher",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "bazooka.png",
		element = "Holy",
		vfxNotes = "Angel-wing guard · orange muzzle seal",
		damagePerHit = 25,
	},
	{
		id = "bazuka",
		displayName = "Bazuka",
		kind = "Launcher",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "bazuka-lion.png",
		element = "Arcane",
		vfxNotes = "Lion crest · purple lightning barrel",
		damagePerHit = 25,
	},
	{
		id = "thors_hammer",
		displayName = "Thor's Hammer",
		kind = "Hammer",
		loadoutSlot = "heavy",
		robux = 1399,
		conceptArtFile = "thors-hammer.png",
		element = "Fire",
		vfxNotes = "Sunburst head · flaming strike · divine hall aura",
		damagePerHit = 22,
	},
	{
		id = "demon_slayer_sword",
		displayName = "Demon Slayer Sword",
		kind = "Greatsword",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "demon-slayer-sword.png",
		element = "Holy",
		vfxNotes = "Rune blade · prismatic lightning arcs",
		damagePerHit = 20,
	},
	{
		id = "heavenly_sword",
		displayName = "Heavenly Sword",
		kind = "Greatsword",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "heavenly-sword.png",
		element = "Light",
		vfxNotes = "Golden translucent blade · ground rune seal",
		damagePerHit = 20,
	},
}

function PrismLegendaryWeaponsCatalog.getWeapon(weaponId: string): LegendaryWeaponDef?
	for _, def in PrismLegendaryWeaponsCatalog.Weapons do
		if def.id == weaponId then
			return def
		end
	end
	return nil
end

function PrismLegendaryWeaponsCatalog.getWeaponsForSlot(slot: WeaponSlot): { LegendaryWeaponDef }
	local list: { LegendaryWeaponDef } = {}
	for _, def in PrismLegendaryWeaponsCatalog.Weapons do
		if def.loadoutSlot == slot then
			table.insert(list, def)
		end
	end
	return list
end

function PrismLegendaryWeaponsCatalog.toCommerceEntries(): { { id: string, displayName: string, robux: number, kind: WeaponKind } }
	local entries: { { id: string, displayName: string, robux: number, kind: WeaponKind } } = {}
	for _, def in PrismLegendaryWeaponsCatalog.Weapons do
		table.insert(entries, {
			id = def.id,
			displayName = def.displayName,
			robux = def.robux,
			kind = def.kind,
		})
	end
	return entries
end

function PrismLegendaryWeaponsCatalog.getBossHitDamage(weaponId: string?, loadoutSlot: WeaponSlot): number
	if weaponId then
		local def = PrismLegendaryWeaponsCatalog.getWeapon(weaponId)
		if def and def.damagePerHit then
			return def.damagePerHit
		end
	end
	if loadoutSlot == "heavy" then
		return 18
	end
	return 15
end

return PrismLegendaryWeaponsCatalog
