--!strict
--[[
	Shop rental promoter NPC — Eternity City sanctuary (Phase A).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopRentalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopRentalConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local ShopPromoterNpcKit = {}

export type PromoterContext = {
	parent: Instance,
	origin: Vector3,
	palette: any,
	budget: WorldBuildBudget.Budget?,
}

local lineIndex = 1

local function addPart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.Material = material
	part.Parent = parent
	return part
end

function ShopPromoterNpcKit.addPromoter(ctx: PromoterContext): Model
	local palette = ctx.palette
	local baseCf = CFrame.new(ctx.origin + Vector3.new(10, 0, -8))

	local model = Instance.new("Model")
	model.Name = "ShopPromoterNpc"
	model.Parent = ctx.parent

	local torso = addPart(model, "Torso", Vector3.new(2, 3, 1.2), baseCf * CFrame.new(0, 4.5, 0), palette.Pearl, Enum.Material.SmoothPlastic)
	addPart(model, "Head", Vector3.new(1.6, 1.6, 1.6), baseCf * CFrame.new(0, 6.8, 0), palette.Pearl, Enum.Material.SmoothPlastic)
	addPart(model, "LegL", Vector3.new(0.8, 2.8, 0.8), baseCf * CFrame.new(-0.5, 1.4, 0), palette.Slate, Enum.Material.SmoothPlastic)
	addPart(model, "LegR", Vector3.new(0.8, 2.8, 0.8), baseCf * CFrame.new(0.5, 1.4, 0), palette.Slate, Enum.Material.SmoothPlastic)
	addPart(model, "ArmL", Vector3.new(0.6, 2.4, 0.6), baseCf * CFrame.new(-1.4, 4.8, 0), palette.Pearl, Enum.Material.SmoothPlastic)
	addPart(model, "ArmR", Vector3.new(0.6, 2.4, 0.6), baseCf * CFrame.new(1.4, 4.8, 0), palette.Pearl, Enum.Material.SmoothPlastic)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PromoterBillboard"
	billboard.Size = UDim2.fromOffset(280, 56)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = torso

	local lineLabel = Instance.new("TextLabel")
	lineLabel.Name = "PromoterLine"
	lineLabel.Size = UDim2.fromScale(1, 1)
	lineLabel.BackgroundTransparency = 0.2
	lineLabel.BackgroundColor3 = palette.Midnight
	lineLabel.TextColor3 = palette.Gold
	lineLabel.TextScaled = true
	lineLabel.Font = Enum.Font.GothamBold
	lineLabel.Text = ShopRentalConfig.PromoterLines[1]
	lineLabel.Parent = billboard

	task.spawn(function()
		while model.Parent do
			task.wait(8)
			lineIndex = (lineIndex % #ShopRentalConfig.PromoterLines) + 1
			lineLabel.Text = ShopRentalConfig.PromoterLines[lineIndex]
		end
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPromoterPrompt"
	prompt.ActionText = "คุยกับเจ้าหน้าที่เช่าร้าน"
	prompt.ObjectText = "Shop Promoter"
	prompt.MaxActivationDistance = 12
	prompt.Parent = torso

	local ff = Instance.new("ForceField")
	ff.Visible = false
	ff.Parent = torso

	model.PrimaryPart = torso
	if ctx.budget then
		WorldBuildBudget:add(ctx.budget, 6)
	end
	return model
end

return ShopPromoterNpcKit
