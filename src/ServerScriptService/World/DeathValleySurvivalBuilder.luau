--!strict
--[[
	Phase A world props — fuel depot, beacon upgrade kiosk, exit portal.
]]

local DeathValleySurvivalBuilder = {}

function DeathValleySurvivalBuilder:Build(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "SurvivalPhaseA"
	folder.Parent = parent

	local fuelDepot = Instance.new("Part")
	fuelDepot.Name = "BeaconFuelDepot"
	fuelDepot.Size = Vector3.new(8, 4, 8)
	fuelDepot.CFrame = CFrame.new(18, 2, 8)
	fuelDepot.Anchored = true
	fuelDepot.Color = profile.Palette.Amber
	fuelDepot.Material = Enum.Material.Neon
	fuelDepot.Parent = folder
	fuelDepot:SetAttribute("BeaconFuelDepot", true)

	local fuelPrompt = Instance.new("ProximityPrompt")
	fuelPrompt.ActionText = "Deposit Fuel"
	fuelPrompt.ObjectText = "Beacon Fuel"
	fuelPrompt.MaxActivationDistance = 10
	fuelPrompt.Parent = fuelDepot

	local upgradeKiosk = Instance.new("Part")
	upgradeKiosk.Name = "BeaconUpgradeKiosk"
	upgradeKiosk.Size = Vector3.new(6, 8, 4)
	upgradeKiosk.CFrame = CFrame.new(-18, 4, 10)
	upgradeKiosk.Anchored = true
	upgradeKiosk.Color = Color3.fromRGB(180, 140, 255)
	upgradeKiosk.Material = Enum.Material.SmoothPlastic
	upgradeKiosk.Parent = folder
	upgradeKiosk:SetAttribute("BeaconUpgradeKiosk", true)

	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.ActionText = "Upgrade Beacon"
	upgradePrompt.ObjectText = "Light Beacon"
	upgradePrompt.MaxActivationDistance = 10
	upgradePrompt.Parent = upgradeKiosk

	local exitPortal = Instance.new("Part")
	exitPortal.Name = "ExitPortal"
	exitPortal.Size = Vector3.new(10, 12, 2)
	exitPortal.CFrame = CFrame.new(0, 6, 55)
	exitPortal.Anchored = true
	exitPortal.Color = Color3.fromRGB(0, 229, 255)
	exitPortal.Material = Enum.Material.Neon
	exitPortal.Transparency = 0.25
	exitPortal.Parent = folder
	exitPortal:SetAttribute("ExitPortal", true)
	exitPortal:SetAttribute("PlaceKey", "Hub")

	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.ActionText = "Return to Hub"
	exitPrompt.ObjectText = "Exit Portal"
	exitPrompt.MaxActivationDistance = 12
	exitPrompt.Parent = exitPortal

	local beacon = parent:FindFirstChild("LifeBeacon", true)
	if beacon and beacon:IsA("BasePart") then
		beacon:SetAttribute("LightBeaconCore", true)
	end

	WorldBuildBudget:add(budget, 3)
end

return DeathValleySurvivalBuilder
