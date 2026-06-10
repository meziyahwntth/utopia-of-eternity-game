--!strict
--[[
	Phase B — POIs, Horizon Ring gates, Hellbound path stub, checkpoint terminal.
	Art pass: Whispering Grove (haunted trees + spirit whisps) + Hollow Lake (water + jumpscare).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))

local DeathValleyPOIBuilder = {}

-- ──────────────────────────────────────────────
-- Helpers — must precede all callers
-- ──────────────────────────────────────────────

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLabel(part: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
end

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

-- Simple deterministic random using a fixed seed
local function seededRandom(seed: number, i: number): number
	local s = (seed * 1103515245 + 12345) % 2147483648
	local r = (s + i * 1664525 + 1013904223) % 2147483648
	return (r % 10000) / 10000
end

-- ──────────────────────────────────────────────
-- Whispering Grove — haunted tree forest
-- ──────────────────────────────────────────────

local WHISPER_SEED = 20260610
local TREE_COUNT = 10
local TREE_SPREAD = 14

local function buildWhisperingGrove(folder: Instance, center: Vector3, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local partCount = 0

	-- Grove ground marker
	addPart(
		folder,
		"GroveGround",
		Vector3.new(32, 0.5, 28),
		CFrame.new(center + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(35, 30, 40),
		Enum.Material.Slate
	)
	partCount += 1

	-- Haunted trees: ≥8, with twisted cylinders, 2-3 branches, dark canopy
	for i = 1, TREE_COUNT do
		local theta = seededRandom(WHISPER_SEED + i, 1) * math.pi * 2
		local radius = 3 + seededRandom(WHISPER_SEED + i, 2) * TREE_SPREAD
		local x = math.cos(theta) * radius
		local z = math.sin(theta) * radius
		local treeBase = center + Vector3.new(x, 0, z)

		-- Trunk height varies per tree
		local trunkHeight = 9 + seededRandom(WHISPER_SEED + i, 3) * 6
		local trunkRadius = 1 + seededRandom(WHISPER_SEED + i, 4) * 0.8

		-- Trunk — slight random lean via CFrame rotation
		local leanAngleX = (seededRandom(WHISPER_SEED + i, 5) - 0.5) * 0.15
		local leanAngleZ = (seededRandom(WHISPER_SEED + i, 6) - 0.5) * 0.15
		local trunkCF = CFrame.new(treeBase + Vector3.new(0, trunkHeight / 2, 0))
			* CFrame.Angles(leanAngleX, 0, leanAngleZ)

		addPart(
			folder,
			"WhisperTrunk_" .. i,
			Vector3.new(trunkRadius * 2, trunkHeight, trunkRadius * 2),
			trunkCF,
			Color3.fromRGB(40, 35, 50),
			Enum.Material.Wood
		)
		partCount += 1

		-- Branches: 2-3 per tree
		local branchCount = 2 + math.floor(seededRandom(WHISPER_SEED + i, 7) * 2)
		for b = 1, branchCount do
			local branchY = trunkHeight * (0.4 + seededRandom(WHISPER_SEED + i, 8 + b) * 0.5)
			local branchAngle = seededRandom(WHISPER_SEED + i, 10 + b) * math.pi * 2
			local branchLen = 3 + seededRandom(WHISPER_SEED + i, 13 + b) * 4
			local branchTilt = (seededRandom(WHISPER_SEED + i, 16 + b) - 0.3) * 0.7

			local branchStart = treeBase + Vector3.new(0, branchY, 0)
			local branchDir = Vector3.new(math.cos(branchAngle), 0, math.sin(branchAngle))
			local branchMid = branchStart + branchDir * (branchLen / 2) + Vector3.new(0, 2, 0)

			local branchCF = CFrame.new(branchMid)
				* CFrame.Angles(branchTilt, branchAngle, 0)

			addPart(
				folder,
				"WhisperBranch_" .. i .. "_" .. b,
				Vector3.new(0.7, 0.7, branchLen),
				branchCF,
				Color3.fromRGB(50, 35, 55),
				Enum.Material.Wood
			)
			partCount += 1

			-- Canopy cluster at branch tip
			local canopyTip = branchStart + branchDir * branchLen + Vector3.new(0, 2, 0)
			for c = 1, 2 do
				local canopyOffX = (seededRandom(WHISPER_SEED + i, 20 + b * 3 + c) - 0.5) * 3
				local canopyOffZ = (seededRandom(WHISPER_SEED + i, 30 + b * 3 + c) - 0.5) * 3
				local canopyOffY = seededRandom(WHISPER_SEED + i, 40 + b * 3 + c) * 2

				addPart(
					folder,
					"WhisperCanopy_" .. i .. "_" .. b .. "_" .. c,
					Vector3.new(2.5, 2, 2.5),
					CFrame.new(canopyTip + Vector3.new(canopyOffX, canopyOffY, canopyOffZ)),
					Color3.fromRGB(45, 40, 60),
					Enum.Material.LeafyGrass
				)
				partCount += 1
			end
		end
	end

	-- Spirit whisps: Neon floaters with GroveWhisper=true
	for w = 1, 5 do
		local wTheta = seededRandom(WHISPER_SEED, 50 + w) * math.pi * 2
		local wRadius = 2 + seededRandom(WHISPER_SEED, 55 + w) * 12
		local wx = math.cos(wTheta) * wRadius
		local wz = math.sin(wTheta) * wRadius
		local wy = 3 + seededRandom(WHISPER_SEED, 60 + w) * 5

		local whisp = addPart(
			folder,
			"GroveWhisper_" .. w,
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(center + Vector3.new(wx, wy, wz)),
			Color3.fromRGB(160, 100, 220),
			Enum.Material.Neon,
			0.55
		)
		whisp:SetAttribute("GroveWhisper", true)
		partCount += 1
	end

	-- Path markers — stone slabs leading into grove
	for p = 0, 3 do
		local pathX = center.X - 18 + p * 8
		local pathZ = center.Z - 2 + (p % 2) * 3
		addPart(
			folder,
			"GrovePathStone_" .. p,
			Vector3.new(3, 0.6, 2),
			CFrame.new(pathX, 0.8, pathZ),
			Color3.fromRGB(70, 65, 80),
			Enum.Material.Slate
		)
		partCount += 1
	end

	-- Grove sign
	local sign = addPart(
		folder,
		"WhisperingGroveSign",
		Vector3.new(8, 4, 1),
		CFrame.new(center + Vector3.new(-18, 3, 0)),
		Color3.fromRGB(255, 179, 71),
		Enum.Material.Neon,
		0.15
	)
	sign:SetAttribute("GroveSign", true)
	addLabel(sign, "Whispering Grove")
	partCount += 1

	WorldBuildBudget:add(budget, partCount)
	return partCount
end

-- ──────────────────────────────────────────────
-- Hollow Lake — water body + jumpscare triggers + shadows
-- ──────────────────────────────────────────────

local LAKE_RADIUS = 18
local LAKE_SEED = 20260611

local function buildHollowLake(folder: Instance, center: Vector3, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local partCount = 0

	-- Water surface — dark glass, moderate transparency
	local water = addPart(
		folder,
		"HollowWater",
		Vector3.new(LAKE_RADIUS * 2, 0.4, LAKE_RADIUS * 2),
		CFrame.new(center + Vector3.new(0, -0.2, 0)),
		Color3.fromRGB(15, 25, 55),
		Enum.Material.Glass,
		0.55
	)
	water.CanCollide = false
	partCount += 1

	-- Rocky border — 24 stone slabs around rim
	for r = 0, 23 do
		local angle = r * (math.pi * 2 / 24)
		local rimX = math.cos(angle) * (LAKE_RADIUS + 1.2)
		local rimZ = math.sin(angle) * (LAKE_RADIUS + 1.2)
		local rockSize = 2.5 + seededRandom(LAKE_SEED, r) * 2

		addPart(
			folder,
			"HollowLakeRim_" .. r,
			Vector3.new(rockSize, 1.2, rockSize),
			CFrame.new(center + Vector3.new(rimX, 0.6, rimZ)),
			Color3.fromRGB(55 + r % 3 * 10, 50 + r % 4 * 8, 65 + r % 5 * 5),
			Enum.Material.Slate
		)
		partCount += 1
	end

	-- Rotting wooden dock on the west shore
	local dockOrigin = center + Vector3.new(-LAKE_RADIUS - 4, 0.2, 0)
	-- Dock posts
	for dp = -1, 1, 2 do
		addPart(
			folder,
			"HollowDockPost_" .. (dp > 0 and "N" or "S"),
			Vector3.new(0.8, 5, 0.8),
			CFrame.new(dockOrigin + Vector3.new(0, 2.5, dp * 4)),
			Color3.fromRGB(90, 75, 60),
			Enum.Material.WoodPlanks
		)
		partCount += 1
	end
	-- Dock planks
	for dp = 0, 4 do
		addPart(
			folder,
			"HollowDockPlank_" .. dp,
			Vector3.new(4, 0.3, 1.2),
			CFrame.new(dockOrigin + Vector3.new(0, 0.6, dp - 2) * 2),
			Color3.fromRGB(95, 80, 65),
			Enum.Material.WoodPlanks
		)
		partCount += 1
	end

	-- Jumpscare triggers: 2 transparent zones along the shore
	local triggerPositions = {
		center + Vector3.new(12, 0.5, 8),
		center + Vector3.new(-14, 0.5, -10),
	}
	for t, tpos in triggerPositions do
		local trig = addPart(
			folder,
			"LakeScareTrigger_" .. t,
			Vector3.new(10, 4, 10),
			CFrame.new(tpos),
			Color3.fromRGB(255, 0, 0),
			Enum.Material.SmoothPlastic,
			1.0
		)
		trig.CanCollide = false
		trig:SetAttribute("ScareTrigger", true)
		trig:SetAttribute("SourcePOI", "hollow_lake")
		partCount += 1
	end

	-- Underwater shadows: dark, vague shapes beneath the surface
	local shadowDefs = {
		{ pos = center + Vector3.new(4, -3, -2), size = Vector3.new(8, 2, 5) },
		{ pos = center + Vector3.new(-5, -4, 5), size = Vector3.new(6, 2.5, 10) },
	}
	for s, sd in shadowDefs do
		local shadow = addPart(
			folder,
			"LakeShadow_" .. s,
			sd.size,
			CFrame.new(sd.pos),
			Color3.fromRGB(8, 8, 15),
			Enum.Material.SmoothPlastic,
			0.7
		)
		shadow.CanCollide = false
		shadow:SetAttribute("LakeShadow", true)
		partCount += 1
	end

	-- Hollow Lake sign
	local lakeSign = addPart(
		folder,
		"HollowLakeSign",
		Vector3.new(8, 4, 1),
		CFrame.new(center + Vector3.new(LAKE_RADIUS + 8, 3, 0)),
		Color3.fromRGB(255, 179, 71),
		Enum.Material.Neon,
		0.15
	)
	lakeSign:SetAttribute("LakeSign", true)
	addLabel(lakeSign, "Hollow Lake")
	partCount += 1

	WorldBuildBudget:add(budget, partCount)
	return partCount
end

-- ──────────────────────────────────────────────
-- Public: BuildPOIs — art pass for all POIs
-- ──────────────────────────────────────────────

function DeathValleyPOIBuilder:BuildPOIs(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "PhaseB_POI"
	folder.Parent = parent

	for _, poi in PrismDeathValleySurvivalConfig.POIs do
		if poi.id == "whispering_grove" then
			buildWhisperingGrove(folder, poi.position, budget)
		elseif poi.id == "hollow_lake" then
			buildHollowLake(folder, poi.position, budget)
		elseif poi.id == "seasonal_echo_shrine" then
			local anchor = Instance.new("Part")
			anchor.Name = poi.displayName:gsub(" ", "")
			anchor.Size = Vector3.new(14, 1, 14)
			anchor.Anchored = true
			anchor.CanCollide = true
			anchor.CFrame = CFrame.new(poi.position)
			anchor.Color = Color3.fromRGB(60, 100, 70)
			anchor.Material = Enum.Material.Grass
			anchor.Parent = folder
			anchor:SetAttribute("PoiId", poi.id)
			anchor:SetAttribute("MinRing", poi.ring)
			anchor:SetAttribute("SeasonalShrine", true)

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Claim Seasonal Echo"
			prompt.ObjectText = poi.displayName
			prompt.MaxActivationDistance = 12
			prompt.Parent = anchor

			local obelisk = Instance.new("Part")
			obelisk.Name = "SeasonalObelisk"
			obelisk.Size = Vector3.new(3, 14, 3)
			obelisk.Anchored = true
			obelisk.Color = Color3.fromRGB(255, 179, 71)
			obelisk.Material = Enum.Material.Neon
			obelisk.Transparency = 0.2
			obelisk.CFrame = CFrame.new(poi.position + Vector3.new(0, 7, 0))
			obelisk.Parent = folder

			WorldBuildBudget:add(budget, 3)
		end
	end
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