--!strict
--[[
	Phase C — Mega Dungeon zones 2–5 greybox arenas + art pass.
	Art pass: arena walls, raised boss platforms, torch pillars, entrance gates, signs.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))

local DeathValleyMegaZonesBuilder = {}

local ZONE_ORIGINS = {
	squad_hollow = Vector3.new(200, 0, 0),
	raid_cavern = Vector3.new(200, 0, 200),
	legion_pass = Vector3.new(-200, 0, 200),
	abyss_throne = Vector3.new(-200, 0, -200),
}

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

local function addPrompt(parent: Instance, actionText: string, objectText: string, zoneId: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DungeonPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0.35
	prompt.Parent = parent
	parent:SetAttribute("ZoneId", zoneId)
end

local function addZoneLabel(part: BasePart, displayName: string, teamSize: number, minToSucceed: number)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = string.format(
		"%s\nTeam %d · Win %d+",
		displayName,
		teamSize,
		minToSucceed
	)
	label.Parent = gui
end

-- Theme palette per zone (dark tones)
local ZONE_THEMES = {
	squad_hollow = {
		wallColor = Color3.fromRGB(40, 35, 45),       -- dark stone
		wallMaterial = Enum.Material.Slate,
		platformColor = Color3.fromRGB(60, 45, 70),
		torchColor = Color3.fromRGB(140, 100, 200),    -- violet flame
	},
	raid_cavern = {
		wallColor = Color3.fromRGB(55, 50, 40),       -- stalactite rock
		wallMaterial = Enum.Material.Rock,
		platformColor = Color3.fromRGB(65, 55, 45),
		torchColor = Color3.fromRGB(200, 140, 60),     -- amber lava
	},
	legion_pass = {
		wallColor = Color3.fromRGB(50, 55, 60),       -- mountain stone
		wallMaterial = Enum.Material.Slate,
		platformColor = Color3.fromRGB(60, 65, 70),
		torchColor = Color3.fromRGB(80, 200, 220),     -- cyan frost
	},
	abyss_throne = {
		wallColor = Color3.fromRGB(25, 22, 35),       -- dark obsidian towers
		wallMaterial = Enum.Material.Slate,
		platformColor = Color3.fromRGB(30, 25, 40),
		torchColor = Color3.fromRGB(200, 60, 80),      -- crimson dread
	},
}

-- ──────────────────────────────────────────────
-- Art pass: arena walls (ring of ≥6 segments around BossArena)
-- ──────────────────────────────────────────────

local function buildArenaWalls(folder: Instance, origin: Vector3, zoneIndex: number, theme: typeof(ZONE_THEMES.squad_hollow))
	local arenaSize = 30 + zoneIndex * 8
	local halfSize = arenaSize / 2
	local arenaCenter = origin + Vector3.new(0, 1, -30)
	local partCount = 0

	-- Ring of wall segments around the arena perimeter
	local ringRadius = halfSize - 1
	local segmentCount = 6 + zoneIndex -- bigger zones get more segments
	for s = 0, segmentCount - 1 do
		local angle = s * (math.pi * 2 / segmentCount)
		local wx = math.cos(angle) * ringRadius
		local wz = math.sin(angle) * ringRadius
		local segHeight = 6 + zoneIndex * 1.5

		addPart(
			folder,
			"ArenaWall_" .. zoneIndex .. "_" .. s,
			Vector3.new(4, segHeight, 3),
			CFrame.new(arenaCenter + Vector3.new(wx, segHeight / 2, wz)),
			theme.wallColor,
			theme.wallMaterial
		)
		partCount += 1
	end

	-- Corner accent pillars (4 corners of arena)
	local corners = {
		Vector3.new(halfSize - 2, 0, halfSize - 2),
		Vector3.new(halfSize - 2, 0, -halfSize + 2),
		Vector3.new(-halfSize + 2, 0, halfSize - 2),
		Vector3.new(-halfSize + 2, 0, -halfSize + 2),
	}
	for i, corner in corners do
		local pillarHeight = 5 + zoneIndex * 2
		addPart(
			folder,
			"ArenaPillar_" .. zoneIndex .. "_" .. i,
			Vector3.new(2, pillarHeight, 2),
			CFrame.new(arenaCenter + corner + Vector3.new(0, pillarHeight / 2, 0)),
			theme.wallColor,
			theme.wallMaterial
		)
		partCount += 1
	end

	return partCount
end

-- ──────────────────────────────────────────────
-- Art pass: boss platform (raised platform + ramp + 4 torch pillars)
-- ──────────────────────────────────────────────

local function buildBossPlatform(folder: Instance, origin: Vector3, zoneIndex: number, theme: typeof(ZONE_THEMES.squad_hollow))
	local arenaCenter = origin + Vector3.new(0, 1, -30)
	local platformSize = 10 + zoneIndex * 3
	local platformHeight = 3
	local partCount = 0

	-- Raised central platform
	addPart(
		folder,
		"BossPlatform_" .. zoneIndex,
		Vector3.new(platformSize, 1.5, platformSize),
		CFrame.new(arenaCenter + Vector3.new(0, platformHeight, 0)),
		theme.platformColor,
		Enum.Material.Slate
	)
	partCount += 1

	-- Ramp up to platform (on the pad-facing side, +Z = north toward ZonePad)
	-- Simple angled ramp plank
	local rampLength = platformSize * 0.6
	local rampAngle = math.atan(platformHeight / rampLength)
	local rampStart = arenaCenter + Vector3.new(0, 0, -platformSize / 2)
	local rampMid = rampStart + Vector3.new(0, platformHeight / 2, rampLength / 2)

	addPart(
		folder,
		"BossRamp_" .. zoneIndex,
		Vector3.new(8, 0.4, rampLength),
		CFrame.new(rampMid) * CFrame.Angles(-rampAngle, 0, 0),
		Color3.fromRGB(70, 60, 80),
		Enum.Material.Slate
	)
	partCount += 1

	-- Torch pillars: 4 around the boss platform with BossTorch=true
	local torchRadius = platformSize / 2 + 2
	for t = 0, 3 do
		local angle = t * (math.pi / 2)
		local tx = math.cos(angle) * torchRadius
		local tz = math.sin(angle) * torchRadius
		local torchHeight = 8 + zoneIndex * 2

		local pillar = addPart(
			folder,
			"BossTorch_" .. zoneIndex .. "_" .. t,
			Vector3.new(1.5, torchHeight, 1.5),
			CFrame.new(arenaCenter + Vector3.new(tx, torchHeight / 2 + platformHeight, tz)),
			Color3.fromRGB(50, 40, 55),
			Enum.Material.Metal
		)
		pillar:SetAttribute("BossTorch", true)

		-- Torch flame (Neon sphere on top)
		addPart(
			folder,
			"BossTorchFlame_" .. zoneIndex .. "_" .. t,
			Vector3.new(2, 2, 2),
			CFrame.new(arenaCenter + Vector3.new(tx, torchHeight + 1.5 + platformHeight, tz)),
			theme.torchColor,
			Enum.Material.Neon,
			0.25
		)
		partCount += 2
	end

	-- Neon ring around platform (12 segments)
	local ringRadius = platformSize / 2 + 1
	for r = 0, 11 do
		local rAngle = r * (math.pi * 2 / 12)
		local rX = math.cos(rAngle) * ringRadius
		local rZ = math.sin(rAngle) * ringRadius

		addPart(
			folder,
			"BossRing_" .. zoneIndex .. "_" .. r,
			Vector3.new(1.5, 0.3, 0.6),
			CFrame.new(arenaCenter + Vector3.new(rX, platformHeight + 0.9, rZ))
				* CFrame.Angles(0, -rAngle, 0),
			theme.torchColor,
			Enum.Material.Neon,
			0.3
		)
		partCount += 1
	end

	return partCount
end

-- ──────────────────────────────────────────────
-- Art pass: entrance arch (gate pillars flanking DungeonZoneGate)
-- ──────────────────────────────────────────────

local function buildEntrance(folder: Instance, origin: Vector3, zoneIndex: number, displayName: string, teamSize: number, minToSucceed: number, theme: typeof(ZONE_THEMES.squad_hollow))
	local partCount = 0
	local gatePos = origin + Vector3.new(0, 5, 20)

	-- Left pillar
	addPart(
		folder,
		"GatePillar_Left_" .. zoneIndex,
		Vector3.new(3, 14, 3),
		CFrame.new(gatePos + Vector3.new(-9, 2, 0)),
		theme.wallColor,
		theme.wallMaterial
	)
	partCount += 1

	-- Right pillar
	addPart(
		folder,
		"GatePillar_Right_" .. zoneIndex,
		Vector3.new(3, 14, 3),
		CFrame.new(gatePos + Vector3.new(9, 2, 0)),
		theme.wallColor,
		theme.wallMaterial
	)
	partCount += 1

	-- Left torch on pillar
	local torch = addPart(
		folder,
		"GateTorch_Left_" .. zoneIndex,
		Vector3.new(1.5, 1.5, 1.5),
		CFrame.new(gatePos + Vector3.new(-9, 8.5, 0)),
		theme.torchColor,
		Enum.Material.Neon,
		0.25
	)
	torch:SetAttribute("BossTorch", true)
	partCount += 1

	-- Right torch on pillar
	local torchR = addPart(
		folder,
		"GateTorch_Right_" .. zoneIndex,
		Vector3.new(1.5, 1.5, 1.5),
		CFrame.new(gatePos + Vector3.new(9, 8.5, 0)),
		theme.torchColor,
		Enum.Material.Neon,
		0.25
	)
	torchR:SetAttribute("BossTorch", true)
	partCount += 1

	-- Arch beam across top
	addPart(
		folder,
		"GateArch_" .. zoneIndex,
		Vector3.new(16, 1.5, 2),
		CFrame.new(gatePos + Vector3.new(0, 8, 0)),
		Color3.fromRGB(255, 179, 71), -- Gold accent
		Enum.Material.Neon,
		0.2
	)
	partCount += 1

	return partCount
end

-- ──────────────────────────────────────────────
-- Public: Build(zones 2-5)
-- ──────────────────────────────────────────────

function DeathValleyMegaZonesBuilder:Build(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = Instance.new("Folder")
	folder.Name = "MegaDungeon_Zones2_5"
	folder.Parent = parent

	for _, zoneDef in PrismDeathValleyDungeonConfig.Zones do
		if zoneDef.zoneIndex <= 1 then
			continue
		end
		local origin = ZONE_ORIGINS[zoneDef.id]
		if not origin then
			continue
		end

		local theme = ZONE_THEMES[zoneDef.id] or ZONE_THEMES.squad_hollow

		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zone" .. zoneDef.zoneIndex .. "_" .. zoneDef.id
		zoneFolder.Parent = folder

		-- ── Existing greybox parts (kept intact) ──

		local pad = Instance.new("Part")
		pad.Name = "ZonePad"
		pad.Size = Vector3.new(40 + zoneDef.nominalTeamSize * 4, 1, 40 + zoneDef.nominalTeamSize * 4)
		pad.CFrame = CFrame.new(origin + Vector3.new(0, 0.5, 0))
		pad.Anchored = true
		pad.Color = profile.Palette.Pearl
		pad.Material = Enum.Material.Slate
		pad.Parent = zoneFolder

		local gate = Instance.new("Part")
		gate.Name = "DungeonZoneGate"
		gate.Size = Vector3.new(14, 10, 4)
		gate.CFrame = CFrame.new(origin + Vector3.new(0, 5, 20))
		gate.Anchored = true
		gate.Color = profile.Palette.Gold
		gate.Material = Enum.Material.Metal
		gate.Parent = zoneFolder
		gate:SetAttribute("NominalTeamSize", zoneDef.nominalTeamSize)
		addPrompt(gate, "Enter " .. zoneDef.displayName, zoneDef.bossName, zoneDef.id)

		local arena = Instance.new("Part")
		arena.Name = "BossArena"
		arena.Size = Vector3.new(30 + zoneDef.zoneIndex * 8, 2, 30 + zoneDef.zoneIndex * 8)
		arena.CFrame = CFrame.new(origin + Vector3.new(0, 1, -30))
		arena.Anchored = true
		arena.Color = Color3.fromRGB(50, 20, 70)
		arena.Material = Enum.Material.Neon
		arena.Parent = zoneFolder
		arena:SetAttribute("BossName", zoneDef.bossName)
		addPrompt(arena, "Start Boss", zoneDef.bossName, zoneDef.id)

		local sign = Instance.new("Part")
		sign.Name = "ZoneSign"
		sign.Size = Vector3.new(20, 5, 1)
		sign.CFrame = CFrame.new(origin + Vector3.new(0, 8, 35))
		sign.Anchored = true
		sign.Color = profile.Palette.Gold
		sign.Material = Enum.Material.Neon
		sign.Parent = zoneFolder
		sign:SetAttribute("ZoneSign", true)
		addZoneLabel(sign, zoneDef.displayName, zoneDef.nominalTeamSize, zoneDef.minToSucceed)

		-- ── Art pass additions ──

		local wallsCount = buildArenaWalls(zoneFolder, origin, zoneDef.zoneIndex, theme)
		local platformCount = buildBossPlatform(zoneFolder, origin, zoneDef.zoneIndex, theme)
		local entranceCount = buildEntrance(zoneFolder, origin, zoneDef.zoneIndex, zoneDef.displayName, zoneDef.nominalTeamSize, zoneDef.minToSucceed, theme)

		local zonePartTotal = 4 + wallsCount + platformCount + entranceCount
		WorldBuildBudget:add(budget, zonePartTotal)
	end

	print("[Utopia] Mega Dungeon zones 2–5 art pass built")
end

-- ──────────────────────────────────────────────
-- Public: BuildWeeklyBossArena (art pass)
-- ──────────────────────────────────────────────

function DeathValleyMegaZonesBuilder:BuildWeeklyBossArena(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = parent:FindFirstChild("HorizonRings") or parent

	local arenaOrigin = Vector3.new(150, 1, 150)
	local arenaHalf = 18

	-- Existing arena pad (kept intact)
	local arena = Instance.new("Part")
	arena.Name = "WeeklyBossArena"
	arena.Size = Vector3.new(36, 1, 36)
	arena.CFrame = CFrame.new(arenaOrigin)
	arena.Anchored = true
	arena.Color = Color3.fromRGB(80, 20, 100)
	arena.Material = Enum.Material.Neon
	arena.Parent = folder
	arena:SetAttribute("WeeklyBossArena", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Challenge Weekly Boss"
	prompt.ObjectText = "Horizon Ring 3"
	prompt.MaxActivationDistance = 16
	prompt.Parent = arena

	-- Pedestal
	local pillar = Instance.new("Part")
	pillar.Name = "WeeklyBossPedestal"
	pillar.Size = Vector3.new(8, 16, 8)
	pillar.CFrame = CFrame.new(150, 9, 150)
	pillar.Anchored = true
	pillar.Color = profile.Palette.Gold
	pillar.Material = Enum.Material.Neon
	pillar.Parent = folder

	local partCount = 2 -- existing: arena + pedestal

	-- Border ring: 16 segments around the arena
	local ringRadius = arenaHalf - 0.5
	for r = 0, 15 do
		local angle = r * (math.pi * 2 / 16)
		local rx = math.cos(angle) * ringRadius
		local rz = math.sin(angle) * ringRadius

		addPart(
			folder,
			"WeeklyRingBorder_" .. r,
			Vector3.new(3, 2.5, 1.5),
			CFrame.new(arenaOrigin + Vector3.new(rx, 1.75, rz))
				* CFrame.Angles(0, -angle, 0),
			Color3.fromRGB(120, 40, 150),
			Enum.Material.Neon,
			0.3
		)
		partCount += 1
	end

	-- 4 corner pillars with WeeklyPillar=true
	local cornerPillarPositions = {
		Vector3.new(arenaHalf - 1, 0, arenaHalf - 1),
		Vector3.new(arenaHalf - 1, 0, -arenaHalf + 1),
		Vector3.new(-arenaHalf + 1, 0, arenaHalf - 1),
		Vector3.new(-arenaHalf + 1, 0, -arenaHalf + 1),
	}
	for i, cp in cornerPillarPositions do
		local wp = addPart(
			folder,
			"WeeklyPillar_" .. i,
			Vector3.new(2.5, 8, 2.5),
			CFrame.new(arenaOrigin + cp + Vector3.new(0, 4, 0)),
			Color3.fromRGB(160, 40, 180),
			Enum.Material.Metal
		)
		wp:SetAttribute("WeeklyPillar", true)

		-- Pillar flame on top
		addPart(
			folder,
			"WeeklyPillarFlame_" .. i,
			Vector3.new(2, 2, 2),
			CFrame.new(arenaOrigin + cp + Vector3.new(0, 8.5, 0)),
			Color3.fromRGB(200, 80, 200),
			Enum.Material.Neon,
			0.2
		)
		partCount += 2
	end

	WorldBuildBudget:add(budget, partCount)
end

return DeathValleyMegaZonesBuilder