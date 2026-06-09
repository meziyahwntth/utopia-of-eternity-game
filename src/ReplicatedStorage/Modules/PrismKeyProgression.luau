--!strict
--[[
	Prism Key unlock gates for Eternity City + meta rewards.
]]

local PrismKeyProgression = {}

PrismKeyProgression.EternityCityAccess = {
	PreviewTourMaxKeys = 9,
	FreeRoamMinKeys = 10,
	ZoneGateKeys = {
		[11] = "CanalPromenade",
		[15] = "SkyRailPlaza",
		[20] = "FullCity",
	},
	KeysForbiddenInCity = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
	GateKeysInCity = { 11, 15, 20 },
}

PrismKeyProgression.Rewards = {
	[1] = { type = "mount_choice", options = { "Dog", "Cat", "Rabbit" } },
	[5] = { type = "mount_choice", options = { "Dog", "Cat", "Rabbit" }, noDuplicate = true },
	[10] = { type = "mount_choice", options = { "Dog", "Cat", "Rabbit" }, noDuplicate = true, endsPreviewTour = true },
	[15] = {
		type = "vehicle_choice",
		options = { "BigBike", "SportsCar", "Sedan", "PickupTruck" },
		unlocksPremiumShop = true,
	},
	[20] = { type = "weapon_choice", count = 1, tier = "Legendary" },
	[25] = { type = "face_unlock", mode = "PrismLiveMirror" },
}

function PrismKeyProgression.getZoneForKeyCount(keyCount: number): string
	if keyCount >= 20 then
		return "FullCity"
	end
	if keyCount >= 15 then
		return "SkyRailPlaza"
	end
	if keyCount >= 11 then
		return "CanalPromenade"
	end
	if keyCount >= 10 then
		return "FreeRoamPartial"
	end
	return "PreviewTour"
end

function PrismKeyProgression.hasReward(keyCount: number): boolean
	return PrismKeyProgression.Rewards[keyCount] ~= nil
end

function PrismKeyProgression.isKeyForbiddenInCity(keyIndex: number): boolean
	for _, forbidden in PrismKeyProgression.EternityCityAccess.KeysForbiddenInCity do
		if forbidden == keyIndex then
			return true
		end
	end
	return false
end

function PrismKeyProgression.isGateKeyInCity(keyIndex: number): boolean
	for _, gate in PrismKeyProgression.EternityCityAccess.GateKeysInCity do
		if gate == keyIndex then
			return true
		end
	end
	return false
end

function PrismKeyProgression.getMinKeysForZone(zoneId: string): number
	if zoneId == "AuroraMegaMall" or zoneId == "FullCity" then
		return 20
	end
	if zoneId == "SkyRailPlaza" or zoneId == "PremiumShop" then
		return 15
	end
	if zoneId == "CanalPromenade" or zoneId == "HoverShowroom" or zoneId == "MarinaRing" then
		return 11
	end
	return PrismKeyProgression.EternityCityAccess.FreeRoamMinKeys
end

-- Keys 1–10 and random keys belong outside Eternity City; gate keys 11/15/20 only inside.
function PrismKeyProgression.canGrantKeyInPlace(keyNumber: number, placeKey: string): boolean
	if placeKey == "EternityCity" then
		return PrismKeyProgression.isGateKeyInCity(keyNumber)
	end
	if PrismKeyProgression.isGateKeyInCity(keyNumber) then
		return false
	end
	return true
end

return PrismKeyProgression
