--!strict
--[[
	Mount / vehicle key milestone rewards — keys 1/5/10/15/20.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismKeyProgression = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyProgression"))
local PrismKeyService = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("PrismKeyService"))
local VehicleMountCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VehicleMountCatalog"))
local PrismWeaponCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismWeaponCatalog"))

local MountRewardService = {}

local function ownedList(player: Player, attr: string): { string }
	local raw = player:GetAttribute(attr)
	if typeof(raw) ~= "string" or raw == "" then
		return {}
	end
	local list: { string } = {}
	for token in string.gmatch(raw, "[^,]+") do
		table.insert(list, token)
	end
	return list
end

local function appendOwned(player: Player, attr: string, id: string)
	local list = ownedList(player, attr)
	for _, existing in list do
		if existing == id then
			return
		end
	end
	table.insert(list, id)
	player:SetAttribute(attr, table.concat(list, ","))
end

function MountRewardService.getPendingReward(player: Player): number?
	local pending = player:GetAttribute("PrismKeyMilestonePending")
	if typeof(pending) == "number" then
		return pending
	end
	return nil
end

function MountRewardService.checkMilestones(player: Player)
	local pending = player:GetAttribute("PrismKeyMilestonePending")
	if typeof(pending) == "number" then
		return
	end
	for _, keyNum in PrismKeyService.getOwnedKeys(player) do
		if PrismKeyProgression.hasReward(keyNum) then
			local claimed = player:GetAttribute("PrismKeyMilestoneClaimed_" .. tostring(keyNum))
			if claimed ~= true then
				player:SetAttribute("PrismKeyMilestonePending", keyNum)
				return
			end
		end
	end
end

function MountRewardService.claimPetReward(player: Player, petId: string): (boolean, string)
	local pending = MountRewardService.getPendingReward(player)
	if not pending or (pending ~= 1 and pending ~= 5 and pending ~= 10) then
		return false, "No pet reward pending"
	end
	local reward = PrismKeyProgression.Rewards[pending]
	if not reward or reward.type ~= "mount_choice" then
		return false, "Invalid reward"
	end
	local entry = VehicleMountCatalog.getEntry(string.lower(petId))
	if not entry then
		return false, "Unknown pet — use dog, cat, or rabbit"
	end
	local valid = false
	for _, opt in reward.options do
		if string.lower(opt) == entry.id then
			valid = true
			break
		end
	end
	if not valid then
		return false, "Not a valid pet for this reward"
	end
	if reward.noDuplicate then
		for _, owned in ownedList(player, "OwnedPets") do
			if owned == entry.id then
				return false, "Already own this pet"
			end
		end
	end
	appendOwned(player, "OwnedPets", entry.id)
	player:SetAttribute("PrismKeyMilestoneClaimed_" .. tostring(pending), true)
	player:SetAttribute("PrismKeyMilestonePending", nil)
	if reward.endsPreviewTour then
		player:SetAttribute("EternityPreviewTour", false)
	end
	return true, "Pet unlocked: " .. entry.displayName
end

function MountRewardService.claimVehicleReward(player: Player, vehicleId: string): (boolean, string)
	local pending = MountRewardService.getPendingReward(player)
	if pending ~= 15 then
		return false, "Need key 15 vehicle reward pending"
	end
	local entry = VehicleMountCatalog.getEntry(vehicleId)
	if not entry or entry.keyRewardEligible ~= true then
		return false, "Invalid vehicle choice"
	end
	appendOwned(player, "OwnedVehicles", entry.id)
	player:SetAttribute("PrismKeyMilestoneClaimed_15", true)
	player:SetAttribute("PrismKeyMilestonePending", nil)
	player:SetAttribute("EternityPremiumShopUnlocked", true)
	return true, "Vehicle unlocked: " .. entry.displayName
end

function MountRewardService.claimWeaponReward(player: Player, weaponId: string): (boolean, string)
	local pending = MountRewardService.getPendingReward(player)
	if pending ~= 20 then
		return false, "Need key 20 weapon reward pending"
	end
	local weapon = PrismWeaponCatalog.getWeapon(weaponId)
	if not weapon then
		return false, "Unknown weapon"
	end
	if player:GetAttribute("Key20WeaponClaimed") == true then
		return false, "Already claimed key 20 weapon"
	end
	player:SetAttribute("Key20WeaponClaimed", true)
	player:SetAttribute("Key20WeaponId", weaponId)
	player:SetAttribute("PrismKeyMilestoneClaimed_20", true)
	player:SetAttribute("PrismKeyMilestonePending", nil)
	appendOwned(player, "OwnedWeapons", weaponId)
	return true, "Legendary weapon: " .. weapon.displayName
end

function MountRewardService.getRewardCatalog(player: Player): any
	local pending = MountRewardService.getPendingReward(player)
	if not pending then
		return { pending = nil }
	end
	local reward = PrismKeyProgression.Rewards[pending]
	if not reward then
		return { pending = pending }
	end
	if reward.type == "mount_choice" then
		return {
			pending = pending,
			type = "mount_choice",
			options = VehicleMountCatalog.getKeyRewardPets(),
		}
	elseif reward.type == "vehicle_choice" then
		return {
			pending = pending,
			type = "vehicle_choice",
			options = VehicleMountCatalog.getKeyRewardVehicles(),
		}
	elseif reward.type == "weapon_choice" then
		return {
			pending = pending,
			type = "weapon_choice",
			options = PrismWeaponCatalog.getKey20Choices(),
		}
	end
	return { pending = pending, type = reward.type }
end

function MountRewardService.start()
	Players.PlayerAdded:Connect(function(player)
		player:GetAttributeChangedSignal("PrismKeyCount"):Connect(function()
			MountRewardService.checkMilestones(player)
		end)
		task.defer(function()
			MountRewardService.checkMilestones(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.defer(function()
			MountRewardService.checkMilestones(player)
		end)
	end
	print("[Mount] Reward service online")
end

return MountRewardService
