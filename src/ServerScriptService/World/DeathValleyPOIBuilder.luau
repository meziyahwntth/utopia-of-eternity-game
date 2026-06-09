--!strict
--[[
	Phase B — POIs, Horizon Ring gates, Hellbound path stub, checkpoint terminal.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleyPOIBuilder = {}

local function addRingSign(part: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RingSign"
	gui.Size = UDim2.fromOffset(200, 48)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 179, 71)
	label.Text = text
	label.Parent = gui
end

function DeathValleyPOIBuilder:BuildPOIs(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "PhaseB_POI"
	folder.Parent = parent

	for _, poi in PrismDeathValleySurvivalConfig.POIs do
		local anchor = Instance.new("Part")
		anchor.Name = poi.displayName:gsub(" ", "")
		anchor.Size = Vector3.new(14, 1, 14)
		anchor.Anchored = true
		anchor.CanCollide = true
		anchor.CFrame = CFrame.new(poi.position)
		anchor.Color = if poi.optInScare then Color3.fromRGB(40, 80, 120) else Color3.fromRGB(60, 100, 70)
		anchor.Material = Enum.Material.Grass
		anchor.Parent = folder
		anchor:SetAttribute("PoiId", poi.id)
		anchor:SetAttribute("MinRing", poi.ring)
		if poi.optInScare then
			anchor:SetAttribute("OptInScare", true)
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = if poi.optInScare then "Peer into Hollow" else "Listen"
		prompt.ObjectText = poi.displayName
		prompt.MaxActivationDistance = 12
		prompt.Parent = anchor

		if poi.id == "whispering_grove" then
			for i = 1, 5 do
				local tree = Instance.new("Part")
				tree.Name = "WhisperTree"
				tree.Size = Vector3.new(2, 10 + i, 2)
				tree.Anchored = true
				tree.Color = Color3.fromRGB(35, 55, 40)
				tree.Material = Enum.Material.Wood
				tree.CFrame = CFrame.new(poi.position + Vector3.new((i - 3) * 4, 5, (i % 2) * 3))
				tree.Parent = folder
			end
		elseif poi.id == "hollow_lake" then
			local water = Instance.new("Part")
			water.Name = "HollowWater"
			water.Size = Vector3.new(24, 0.5, 24)
			water.Anchored = true
			water.CanCollide = false
			water.Color = Color3.fromRGB(20, 40, 80)
			water.Material = Enum.Material.Glass
			water.Transparency = 0.35
			water.CFrame = CFrame.new(poi.position + Vector3.new(0, -0.5, 0))
			water.Parent = folder
		elseif poi.id == "seasonal_echo_shrine" then
			anchor:SetAttribute("SeasonalShrine", true)
			prompt.ActionText = "Claim Seasonal Echo"
			local obelisk = Instance.new("Part")
			obelisk.Name = "SeasonalObelisk"
			obelisk.Size = Vector3.new(3, 14, 3)
			obelisk.Anchored = true
			obelisk.Color = Color3.fromRGB(255, 179, 71)
			obelisk.Material = Enum.Material.Neon
			obelisk.Transparency = 0.2
			obelisk.CFrame = CFrame.new(poi.position + Vector3.new(0, 7, 0))
			obelisk.Parent = folder
		end
	end

	WorldBuildBudget:add(budget, #PrismDeathValleySurvivalConfig.POIs + 6)
end

function DeathValleyPOIBuilder:BuildHorizonRings(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "HorizonRings"
	folder.Parent = parent

	local gateSpecs = {
		{ ring = 1, angle = math.rad(45), radius = 72, label = "POI Frontier · 5 nights" },
		{ ring = 2, angle = math.rad(135), radius = 105, label = "Deep Wilds · 15 nights" },
		{ ring = 3, angle = math.rad(225), radius = 138, label = "Mega Gate · 20 nights" },
		{ ring = 4, angle = math.rad(315), radius = 168, label = "Seasonal Echo · 30 nights" },
	}

	for _, spec in gateSpecs do
		local pos = Vector3.new(math.cos(spec.angle) * spec.radius, 4, math.sin(spec.angle) * spec.radius)
		local gate = Instance.new("Part")
		gate.Name = "HorizonRingGate_" .. spec.ring
		gate.Size = Vector3.new(2, 10, 40)
		gate.Anchored = true
		gate.CanCollide = true
		gate.CFrame = CFrame.new(pos) * CFrame.Angles(0, -spec.angle, 0)
		gate.Color = profile.Palette.Amber
		gate.Material = Enum.Material.Neon
		gate.Transparency = 0.35
		gate.Parent = folder
		gate:SetAttribute("HorizonRingGate", true)
		gate:SetAttribute("MinRing", spec.ring)
		addRingSign(gate, spec.label)
	end

	WorldBuildBudget:add(budget, #gateSpecs)
end

function DeathValleyPOIBuilder:BuildHellboundPathStub(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "HellboundPathStub"
	folder.Parent = parent

	local peak = parent:FindFirstChild("HellboundZones") and parent.HellboundZones:FindFirstChild("PeakColony")
	local startPos = if peak and peak:IsA("BasePart") then peak.Position else Vector3.new(-80, 2, 80)
	local endPos = Vector3.new(0, 2, 40)
	local segments = 8
	for i = 0, segments do
		local t = i / segments
		local pos = startPos:Lerp(endPos, t)
		local slab = Instance.new("Part")
		slab.Name = "PathSegment"
		slab.Size = Vector3.new(6, 0.5, 6)
		slab.Anchored = true
		slab.Color = Color3.fromRGB(55, 45, 65)
		slab.Material = Enum.Material.Slate
		slab.CFrame = CFrame.new(pos)
		slab.Parent = folder
	end

	local sign = Instance.new("Part")
	sign.Name = "HellboundPathSign"
	sign.Size = Vector3.new(4, 6, 1)
	sign.Anchored = true
	sign.CFrame = CFrame.new(startPos + Vector3.new(0, 4, 0))
	sign.Color = profile.Palette.Amber
	sign.Material = Enum.Material.Neon
	sign.Parent = folder
	addRingSign(sign, "Hellbound Arrival · Preview Path")

	local checkpoint = Instance.new("Part")
	checkpoint.Name = "CheckpointTerminal"
	checkpoint.Size = Vector3.new(5, 7, 3)
	checkpoint.Anchored = true
	checkpoint.CFrame = CFrame.new(12, 3.5, -12)
	checkpoint.Color = Color3.fromRGB(120, 200, 255)
	checkpoint.Material = Enum.Material.SmoothPlastic
	checkpoint.Parent = folder
	checkpoint:SetAttribute("CheckpointTerminal", true)
	addRingSign(checkpoint, "Checkpoint · Beacon Lv3")

	WorldBuildBudget:add(budget, segments + 3)
end

return DeathValleyPOIBuilder
