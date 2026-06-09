--!strict
--[[
	Eternity Premium Shop — vehicles + weapons (key 15+ · Eternity City only).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleMountCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VehicleMountCatalog"))
local PrismWeaponCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismWeaponCatalog"))
local PrismKeyService = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("PrismKeyService"))

local EternityVehicleShop = {}

function EternityVehicleShop.canUseShop(player: Player): (boolean, string?)
	if PrismKeyService.getKeyCount(player) < 15 then
		return false, "Requires 15 Prism Keys for Eternity Premium Shop"
	end
	if player:GetAttribute("EternityPremiumShopUnlocked") ~= true then
		return false, "Unlock at key 15 reward or visit VehicleAdvisor"
	end
	return true, nil
end

function EternityVehicleShop.getCatalog(player: Player): { [string]: any }
	local ok, err = EternityVehicleShop.canUseShop(player)
	if not ok then
		return { ok = false, message = err }
	end

	local vehicles = {}
	for _, e in VehicleMountCatalog.getShopEntries(true) do
		table.insert(vehicles, {
			id = e.id,
			displayName = e.displayName,
			category = e.category,
			travelMode = e.travelMode,
			doorType = e.doorType,
			seatCount = e.seatCount,
			refImage = e.refImage,
		})
	end

	local weapons = {}
	for _, w in PrismWeaponCatalog.getShopWeapons() do
		table.insert(weapons, {
			id = w.id,
			displayName = w.displayName,
			robux = w.robux,
			loadoutSlot = w.loadoutSlot,
			refImage = w.refImage,
		})
	end

	return {
		ok = true,
		vehicles = vehicles,
		weapons = weapons,
		advisorTip = "Tri-mode first — then buy favorites with Robux (cosmetic only).",
	}
end

function EternityVehicleShop.grantDev(player: Player, itemId: string, kind: string): (boolean, string)
	local ok, err = EternityVehicleShop.canUseShop(player)
	if not ok then
		return false, err or "Shop locked"
	end
	if kind == "weapon" then
		local w = PrismWeaponCatalog.getWeapon(itemId)
		if not w then
			return false, "Unknown weapon"
		end
		player:SetAttribute("OwnedWeapon_" .. itemId, true)
		return true, "Dev grant: " .. w.displayName
	elseif kind == "vehicle" or kind == "mount" then
		local e = VehicleMountCatalog.getEntry(itemId)
		if not e then
			return false, "Unknown entry"
		end
		player:SetAttribute("OwnedVehicle_" .. itemId, true)
		return true, "Dev grant: " .. e.displayName
	end
	return false, "Invalid kind"
end

return EternityVehicleShop
