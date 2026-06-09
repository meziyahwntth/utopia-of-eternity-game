--!strict
--[[
	Shared Prism Key world pickups — keys 1–10 outside Eternity City, gate keys 11/15/20 inside.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local PrismKeyPickupService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PrismKeyPickupService"))

local PrismKeyPickupKit = {}

export type PickupOptions = {
	pickupId: string,
	keyNumber: number,
	position: Vector3,
	parent: Instance,
	name: string?,
}

function PrismKeyPickupKit.addPickup(opts: PickupOptions): BasePart
	local part = Instance.new("Part")
	part.Name = opts.name or ("PrismKeyPickup_" .. tostring(opts.keyNumber))
	part.Size = Vector3.new(2.4, 2.4, 2.4)
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(0, 229, 255)
	part.Transparency = 0.12
	part.CFrame = CFrame.new(opts.position)
	part:SetAttribute("PrismKeyPickupId", opts.pickupId)
	part:SetAttribute("PrismKeyNumber", opts.keyNumber)
	part.Parent = opts.parent

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = string.format("Prism Key #%d", opts.keyNumber)
	label.Parent = billboard

	PrismKeyPickupService.wirePart(part)
	return part
end

return PrismKeyPickupKit
