--!strict
--[[
	Shared Light Beacon state — fuel, level, sanctuary radius.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleyBeaconService = {}

local beaconLevel = 1
local beaconFuel = 0
local initialized = false
local fuelDrainMultiplier = 1

function DeathValleyBeaconService.init()
	if initialized then
		return
	end
	local def = PrismDeathValleySurvivalConfig.getBeaconLevel(1)
	beaconLevel = 1
	beaconFuel = math.floor(def.maxFuel * 0.5)
	initialized = true
end

function DeathValleyBeaconService.getLevel(): number
	return beaconLevel
end

function DeathValleyBeaconService.getFuel(): number
	return beaconFuel
end

function DeathValleyBeaconService.getRadius(): number
	return PrismDeathValleySurvivalConfig.getBeaconLevel(beaconLevel).radiusStuds
end

function DeathValleyBeaconService.getMaxFuel(): number
	return PrismDeathValleySurvivalConfig.getBeaconLevel(beaconLevel).maxFuel
end

function DeathValleyBeaconService.isInsideSanctuary(position: Vector3): boolean
	local flat = Vector3.new(position.X, 0, position.Z)
	local origin = Vector3.new(
		PrismDeathValleySurvivalConfig.BeaconOrigin.X,
		0,
		PrismDeathValleySurvivalConfig.BeaconOrigin.Z
	)
	return (flat - origin).Magnitude <= DeathValleyBeaconService.getRadius()
end

function DeathValleyBeaconService.setFuelDrainMultiplier(multiplier: number)
	fuelDrainMultiplier = math.max(0.1, multiplier)
end

function DeathValleyBeaconService.getFuelDrainMultiplier(): number
	return fuelDrainMultiplier
end

function DeathValleyBeaconService.restore(level: number, fuel: number)
	beaconLevel = math.clamp(level, 1, #PrismDeathValleySurvivalConfig.BeaconLevels)
	local def = PrismDeathValleySurvivalConfig.getBeaconLevel(beaconLevel)
	beaconFuel = math.clamp(fuel, 0, def.maxFuel)
	initialized = true
end

function DeathValleyBeaconService.depositFuel(amount: number): (boolean, string)
	local maxFuel = DeathValleyBeaconService.getMaxFuel()
	if beaconFuel >= maxFuel then
		return false, "Beacon fuel full"
	end
	beaconFuel = math.min(maxFuel, beaconFuel + amount)
	return true, string.format("Fuel +%d (%.0f/%.0f)", amount, beaconFuel, maxFuel)
end

function DeathValleyBeaconService.drainFuel(deltaSeconds: number): boolean
	beaconFuel = math.max(
		0,
		beaconFuel - PrismDeathValleySurvivalConfig.FuelDrainPerSecond * fuelDrainMultiplier * deltaSeconds
	)
	return beaconFuel > 0
end

function DeathValleyBeaconService.tryUpgrade(player: Player): (boolean, string)
	if beaconLevel >= #PrismDeathValleySurvivalConfig.BeaconLevels then
		return false, "Beacon max level"
	end
	local nextLevel = beaconLevel + 1
	local def = PrismDeathValleySurvivalConfig.getBeaconLevel(nextLevel)
	local shards = player:GetAttribute("DV_LuminiteShards")
	if typeof(shards) ~= "number" then
		shards = PrismDeathValleySurvivalConfig.StartingLuminiteShards
		player:SetAttribute("DV_LuminiteShards", shards)
	end
	if shards < def.upgradeShardCost then
		return false, string.format("Need %d Luminite shards", def.upgradeShardCost)
	end
	player:SetAttribute("DV_LuminiteShards", shards - def.upgradeShardCost)
	beaconLevel = nextLevel
	beaconFuel = math.min(beaconFuel, def.maxFuel)
	return true, string.format("Beacon upgraded to Lv%d", beaconLevel)
end

function DeathValleyBeaconService.snapshot(): { [string]: any }
	local def = PrismDeathValleySurvivalConfig.getBeaconLevel(beaconLevel)
	return {
		level = beaconLevel,
		fuel = beaconFuel,
		maxFuel = def.maxFuel,
		radiusStuds = def.radiusStuds,
	}
end

return DeathValleyBeaconService
