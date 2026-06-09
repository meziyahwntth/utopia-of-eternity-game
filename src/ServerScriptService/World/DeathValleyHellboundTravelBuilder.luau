--!strict
--[[
	Phase C — Playable Hellbound stations: Peak → Rail → Base → Spirit → Sanctuary.
]]

local DeathValleyHellboundTravelBuilder = {}

local STATIONS = {
	{ name = "PeakColonyDock", pos = Vector3.new(-120, 4, 100), label = "Peak Colony Dock", action = "BeginTravel" },
	{ name = "ElevatorShaft", pos = Vector3.new(-100, 4, 70), label = "Colony Elevator", action = "ContinueTravel" },
	{ name = "RailPlatform", pos = Vector3.new(-70, 4, 40), label = "High-Speed Rail", action = "ContinueTravel" },
	{ name = "MilitaryBase", pos = Vector3.new(-40, 4, 10), label = "Military Research Base", action = "ContinueTravel" },
	{ name = "SpiritChamber1", pos = Vector3.new(-20, 4, -10), label = "Spirit Lock I", action = "ContinueTravel" },
	{ name = "SpiritChamber2", pos = Vector3.new(0, 4, -25), label = "Spirit Lock II", action = "ContinueTravel" },
	{ name = "SpiritChamber3", pos = Vector3.new(15, 4, -35), label = "Spirit Lock III", action = "ContinueTravel" },
	{ name = "DeathValleyArrival", pos = Vector3.new(0, 4, 25), label = "Sanctuary Arrival", action = "ArriveSanctuary", teleport = Vector3.new(0, 5, 0) },
}

function DeathValleyHellboundTravelBuilder:BuildPlayable(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "HellboundTravelPipeline"
	folder.Parent = parent

	for i, spec in STATIONS do
		local prev = STATIONS[i - 1]
		if prev then
			local mid = prev.pos:Lerp(spec.pos, 0.5)
			local segmentCount = 4
			for s = 0, segmentCount do
				local t = s / segmentCount
				local pos = prev.pos:Lerp(spec.pos, t)
				local slab = Instance.new("Part")
				slab.Name = "TravelSegment"
				slab.Size = Vector3.new(5, 0.4, 5)
				slab.Anchored = true
				slab.Color = Color3.fromRGB(70, 55, 80)
				slab.Material = Enum.Material.Metal
				slab.CFrame = CFrame.new(pos)
				slab.Parent = folder
			end
		end

		local station = Instance.new("Part")
		station.Name = spec.name
		station.Size = Vector3.new(10, 1, 10)
		station.Anchored = true
		station.CFrame = CFrame.new(spec.pos)
		station.Color = profile.Palette.Amber
		station.Material = Enum.Material.Neon
		station.Parent = folder
		station:SetAttribute("HellboundStation", true)
		station:SetAttribute("HellboundAction", spec.action)
		if spec.teleport then
			station:SetAttribute("TeleportTarget", spec.teleport)
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = if spec.action == "BeginTravel" then "Begin Hellbound Journey" else "Continue"
		prompt.ObjectText = spec.label
		prompt.MaxActivationDistance = 14
		prompt.Parent = station

		local sign = Instance.new("BillboardGui")
		sign.Size = UDim2.fromOffset(180, 40)
		sign.StudsOffset = Vector3.new(0, 5, 0)
		sign.AlwaysOnTop = true
		sign.Parent = station
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 13
		lbl.TextColor3 = profile.Palette.Amber
		lbl.Text = spec.label
		lbl.Parent = sign

		if spec.name == "MilitaryBase" then
			station:SetAttribute("LfgBoard", true)
			local lfgPad = Instance.new("Part")
			lfgPad.Name = "LfgBoard"
			lfgPad.Size = Vector3.new(12, 8, 2)
			lfgPad.CFrame = CFrame.new(spec.pos + Vector3.new(0, 5, 8))
			lfgPad.Anchored = true
			lfgPad.Color = profile.Palette.Cyan
			lfgPad.Material = Enum.Material.Neon
			lfgPad.Parent = folder
			lfgPad:SetAttribute("LfgBoard", true)
			local lfgPrompt = Instance.new("ProximityPrompt")
			lfgPrompt.ActionText = "Open LFG Board"
			lfgPrompt.ObjectText = "Mega Dungeon LFG"
			lfgPrompt.MaxActivationDistance = 12
			lfgPrompt.Parent = lfgPad
		end

		if string.find(spec.name, "SpiritChamber") then
			station:SetAttribute("SpiritChamberPad", true)
		end
	end

	WorldBuildBudget:add(budget, #STATIONS * 5)
end

return DeathValleyHellboundTravelBuilder
