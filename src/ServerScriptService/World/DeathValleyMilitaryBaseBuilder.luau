--!strict
--[[
	Death Valley Military Research Base — undermountain complex
	Tunnel entry → Research Hall → Barracks + Armory → LFG Board
	Docs: docs/death-valley/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md §5
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)

local DeathValleyMilitaryBaseBuilder = {}

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

local function addLabel(parent: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
end

-- ──────────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────────

-- Positioned inside mountain FillBlock (z=-60 to -100), near MilitaryBase station (-40, 4, 10)
local BASE_CENTER = Vector3.new(-35, 0, -68)
local BASE_HALF = 22

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Amber = Color3.fromRGB(255, 179, 71),
	Twilight = Color3.fromRGB(20, 12, 30),
	MilitaryGreen = Color3.fromRGB(40, 120, 60),
	MilitaryRed = Color3.fromRGB(180, 40, 50),
	DarkMetal = Color3.fromRGB(60, 70, 80),
}

-- ──────────────────────────────────────────────
-- Entry tunnel — descending from surface (MilitaryBase station) into mountain
-- ──────────────────────────────────────────────

local ENTRANCE_MOUTH = Vector3.new(-35, 5, -20) -- surface level near travel station
local TUNNEL_END = Vector3.new(-35, 0.5, -46) -- descent into mountain

local function buildEntryTunnel(parent: Instance, budget: WorldBuildBudget.Budget)
	local delta = TUNNEL_END - ENTRANCE_MOUTH
	local length = delta.Magnitude
	local tunnelMid = ENTRANCE_MOUTH:Lerp(TUNNEL_END, 0.5)
	local tunnelAngle = math.atan(-delta.Y / length)
	local tunnelDir = delta / length
	local partCount = 0

	-- Tunnel floor
	addPart(
		parent,
		"TunnelFloor",
		Vector3.new(6, 0.8, length),
		CFrame.new(tunnelMid) * CFrame.Angles(tunnelAngle, 0, 0),
		Color3.fromRGB(40, 35, 50),
		Enum.Material.Slate
	)
	partCount += 1

	-- Tunnel ceiling
	addPart(
		parent,
		"TunnelCeiling",
		Vector3.new(6, 0.8, length),
		CFrame.new(tunnelMid + Vector3.new(0, 8, 0)) * CFrame.Angles(tunnelAngle, 0, 0),
		Color3.fromRGB(30, 25, 40),
		Enum.Material.Slate
	)
	partCount += 1

	-- Tunnel side walls (left + right)
	for _, xSide in { -3, 3 } do
		local wallLabel = if xSide < 0 then "L" else "R"
		for i = 0, 4 do
			local t = i / 5
			local pillarPos = ENTRANCE_MOUTH:Lerp(TUNNEL_END, t) + Vector3.new(xSide, 4, 0)
			addPart(
				parent,
				"TunnelWall_" .. wallLabel .. "_" .. i,
				Vector3.new(0.8, 8, 1.5),
				CFrame.new(pillarPos) * CFrame.Angles(0, math.atan2(tunnelDir.X, tunnelDir.Z), 0),
				Color3.fromRGB(50, 60, 70),
				Enum.Material.Metal
			)
			partCount += 1
		end
	end

	-- Guide lights along tunnel (Amber strips on walls)
	for i = 0, 5 do
		local t = i / 6
		local lightPos = ENTRANCE_MOUTH:Lerp(TUNNEL_END, t) + Vector3.new(0, 1.5, 0)
		for _, xOff in { -2.8, 2.8 } do
			addPart(
				parent,
				"TunnelLight_" .. t .. "_" .. tostring(xOff),
				Vector3.new(0.3, 0.8, 0.3),
				CFrame.new(lightPos + Vector3.new(xOff, 0, 0)),
				PALETTE.Amber,
				Enum.Material.Neon,
				0.12
			)
			partCount += 1
		end
	end

	-- Entry arch (surface entrance)
	OrganicCSGBuilder:createArch(CFrame.new(ENTRANCE_MOUTH + Vector3.new(0, 4, 2)), 8, 10, 1.5, {
		color = PALETTE.DarkMetal,
		material = Enum.Material.Metal,
		parent = parent,
		name = "BaseEntryArch",
	})
	partCount += 1

	-- Blast door at tunnel end (between tunnel and main hall)
	local blastDoor = addPart(
		parent,
		"BlastDoor",
		Vector3.new(6, 8, 1),
		CFrame.new(TUNNEL_END + Vector3.new(0, 4, 0)),
		PALETTE.MilitaryRed,
		Enum.Material.Metal,
		0
	)
	blastDoor:SetAttribute("BaseGate", true)
	blastDoor:SetAttribute("BaseGateDirection", "Entry")

	-- Door frame Neon (military green)
	addPart(
		parent,
		"BlastDoorFrame",
		Vector3.new(7, 9, 1.2),
		CFrame.new(TUNNEL_END + Vector3.new(0, 4, -0.1)),
		PALETTE.MilitaryGreen,
		Enum.Material.Neon,
		0.15
	)

	-- Sign at entrance
	local signPart = addPart(
		parent,
		"BaseEntranceSign",
		Vector3.new(10, 4, 0.8),
		CFrame.new(ENTRANCE_MOUTH + Vector3.new(0, 5, -2)),
		PALETTE.Gold,
		Enum.Material.Neon,
		0.12
	)
	addLabel(signPart, "Undermountain Military Base")
	partCount += 1

	WorldBuildBudget:add(budget, partCount + 2)
end

-- Research Hall room dimensions (used by barracks/armory)
local halfW = 20
local halfD = 16

-- ──────────────────────────────────────────────
-- Main Research Hall — large chamber with structural pillars, lab stations
-- ──────────────────────────────────────────────

local function buildResearchHall(parent: Instance, budget: WorldBuildBudget.Budget)
	local c = BASE_CENTER + Vector3.new(0, 0, -20) -- deeper into mountain
	local halfW = 20
	local halfD = 16
	local height = 12
	local partCount = 0

	-- Floor
	addPart(
		parent,
		"HallFloor",
		Vector3.new(halfW * 2, 1, halfD * 2),
		CFrame.new(c + Vector3.new(0, -0.5, 0)),
		Color3.fromRGB(50, 60, 70),
		Enum.Material.Slate
	)
	partCount += 1

	-- Ceiling
	addPart(
		parent,
		"HallCeiling",
		Vector3.new(halfW * 2, 0.6, halfD * 2),
		CFrame.new(c + Vector3.new(0, height + 0.3, 0)),
		Color3.fromRGB(30, 35, 45),
		Enum.Material.Slate
	)
	partCount += 1

	-- Walls (4 sides)
	local wallSpecs = {
		{ name = "HallWallN", pos = Vector3.new(0, height / 2, halfD), size = Vector3.new(halfW * 2, height, 1.5) },
		{ name = "HallWallS", pos = Vector3.new(0, height / 2, -halfD), size = Vector3.new(halfW * 2, height, 1.5) },
		{ name = "HallWallW", pos = Vector3.new(-halfW, height / 2, 0), size = Vector3.new(1.5, height, halfD * 2) },
		{ name = "HallWallE", pos = Vector3.new(halfW, height / 2, 0), size = Vector3.new(1.5, height, halfD * 2) },
	}
	for _, w in wallSpecs do
		addPart(
			parent,
			w.name,
			w.size,
			CFrame.new(c + w.pos),
			Color3.fromRGB(45, 50, 60),
			Enum.Material.Metal
		)
		partCount += 1
	end

	-- Structural pillars (4 interior columns)
	local pillarPositions = {
		{ -8, -8 }, { -8, 8 }, { 8, -8 }, { 8, 8 },
	}
	for _, pp in pillarPositions do
		addPart(
			parent,
			"HallPillar_" .. pp[1] .. "_" .. pp[2],
			Vector3.new(2, height, 2),
			CFrame.new(c + Vector3.new(pp[1], height / 2, pp[2])),
			Color3.fromRGB(70, 80, 90),
			Enum.Material.Metal
		)
		partCount += 1
	end

	-- Neon wall strips (military green, 2 heights)
	for _, yOff in { 2.5, height - 2.5 } do
		-- North wall strip
		addPart(
			parent,
			"HallNeon_N_" .. tostring(yOff),
			Vector3.new(halfW * 2 - 4, 0.3, 0.3),
			CFrame.new(c + Vector3.new(0, yOff, halfD - 0.9)),
			PALETTE.MilitaryGreen,
			Enum.Material.Neon,
			0.15
		)
		partCount += 1
		-- South wall strip
		addPart(
			parent,
			"HallNeon_S_" .. tostring(yOff),
			Vector3.new(halfW * 2 - 4, 0.3, 0.3),
			CFrame.new(c + Vector3.new(0, yOff, -halfD + 0.9)),
			PALETTE.MilitaryGreen,
			Enum.Material.Neon,
			0.15
		)
		partCount += 1
	end

	-- Research stations (4 greybox consoles positioned around hall)
	local stationPositions = {
		{ pos = Vector3.new(-12, 1.5, -4), label = "Research Station Alpha" },
		{ pos = Vector3.new(12, 1.5, -4), label = "Research Station Beta" },
		{ pos = Vector3.new(-12, 1.5, 6), label = "Research Station Gamma" },
		{ pos = Vector3.new(6, 1.5, 8), label = "Research Station Delta" },
	}
	for i, st in stationPositions do
		local station = addPart(
			parent,
			"ResearchStation_" .. i,
			Vector3.new(6, 3, 4),
			CFrame.new(c + st.pos),
			Color3.fromRGB(80, 85, 95),
			Enum.Material.Metal
		)
		station:SetAttribute("ResearchStation", true)

		-- Console hologram glow
		addPart(
			parent,
			"ResearchStationGlow_" .. i,
			Vector3.new(5.5, 0.3, 3.5),
			CFrame.new(c + st.pos + Vector3.new(0, 1.8, 0)),
			PALETTE.Cyan,
			Enum.Material.Neon,
			0.25
		)
		-- Small sign
		addPart(
			parent,
			"ResearchStationLabel_" .. i,
			Vector3.new(5, 1, 0.5),
			CFrame.new(c + st.pos + Vector3.new(0, 2.5, 2.2)),
			PALETTE.Gold,
			Enum.Material.Neon,
			0.15
		)
		partCount += 3
	end

	-- Central holographic table
	local holoTable = addPart(
		parent,
		"CentralHoloTable",
		Vector3.new(10, 1, 10),
		CFrame.new(c + Vector3.new(0, 1, 0)),
		Color3.fromRGB(90, 95, 105),
		Enum.Material.Metal
	)
	holoTable:SetAttribute("ResearchStation", true)
	partCount += 1
	addPart(
		parent,
		"CentralHoloGlow",
		Vector3.new(9, 0.3, 9),
		CFrame.new(c + Vector3.new(0, 1.7, 0)),
		PALETTE.Cyan,
		Enum.Material.Neon,
		0.2
	)
	partCount += 1

	-- Exit door (toward spirit chambers)
	local exitDoor = addPart(
		parent,
		"HallExitDoor",
		Vector3.new(5, 6, 0.5),
		CFrame.new(c + Vector3.new(0, 3, -halfD + 0.1)),
		PALETTE.MilitaryRed,
		Enum.Material.Metal,
		0
	)
	exitDoor:SetAttribute("BaseGate", true)
	exitDoor:SetAttribute("BaseGateDirection", "ExitSpiritTunnel")
	partCount += 1
	addPart(
		parent,
		"HallExitDoorFrame",
		Vector3.new(6, 7, 0.7),
		CFrame.new(c + Vector3.new(0, 3, -halfD)),
		PALETTE.MilitaryGreen,
		Enum.Material.Neon,
		0.15
	)
	partCount += 1

	WorldBuildBudget:add(budget, partCount)
end

-- ──────────────────────────────────────────────
-- LFG Board — central recruitment board (uses contract: LfgBoard=true + ProximityPrompt)
-- ──────────────────────────────────────────────

local function buildLfgBoard(parent: Instance, budget: WorldBuildBudget.Budget)
	local c = BASE_CENTER + Vector3.new(0, 0, -20)
	local boardPos = c + Vector3.new(0, 4, -halfD + 6)

	-- Large display board
	local board = addPart(
		parent,
		"LfgBoard",
		Vector3.new(14, 8, 1),
		CFrame.new(boardPos),
		PALETTE.Gold,
		Enum.Material.Neon,
		0.12
	)
	board:SetAttribute("LfgBoard", true)

	-- ProximityPrompt (contract: wireLfgBoard uses any prompt on LfgBoard=true parts)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LfgPrompt"
	prompt.ActionText = "Open LFG Board"
	prompt.ObjectText = "Mega Dungeon LFG"
	prompt.MaxActivationDistance = 14
	prompt.Parent = board

	-- Board frame / accent
	addPart(
		parent,
		"LfgBoardFrame",
		Vector3.new(15, 9, 0.5),
		CFrame.new(boardPos + Vector3.new(0, 0, -0.3)),
		PALETTE.MilitaryGreen,
		Enum.Material.Neon,
		0.2
	)

	WorldBuildBudget:add(budget, 3)
end

-- ──────────────────────────────────────────────
-- Barracks + Armory (adjacent rooms off main hall)
-- ──────────────────────────────────────────────

-- Helper: build room shell (floor + ceiling + walls + door + entrance neon) — must precede callers
local function buildRoom(parent: Instance, budget: WorldBuildBudget.Budget, center: Vector3, hw: number, hd: number, h: number, roomType: string)
	-- Floor
	addPart(
		parent,
		roomType .. "Floor",
		Vector3.new(hw * 2, 1, hd * 2),
		CFrame.new(center + Vector3.new(0, -0.5, 0)),
		Color3.fromRGB(55, 60, 70),
		Enum.Material.Slate
	)
	-- Ceiling
	addPart(
		parent,
		roomType .. "Ceiling",
		Vector3.new(hw * 2, 0.6, hd * 2),
		CFrame.new(center + Vector3.new(0, h + 0.3, 0)),
		Color3.fromRGB(35, 40, 50),
		Enum.Material.Slate
	)
	-- Walls (4 sides, with door on inner wall facing main hall)
	local innerDir = if center.X < (BASE_CENTER + Vector3.new(0, 0, -20)).X then 1 else -1
	local wallDefs = {
		{ name = roomType .. "WallTop", pos = Vector3.new(0, h / 2, hd), size = Vector3.new(hw * 2, h, 1.5) },
		{ name = roomType .. "WallBottom", pos = Vector3.new(0, h / 2, -hd), size = Vector3.new(hw * 2, h, 1.5) },
		{ name = roomType .. "WallOuter", pos = Vector3.new(innerDir * -hw, h / 2, 0), size = Vector3.new(1.5, h, hd * 2) },
	}
	for _, w in wallDefs do
		addPart(parent, w.name, w.size, CFrame.new(center + w.pos), Color3.fromRGB(50, 55, 65), Enum.Material.Metal)
	end
	-- Inner wall with door opening (top half-wall + bottom half-wall)
	addPart(parent, roomType .. "WallInnerTop", Vector3.new(1.5, h / 2 - 4, hd * 2 - 8),
		CFrame.new(center + Vector3.new(innerDir * hw, h * 0.75 + 2, 0)), Color3.fromRGB(50, 55, 65), Enum.Material.Metal)
	addPart(parent, roomType .. "WallInnerBottom", Vector3.new(1.5, h / 2 - 4, hd * 2 - 8),
		CFrame.new(center + Vector3.new(innerDir * hw, h * 0.25 - 2, 0)), Color3.fromRGB(50, 55, 65), Enum.Material.Metal)

	-- Door frame neon
	addPart(parent, roomType .. "DoorFrame",
		Vector3.new(5, 0.2, 0.7),
		CFrame.new(center + Vector3.new(innerDir * hw, h / 2, 0)),
		PALETTE.MilitaryGreen,
		Enum.Material.Neon, 0.15
	)

	-- Room attribute & label
	local labelPart = addPart(
		parent,
		roomType .. "Sign",
		Vector3.new(6, 2, 0.5),
		CFrame.new(center + Vector3.new(innerDir * hw, h - 1, -hd + 2)),
		PALETTE.Gold,
		Enum.Material.Neon, 0.12
	)
	labelPart:SetAttribute("BaseRoom", roomType)
	addLabel(labelPart, roomType)
end

local function buildBarracks(parent: Instance, budget: WorldBuildBudget.Budget)
	local c = BASE_CENTER + Vector3.new(0, 0, -20)
	local roomCenter = c + Vector3.new(-halfW - 10, 0, -4)
	local roomHalfW = 8
	local roomHalfD = 7
	local roomHeight = 10
	local partCount = 0

	-- Room label sign
	buildRoom(parent, budget, roomCenter, roomHalfW, roomHalfD, roomHeight, "Barracks")
	partCount += 1

	-- Beds (3 greybox bunk rows)
	for row = 0, 2 do
		local bedZ = -5 + row * 5
		-- Bed frame
		addPart(
			parent,
			"BarracksBed_" .. row,
			Vector3.new(4, 1, 6),
			CFrame.new(roomCenter + Vector3.new(-2, 1, bedZ)),
			Color3.fromRGB(100, 110, 120),
			Enum.Material.Metal
		)
		-- Mattress
		addPart(
			parent,
			"BarracksMattress_" .. row,
			Vector3.new(3.5, 0.6, 5.5),
			CFrame.new(roomCenter + Vector3.new(-2, 1.8, bedZ)),
			Color3.fromRGB(80, 90, 100),
			Enum.Material.SmoothPlastic
		)
		-- Locker
		addPart(
			parent,
			"BarracksLocker_" .. row,
			Vector3.new(2, 4, 1.5),
			CFrame.new(roomCenter + Vector3.new(3, 2, bedZ)),
			Color3.fromRGB(70, 80, 90),
			Enum.Material.Metal
		)
		partCount += 3
	end

	WorldBuildBudget:add(budget, partCount + 15) -- 15 for room walls from buildRoom
end

local function buildArmory(parent: Instance, budget: WorldBuildBudget.Budget)
	local c = BASE_CENTER + Vector3.new(0, 0, -20)
	local roomCenter = c + Vector3.new(halfW + 10, 0, -4)
	local roomHalfW = 8
	local roomHalfD = 7
	local roomHeight = 10
	local partCount = 0

	buildRoom(parent, budget, roomCenter, roomHalfW, roomHalfD, roomHeight, "Armory")
	partCount += 1

	-- Weapon racks (3)
	for rack = 0, 2 do
		local rackZ = -4 + rack * 4
		addPart(
			parent,
			"ArmoryRack_" .. rack,
			Vector3.new(5, 3, 0.6),
			CFrame.new(roomCenter + Vector3.new(-1, 1.5, rackZ)),
			PALETTE.DarkMetal,
			Enum.Material.Metal
		)
		-- Rack Neon highlight
		addPart(
			parent,
			"ArmoryRackGlow_" .. rack,
			Vector3.new(5.2, 0.2, 0.8),
			CFrame.new(roomCenter + Vector3.new(-1, 3.2, rackZ)),
			PALETTE.MilitaryRed,
			Enum.Material.Neon,
			0.2
		)
		partCount += 2
	end

	-- Ammo crate stack
	for crate = 0, 2 do
		local cx = 2.5 + (crate % 2) * 2.5
		local cz = 0 + math.floor(crate / 2) * 2
		addPart(
			parent,
			"ArmoryCrate_" .. crate,
			Vector3.new(2, 2, 2),
			CFrame.new(roomCenter + Vector3.new(cx, 1, cz)),
			Color3.fromRGB(60, 70, 50),
			Enum.Material.Metal
		)
		partCount += 1
	end

	WorldBuildBudget:add(budget, partCount + 15)
end

-- ──────────────────────────────────────────────
-- Public: Build(model, profile, budget)
-- ──────────────────────────────────────────────

function DeathValleyMilitaryBaseBuilder:Build(model: Model, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	local base = Instance.new("Model")
	base.Name = "MilitaryBase"
	base:SetAttribute("Planet", "Hellbound")
	base:SetAttribute("BaseType", "MilitaryResearch")
	base:SetAttribute("Undermountain", true)
	base.Parent = model

	buildEntryTunnel(base, budget)
	buildResearchHall(base, budget)
	buildLfgBoard(base, budget)
	buildBarracks(base, budget)
	buildArmory(base, budget)
end

return DeathValleyMilitaryBaseBuilder