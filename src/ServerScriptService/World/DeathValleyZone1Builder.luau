--!strict
--[[
	Zone 1 — Duo Depth greybox: loadout station, arena, boss platform.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local DeathValleyZone1Builder = {}

local ORIGIN = Vector3.new(140, 0, 0)

local function addPrompt(parent: Instance, actionText: string, objectText: string, attrName: string, attrValue: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DungeonPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0.35
	prompt:SetAttribute("DungeonAction", attrValue)
	prompt.Parent = parent
	parent:SetAttribute(attrName, attrValue)
end

function DeathValleyZone1Builder:Build(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	local folder = Instance.new("Folder")
	folder.Name = "MegaDungeon_Zone1_DuoDepth"
	folder.Parent = parent

	local zoneDef = {
		id = "duo_depth",
		displayName = "Zone 1 — Duo Depth",
		nominalTeamSize = 2,
	}

	-- Loadout station
	local loadoutPad = Instance.new("Part")
	loadoutPad.Name = "LoadoutStation"
	loadoutPad.Size = Vector3.new(24, 1, 24)
	loadoutPad.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 0.5, 0))
	loadoutPad.Anchored = true
	loadoutPad.Color = profile.Palette.Pearl
	loadoutPad.Material = Enum.Material.SmoothPlastic
	loadoutPad.Parent = folder
	WorldBuildBudget:add(budget, 1)

	local loadoutKiosk = Instance.new("Part")
	loadoutKiosk.Name = "LoadoutKiosk"
	loadoutKiosk.Size = Vector3.new(8, 10, 4)
	loadoutKiosk.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 5, -10))
	loadoutKiosk.Anchored = true
	loadoutKiosk.Color = profile.Palette.Cyan
	loadoutKiosk.Material = Enum.Material.Neon
	loadoutKiosk.Parent = folder
	addPrompt(loadoutKiosk, "Open Loadout", "Hellbound Loadout", "ZoneId", zoneDef.id)
	WorldBuildBudget:add(budget, 1)

	-- Path to arena
	local pathPoints: { Vector3 } = {}
	for i = 0, 8 do
		local t = i / 8
		table.insert(pathPoints, ORIGIN + Vector3.new(0, 1, -20 - t * 40))
	end
	MicroCurveBuilder:fillArc(pathPoints, 3, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Amber,
		material = Enum.Material.Neon,
		parent = folder,
		collision = true,
		budget = budget,
	})

	-- Arena ring
	local arenaCenter = ORIGIN + Vector3.new(0, 0, -70)
	MicroCurveBuilder:fillCircle(arenaCenter + Vector3.new(0, 1, 0), 42, 1.2, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Amber,
		material = Enum.Material.Neon,
		parent = folder,
		filled = false,
		budget = budget,
	})

	local arenaFloor = Instance.new("Part")
	arenaFloor.Name = "ArenaFloor"
	arenaFloor.Size = Vector3.new(84, 1, 84)
	arenaFloor.CFrame = CFrame.new(arenaCenter + Vector3.new(0, 0.2, 0))
	arenaFloor.Anchored = true
	arenaFloor.Color = Color3.fromRGB(35, 25, 45)
	arenaFloor.Material = Enum.Material.Slate
	arenaFloor.Parent = folder
	arenaFloor:SetAttribute("ZoneId", zoneDef.id)
	WorldBuildBudget:add(budget, 1)

	-- Zone gate
	local gate = Instance.new("Part")
	gate.Name = "Zone1Gate"
	gate.Size = Vector3.new(16, 12, 4)
	gate.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 6, -45))
	gate.Anchored = true
	gate.Color = profile.Palette.Gold
	gate.Material = Enum.Material.Metal
	gate.Parent = folder
	gate:SetAttribute("ZoneId", zoneDef.id)
	gate:SetAttribute("NominalTeamSize", zoneDef.nominalTeamSize)
	addPrompt(gate, "Enter Zone 1", zoneDef.displayName, "ZoneId", zoneDef.id)
	WorldBuildBudget:add(budget, 1)

	-- Boss platform
	local bossPlatform = Instance.new("Part")
	bossPlatform.Name = "BossArena"
	bossPlatform.Size = Vector3.new(30, 2, 30)
	bossPlatform.CFrame = CFrame.new(arenaCenter + Vector3.new(0, 1, -15))
	bossPlatform.Anchored = true
	bossPlatform.Color = Color3.fromRGB(60, 20, 80)
	bossPlatform.Material = Enum.Material.Neon
	bossPlatform.Parent = folder
	bossPlatform:SetAttribute("ZoneId", zoneDef.id)
	bossPlatform:SetAttribute("BossName", "Wraith Pair")
	addPrompt(bossPlatform, "Start Boss", "Wraith Pair (Duo)", "ZoneId", zoneDef.id)
	WorldBuildBudget:add(budget, 1)

	for i = 1, 2 do
		local wraith = Instance.new("Part")
		wraith.Name = "WraithPair_" .. i
		wraith.Size = Vector3.new(6, 12, 6)
		wraith.CFrame = CFrame.new(arenaCenter + Vector3.new(-8 + (i - 1) * 16, 7, -15))
		wraith.Anchored = true
		wraith.Color = Color3.fromRGB(120, 40, 160)
		wraith.Material = Enum.Material.Neon
		wraith.Transparency = 0.2
		wraith.Parent = folder
		wraith:SetAttribute("BossMinion", true)
		WorldBuildBudget:add(budget, 1)
	end

	-- Sign
	local sign = Instance.new("Part")
	sign.Name = "Zone1Sign"
	sign.Size = Vector3.new(28, 6, 1)
	sign.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 8, 8))
	sign.Anchored = true
	sign.Color = profile.Palette.Gold
	sign.Material = Enum.Material.Neon
	sign.Parent = folder
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "ZONE 1 — DUO DEPTH\nTeam 2 · Loadout required"
	label.Parent = gui
	WorldBuildBudget:add(budget, 2)

	print("[Utopia] Mega Dungeon Zone 1 greybox built at", ORIGIN)
end

return DeathValleyZone1Builder
