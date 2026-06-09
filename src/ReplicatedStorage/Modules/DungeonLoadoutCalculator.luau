--!strict
--[[
	Validate dungeon loadout weight and role rules.
]]

local PrismDeathValleyDungeonConfig = require(script.Parent:WaitForChild("PrismDeathValleyDungeonConfig"))
local PrismLegendaryWeaponsCatalog = require(script.Parent:WaitForChild("PrismLegendaryWeaponsCatalog"))

export type LoadoutItemId = PrismDeathValleyDungeonConfig.LoadoutItemId
export type PlayerLoadout = PrismDeathValleyDungeonConfig.PlayerLoadout

local DungeonLoadoutCalculator = {}

function DungeonLoadoutCalculator.getItemDef(itemId: LoadoutItemId): PrismDeathValleyDungeonConfig.LoadoutItemDef?
	for _, def in PrismDeathValleyDungeonConfig.LoadoutItems do
		if def.id == itemId then
			return def
		end
	end
	return nil
end

function DungeonLoadoutCalculator.computeWeight(items: { [LoadoutItemId]: number }): number
	local total = 0
	for _, def in PrismDeathValleyDungeonConfig.LoadoutItems do
		local count = items[def.id] or 0
		if count > 0 then
			total += count * def.weightPerUnit
		end
	end
	return total
end

function DungeonLoadoutCalculator.validate(loadout: PlayerLoadout): (boolean, string?)
	local role = loadout.role
	if PrismDeathValleyDungeonConfig.RoleLabels[role] == nil then
		return false, "Invalid role"
	end

	for itemId, count in loadout.items do
		if typeof(count) ~= "number" or count < 0 or count ~= math.floor(count) then
			return false, "Invalid item count"
		end
		local def = DungeonLoadoutCalculator.getItemDef(itemId :: LoadoutItemId)
		if not def then
			return false, "Unknown item"
		end
		if count > def.maxCount then
			return false, string.format("%s max %d", def.displayName, def.maxCount)
		end
	end

	local medicSupply = loadout.items.medic_supply or 0
	local heavy = loadout.items.heavy_weapon or 0

	if role == "CombatMedic" and heavy > 0 then
		return false, "Combat Medic — light weapons only"
	end

	if role == "CombatMedic" and medicSupply <= 0 then
		return false, "Combat Medic needs team medic supplies"
	end

	if role == "HeavyGunner" and heavy <= 0 then
		return false, "Heavy Gunner needs a heavy weapon"
	end

	if role == "HeavyGunner" and medicSupply > 0 then
		return false, "Heavy Gunner cannot carry team medic supplies"
	end

	local weight = DungeonLoadoutCalculator.computeWeight(loadout.items)
	if weight > PrismDeathValleyDungeonConfig.WeightCap then
		return false, string.format("Over weight cap (%d/%d)", weight, PrismDeathValleyDungeonConfig.WeightCap)
	end

	if weight <= 0 then
		return false, "Loadout cannot be empty"
	end

	local skinOk, skinErr = DungeonLoadoutCalculator.validateWeaponSkins(loadout)
	if not skinOk then
		return false, skinErr
	end

	return true, nil
end

function DungeonLoadoutCalculator.validateWeaponSkins(loadout: PlayerLoadout): (boolean, string?)
	local skins = loadout.weaponSkins
	local lightCount = loadout.items.light_weapon or 0
	local heavyCount = loadout.items.heavy_weapon or 0

	if not skins then
		return true, nil
	end

	if skins.light then
		if lightCount <= 0 then
			return false, "Select light weapon loadout item first"
		end
		local def = PrismLegendaryWeaponsCatalog.getWeapon(skins.light)
		if not def then
			return false, "Unknown light weapon skin"
		end
		if def.loadoutSlot ~= "light" then
			return false, string.format("%s is not a light weapon", def.displayName)
		end
	end

	if skins.heavy then
		if heavyCount <= 0 then
			return false, "Select heavy weapon loadout item first"
		end
		local def = PrismLegendaryWeaponsCatalog.getWeapon(skins.heavy)
		if not def then
			return false, "Unknown heavy weapon skin"
		end
		if def.loadoutSlot ~= "heavy" then
			return false, string.format("%s is not a heavy weapon", def.displayName)
		end
	end

	if role == "CombatMedic" and skins.heavy then
		return false, "Combat Medic — light weapon skins only"
	end

	return true, nil
end

function DungeonLoadoutCalculator.getBossHitDamage(loadout: PlayerLoadout): number
	local heavyCount = loadout.items.heavy_weapon or 0
	local slot: PrismLegendaryWeaponsCatalog.WeaponSlot = if heavyCount > 0 then "heavy" else "light"
	local skins = loadout.weaponSkins
	local weaponId: string? = nil
	if slot == "heavy" and skins and skins.heavy then
		weaponId = skins.heavy
	elseif slot == "light" and skins and skins.light then
		weaponId = skins.light
	end
	return PrismLegendaryWeaponsCatalog.getBossHitDamage(weaponId, slot)
end

function DungeonLoadoutCalculator.defaultLoadout(role: PrismDeathValleyDungeonConfig.DungeonRoleId): PlayerLoadout
	local items: { [LoadoutItemId]: number } = {}
	if role == "CombatMedic" then
		items.medic_supply = 20
	elseif role == "HeavyGunner" then
		items.heavy_weapon = 1
		items.ammo_pack = 3
	elseif role == "AmmoRunner" then
		items.ammo_pack = 8
		items.light_weapon = 1
	elseif role == "Grenadier" then
		items.grenade = 3
		items.trap = 2
	else
		items.light_weapon = 1
		if role == "PersonalMedic" then
			items.personal_medic_kit = 1
		end
	end

	local weaponSkins: { light: string?, heavy: string? } = {}
	if items.light_weapon and items.light_weapon > 0 then
		if role == "BossStriker" or role == "AddStriker" then
			weaponSkins.light = "m16"
		elseif role == "PersonalMedic" then
			weaponSkins.light = "blood_knife"
		else
			weaponSkins.light = "ak47"
		end
	end
	if items.heavy_weapon and items.heavy_weapon > 0 then
		weaponSkins.heavy = "demon_slayer_sword"
	end

	return { role = role, items = items, weaponSkins = weaponSkins }
end

function DungeonLoadoutCalculator.hasPersonalKit(loadout: PlayerLoadout): boolean
	return (loadout.items.personal_medic_kit or 0) > 0
end

function DungeonLoadoutCalculator.canHeal(loadout: PlayerLoadout): boolean
	return loadout.role == "CombatMedic" or DungeonLoadoutCalculator.hasPersonalKit(loadout)
end

function DungeonLoadoutCalculator.getHealChannelSeconds(loadout: PlayerLoadout): number
	if loadout.role == "CombatMedic" then
		return PrismDeathValleyDungeonConfig.MedicTeamSupply.channelSeconds
	end
	return PrismDeathValleyDungeonConfig.MedicPersonalKit.channelSeconds
end

function DungeonLoadoutCalculator.getHealSlowPercent(loadout: PlayerLoadout): number
	if loadout.role == "CombatMedic" then
		return PrismDeathValleyDungeonConfig.MedicTeamSupply.slowPercent
	end
	return PrismDeathValleyDungeonConfig.MedicPersonalKit.slowPercent
end

return DungeonLoadoutCalculator
