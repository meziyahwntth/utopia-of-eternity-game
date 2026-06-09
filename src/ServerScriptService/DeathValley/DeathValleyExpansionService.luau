--!strict
--[[
	Phase B — Horizon Rings unlock by nights survived.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleyExpansionService = {}

local unlockedRing = 0
local ringGates: { BasePart } = {}

local function collectGates(world: Model?)
	table.clear(ringGates)
	local root = world or Workspace:FindFirstChild("UtopiaDeathValley") :: Model?
	if not root then
		return
	end
	local folder = root:FindFirstChild("HorizonRings")
	if not folder then
		return
	end
	for _, desc in folder:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("HorizonRingGate") == true then
			table.insert(ringGates, desc)
		end
	end
end

function DeathValleyExpansionService.getUnlockedRing(): number
	return unlockedRing
end

function DeathValleyExpansionService.syncFromNights(nightsSurvived: number): number
	local newRing = PrismDeathValleySurvivalConfig.getUnlockedRing(nightsSurvived)
	if newRing ~= unlockedRing then
		unlockedRing = newRing
		DeathValleyExpansionService.applyGates()
	end
	return unlockedRing
end

function DeathValleyExpansionService.applyGates()
	for _, gate in ringGates do
		local minRing = gate:GetAttribute("MinRing")
		if typeof(minRing) ~= "number" then
			minRing = 1
		end
		local open = unlockedRing >= minRing
		gate.CanCollide = not open
		gate.Transparency = if open then 0.92 else 0.35
		local sign = gate:FindFirstChild("RingSign") :: BillboardGui?
		if sign then
			local label = sign:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = if open then "OPEN" else string.format("Ring %d · %d nights", minRing, DeathValleyExpansionService.getRequiredNights(minRing))
			end
		end
	end
end

function DeathValleyExpansionService.getRequiredNights(ring: number): number
	local def = PrismDeathValleySurvivalConfig.getRingDef(ring)
	return if def then def.minNightsSurvived else 0
end

function DeathValleyExpansionService.toPublicPayload(): { [string]: any }
	local def = PrismDeathValleySurvivalConfig.getRingDef(unlockedRing)
	return {
		unlockedRing = unlockedRing,
		displayName = if def then def.displayName else "Sanctuary Core",
		nextRing = unlockedRing + 1,
		nextRingNights = DeathValleyExpansionService.getRequiredNights(unlockedRing + 1),
	}
end

function DeathValleyExpansionService.bindWorld(world: Model)
	collectGates(world)
	DeathValleyExpansionService.applyGates()
end

function DeathValleyExpansionService.restoreRing(ring: number)
	unlockedRing = ring
	DeathValleyExpansionService.applyGates()
end

return DeathValleyExpansionService
