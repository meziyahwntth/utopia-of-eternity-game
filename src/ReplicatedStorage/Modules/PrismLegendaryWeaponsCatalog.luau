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
	| "Bow"
	| "Staff"

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
		vfxNotes = "Dragon's Fury crown head · Starfire muzzle dragon jaw · Runic magazine stores ancient power · Celestial stock ethereal energy · Purple-blue-gold fire trail",
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
		vfxNotes = "Dragon soul orb core pulses purple · Celestial flame wreath barrel · Emperor gold crest shoulder · Arcane rune magazine glows red · Full fire trail on fire",
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
		vfxNotes = "Black gold filigree body · Compass star scope mount · Purple rune magazine · Red gem trigger guard · Gold prism trail burst on fire",
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
	-- Wave 2: Sword / Greatsword
	{
		id = "eternity_blade_skin",
		displayName = "Eternity Blade",
		kind = "Longsword",
		loadoutSlot = "heavy",
		robux = 1699,
		conceptArtFile = "eternity-blade.png",
		element = "Prism",
		vfxNotes = "White-gold crystal blade · prism light trail · fracture particles",
		damagePerHit = 22,
	},
	{
		id = "void_cleaver",
		displayName = "Void Cleaver",
		kind = "Greatsword",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "void-cleaver.png",
		element = "Void",
		vfxNotes = "Black blade with void rift crack · purple energy seep",
		damagePerHit = 20,
	},
	{
		id = "sakura_katana",
		displayName = "Sakura Katana",
		kind = "Longsword",
		loadoutSlot = "light",
		robux = 1399,
		conceptArtFile = "sakura-katana.png",
		element = "Nature",
		vfxNotes = "Cherry blossom petals trail · pink blade shimmer",
		damagePerHit = 16,
	},
	{
		id = "thunder_claymore",
		displayName = "Thunder Claymore",
		kind = "Greatsword",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "thunder-claymore.png",
		element = "Lightning",
		vfxNotes = "Electric arc crackling on blade · yellow storm aura",
		damagePerHit = 19,
	},
	{
		id = "blood_moon_blade",
		displayName = "Blood Moon Blade",
		kind = "Longsword",
		loadoutSlot = "heavy",
		robux = 1599,
		conceptArtFile = "blood-moon-blade.png",
		element = "Arcane",
		vfxNotes = "Crimson moon aura · blood drip VFX on swing · cathedral fire runes",
		damagePerHit = 18,
	},
	{
		id = "prism_twin_daggers",
		displayName = "Prism Twin Daggers",
		kind = "Dagger",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "prism-twin-daggers.png",
		element = "Prism",
		vfxNotes = "Dual rainbow light trail · prism burst on hit · void arcane aura",
		damagePerHit = 14,
	},
	-- Wave 2: Bow / Rifle
	{
		id = "celestial_longbow",
		displayName = "Celestial Longbow",
		kind = "Bow",
		loadoutSlot = "light",
		robux = 1399,
		conceptArtFile = "celestial-longbow.png",
		element = "Celestial",
		vfxNotes = "Star arrows · golden bow limb glow · constellation trail",
		damagePerHit = 17,
	},
	{
		id = "void_shadow_bow",
		displayName = "Void Shadow Bow",
		kind = "Bow",
		loadoutSlot = "light",
		robux = 1499,
		conceptArtFile = "void-shadow-bow.png",
		element = "Void",
		vfxNotes = "Dark matter arrows · shadow void burst on impact",
		damagePerHit = 18,
	},
	{
		id = "prism_sniper_rifle",
		displayName = "Prism Sniper Rifle",
		kind = "AssaultRifle",
		loadoutSlot = "light",
		robux = 1599,
		conceptArtFile = "prism-sniper.png",
		element = "Prism",
		vfxNotes = "Rainbow light beam trail · scope prism flash",
		damagePerHit = 25,
	},
	{
		id = "sakura_shortbow",
		displayName = "Sakura Shortbow",
		kind = "Bow",
		loadoutSlot = "light",
		robux = 1199,
		conceptArtFile = "sakura-shortbow.png",
		element = "Nature",
		vfxNotes = "Petal arrow trail · green nature burst",
		damagePerHit = 15,
	},
	{
		id = "thunder_repeater",
		displayName = "Thunder Repeater",
		kind = "AssaultRifle",
		loadoutSlot = "light",
		robux = 1399,
		conceptArtFile = "thunder-repeater.png",
		element = "Lightning",
		vfxNotes = "Chain lightning on rapid fire · electric barrel glow",
		damagePerHit = 16,
	},
	-- Wave 2: Staff / Magic
	{
		id = "prism_crystal_staff",
		displayName = "Prism Crystal Staff",
		kind = "Staff",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "prism-crystal-staff.png",
		element = "Prism",
		vfxNotes = "Prism orb tip · rainbow mana pulse · staff glow trail",
		damagePerHit = 14,
	},
	{
		id = "void_wand",
		displayName = "Void Wand",
		kind = "Staff",
		loadoutSlot = "light",
		robux = 1299,
		conceptArtFile = "void-wand.png",
		element = "Void",
		vfxNotes = "Void singularity orb · purple-black swirl on cast",
		damagePerHit = 16,
	},
	{
		id = "eternal_staff_divine",
		displayName = "Eternal Staff Divine",
		kind = "Staff",
		loadoutSlot = "heavy",
		robux = 1699,
		conceptArtFile = "eternal-staff-divine.png",
		element = "Holy",
		vfxNotes = "Angel wing feather burst · divine white-gold light column",
		damagePerHit = 13,
	},
	{
		id = "dragon_tome_staff",
		displayName = "Dragon Tome Staff",
		kind = "Staff",
		loadoutSlot = "heavy",
		robux = 1599,
		conceptArtFile = "dragon-tome-staff.png",
		element = "Draconic",
		vfxNotes = "Dragon head top · fire breath VFX on cast · scales trail",
		damagePerHit = 17,
	},
	{
		id = "lunar_moon_staff",
		displayName = "Lunar Moon Staff",
		kind = "Staff",
		loadoutSlot = "heavy",
		robux = 1399,
		conceptArtFile = "lunar-moon-staff.png",
		element = "Arcane",
		vfxNotes = "Crescent moon orb · silver moonbeam cast trail",
		damagePerHit = 15,
	},
	-- Wave 2: Heavy
	{
		id = "earth_shatter_hammer",
		displayName = "Earth Shatter Hammer",
		kind = "Hammer",
		loadoutSlot = "heavy",
		robux = 1499,
		conceptArtFile = "earth-shatter-hammer.png",
		element = "Earth",
		vfxNotes = "Rock crystal smash VFX · ground crack on hit · solar fire compass head",
		damagePerHit = 24,
	},
	{
		id = "void_cannon",
		displayName = "Void Cannon",
		kind = "Launcher",
		loadoutSlot = "heavy",
		robux = 1799,
		conceptArtFile = "void-cannon.png",
		element = "Void",
		vfxNotes = "Black hole projectile · purple singularity explosion · rune wheel muzzle",
		damagePerHit = 28,
	},
	{
		id = "prism_railgun",
		displayName = "Prism Railgun",
		kind = "LMG",
		loadoutSlot = "heavy",
		robux = 1699,
		conceptArtFile = "prism-railgun.png",
		element = "Prism",
		vfxNotes = "Continuous rainbow energy beam · prism shard spray · lion arcane crest",
		damagePerHit = 20,
	},
	{
		id = "dragon_mortar",
		displayName = "Dragon Mortar",
		kind = "Launcher",
		loadoutSlot = "heavy",
		robux = 1599,
		conceptArtFile = "dragon-mortar.png",
		element = "Draconic",
		vfxNotes = "Dragon fire projectile arc · fire pillar explosion",
		damagePerHit = 26,
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
