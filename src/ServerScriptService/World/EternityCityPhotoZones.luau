--!strict
--[[
	Summer Music Festival Phase 1 — Stage B: Photo Zones ×3
	- Zone 1 (near stage): Ring frame + "Eternity Soundwave" sign, stage-side
	- Zone 2 (canal): Wing frame, canal view
	- Zone 3 (marina): Arch frame, marina waterfront view
	All: PhotoZone=true, platform + spotlight PointLight, near-white=0
]]
local EternityCityPhotoZones = {}

-- ──────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): BasePart
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

local function addBillboard(parent: BasePart, text: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(280, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = text
	label.Parent = gui
end

-- ──────────────────────────────────────────────
-- Zone 1: Near stage — Neon ring frame
-- ──────────────────────────────────────────────

local function buildZone1(parent: Model, palette: any, partsCount: { count: number })
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "PhotoZone1_Stage"
	zoneFolder.Parent = parent

	local origin = parent:GetPivot().Position + Vector3.new(-120, 1.5, 105)

	-- Standing platform
	addPart(
		zoneFolder,
		"PhotoPlatform",
		Vector3.new(8, 0.3, 8),
		CFrame.new(origin),
		palette.Midnight,
		Enum.Material.Slate
	):SetAttribute("PhotoZone", 1)
	partsCount.count += 1

	-- Ring frame (4 arc segments forming a circle)
	local ringR = 4
	local arcSegments = 16
	for i = 0, arcSegments - 1 do
		local a0 = (i / arcSegments) * math.pi * 2
		local a1 = ((i + 1) / arcSegments) * math.pi * 2
		local mid = (a0 + a1) * 0.5
		local arcLen = ringR * (a1 - a0)
		local cx = origin.X + math.cos(mid) * ringR
		local cz = origin.Z + math.sin(mid) * ringR
		addPart(
			zoneFolder,
			"PhotoRing_" .. i,
			Vector3.new(if arcLen < 0.5 then 0.25 else arcLen, 0.35, 0.55),
			CFrame.new(cx, origin.Y + 5, cz) * CFrame.Angles(0, -mid + math.pi * 0.5, 0),
			palette.Cyan,
			Enum.Material.Neon,
			0.08
		)
		partsCount.count += 1
	end

	-- Sign post
	local signPost = addPart(
		zoneFolder,
		"PhotoSign",
		Vector3.new(6, 1.2, 0.4),
		CFrame.new(origin.X, origin.Y + 8, origin.Z - ringR - 1.5),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addBillboard(signPost, "Eternity Soundwave", palette.Cyan)
	partsCount.count += 1

	-- Spotlight PointLight
	local spotlight = Instance.new("PointLight")
	spotlight.Color = palette.Amber
	spotlight.Brightness = 3
	spotlight.Range = 24
	spotlight.Parent = addPart(
		zoneFolder,
		"PhotoSpotlight1",
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(origin.X, origin.Y + 7, origin.Z + ringR + 1),
		palette.Gold,
		Enum.Material.Neon,
		0.02
	)
	partsCount.count += 1
end

-- ──────────────────────────────────────────────
-- Zone 2: Canal area — Wing frame
-- ──────────────────────────────────────────────

local function buildZone2(parent: Model, palette: any, partsCount: { count: number })
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "PhotoZone2_Canal"
	zoneFolder.Parent = parent

	-- Canal midpoint: x≈90, z≈60
	local origin = parent:GetPivot().Position + Vector3.new(90, 1.5, 100)

	-- Standing platform
	addPart(
		zoneFolder,
		"PhotoPlatform",
		Vector3.new(6, 0.3, 6),
		CFrame.new(origin),
		palette.Midnight,
		Enum.Material.Slate
	):SetAttribute("PhotoZone", 2)
	partsCount.count += 1

	-- Left wing (feather-like ribs)
	for i = 0, 4 do
		local yOff = i * 1.8
		local xLen = 5 - i * 0.8
		addPart(
			zoneFolder,
			"PhotoWingL_" .. i,
			Vector3.new(xLen, 0.25, 4),
			CFrame.new(origin.X - 5 + xLen / 2, origin.Y + 3 + yOff, origin.Z),
			palette.Teal,
			Enum.Material.Neon,
			0.1
		)
		partsCount.count += 1
	end
	-- Right wing
	for i = 0, 4 do
		local yOff = i * 1.8
		local xLen = 5 - i * 0.8
		addPart(
			zoneFolder,
			"PhotoWingR_" .. i,
			Vector3.new(xLen, 0.25, 4),
			CFrame.new(origin.X + 5 - xLen / 2, origin.Y + 3 + yOff, origin.Z),
			palette.Teal,
			Enum.Material.Neon,
			0.1
		)
		partsCount.count += 1
	end

	-- Center pillar
	local pillar = addPart(
		zoneFolder,
		"PhotoSign",
		Vector3.new(5, 0.8, 0.4),
		CFrame.new(origin.X, origin.Y + 7.5, origin.Z - 3),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addBillboard(pillar, "Eternity Soundwave", palette.Cyan)
	partsCount.count += 1

	-- Spotlight
	local spotlight = Instance.new("PointLight")
	spotlight.Color = palette.Amber
	spotlight.Brightness = 3
	spotlight.Range = 24
	spotlight.Parent = addPart(
		zoneFolder,
		"PhotoSpotlight2",
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(origin.X, origin.Y + 6, origin.Z + 3),
		palette.Gold,
		Enum.Material.Neon,
		0.02
	)
	partsCount.count += 1
end

-- ──────────────────────────────────────────────
-- Zone 3: Marina area — Arch frame
-- ──────────────────────────────────────────────

local function buildZone3(parent: Model, palette: any, partsCount: { count: number })
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "PhotoZone3_Marina"
	zoneFolder.Parent = parent

	-- Marina viewpoint: south of marina
	local origin = parent:GetPivot().Position + Vector3.new(140, 1.5, -120)

	-- Standing platform
	addPart(
		zoneFolder,
		"PhotoPlatform",
		Vector3.new(8, 0.3, 8),
		CFrame.new(origin),
		palette.Midnight,
		Enum.Material.Slate
	):SetAttribute("PhotoZone", 3)
	partsCount.count += 1

	-- Arch frame (left pillar, right pillar, top arch)
	local archW, archH = 7, 10
	-- Left pillar
	addPart(
		zoneFolder,
		"PhotoArchL",
		Vector3.new(0.6, archH, 0.8),
		CFrame.new(origin.X - archW / 2, origin.Y + archH / 2, origin.Z),
		palette.Steel,
		Enum.Material.SmoothPlastic
	)
	partsCount.count += 1
	-- Right pillar
	addPart(
		zoneFolder,
		"PhotoArchR",
		Vector3.new(0.6, archH, 0.8),
		CFrame.new(origin.X + archW / 2, origin.Y + archH / 2, origin.Z),
		palette.Steel,
		Enum.Material.SmoothPlastic
	)
	partsCount.count += 1

	-- Arch top (segmented semi-circle)
	local archR = archW / 2
	local archSegments = 12
	for i = 0, archSegments - 1 do
		local a0 = (i / archSegments) * math.pi
		local a1 = ((i + 1) / archSegments) * math.pi
		local mid = (a0 + a1) * 0.5
		local arcLen = archR * (a1 - a0)
		local cx = origin.X + math.cos(mid + math.pi) * archR
		local cy = origin.Y + archH + math.sin(mid + math.pi) * archR
		addPart(
			zoneFolder,
			"PhotoArchTop_" .. i,
			Vector3.new(if arcLen < 0.5 then 0.25 else arcLen, 0.35, 0.8),
			CFrame.new(cx, cy, origin.Z) * CFrame.Angles(0, 0, mid + math.pi * 0.5),
			palette.Cyan,
			Enum.Material.Neon,
			0.08
		)
		partsCount.count += 1
	end

	-- Sign
	local signPost = addPart(
		zoneFolder,
		"PhotoSign",
		Vector3.new(6, 1, 0.4),
		CFrame.new(origin.X, origin.Y + archH / 2 + 0.5, origin.Z - 4),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addBillboard(signPost, "Eternity Soundwave", palette.Cyan)
	partsCount.count += 1

	-- Spotlight
	local spotlight = Instance.new("PointLight")
	spotlight.Color = palette.Amber
	spotlight.Brightness = 3
	spotlight.Range = 24
	spotlight.Parent = addPart(
		zoneFolder,
		"PhotoSpotlight3",
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(origin.X, origin.Y + archH / 2 + 2, origin.Z + 4),
		palette.Gold,
		Enum.Material.Neon,
		0.02
	)
	partsCount.count += 1
end

-- ──────────────────────────────────────────────
-- Entry: setup(model)
-- ──────────────────────────────────────────────

function EternityCityPhotoZones.setup(model: Model, palette: any)
	local partsCount = { count = 0 }

	buildZone1(model, palette, partsCount)
	buildZone2(model, palette, partsCount)
	buildZone3(model, palette, partsCount)

	print(string.format("[PhotoZones] 3 photo zones built — %d parts", partsCount.count))
end

return EternityCityPhotoZones