--!strict
--[[
	Procedural shop rental units — UtopiaPlaza (32) + EternityTower (24).
	Phase A: signage + prompts only (no inventory wall).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopRentalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopRentalConfig"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local ShopUnitKit = {}

export type KitContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame,
}

local MALL_FLOOR_H = 16
local ET_FLOOR_H = 16

local partCount = 0

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	opts: { transparency: number?, collide: boolean? }?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = if opts then opts.transparency or 0 else 0
	part.CanCollide = if opts and opts.collide ~= nil then opts.collide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	partCount += 1
	return part
end

local function addSurfaceLabel(part: BasePart, face: Enum.NormalId, text: string, name: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = name .. "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
	return label
end

local function buildOneUnit(
	district: Folder,
	ctx: KitContext,
	building: ShopRentalConfig.BuildingCode,
	floor: number,
	slot: number,
	offset: Vector3,
	floorY: number
): Model
	local palette = ctx.profile.Palette
	local roomId = ShopRentalConfig.formatRoomId(building, floor, slot)
	local zone = ShopRentalConfig.getZone(building, floor)

	local unit = Instance.new("Model")
	unit.Name = "ShopUnit_" .. roomId
	unit:SetAttribute("ShopRoomId", roomId)
	unit:SetAttribute("ShopZone", zone)
	unit:SetAttribute("ShopBuilding", building)
	unit:SetAttribute("ShopFloor", floor)
	unit:SetAttribute("ShopSlot", slot)

	local worldCf = ctx.base * CFrame.new(offset.X, floorY, offset.Z)
	local facing = CFrame.lookAt(worldCf.Position, (ctx.base * CFrame.new(0, floorY, 0)).Position)

	-- Floor pad + prompt anchor
	local pad = addPart(unit, "ShopPad", Vector3.new(6, 0.25, 5), facing * CFrame.new(0, 0.15, 2.5), palette.Pearl, Enum.Material.Marble)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopRentPrompt"
	prompt.ActionText = "เช่าร้าน / ดูร้าน"
	prompt.ObjectText = roomId
	prompt.MaxActivationDistance = 10
	prompt.Parent = pad

	-- Side dividers
	addPart(unit, "DividerL", Vector3.new(0.3, 5, 5), facing * CFrame.new(-3.2, 2.5, 0), palette.Pearl, Enum.Material.Marble)
	addPart(unit, "DividerR", Vector3.new(0.3, 5, 5), facing * CFrame.new(3.2, 2.5, 0), palette.Pearl, Enum.Material.Marble)

	-- Back wall (uses outer mall wall conceptually)
	local back = addPart(unit, "BackWall", Vector3.new(6.6, 6, 0.4), facing * CFrame.new(0, 3, -2.5), palette.Pearl, Enum.Material.Marble)

	-- Address sign
	local address = addPart(unit, "AddressSign", Vector3.new(4, 1.2, 0.2), facing * CFrame.new(0, 5.2, -2.2), palette.Gold, Enum.Material.Metal)
	addSurfaceLabel(address, Enum.NormalId.Front, roomId, "ShopAddress")

	-- Shop name sign (synced by ShopRentalService)
	local nameSign = addPart(unit, "NameSign", Vector3.new(5, 1.5, 0.2), facing * CFrame.new(0, 3.8, -2.15), palette.Cyan, Enum.Material.Neon, { transparency = 0.08 })
	local nameLabel = addSurfaceLabel(nameSign, Enum.NormalId.Front, "FOR RENT", "ShopName")
	nameLabel.TextColor3 = palette.Gold

	unit.PrimaryPart = pad
	unit.Parent = district
	return unit
end

function ShopUnitKit.addShopUnits(district: Folder, ctx: KitContext, building: ShopRentalConfig.BuildingCode): number
	partCount = 0
	local unitsFolder = Instance.new("Folder")
	unitsFolder.Name = "ShopUnits"
	unitsFolder.Parent = district

	if building == "UP" then
		for floor = 1, ShopRentalConfig.UPFloors do
			local floorY = (floor - 1) * MALL_FLOOR_H + 0.8
			for slot = 1, ShopRentalConfig.UPSlotsPerFloor do
				local offset = ShopRentalConfig.UPSlotOffsets[slot]
				buildOneUnit(unitsFolder, ctx, "UP", floor, slot, offset, floorY)
			end
		end
	else
		for floor = 1, ShopRentalConfig.ETFloors do
			local floorY = (floor - 1) * ET_FLOOR_H + 0.8
			for slot = 1, ShopRentalConfig.ETSlotsPerFloor do
				local offset = ShopRentalConfig.ETSlotOffsets[slot]
				buildOneUnit(unitsFolder, ctx, "ET", floor, slot, offset, floorY)
			end
		end
	end

	local built = partCount
	WorldBuildBudget:add(ctx.budget, built)
	print(string.format("[SHOP] %s units built parts=%d", building, built))
	district:SetAttribute("ShopUnitsBuilt", (district:GetAttribute("ShopUnitsBuilt") or 0) + built)
	return built
end

return ShopUnitKit
