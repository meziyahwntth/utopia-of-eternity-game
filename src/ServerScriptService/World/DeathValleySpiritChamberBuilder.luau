--!strict
--[[
	Death Valley Spirit Chamber Builder — 3 sequential underground combat chambers
	Phase D/E · Spirit Lock Tunnel · Entry → Mid → Final Lock
	Docs: docs/death-valley/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md §6
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local DeathValleySpiritChamberBuilder = {}

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

-- Chamber definitions — progressively larger
-- Positions aligned with travel pipeline stations (spaced ~15-20 studs apart)
local CHAMBERS = {
	{
		index = 1,
		name = "SpiritChamber_1",
		center = Vector3.new(-20, 0, -5),
		halfW = 15,
		halfD = 14,
		height = 14,
		darkColor = Color3.fromRGB(28, 20, 38), -- Twilight Basalt
		spiritColor = Color3.fromRGB(0, 229, 255), -- Cyan
		accentColor = Color3.fromRGB(255, 179, 71), -- Amber
		spiritSpawns = 4,
	},
	{
		index = 2,
		name = "SpiritChamber_2",
		center = Vector3.new(0, 0, -20),
		halfW = 20,
		halfD = 16,
		height = 16,
		darkColor = Color3.fromRGB(24, 16, 34),
		spiritColor = Color3.fromRGB(0, 229, 255),
		accentColor = Color3.fromRGB(255, 179, 71),
		spiritSpawns = 5,
	},
	{
		index = 3,
		name = "SpiritChamber_3",
		center = Vector3.new(15, 0, -30),
		halfW = 25,
		halfD = 18,
		height = 20,
		darkColor = Color3.fromRGB(20, 12, 30),
		spiritColor = Color3.fromRGB(0, 229, 255),
		accentColor = Color3.fromRGB(255, 179, 71),
		spiritSpawns = 6,
	},
}

local DOOR_WIDTH = 6
local DOOR_HEIGHT = 8
local WALL_THICKNESS = 1.5

local function buildChamberFloor(parent: Instance, ch: typeof(CHAMBERS[1]))
	local halfW = ch.halfW
	local halfD = ch.halfD
	local c = ch.center

	-- Main floor slab
	addPart(
		parent,
		"Floor",
		Vector3.new(halfW * 2 + WALL_THICKNESS * 2, 1, halfD * 2 + WALL_THICKNESS * 2),
		CFrame.new(c + Vector3.new(0, -0.5, 0)),
		ch.darkColor,
		Enum.Material.Slate
	)

	-- Floor grid lines (Neon spirit tracks)
	for _, xLine in { halfW * -0.4, halfW * 0.4 } do
		addPart(
			parent,
			"FloorGridX_" .. tostring(xLine),
			Vector3.new(0.3, 0.3, halfD * 2 - 2),
			CFrame.new(c + Vector3.new(xLine, 0.05, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.4
		)
	end
end

local function buildChamberWalls(parent: Instance, ch: typeof(CHAMBERS[1]))
	local halfW = ch.halfW
	local halfD = ch.halfD
	local h = ch.height
	local c = ch.center
	local wallY = h / 2

	-- 4 walls (north, south, west, east)
	local wallSpecs = {
		{ name = "WallN", pos = Vector3.new(0, wallY, halfD + WALL_THICKNESS / 2), size = Vector3.new(halfW * 2 + WALL_THICKNESS * 2, h, WALL_THICKNESS) },
		{ name = "WallS", pos = Vector3.new(0, wallY, -(halfD + WALL_THICKNESS / 2)), size = Vector3.new(halfW * 2 + WALL_THICKNESS * 2, h, WALL_THICKNESS) },
		{ name = "WallW", pos = Vector3.new(-(halfW + WALL_THICKNESS / 2), wallY, 0), size = Vector3.new(WALL_THICKNESS, h, halfD * 2 + WALL_THICKNESS * 2) },
		{ name = "WallE", pos = Vector3.new(halfW + WALL_THICKNESS / 2, wallY, 0), size = Vector3.new(WALL_THICKNESS, h, halfD * 2 + WALL_THICKNESS * 2) },
	}

	for _, w in wallSpecs do
		addPart(
			parent,
			w.name,
			w.size,
			CFrame.new(c + w.pos),
			ch.darkColor,
			Enum.Material.Slate
		)
	end

	-- Ceiling
	addPart(
		parent,
		"Ceiling",
		Vector3.new(halfW * 2 + WALL_THICKNESS * 2, 0.6, halfD * 2 + WALL_THICKNESS * 2),
		CFrame.new(c + Vector3.new(0, h + 0.3, 0)),
		ch.darkColor,
		Enum.Material.Slate
	)
end

local function buildChamberDoors(parent: Instance, ch: typeof(CHAMBERS[1]))
	local c = ch.center
	local halfD = ch.halfD
	local wallY = ch.height / 2

	-- Entry door (z positive side — coming from Military Base)
	local entryDoor = addPart(
		parent,
		"EntryDoor",
		Vector3.new(DOOR_WIDTH, DOOR_HEIGHT, 0.4),
		CFrame.new(c + Vector3.new(0, wallY, halfD + WALL_THICKNESS)),
		ch.accentColor,
		Enum.Material.Metal,
		0
	)
	entryDoor:SetAttribute("ChamberGate", true)
	entryDoor:SetAttribute("GateDirection", "Entry")

	-- Exit door (z negative side — going to Death Valley)
	local exitDoor = addPart(
		parent,
		"ExitDoor",
		Vector3.new(DOOR_WIDTH, DOOR_HEIGHT, 0.4),
		CFrame.new(c + Vector3.new(0, wallY, -(halfD + WALL_THICKNESS))),
		ch.accentColor,
		Enum.Material.Metal,
		0
	)
	exitDoor:SetAttribute("ChamberGate", true)
	exitDoor:SetAttribute("GateDirection", "Exit")

	-- Door frame neon outlines
	for _, doorPos in { Vector3.new(0, wallY, halfD + WALL_THICKNESS), Vector3.new(0, wallY, -(halfD + WALL_THICKNESS)) } do
		-- Frame top
		addPart(
			parent,
			"DoorFrameTop_" .. tostring(doorPos.Z),
			Vector3.new(DOOR_WIDTH + 1, 0.3, 0.5),
			CFrame.new(c + doorPos + Vector3.new(0, DOOR_HEIGHT / 2 + 0.5, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.1
		)
		-- Frame left
		addPart(
			parent,
			"DoorFrameLeft_" .. tostring(doorPos.Z),
			Vector3.new(0.3, DOOR_HEIGHT, 0.5),
			CFrame.new(c + doorPos + Vector3.new(-DOOR_WIDTH / 2 - 0.5, 0, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.1
		)
		-- Frame right
		addPart(
			parent,
			"DoorFrameRight_" .. tostring(doorPos.Z),
			Vector3.new(0.3, DOOR_HEIGHT, 0.5),
			CFrame.new(c + doorPos + Vector3.new(DOOR_WIDTH / 2 + 0.5, 0, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.1
		)
	end
end

local function buildSpiritSpawns(parent: Instance, ch: typeof(CHAMBERS[1]))
	local halfW = ch.halfW
	local halfD = ch.halfD
	local c = ch.center
	local count = ch.spiritSpawns

	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + math.pi * 0.25
		local radius = math.min(halfW, halfD) * 0.5
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local spawnMarker = addPart(
			parent,
			"SpiritSpawn_" .. i,
			Vector3.new(2, 0.4, 2),
			CFrame.new(c + Vector3.new(x, 0.3, z)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.35
		)
		spawnMarker:SetAttribute("SpiritSpawn", true)
	end
end

local function buildSpiritLines(parent: Instance, ch: typeof(CHAMBERS[1]))
	local halfW = ch.halfW
	local halfD = ch.halfD
	local c = ch.center

	-- Horizontal neon strips along walls at 3 heights
	for _, yOff in { 2, ch.height * 0.5, ch.height - 2 } do
		-- North wall
		addPart(
			parent,
			"SpiritLine_N_" .. tostring(yOff),
			Vector3.new(halfW * 2 - 2, 0.2, 0.2),
			CFrame.new(c + Vector3.new(0, yOff, halfD + WALL_THICKNESS - 0.1)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.2
		)
		-- South wall
		addPart(
			parent,
			"SpiritLine_S_" .. tostring(yOff),
			Vector3.new(halfW * 2 - 2, 0.2, 0.2),
			CFrame.new(c + Vector3.new(0, yOff, -(halfD + WALL_THICKNESS - 0.1))),
			ch.spiritColor,
			Enum.Material.Neon,
			0.2
		)
		-- West wall
		addPart(
			parent,
			"SpiritLine_W_" .. tostring(yOff),
			Vector3.new(0.2, 0.2, halfD * 2 - 2),
			CFrame.new(c + Vector3.new(-(halfW + WALL_THICKNESS - 0.1), yOff, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.2
		)
		-- East wall
		addPart(
			parent,
			"SpiritLine_E_" .. tostring(yOff),
			Vector3.new(0.2, 0.2, halfD * 2 - 2),
			CFrame.new(c + Vector3.new(halfW + WALL_THICKNESS - 0.1, yOff, 0)),
			ch.spiritColor,
			Enum.Material.Neon,
			0.2
		)
	end

	-- Vertical corner strips
	for _, xCorner in { -(halfW + WALL_THICKNESS / 2 - 0.3), (halfW + WALL_THICKNESS / 2 - 0.3) } do
		for _, zCorner in { -(halfD + WALL_THICKNESS / 2 - 0.3), (halfD + WALL_THICKNESS / 2 - 0.3) } do
			addPart(
				parent,
				"SpiritCorner_" .. tostring(xCorner) .. "_" .. tostring(zCorner),
				Vector3.new(0.3, ch.height - 1, 0.3),
				CFrame.new(c + Vector3.new(xCorner, ch.height / 2, zCorner)),
				ch.spiritColor,
				Enum.Material.Neon,
				0.2
			)
		end
	end
end

-- Chamber 3 only: boss platform
local function buildBossPlatform(parent: Instance, ch: typeof(CHAMBERS[1]))
	local c = ch.center

	-- Raised circular platform
	local platform = addPart(
		parent,
		"BossPlatform",
		Vector3.new(14, 1.5, 14),
		CFrame.new(c + Vector3.new(0, 1, 0)),
		ch.darkColor,
		Enum.Material.Slate
	)
	platform:SetAttribute("BossPlatform", true)

	-- Neon ring around platform
	MicroCurveBuilder:fillCircle(c + Vector3.new(0, 1.9, 0), 7, 0.6, {
		voxelStuds = 0.15,
		color = ch.spiritColor,
		material = Enum.Material.Neon,
		parent = parent,
		filled = false,
		collision = false,
	})

	-- Amber boss spawn marker at center
	local bossMarker = addPart(
		parent,
		"BossSpawn",
		Vector3.new(3, 0.4, 3),
		CFrame.new(c + Vector3.new(0, 1.5, 0)),
		ch.accentColor,
		Enum.Material.Neon,
		0.15
	)
	bossMarker:SetAttribute("SpiritBossSpawn", true)
end

-- ──────────────────────────────────────────────
-- Public: Build(model, profile, budget)
-- ──────────────────────────────────────────────

function DeathValleySpiritChamberBuilder:Build(model: Model, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	local spiritFolder = Instance.new("Folder")
	spiritFolder.Name = "SpiritChambers"
	spiritFolder:SetAttribute("Planet", "Hellbound")
	spiritFolder:SetAttribute("TunnelSystem", "SpiritLock")
	spiritFolder.Parent = model

	for _, ch in CHAMBERS do
		local chamberModel = Instance.new("Model")
		chamberModel.Name = ch.name
		chamberModel:SetAttribute("ChamberIndex", ch.index)
		chamberModel:SetAttribute("WalkOnly", true)
		chamberModel:SetAttribute("VehiclesAllowed", false)
		chamberModel.Parent = spiritFolder

		buildChamberFloor(chamberModel, ch)
		buildChamberWalls(chamberModel, ch)
		buildChamberDoors(chamberModel, ch)
		buildSpiritSpawns(chamberModel, ch)
		buildSpiritLines(chamberModel, ch)

		if ch.index == 3 then
			buildBossPlatform(chamberModel, ch)
		end

		WorldBuildBudget:add(budget, 8 + ch.spiritSpawns + 16 + 6 + 9)
	end
end

return DeathValleySpiritChamberBuilder