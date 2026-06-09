--!strict
--[[
	Dungeon loadout persistence + validation (server-authoritative).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonLoadoutCalculator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DungeonLoadoutCalculator"))
local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))
local PrismLegendaryWeaponsCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismLegendaryWeaponsCatalog"))

local playerLoadoutsMap: { [number]: DungeonLoadoutCalculator.PlayerLoadout } = {}

local DungeonLoadoutService = {}

local function serializeItems(items: { [string]: number }): string
	local parts: { string } = {}
	for _, def in PrismDeathValleyDungeonConfig.LoadoutItems do
		local count = items[def.id] or 0
		if count > 0 then
			table.insert(parts, def.id .. ":" .. tostring(count))
		end
	end
	return table.concat(parts, ",")
end

local function applyAttributes(player: Player, loadout: DungeonLoadoutCalculator.PlayerLoadout, locked: boolean)
	player:SetAttribute("DungeonLoadoutLocked", locked)
	player:SetAttribute("DungeonRole", loadout.role)
	player:SetAttribute("DungeonLoadoutWeight", DungeonLoadoutCalculator.computeWeight(loadout.items))
	player:SetAttribute("DungeonLoadoutItems", serializeItems(loadout.items))
	local skins = loadout.weaponSkins
	player:SetAttribute("DungeonLightWeapon", if skins then skins.light else nil)
	player:SetAttribute("DungeonHeavyWeapon", if skins then skins.heavy else nil)
end

function DungeonLoadoutService.getLoadout(player: Player): DungeonLoadoutCalculator.PlayerLoadout?
	return playerLoadoutsMap[player.UserId]
end

function DungeonLoadoutService.requireLoadout(player: Player): (boolean, string?)
	local loadout = playerLoadoutsMap[player.UserId]
	if not loadout then
		return false, "Lock your loadout at the station first"
	end
	if player:GetAttribute("DungeonLoadoutLocked") ~= true then
		return false, "Loadout not locked"
	end
	return true, nil
end

function DungeonLoadoutService.start()
	local remotes = ReplicatedStorage:WaitForChild("DungeonRemotes")
	local getCatalog = remotes:WaitForChild("GetLoadoutCatalog") :: RemoteFunction
	local saveLoadout = remotes:WaitForChild("SaveLoadout") :: RemoteFunction

	getCatalog.OnServerInvoke = function(_player: Player)
		local items = {}
		for _, def in PrismDeathValleyDungeonConfig.LoadoutItems do
			table.insert(items, {
				id = def.id,
				displayName = def.displayName,
				weightPerUnit = def.weightPerUnit,
				maxCount = def.maxCount,
				category = def.category,
			})
		end
		local roles = {}
		for _, roleId in PrismDeathValleyDungeonConfig.Zone1Roles do
			table.insert(roles, {
				id = roleId,
				label = PrismDeathValleyDungeonConfig.RoleLabels[roleId],
			})
		end
		local legendaryWeapons = {}
		for _, def in PrismLegendaryWeaponsCatalog.Weapons do
			table.insert(legendaryWeapons, {
				id = def.id,
				displayName = def.displayName,
				kind = def.kind,
				loadoutSlot = def.loadoutSlot,
				element = def.element,
				conceptArtFile = def.conceptArtFile,
			})
		end
		return {
			weightCap = PrismDeathValleyDungeonConfig.WeightCap,
			roles = roles,
			items = items,
			legendaryWeapons = legendaryWeapons,
			zone1 = PrismDeathValleyDungeonConfig.Zones[1],
		}
	end

	saveLoadout.OnServerInvoke = function(player: Player, payload: any)
		if typeof(payload) ~= "table" then
			return { ok = false, message = "Invalid payload" }
		end
		local role = payload.role
		local items = payload.items
		local weaponSkins = payload.weaponSkins
		if typeof(role) ~= "string" or typeof(items) ~= "table" then
			return { ok = false, message = "Invalid loadout" }
		end

		local loadout: DungeonLoadoutCalculator.PlayerLoadout = {
			role = role :: PrismDeathValleyDungeonConfig.DungeonRoleId,
			items = items,
			weaponSkins = if typeof(weaponSkins) == "table"
				then {
					light = weaponSkins.light,
					heavy = weaponSkins.heavy,
				}
				else nil,
		}

		local ok, err = DungeonLoadoutCalculator.validate(loadout)
		if not ok then
			return { ok = false, message = err or "Validation failed" }
		end

		playerLoadoutsMap[player.UserId] = loadout
		applyAttributes(player, loadout, true)

		return {
			ok = true,
			message = "Loadout locked",
			weight = DungeonLoadoutCalculator.computeWeight(loadout.items),
			role = loadout.role,
			canHeal = DungeonLoadoutCalculator.canHeal(loadout),
			healChannelSeconds = DungeonLoadoutCalculator.getHealChannelSeconds(loadout),
			bossHitDamage = DungeonLoadoutCalculator.getBossHitDamage(loadout),
			weaponSkins = loadout.weaponSkins,
		}
	end

	Players.PlayerRemoving:Connect(function(player)
		playerLoadoutsMap[player.UserId] = nil
	end)

	print("[Dungeon] Loadout service online")
end

return DungeonLoadoutService
