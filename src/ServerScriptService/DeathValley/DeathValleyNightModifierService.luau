--!strict
--[[
	Phase B — Night modifier selection and wave tuning helpers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleyNightModifierService = {}

function DeathValleyNightModifierService.getForNight(nightNumber: number): PrismDeathValleySurvivalConfig.NightModifierDef
	return PrismDeathValleySurvivalConfig.getNightModifier(nightNumber)
end

function DeathValleyNightModifierService.getWaveSeconds(nightNumber: number): number
	local mod = DeathValleyNightModifierService.getForNight(nightNumber)
	return PrismDeathValleySurvivalConfig.WaveSeconds + mod.waveSecondsBonus
end

function DeathValleyNightModifierService.getFuelDrainMultiplier(nightNumber: number): number
	return DeathValleyNightModifierService.getForNight(nightNumber).fuelDrainMultiplier
end

function DeathValleyNightModifierService.toPublicPayload(nightNumber: number): { [string]: any }
	local mod = DeathValleyNightModifierService.getForNight(nightNumber)
	return {
		id = mod.id,
		displayName = mod.displayName,
		description = mod.description,
	}
end

return DeathValleyNightModifierService
