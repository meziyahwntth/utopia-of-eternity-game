--!strict
--[[
	Eternity City — Fashion Show stage (Dress to Impress style).
	Runway + showcase podiums + spotlights + audience seating.
	Placed south-west of TwilightOverpass festival zone (no overlap with EventStage).
]]
local EternityCityFashionStage = {}

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

local function buildRunway(parent: Folder, palette: any, center: Vector3)
	addPart(
		parent,
		"FashionRunway",
		Vector3.new(8, 0.35, 42),
		CFrame.new(center + Vector3.new(0, 0.2, 0)),
		palette.Pearl,
		Enum.Material.Marble
	)
	for _, zOff in { -20, -10, 0, 10, 20 } do
		addPart(
			parent,
			"RunwayLane_" .. zOff,
			Vector3.new(7.2, 0.12, 0.8),
			CFrame.new(center + Vector3.new(0, 0.45, zOff)),
			palette.Teal,
			Enum.Material.Neon,
			0.08
		)
	end
end

local function buildPodiums(parent: Folder, palette: any, center: Vector3)
	for i, xOff in { -1, 1 } do
		local podium = addPart(
			parent,
			"ShowcasePodium_" .. i,
			Vector3.new(5, 1.2, 5),
			CFrame.new(center + Vector3.new(xOff * 14, 0.8, 18)),
			palette.Pearl,
			Enum.Material.Marble
		)
		podium:SetAttribute("FashionPodium", true)
		addPart(
			parent,
			"PodiumTrim_" .. i,
			Vector3.new(5.4, 0.2, 5.4),
			CFrame.new(center + Vector3.new(xOff * 14, 1.5, 18)),
			palette.Gold,
			Enum.Material.Metal,
			0.05
		)
	end
end

local function buildSpotlights(parent: Folder, palette: any, center: Vector3)
	for i = 1, 4 do
		local xOff = (i - 2.5) * 10
		local truss = addPart(
			parent,
			"SpotTruss_" .. i,
			Vector3.new(1.2, 14, 1.2),
			CFrame.new(center + Vector3.new(xOff, 7.5, -6)),
			palette.Steel,
			Enum.Material.Metal
		)
		local lamp = addPart(
			parent,
			"SpotLamp_" .. i,
			Vector3.new(2.5, 1, 2.5),
			CFrame.new(center + Vector3.new(xOff, 14.5, -6)),
			palette.Cyan,
			Enum.Material.Neon,
			0.1
		)
		lamp:SetAttribute("FashionSpotlight", true)
		local light = Instance.new("SpotLight")
		light.Name = "FashionSpot"
		light.Color = palette.Amber
		light.Brightness = 3
		light.Range = 45
		light.Angle = 35
		light.Face = Enum.NormalId.Bottom
		light.Parent = lamp

		local point = Instance.new("PointLight")
		point.Color = palette.Cyan
		point.Brightness = 1.2
		point.Range = 18
		point.Parent = truss
	end
end

local function buildAudience(parent: Folder, palette: any, center: Vector3)
	for row = 1, 3 do
		for col = 1, 6 do
			local x = (col - 3.5) * 5
			local z = 28 + row * 5
			addPart(
				parent,
				string.format("AudienceBench_R%d_C%d", row, col),
				Vector3.new(4, 1.2, 2),
				CFrame.new(center + Vector3.new(x, 0.6 + row * 0.4, z)),
				palette.Steel,
				Enum.Material.SmoothPlastic
			)
		end
	end
	addPart(
		parent,
		"AudienceDeck",
		Vector3.new(34, 0.3, 14),
		CFrame.new(center + Vector3.new(0, 0.15, 38)),
		palette.Slate,
		Enum.Material.Slate
	)
end

local function buildSign(parent: Folder, palette: any, center: Vector3)
	local sign = addPart(
		parent,
		"FashionStageSign",
		Vector3.new(18, 4, 1),
		CFrame.new(center + Vector3.new(0, 10, -14)),
		palette.Gold,
		Enum.Material.Neon,
		0.08
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Eternity Fashion Show"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
end

function EternityCityFashionStage.setup(model: Model, palette: any, center: Vector3?)
	local stageCenter = center or Vector3.new(-130, 1.2, 115)

	local stage = Instance.new("Folder")
	stage.Name = "UtopiaFashionStage"
	stage.Parent = model

	local root = addPart(
		stage,
		"FashionStageRoot",
		Vector3.new(36, 0.5, 52),
		CFrame.new(stageCenter),
		palette.Midnight,
		Enum.Material.SmoothPlastic,
		0.15
	)
	root:SetAttribute("FashionStage", true)
	root:SetAttribute("FashionState", "Idle")
	root:SetAttribute("FashionRound", 0)

	buildRunway(stage, palette, stageCenter)
	buildPodiums(stage, palette, stageCenter)
	buildSpotlights(stage, palette, stageCenter)
	buildAudience(stage, palette, stageCenter)
	buildSign(stage, palette, stageCenter)

	workspace:SetAttribute("FashionState", "Idle")
	workspace:SetAttribute("FashionRound", 0)

	print("[FashionStage] Built near TwilightOverpass — runway + seating + spotlights")
end

return EternityCityFashionStage
