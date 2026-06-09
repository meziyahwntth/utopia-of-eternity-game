--!strict
--[[
	Temporary greybox accessories until UGC meshes uploaded.
	Preview cosmetic slots with Prism palette parts.
]]
local GreyboxAccessoryFactory = {}

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
}

local SLOT_ATTACHMENT: { [string]: string } = {
	Shirt = "UpperTorso",
	Pants = "LowerTorso",
	Hat = "Head",
	Hair = "Head",
	Shoes = "LeftFoot",
	Back = "UpperTorso",
	Neck = "Head",
	Wrist = "LeftHand",
	Face = "Head",
}

function GreyboxAccessoryFactory:ClearPreview(character: Model)
	local folder = character:FindFirstChild("PrismGreyboxAccessories")
	if folder then
		folder:Destroy()
	end
end

function GreyboxAccessoryFactory:EquipPreview(character: Model, itemId: string, slot: string)
	self:ClearPreview(character)

	local attachName = SLOT_ATTACHMENT[slot] or "UpperTorso"
	local attach = character:FindFirstChild(attachName, true)
	if not attach or not attach:IsA("BasePart") then
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "PrismGreyboxAccessories"
	folder.Parent = character

	local part = Instance.new("Part")
	part.Name = "Preview_" .. itemId
	part.Size = if slot == "Back" then Vector3.new(2, 2.5, 0.4) elseif slot == "Hat" then Vector3.new(1.8, 0.6, 1.8) else Vector3.new(1.6, 1.2, 0.8)
	part.Color = PALETTE.Cyan
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = false
	part.Parent = folder

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = attach
	weld.Part1 = part
	weld.Parent = part

	if slot == "Hat" or slot == "Hair" then
		part.CFrame = attach.CFrame * CFrame.new(0, 0.6, 0)
	elseif slot == "Back" then
		part.CFrame = attach.CFrame * CFrame.new(0, 0.5, 0.7)
	elseif slot == "Shoes" then
		part.CFrame = attach.CFrame * CFrame.new(0, -0.4, 0)
	else
		part.CFrame = attach.CFrame
	end

	local tag = Instance.new("StringValue")
	tag.Name = "ItemId"
	tag.Value = itemId
	tag.Parent = part

	return part
end

return GreyboxAccessoryFactory
