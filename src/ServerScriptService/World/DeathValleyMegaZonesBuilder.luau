--!strict
--[[
	Phase C — Mega Dungeon zones 2–5 greybox arenas.
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

		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zone" .. zoneDef.zoneIndex .. "_" .. zoneDef.id
		zoneFolder.Parent = folder

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
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = string.format(
			"%s\nTeam %d · Win %d+",
			zoneDef.displayName,
			zoneDef.nominalTeamSize,
			zoneDef.minToSucceed
		)
		label.Parent = gui

		WorldBuildBudget:add(budget, 4)
	end

	print("[Utopia] Mega Dungeon zones 2–5 greybox built")
end

function DeathValleyMegaZonesBuilder:BuildWeeklyBossArena(parent: Model, profile: any, budget: any)
	local WorldBuildBudget = require(script.Parent:WaitForChild("WorldBuildBudget"))
	local folder = parent:FindFirstChild("HorizonRings") or parent

	local arena = Instance.new("Part")
	arena.Name = "WeeklyBossArena"
	arena.Size = Vector3.new(36, 1, 36)
	arena.CFrame = CFrame.new(150, 1, 150)
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

	local pillar = Instance.new("Part")
	pillar.Name = "WeeklyBossPedestal"
	pillar.Size = Vector3.new(8, 16, 8)
	pillar.CFrame = CFrame.new(150, 9, 150)
	pillar.Anchored = true
	pillar.Color = profile.Palette.Gold
	pillar.Material = Enum.Material.Neon
	pillar.Parent = folder

	WorldBuildBudget:add(budget, 2)
end

return DeathValleyMegaZonesBuilder
