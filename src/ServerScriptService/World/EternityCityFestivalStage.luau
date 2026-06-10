--!strict
--[[
	Summer Music Festival Phase 1 — Stage A: Festival Stage upgrade
	Expands existing EventStage at Twilight Overpass with:
	- Wider stage + LED wall (12+ panels, FestivalLED=true)
	- Speaker truss columns (4+, FestivalSpeaker=true)
	- Laser/spotlight columns with Heartbeat rotation (6+, FestivalLaser=true)
	- Dance floor grid (Neon colored)
]]
local RunService = game:GetService("RunService")

local EternityCityFestivalStage = {}

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

-- ──────────────────────────────────────────────
-- LED Wall (grid of Neon panels behind stage)
-- ──────────────────────────────────────────────

local LED_COLORS = {
	Color3.fromRGB(255, 80, 180),   -- hot pink
	Color3.fromRGB(0, 220, 255),    -- cyan
	Color3.fromRGB(255, 200, 40),   -- gold
	Color3.fromRGB(160, 80, 255),   -- purple
	Color3.fromRGB(40, 255, 160),   -- mint
	Color3.fromRGB(255, 120, 40),   -- orange
}

local function buildLEDWall(parent: Instance, palette: any, stageCenter: Vector3, partsCount: { count: number })
	-- Panel grid: 4 cols × 3 rows = 12 panels minimum
	local wallOrigin = stageCenter + Vector3.new(0, 2.5, -8.5)
	local panelW, panelH = 5.5, 3.5
	local gap = 0.3
	local totalW = panelW * 4 + gap * 3
	local totalH = panelH * 3 + gap * 2

	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "FestivalLEDWall"
	wallFolder.Parent = parent

	for col = 0, 3 do
		for row = 0, 2 do
			local xOff = (col - 1.5) * (panelW + gap)
			local yOff = row * (panelH + gap)
			local panel = addPart(
				wallFolder,
				"FestivalLED_" .. col .. "_" .. row,
				Vector3.new(panelW, panelH, 0.25),
				CFrame.new(wallOrigin + Vector3.new(xOff, yOff, 0)),
				LED_COLORS[(col * 3 + row) % #LED_COLORS + 1],
				Enum.Material.Neon,
				0.08
			)
			panel:SetAttribute("FestivalLED", true)
			partsCount.count += 1
		end
	end

	-- Frame around LED wall
	addPart(
		wallFolder,
		"FestivalLEDFrame",
		Vector3.new(totalW + 1, totalH + 1, 0.35),
		CFrame.new(wallOrigin + Vector3.new(0, totalH / 2 - panelH / 2, -0.06)),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	partsCount.count += 1
end

-- ──────────────────────────────────────────────
-- Speaker truss columns (2 each side = 4)
-- ──────────────────────────────────────────────

local function buildSpeakers(parent: Instance, palette: any, stageCenter: Vector3, partsCount: { count: number })
	for _, xSide in { -14, 14 } do
		for _, zPos in { -6, -3 } do
			local baseX = stageCenter.X + xSide
			local baseZ = stageCenter.Z + zPos
			local baseY = stageCenter.Y + 0.5

			-- Speaker body (dark box)
			local speaker = addPart(
				parent,
				"FestivalSpeaker_" .. tostring(xSide) .. "_" .. tostring(zPos),
				Vector3.new(3.5, 5, 3),
				CFrame.new(baseX, baseY + 3, baseZ),
				Color3.fromRGB(25, 28, 38),
				Enum.Material.SmoothPlastic
			)
			speaker:SetAttribute("FestivalSpeaker", true)
			partsCount.count += 1

			-- Subwoofer ring (Neon highlight)
			addPart(
				parent,
				"SpeakerRing_" .. tostring(xSide) .. "_" .. tostring(zPos),
				Vector3.new(3.7, 0.5, 3.2),
				CFrame.new(baseX, baseY + 1.2, baseZ),
				palette.Cyan,
				Enum.Material.Neon,
				0.05
			)
			partsCount.count += 1

			-- Truss column (steel pillar)
			addPart(
				parent,
				"SpeakerTruss_" .. tostring(xSide) .. "_" .. tostring(zPos),
				Vector3.new(0.8, 8, 0.8),
				CFrame.new(baseX, baseY + 4, baseZ),
				palette.Steel,
				Enum.Material.SmoothPlastic
			)
			partsCount.count += 1

			-- Top truss cross-beam highlights
			if zPos == -4.5 then
				-- Only add crossbeams once per side (not duplicated)
			end
		end
	end

	-- Cross-beam connecting trusses on each side
	for _, xSide in { -14, 14 } do
		addPart(
			parent,
			"TrussCrossBeam_" .. tostring(xSide),
			Vector3.new(0.5, 0.5, 5),
			CFrame.new(stageCenter.X + xSide, stageCenter.Y + 8.5, stageCenter.Z - 4.5),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)
		partsCount.count += 1
	end
end

-- ──────────────────────────────────────────────
-- Laser / spotlight columns (6 around stage)
-- ──────────────────────────────────────────────

local function buildLasers(parent: Instance, palette: any, stageCenter: Vector3, partsCount: { count: number })
	local laserPositions = {
		{ x = -13, z = -9 },  -- back left
		{ x = -7, z = -9 },   -- back center-left
		{ x = 7, z = -9 },    -- back center-right
		{ x = 13, z = -9 },   -- back right
		{ x = -13, z = 9 },   -- front left
		{ x = 13, z = 9 },    -- front right
	}

	for i, pos in laserPositions do
		local lx = stageCenter.X + pos.x
		local lz = stageCenter.Z + pos.z
		local baseY = stageCenter.Y + 0.5

		local laserFolder = Instance.new("Folder")
		laserFolder.Name = "FestivalLaser_" .. i
		laserFolder.Parent = parent

		-- Post (vertical pillar)
		addPart(
			laserFolder,
			"LaserPost",
			Vector3.new(0.6, 10, 0.6),
			CFrame.new(lx, baseY + 5, lz),
			palette.Midnight,
			Enum.Material.SmoothPlastic
		):SetAttribute("FestivalLaser", true)
		partsCount.count += 1

		-- Beam (Neon, tilted up, rotating)
		local beam = addPart(
			laserFolder,
			"LaserBeam",
			Vector3.new(0.25, 12, 0.25),
			CFrame.new(lx, baseY + 6, lz) * CFrame.Angles(math.rad(30), 0, 0),
			LED_COLORS[i % #LED_COLORS + 1],
			Enum.Material.Neon,
			0.1
		)
		beam:SetAttribute("FestivalLaser", true)
		partsCount.count += 1

		-- Spotlight (PointLight) at top of post
		local spotlight = Instance.new("PointLight")
		spotlight.Color = palette.Amber
		spotlight.Brightness = 4
		spotlight.Range = 60
		spotlight.Parent = addPart(
			laserFolder,
			"Spotlight",
			Vector3.new(0.5, 0.5, 0.5),
			CFrame.new(lx, baseY + 10.5, lz),
			palette.Gold,
			Enum.Material.Neon,
			0.02
		)
		partsCount.count += 1

		-- Heartbeat rotation on the beam
		local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			if not beam or not beam.Parent then
				connection:Disconnect()
				return
			end
			local speed = if i % 2 == 0 then 0.4 else -0.35
			beam.CFrame = beam.CFrame * CFrame.Angles(0, speed * deltaTime, 0)
		end)
	end
end

-- ──────────────────────────────────────────────
-- Dance floor (Neon grid in front of stage)
-- ──────────────────────────────────────────────

local function buildDanceFloor(parent: Instance, palette: any, stageCenter: Vector3, partsCount: { count: number })
	local floorOrigin = stageCenter + Vector3.new(0, 0, 12)
	local floorW, floorD = 30, 20
	local tileSize = 4
	local cols, rows = math.floor(floorW / tileSize), math.floor(floorD / tileSize)

	local danceFolder = Instance.new("Folder")
	danceFolder.Name = "FestivalDanceFloor"
	danceFolder.Parent = parent

	for col = 0, cols - 1 do
		for row = 0, rows - 1 do
			local tx = floorOrigin.X + (col - (cols - 1) / 2) * tileSize
			local tz = floorOrigin.Z + (row - (rows - 1) / 2) * tileSize
			local colorIdx = (col + row) % #LED_COLORS + 1
			local tile = addPart(
				danceFolder,
				"DanceTile_" .. col .. "_" .. row,
				Vector3.new(tileSize - 0.15, 0.15, tileSize - 0.15),
				CFrame.new(tx, stageCenter.Y + 1, tz),
				LED_COLORS[colorIdx],
				Enum.Material.Neon,
				0.35
			)
			partsCount.count += 1
		end
	end

	-- Border frame
	addPart(
		danceFolder,
		"DanceFloorFrame",
		Vector3.new(floorW + 0.5, 0.15, 0.4),
		CFrame.new(floorOrigin.X, stageCenter.Y + 1, floorOrigin.Z - floorD / 2),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addPart(
		danceFolder,
		"DanceFloorFrameFar",
		Vector3.new(floorW + 0.5, 0.15, 0.4),
		CFrame.new(floorOrigin.X, stageCenter.Y + 1, floorOrigin.Z + floorD / 2),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	partsCount.count += 2
end

-- ──────────────────────────────────────────────
-- Entry: setup(model)
-- ──────────────────────────────────────────────

function EternityCityFestivalStage.setup(model: Model, palette: any)
	local stageFolder = model:FindFirstChild("TwilightOverpass", true)
	if not stageFolder then
		warn("[FestivalStage] TwilightOverpass folder not found")
		return
	end

	-- Find existing EventStage at (-82, 1.2, 80) area
	local eventStage: BasePart? = nil
	for _, child in stageFolder:GetDescendants() do
		if child:IsA("BasePart") and child:GetAttribute("EventStage") == true then
			eventStage = child
			break
		end
	end
	if not eventStage then
		warn("[FestivalStage] EventStagePlatform not found")
		return
	end

	local stageCenter = eventStage.Position + Vector3.new(0, -0.4, 0) -- deck surface center
	local partsCount = { count = 0 }

	-- Expand stage: wider + thicker
	eventStage.Size = Vector3.new(32, 1, 20) -- wider and deeper
	partsCount.count += 1  -- modified, not new

	-- Festival elements
	buildLEDWall(stageFolder, palette, stageCenter, partsCount)
	buildSpeakers(stageFolder, palette, stageCenter, partsCount)
	buildLasers(stageFolder, palette, stageCenter, partsCount)
	buildDanceFloor(stageFolder, palette, stageCenter, partsCount)

	print(string.format("[FestivalStage] Upgrade complete — %d festival parts added", partsCount.count))
end

return EternityCityFestivalStage