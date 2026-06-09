--!strict
--[[
	Hover flight — AlignPosition-based movement with instant direction changes.
	No runway takeoff/landing arcs.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

export type HoverVehicle = {
	Root: BasePart,
	AlignPosition: AlignPosition,
	AlignOrientation: AlignOrientation,
}

local HoverFlightController = {}

function HoverFlightController:Bind(root: BasePart): HoverVehicle
	local att = root:FindFirstChild("HoverAttachment") :: Attachment?
	local ap = root:FindFirstChildOfClass("AlignPosition")
	local ao = root:FindFirstChildOfClass("AlignOrientation")
	if att and ap and ao then
		root.Anchored = false
		root.CanCollide = false
		return { Root = root, AlignPosition = ap, AlignOrientation = ao }
	end

	ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.MaxForce = 500_000
	ap.MaxVelocity = GameConfig.HoverFlight.CruiseSpeedStudsPerSecond * 2
	ap.Responsiveness = 25
	ap.ApplyAtCenterOfMass = true
	ap.Parent = root

	att = Instance.new("Attachment")
	att.Name = "HoverAttachment"
	att.Parent = root
	ap.Attachment0 = att

	ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.MaxTorque = 500_000
	ao.Responsiveness = 20
	ao.Parent = root
	ao.Attachment0 = att

	root.Anchored = false
	root.CanCollide = false

	return { Root = root, AlignPosition = ap, AlignOrientation = ao }
end

function HoverFlightController:SetTarget(vehicle: HoverVehicle, targetCFrame: CFrame)
	vehicle.AlignPosition.Position = targetCFrame.Position
	if GameConfig.HoverFlight.InstantTurn then
		vehicle.AlignOrientation.CFrame = targetCFrame
	else
		vehicle.AlignOrientation.CFrame = CFrame.new(vehicle.Root.Position, targetCFrame.Position)
	end
end

function HoverFlightController:MoveToOverSeconds(
	vehicle: HoverVehicle,
	startCFrame: CFrame,
	endCFrame: CFrame,
	durationSeconds: number
): ()
	local steps = math.max(1, math.floor(durationSeconds * 30))
	for i = 1, steps do
		if not vehicle.Root.Parent then
			return
		end
		local alpha = i / steps
		local pos = startCFrame.Position:Lerp(endCFrame.Position, alpha)
		local cf = CFrame.new(pos) * endCFrame.Rotation
		self:SetTarget(vehicle, cf)
		task.wait(durationSeconds / steps)
	end
	self:SetTarget(vehicle, endCFrame)
end

function HoverFlightController:AltitudeCFrame(base: CFrame, altitudeStuds: number): CFrame
	return CFrame.new(base.Position.X, altitudeStuds, base.Position.Z) * base.Rotation
end

function HoverFlightController:Unbind(vehicle: HoverVehicle)
	vehicle.AlignPosition:Destroy()
	vehicle.AlignOrientation:Destroy()
	local att = vehicle.Root:FindFirstChild("HoverAttachment")
	if att then
		att:Destroy()
	end
	vehicle.Root.Anchored = true
	vehicle.Root.CanCollide = true
end

return HoverFlightController
