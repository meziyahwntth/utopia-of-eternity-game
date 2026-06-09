--!strict
--[[
	Greybox Prism Hover Shuttle + Sanctuary transit stop (solarpunk reference).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local ShuttleGreyboxBuilder = {}

export type ShuttleBuild = {
	Model: Model,
	Root: BasePart,
	Seats: { VehicleSeat },
	StopCFrame: CFrame,
	DockCFrame: CFrame,
}

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function ShuttleGreyboxBuilder:BuildStop(parent: Instance, origin: CFrame): (Model, CFrame, CFrame)
	local stop = Instance.new("Model")
	stop.Name = "PrismTransitStop"
	stop.Parent = parent

	local dock = origin * CFrame.new(0, 0, -35)
	local platform = part(
		"Platform",
		Vector3.new(28, 1, 16),
		dock * CFrame.new(0, 0.5, 0),
		Color3.fromRGB(45, 50, 60),
		Enum.Material.Slate
	)
	platform.Parent = stop

	for i = -1, 1 do
		local lane = part(
			"GlowLane_" .. i,
			Vector3.new(24, 0.2, 0.8),
			dock * CFrame.new(0, 0.15, i * 4),
			Color3.fromRGB(212, 175, 55),
			Enum.Material.Neon
		)
		lane.Parent = stop
	end

	local canopy = part(
		"Canopy",
		Vector3.new(26, 1.5, 14),
		dock * CFrame.new(0, 10, 6),
		Color3.fromRGB(240, 245, 255),
		Enum.Material.SmoothPlastic
	)
	canopy.Parent = stop

	local canopyGlow = part(
		"CanopyGlow",
		Vector3.new(24, 0.4, 12),
		dock * CFrame.new(0, 9.2, 6),
		Color3.fromRGB(212, 175, 55),
		Enum.Material.Neon
	)
	canopyGlow.Transparency = 0.35
	canopyGlow.Parent = stop

	local glass = part(
		"GlassWall",
		Vector3.new(0.5, 8, 12),
		dock * CFrame.new(-8, 5, 6),
		Color3.fromRGB(0, 200, 255),
		Enum.Material.Glass
	)
	glass.Transparency = 0.45
	glass.Parent = stop

	local sign = part(
		"Sign",
		Vector3.new(12, 3, 0.5),
		dock * CFrame.new(0, 7, -2),
		Color3.fromRGB(0, 229, 255),
		Enum.Material.Neon
	)
	sign.Parent = stop

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = sign
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = GameConfig.PublicTransit.VehicleName
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Parent = sg

	return stop, dock, dock * CFrame.new(0, 4, -8)
end

function ShuttleGreyboxBuilder:BuildShuttle(parent: Instance, dockCFrame: CFrame): ShuttleBuild
	local shuttle = Instance.new("Model")
	shuttle.Name = "PrismHoverShuttle"
	shuttle.Parent = parent

	local root = part(
		"ShuttleRoot",
		Vector3.new(14, 4, 28),
		dockCFrame,
		Color3.fromRGB(235, 240, 250),
		Enum.Material.SmoothPlastic
	)
	root.Anchored = true
	root.Parent = shuttle
	shuttle.PrimaryPart = root

	local glassFront = part(
		"CockpitGlass",
		Vector3.new(12, 3.5, 0.5),
		dockCFrame * CFrame.new(0, 1.5, -13),
		Color3.fromRGB(80, 90, 110),
		Enum.Material.Glass
	)
	glassFront.Transparency = 0.35
	glassFront.Parent = shuttle

	local goldStrip = part(
		"GoldStrip",
		Vector3.new(14.2, 0.4, 28.2),
		dockCFrame * CFrame.new(0, -1.8, 0),
		Color3.fromRGB(212, 175, 55),
		Enum.Material.Neon
	)
	goldStrip.Parent = shuttle

	for _, side in { -1, 1 } do
		local ring = part(
			"HoverRing",
			Vector3.new(1.2, 3, 3),
			dockCFrame * CFrame.new(side * 7.5, 0, 0),
			Color3.fromRGB(0, 229, 255),
			Enum.Material.Neon
		)
		ring.Transparency = 0.2
		ring.Parent = shuttle
	end

	for _, child in shuttle:GetChildren() do
		if child:IsA("BasePart") and child ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = child
			weld.Parent = root
			child.Anchored = false
		end
	end

	local seats: { VehicleSeat } = {}
	local seatCount = GameConfig.PublicTransit.SeatCount
	local rows = math.ceil(seatCount / 4)
	local idx = 0
	for row = 1, rows do
		for col = 1, 4 do
			idx += 1
			if idx > seatCount then
				break
			end
			local seat = Instance.new("VehicleSeat")
			seat.Name = "Seat_" .. idx
			seat.Size = Vector3.new(2, 1, 2)
			seat.CFrame = dockCFrame
				* CFrame.new(-4.5 + (col - 1) * 3, 0.5, -8 + (row - 1) * 3.5)
			seat.Anchored = false
			seat.Disabled = false
			seat.MaxSpeed = 0
			seat.TurnSpeed = 0
			seat.Parent = shuttle
			table.insert(seats, seat)
		end
	end

	for _, seat in seats do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = seat
		weld.Parent = root
	end

	return {
		Model = shuttle,
		Root = root,
		Seats = seats,
		StopCFrame = dockCFrame,
		DockCFrame = dockCFrame,
	}
end

function ShuttleGreyboxBuilder:BuildEternityVariant(parent: Instance, origin: CFrame): ShuttleBuild
	local _stop, dock, shuttleDock = self:BuildStop(parent, origin)
	local build = self:BuildShuttle(parent, shuttleDock)

	local root = build.Root
	root.Color = Color3.fromRGB(245, 245, 250)
	root.Material = Enum.Material.SmoothPlastic

	local glassBand = Instance.new("Part")
	glassBand.Name = "GullWingGlassBand"
	glassBand.Size = Vector3.new(15, 4, 26)
	glassBand.CFrame = shuttleDock * CFrame.new(0, 2, 0)
	glassBand.Anchored = false
	glassBand.CanCollide = false
	glassBand.Transparency = 0.35
	glassBand.Color = Color3.fromRGB(0, 229, 255)
	glassBand.Material = Enum.Material.Glass
	glassBand.Parent = build.Model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = glassBand
	weld.Parent = root

	for _, side in { -1, 1 } do
		local wing = Instance.new("Part")
		wing.Name = "GullWingPanel_" .. side
		wing.Size = Vector3.new(0.4, 3, 12)
		wing.CFrame = shuttleDock * CFrame.new(side * 7.2, 2.5, 0) * CFrame.Angles(0, 0, math.rad(side * 55))
		wing.Anchored = false
		wing.CanCollide = false
		wing.Transparency = 0.25
		wing.Color = Color3.fromRGB(212, 175, 55)
		wing.Material = Enum.Material.Glass
		wing.Parent = build.Model
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = wing
		w.Parent = root
	end

	return build
end

function ShuttleGreyboxBuilder:BuildAtSanctuary(parent: Instance, origin: CFrame): ShuttleBuild
	local _stop, dock, shuttleDock = self:BuildStop(parent, origin)
	return self:BuildShuttle(parent, shuttleDock)
end

return ShuttleGreyboxBuilder
