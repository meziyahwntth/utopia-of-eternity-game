--!strict
--[[
	Hub greybox: Sanctuary plaza, spawn, museum shell, 4 teleport kiosks.
	Runs only when this place matches Hub id (or Hub id unset for Studio dev).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))

local HubGreyboxBuilder = {}

local COLORS = {
	Hub = Color3.fromRGB(0, 229, 255),
	Solhaven = Color3.fromRGB(255, 200, 80),
	Nocturne = Color3.fromRGB(170, 100, 255),
	EternityCity = Color3.fromRGB(255, 255, 255),
	DeathValley = Color3.fromRGB(80, 40, 100),
}

local function shouldBuildHub(): boolean
	local hubId = PlaceTeleport:GetPlaceId("Hub")
	if hubId and hubId > 0 then
		if game.PlaceId == 0 then
			local sim = GameConfig.StudioDev and GameConfig.StudioDev.SimulatePlaceKey
			return sim == nil or sim == "Hub"
		end
		return game.PlaceId == hubId
	end
	return true
end

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
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

function HubGreyboxBuilder:Build()
	if not shouldBuildHub() then
		return
	end
	if Workspace:FindFirstChild("UtopiaHubGreybox") then
		return
	end

	local model = Instance.new("Model")
	model.Name = "UtopiaHubGreybox"
	model.Parent = Workspace

	local base = makePart(
		"HubGround",
		Vector3.new(512, 1, 512),
		CFrame.new(0, 0, 0),
		Color3.fromRGB(35, 45, 60),
		Enum.Material.Slate
	)
	base.Parent = model

	local sanctuary = makePart(
		"SanctuaryZone",
		Vector3.new(GameConfig.Sanctuary.DefaultRadiusStuds * 2, 0.5, GameConfig.Sanctuary.DefaultRadiusStuds * 2),
		CFrame.new(0, 0.5, 0),
		Color3.fromRGB(0, 180, 200),
		Enum.Material.Neon
	)
	sanctuary.Transparency = 0.85
	sanctuary.CanCollide = false
	sanctuary.Parent = model

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SanctuarySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 1, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model

	local museum = makePart(
		"MuseumShell",
		Vector3.new(40, 20, 30),
		CFrame.new(-60, 10, -40),
		Color3.fromRGB(212, 175, 55),
		Enum.Material.SmoothPlastic
	)
	addLabel(museum, "Museum")
	museum.Parent = model

	local gardenGate = makePart(
		"GardenGate",
		Vector3.new(20, 14, 6),
		CFrame.new(55, 7, -35),
		Color3.fromRGB(100, 200, 120),
		Enum.Material.Grass
	)
	addLabel(gardenGate, "Garden Gate")
	gardenGate.Parent = model

	local kioskRing = {
		{ key = "Solhaven", offset = Vector3.new(70, 0, 0) },
		{ key = "Nocturne", offset = Vector3.new(0, 0, 70) },
		{ key = "EternityCity", offset = Vector3.new(-70, 0, 0) },
		{ key = "DeathValley", offset = Vector3.new(0, 0, -70) },
	}

	for _, entry in kioskRing do
		local placeKey = entry.key :: PlaceTeleport.PlaceKey
		local color = COLORS[placeKey] or COLORS.Hub
		local kiosk = makePart(
			"Teleport_" .. placeKey,
			Vector3.new(10, 12, 10),
			CFrame.new(entry.offset + Vector3.new(0, 6, 0)),
			color,
			Enum.Material.SmoothPlastic
		)
		addLabel(kiosk, PlaceTeleport:GetDisplayName(placeKey))
		kiosk:SetAttribute("PlaceKey", placeKey)
		kiosk.Parent = model

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = PlaceTeleport:GetDisplayName(placeKey)
		prompt.ActionText = "Teleport"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0.5
		prompt.Parent = kiosk
	end

	local loadoutTerminals = {
		{ mode = "loadout", offset = Vector3.new(-22, 0, 38), label = "Valley Wardrobe", color = Color3.fromRGB(120, 80, 160) },
		{ mode = "title", offset = Vector3.new(-38, 0, 38), label = "Title Registry", color = Color3.fromRGB(255, 200, 90) },
	}
	for _, entry in loadoutTerminals do
		local terminal = makePart(
			"ValleyLoadout_" .. entry.mode,
			Vector3.new(8, 10, 8),
			CFrame.new(entry.offset + Vector3.new(0, 5, 0)),
			entry.color,
			Enum.Material.Neon
		)
		addLabel(terminal, entry.label)
		terminal:SetAttribute("ValleyLoadoutTerminal", true)
		terminal:SetAttribute("LoadoutPickerMode", entry.mode)
		terminal.Parent = model
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = entry.label
		prompt.ActionText = if entry.mode == "title" then "Titles" else "Wardrobe"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.3
		prompt.Parent = terminal
	end

	local mirror = Instance.new("Model")
	mirror.Name = "ValleyLoadoutMirror"
	mirror.Parent = model
	mirror:SetAttribute("ValleyLoadoutMirror", true)
	mirror:SetAttribute("MirrorAutoRotate", true)
	mirror:SetAttribute("MirrorRotateSpeed", 0.35)
	local platform = makePart(
		"MirrorPlatform",
		Vector3.new(24, 1, 10),
		CFrame.new(0, 0.5, 52),
		Color3.fromRGB(40, 35, 55),
		Enum.Material.Glass
	)
	platform.Transparency = 0.2
	platform.Parent = mirror
	local trigger = makePart(
		"MirrorTrigger",
		Vector3.new(8, 8, 8),
		CFrame.new(0, 4, 46),
		Color3.fromRGB(120, 90, 160),
		Enum.Material.Neon
	)
	trigger.Transparency = 0.6
	trigger.CanCollide = false
	addLabel(trigger, "Valley Mirror")
	trigger.Parent = mirror
	for index, x in { -7, 0, 7 } do
		local pedestal = makePart(
			"MirrorPedestal_" .. tostring(index),
			Vector3.new(4, 0.5, 4),
			CFrame.new(x, 1.2, 52),
			Color3.fromRGB(90, 70, 120),
			Enum.Material.Neon
		)
		pedestal:SetAttribute("MirrorOffset", Vector3.new(0, 2.5, 0))
		pedestal.Parent = mirror
	end

	local sign = makePart(
		"HubSign",
		Vector3.new(30, 8, 2),
		CFrame.new(0, 10, -25),
		Color3.fromRGB(0, 229, 255),
		Enum.Material.Neon
	)
	addLabel(sign, GameConfig.Places.Hub.name)
	sign.Parent = model

	print("[Utopia] Hub greybox built — Sanctuary + 4 teleport kiosks")
end

return HubGreyboxBuilder
