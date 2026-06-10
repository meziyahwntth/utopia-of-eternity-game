--!strict
--[[
	ShowroomVehicleDisplay — Eternity City Marina Showroom Strip — post-build hook
	- Replaces mock vehicle placeholders on VehiclePad pedestals with catalog-picked
	  block-art display vehicles.
	- Adds BillboardGui (name), ProximityPrompt "View in Shop", and Heartbeat rotation.
	- Gate: prompt visible to all players; shop itself checks canUseShop (key 15+).
	- All server-side, no Mesh asset IDs.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleMountCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VehicleMountCatalog"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local ShowroomVehicleDisplay = {}

-- ──────────────────────────────────────────────
-- Showcase vehicle selection (3 featured models)
-- ──────────────────────────────────────────────

local SHOWCASE_IDS = { "sports_car", "big_bike", "pickup_truck" }

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
-- Block-art vehicle builders per type
-- ──────────────────────────────────────────────

local function buildSportsCar(parent: Instance, palette: any)
	-- Low-profile sports car: wide body, slanted windshield, rear spoiler
	local root = Instance.new("Model")
	root.Name = "DisplayVehicle"
	root.Parent = parent

	addPart(root, "Body", Vector3.new(7, 1.6, 4),
		CFrame.new(0, 0.8, 0), palette.Steel, Enum.Material.SmoothPlastic)
	addPart(root, "Windshield", Vector3.new(3.5, 1.8, 0.4),
		CFrame.new(-0.6, 2.3, 0) * CFrame.Angles(math.rad(-25), 0, 0),
		palette.Cyan, Enum.Material.Glass, 0.35)
	addPart(root, "Spoiler", Vector3.new(2, 0.3, 4.2),
		CFrame.new(3, 2.4, 0), palette.Midnight, Enum.Material.SmoothPlastic)
	for _, wx in { -2.2, 2.2 } do
		for _, wz in { -1.4, 1.4 } do
			addPart(root, "Wheel", Vector3.new(1, 1, 1),
				CFrame.new(wx, -0.1, wz), palette.Twilight, Enum.Material.SmoothPlastic)
		end
	end
	return root
end

local function buildBigBike(parent: Instance, palette: any)
	-- Big Bike: angular body, dual headlights, fat rear tire
	local root = Instance.new("Model")
	root.Name = "DisplayVehicle"
	root.Parent = parent

	addPart(root, "Body", Vector3.new(5.5, 1.8, 2.2),
		CFrame.new(0, 1, 0), palette.Teal, Enum.Material.SmoothPlastic)
	addPart(root, "Headlight", Vector3.new(1.6, 0.6, 2.4),
		CFrame.new(-3, 1.8, 0), palette.Gold, Enum.Material.Neon, 0.1)
	addPart(root, "Seat", Vector3.new(2.5, 0.5, 2),
		CFrame.new(-0.5, 2.1, 0), palette.Slate, Enum.Material.SmoothPlastic)
	addPart(root, "RearWheel", Vector3.new(1.2, 1.2, 1.2),
		CFrame.new(2.8, -0.1, 0), palette.Twilight, Enum.Material.SmoothPlastic)
	addPart(root, "FrontWheel", Vector3.new(1.2, 1.2, 1.2),
		CFrame.new(-2.5, -0.1, 0), palette.Twilight, Enum.Material.SmoothPlastic)
	return root
end

local function buildPickupTruck(parent: Instance, palette: any)
	-- Pickup truck: tall cab, long bed, chunky wheels
	local root = Instance.new("Model")
	root.Name = "DisplayVehicle"
	root.Parent = parent

	addPart(root, "Cab", Vector3.new(3.5, 3, 3.8),
		CFrame.new(-2, 1.5, 0), palette.Slate, Enum.Material.SmoothPlastic)
	addPart(root, "Windshield", Vector3.new(3, 1.6, 0.3),
		CFrame.new(-1.5, 2.6, 0) * CFrame.Angles(math.rad(-20), 0, 0),
		palette.Cyan, Enum.Material.Glass, 0.3)
	addPart(root, "Bed", Vector3.new(5, 1.5, 3.6),
		CFrame.new(2.5, 0.8, 0), palette.Midnight, Enum.Material.SmoothPlastic)
	addPart(root, "Tailgate", Vector3.new(0.4, 1.6, 3.5),
		CFrame.new(5, 1.2, 0), palette.Slate, Enum.Material.SmoothPlastic)
	for _, wx in { -1.2, 3.8 } do
		for _, wz in { -1.3, 1.3 } do
			addPart(root, "Wheel", Vector3.new(1.2, 1.2, 1.2),
				CFrame.new(wx, -0.1, wz), palette.Twilight, Enum.Material.SmoothPlastic)
		end
	end
	return root
end

-- Map catalog id → block-art builder
local VEHICLE_BUILDERS = {
	sports_car = buildSportsCar,
	big_bike = buildBigBike,
	pickup_truck = buildPickupTruck,
}

-- ──────────────────────────────────────────────
-- BillboardGui + ProximityPrompt
-- ──────────────────────────────────────────────

local function attachDisplayGui(displayModel: Model, catalogEntry: any, palette: any)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DisplayLabel"
	billboard.Size = UDim2.fromOffset(200, 60)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = displayModel

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = palette.Gold
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = palette.Cyan
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = catalogEntry.displayName
	text.Parent = frame

	-- ProximityPrompt on the display root
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ViewInShopPrompt"
	prompt.ActionText = "View in Shop"
	prompt.ObjectText = catalogEntry.displayName
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = displayModel

	return prompt
end

-- ──────────────────────────────────────────────
-- Slow rotation via Heartbeat
-- ──────────────────────────────────────────────

local function startRotation(displayModel: Model)
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if not displayModel or not displayModel.Parent then
			connection:Disconnect()
			return
		end
		local current = displayModel:GetPivot()
		local rotated = current * CFrame.Angles(0, 0.3 * deltaTime, 0)
		displayModel:PivotTo(rotated)
	end)
end

-- ──────────────────────────────────────────────
-- Entry: setup (called from EternityCityWorldBuilder post-build)
-- ──────────────────────────────────────────────

function ShowroomVehicleDisplay.setup(model: Model)
	-- Find VehiclePad pedestals in the built world
	local pads: { BasePart } = {}
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") and child:GetAttribute("VehiclePad") == true then
			table.insert(pads, child)
		end
	end

	if #pads == 0 then
		warn("[ShowroomVehicleDisplay] No VehiclePad pedestals found")
		return
	end

	-- Sort by X position for deterministic ordering
	table.sort(pads, function(a, b) return a.Position.X < b.Position.X end)

	local palette = WorldBuildConfig:GetProfile("EternityCity").Palette

	-- Remove mock vehicle placeholder folders
	local district = pads[1]:FindFirstAncestor("MarinaShowroomStripArt")
	if district then
		for _, child in district:GetChildren() do
			if child:IsA("Folder") and child.Name:find("^DisplayVehiclePlaceholder_") then
				child:Destroy()
			end
		end
	end

	-- Build real display vehicles
	for i, pad in pads do
		if i > #SHOWCASE_IDS then break end

		local catalogId = SHOWCASE_IDS[i]
		local catalogEntry = VehicleMountCatalog.getEntry(catalogId)
		if not catalogEntry then continue end

		local builder = VEHICLE_BUILDERS[catalogId]
		if not builder then continue end

		-- Build block-art vehicle model at pedestal position
		local displayModel = builder(pad.Parent or model, palette)
		local pedPos = pad.Position
		local modelY = pedPos.Y + pad.Size.Y / 2 + 0.4
		displayModel:PivotTo(CFrame.new(pedPos.X, modelY, pedPos.Z))

		-- BillboardGui + ProximityPrompt
		local prompt = attachDisplayGui(displayModel, catalogEntry, palette)

		-- Fire OpenEternityShop to the triggering player on prompt
		local mountRemotes = ReplicatedStorage:FindFirstChild("MountRemotes")
		if mountRemotes then
			local openShopEvent = mountRemotes:FindFirstChild("OpenEternityShop")
			if openShopEvent and openShopEvent:IsA("RemoteEvent") then
				prompt.Triggered:Connect(function(player: Player)
					openShopEvent:FireClient(player)
				end)
			end
		end

		-- Slow rotation
		startRotation(displayModel)

		print(string.format("[ShowroomVehicleDisplay] %s spawned on VehiclePad[%d]", catalogEntry.displayName, i))
	end
end

return ShowroomVehicleDisplay