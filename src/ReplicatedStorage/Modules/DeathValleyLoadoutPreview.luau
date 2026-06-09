--!strict
--[[
	Phase K — Shared ViewportFrame preview for loadout pickers.
	Phase L — Uses DeathValleyLoadoutVisuals.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLoadoutVisuals = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DeathValleyLoadoutVisuals"))

export type PreviewHandle = {
	setPreview: (title: string?, cosmeticId: string?) -> (),
	destroy: () -> (),
}

local DeathValleyLoadoutPreview = {}

function DeathValleyLoadoutPreview.mount(parent: GuiObject, size: UDim2, position: UDim2): PreviewHandle
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(8, 6, 14)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.new(1, 0, 0, 18)
	caption.Position = UDim2.fromOffset(0, 4)
	caption.BackgroundTransparency = 1
	caption.Font = Enum.Font.GothamBold
	caption.TextSize = 10
	caption.TextColor3 = Color3.fromRGB(150, 140, 180)
	caption.Text = "3D Preview"
	caption.Parent = frame

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -8, 1, -26)
	viewport.Position = UDim2.fromOffset(4, 22)
	viewport.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(120, 120, 140)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = frame
	Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 6)

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local camera = Instance.new("Camera")
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	local previewModel: Model? = nil

	local function clearModel()
		if previewModel then
			previewModel:Destroy()
			previewModel = nil
		end
	end

	local function setPreview(title: string?, cosmeticId: string?)
		clearModel()
		local player = Players.LocalPlayer
		local character = player.Character
		if not character then
			return
		end

		local clone = character:Clone()
		local pivot = clone:GetPivot()
		DeathValleyLoadoutVisuals.applyLoadoutToCharacter(
			clone,
			if title then title else "",
			if cosmeticId then cosmeticId else ""
		)
		clone:PivotTo(CFrame.new(0, 0, 0) * (pivot - pivot.Position))
		clone.Parent = worldModel
		previewModel = clone
		camera.CFrame = CFrame.new(Vector3.new(0, 1.8, 5.2), Vector3.new(0, 1.4, 0))
	end

	return {
		setPreview = setPreview,
		destroy = function()
			clearModel()
			frame:Destroy()
		end,
	}
end

return DeathValleyLoadoutPreview
