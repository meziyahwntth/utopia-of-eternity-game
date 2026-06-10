--!strict
--[[
	Hub — organic Prism Heart Plaza, museum dome, garden arch, teleport kiosks.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local WorldBuildShared = require(script.Parent.WorldBuildShared)
local WorldBuilderTypes = require(script.Parent.WorldBuilderTypes)
local WorldPlaceGuard = require(script.Parent.WorldPlaceGuard)

local ShuttleGreyboxBuilder = require(ServerScriptService:WaitForChild("ShuttleGreyboxBuilder"))
local ArchRibKit = require(ServerStorage:WaitForChild("WorldKits"):WaitForChild("ArchRibKit"))

local HubWorldBuilder = {}

local COLORS = {
	Solhaven = Color3.fromRGB(255, 200, 80),
	Nocturne = Color3.fromRGB(170, 100, 255),
	EternityCity = Color3.fromRGB(0, 229, 255),
	DeathValley = Color3.fromRGB(80, 40, 100),
}

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

local function addLoadoutMirror(parent: Instance)
	local mirror = Instance.new("Model")
	mirror.Name = "ValleyLoadoutMirror"
	mirror.Parent = parent
	mirror:SetAttribute("ValleyLoadoutMirror", true)
	mirror:SetAttribute("MirrorAutoRotate", true)
	mirror:SetAttribute("MirrorRotateSpeed", 0.35)

	local platform = Instance.new("Part")
	platform.Name = "MirrorPlatform"
	platform.Size = Vector3.new(24, 1, 10)
	platform.CFrame = CFrame.new(0, 0.5, 52)
	platform.Anchored = true
	platform.Color = Color3.fromRGB(40, 35, 55)
	platform.Material = Enum.Material.Glass
	platform.Transparency = 0.2
	platform.Parent = mirror

	local trigger = Instance.new("Part")
	trigger.Name = "MirrorTrigger"
	trigger.Size = Vector3.new(8, 8, 8)
	trigger.CFrame = CFrame.new(0, 4, 46)
	trigger.Anchored = true
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.Parent = mirror
	addLabel(trigger, "Valley Mirror")

	local offsets = { -7, 0, 7 }
	for index, x in offsets do
		local pedestal = Instance.new("Part")
		pedestal.Name = "MirrorPedestal_" .. tostring(index)
		pedestal.Size = Vector3.new(4, 0.5, 4)
		pedestal.CFrame = CFrame.new(x, 1.2, 52)
		pedestal.Anchored = true
		pedestal.Color = Color3.fromRGB(90, 70, 120)
		pedestal.Material = Enum.Material.Neon
		pedestal:SetAttribute("MirrorOffset", Vector3.new(0, 2.5, 0))
		pedestal.Parent = mirror
	end
end

local function addLoadoutTerminals(parent: Instance)
	local terminals = {
		{ offset = Vector3.new(-22, 0, 38), mode = "loadout", label = "Valley Wardrobe" },
		{ offset = Vector3.new(-38, 0, 38), mode = "title", label = "Title Registry" },
	}
	for _, entry in terminals do
		local kiosk = Instance.new("Part")
		kiosk.Name = "ValleyLoadout_" .. entry.mode
		kiosk.Size = Vector3.new(8, 10, 8)
		kiosk.CFrame = CFrame.new(entry.offset + Vector3.new(0, 5, 0))
		kiosk.Anchored = true
		kiosk.Color = if entry.mode == "title"
			then Color3.fromRGB(255, 200, 90)
			else Color3.fromRGB(120, 80, 160)
		kiosk.Material = Enum.Material.Neon
		kiosk.Parent = parent
		kiosk:SetAttribute("ValleyLoadoutTerminal", true)
		kiosk:SetAttribute("LoadoutPickerMode", entry.mode)
		addLabel(kiosk, entry.label)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = entry.label
		prompt.ActionText = if entry.mode == "title" then "Titles" else if entry.mode == "loadout" then "Wardrobe" else "Cosmetics"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.3
		prompt.Parent = kiosk
	end
end

local function addTeleportKiosks(parent: Instance)
	local kioskRing = {
		{ key = "Solhaven", offset = Vector3.new(70, 0, 0) },
		{ key = "Nocturne", offset = Vector3.new(0, 0, 70) },
		{ key = "EternityCity", offset = Vector3.new(-70, 0, 0) },
		{ key = "DeathValley", offset = Vector3.new(0, 0, -70) },
	}
	for _, entry in kioskRing do
		local placeKey = entry.key :: PlaceTeleport.PlaceKey
		local kiosk = Instance.new("Part")
		kiosk.Name = "Teleport_" .. placeKey
		kiosk.Size = Vector3.new(10, 12, 10)
		kiosk.CFrame = CFrame.new(entry.offset + Vector3.new(0, 6, 0))
		kiosk.Anchored = true
		kiosk.Color = COLORS[placeKey] or Color3.fromRGB(0, 229, 255)
		kiosk.Material = Enum.Material.SmoothPlastic
		kiosk.Parent = parent
		addLabel(kiosk, PlaceTeleport:GetDisplayName(placeKey))
		kiosk:SetAttribute("PlaceKey", placeKey)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = PlaceTeleport:GetDisplayName(placeKey)
		prompt.ActionText = "Teleport"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0.5
		prompt.Parent = kiosk
	end
end

-- Blueprint §4.1: pure builder — สร้าง part แล้วคืน BuildResult
-- ห้ามแตะ WorldBuildState / pcall รอบตัวเอง (BuildOrchestrator เป็นเจ้าของ)
function HubWorldBuilder:Build(_ctx: WorldBuilderTypes.BuildContext?): WorldBuilderTypes.BuildResult
	if not WorldPlaceGuard:ShouldBuild("Hub") then
		return WorldBuilderTypes.skip("not this place")
	end
	if WorldPlaceGuard:ModelExists("UtopiaHubWorld") then
		return WorldBuilderTypes.skip("UtopiaHubWorld already built")
	end

	local profile = WorldBuildConfig:GetProfile("Hub")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	local model = Instance.new("Model")
	model.Name = "UtopiaHubWorld"
	model.Parent = workspace

	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, Color3.fromRGB(35, 45, 60), Enum.Material.Slate)
	WorldBuildBudget:add(budget, 1)

	local radius = WorldBuildShared:getSanctuaryRadius("Hub")
	WorldBuildShared:makeSanctuaryZone(model, radius, budget, profile)
	WorldBuildShared:addSpawn(model, "SanctuarySpawn", Vector3.new(0, 1, 0))
	WorldBuildBudget:add(budget, 1)
	WorldBuildShared:buildOrganicCanopy(CFrame.new(0, 0, 0), model, profile, budget)

	MicroCurveBuilder:fillEllipse(Vector3.new(0, 0.8, 0), radius * 0.9, radius * 0.7, 0.9, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Cyan,
		material = Enum.Material.Neon,
		parent = model,
		filled = false,
		budget = budget,
	})

	OrganicCSGBuilder:createDome(Vector3.new(-60, 10, -40), 18, {
		color = profile.Palette.Gold,
		material = Enum.Material.SmoothPlastic,
		parent = model,
		name = "MuseumDome",
	})
	ArchRibKit:Create(1, CFrame.new(55, 0, -35), { parent = model, budget = budget })

	OrganicCSGBuilder:createArch(CFrame.new(55, 0, -35), 24, 14, 2, {
		color = Color3.fromRGB(100, 200, 120),
		parent = model,
		name = "GardenArch",
	})

	addTeleportKiosks(model)
	addLoadoutTerminals(model)
	addLoadoutMirror(model)

	local fountain = Instance.new("Model")
	fountain.Name = "CentralFountain"
	fountain.Parent = model

	local pool = Instance.new("Part")
	pool.Name = "FountainPool"
	pool.Shape = Enum.PartType.Cylinder
	pool.Size = Vector3.new(1.2, 16, 16)
	pool.CFrame = CFrame.new(0, 0.6, 14) * CFrame.Angles(0, 0, math.rad(90))
	pool.Anchored = true
	pool.Color = Color3.fromRGB(40, 120, 180)
	pool.Material = Enum.Material.Glass
	pool.Transparency = 0.25
	pool.Parent = fountain

	local keyRing = Instance.new("Part")
	keyRing.Name = "PrismKeyPickup"
	keyRing.Shape = Enum.PartType.Cylinder
	keyRing.Size = Vector3.new(0.8, 6, 6)
	keyRing.CFrame = CFrame.new(0, 1.2, 14) * CFrame.Angles(0, 0, math.rad(90))
	keyRing.Anchored = true
	keyRing.Color = profile.Palette.Cyan
	keyRing.Material = Enum.Material.Neon
	keyRing.Transparency = 0.15
	keyRing:SetAttribute("PrismKeyPickupId", "hub_fountain_key_1")
	keyRing:SetAttribute("PrismKeyNumber", 1)
	keyRing:SetAttribute("GateZoneId", "CentralFountain")
	keyRing.Parent = fountain

	local pedestal = Instance.new("Part")
	pedestal.Name = "FountainPedestal"
	pedestal.Size = Vector3.new(10, 1, 10)
	pedestal.CFrame = CFrame.new(0, 0.5, 14)
	pedestal.Anchored = true
	pedestal.Color = Color3.fromRGB(55, 65, 85)
	pedestal.Material = Enum.Material.Slate
	pedestal.Parent = fountain

	local sign = Instance.new("Part")
	sign.Name = "HubSign"
	sign.Size = Vector3.new(30, 8, 2)
	sign.CFrame = CFrame.new(0, 10, -25)
	sign.Anchored = true
	sign.Color = profile.Palette.Cyan
	sign.Material = Enum.Material.Neon
	sign.Parent = model
	addLabel(sign, GameConfig.Places.Hub.name)

	local shuttleFolder = Instance.new("Folder")
	shuttleFolder.Name = "UtopiaShuttle"
	shuttleFolder.Parent = model
	ShuttleGreyboxBuilder:BuildAtSanctuary(shuttleFolder, CFrame.new(0, 0, 0))

	WorldBuildBudget:report("Hub", budget)
	print("[Utopia] Hub microcurve world built — plaza + museum + garden + kiosks")
	return WorldBuilderTypes.success(model)
end

return HubWorldBuilder
