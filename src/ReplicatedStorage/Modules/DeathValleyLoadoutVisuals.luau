--!strict
--[[
	Phase L — Shared title/cosmetic visuals for preview UI and Hub mirror clones.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

local DeathValleyLoadoutVisuals = {}

function DeathValleyLoadoutVisuals.stripForDisplay(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Tool") then
			desc:Destroy()
		elseif desc:IsA("BillboardGui") and desc.Name == "DV_SeasonTitleBillboard" then
			desc:Destroy()
		elseif desc.Name == "DV_SeasonCosmeticFx" or desc.Name == "DV_MirrorNameTag" then
			desc:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

function DeathValleyLoadoutVisuals.applyTitleBillboard(character: Model, title: string)
	if title == "" then
		return
	end
	local adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not adornee or not adornee:IsA("BasePart") then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DV_SeasonTitleBillboard"
	billboard.Size = UDim2.fromOffset(220, 36)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = adornee
	billboard.Parent = character
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 215, 120)
	label.TextStrokeTransparency = 0.4
	label.Text = title
	label.Parent = billboard
end

function DeathValleyLoadoutVisuals.applyCosmeticFx(character: Model, cosmeticId: string)
	if cosmeticId == "" then
		return
	end
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	if not def then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "DV_SeasonCosmeticFx"
	folder.Parent = character
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(def.color, def.secondaryColor or def.color)
	emitter.LightEmission = 0.9
	emitter.Size = NumberSequence.new(0.4, 0)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = math.max(8, math.floor(def.particleRate * 0.5))
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Transparency = NumberSequence.new(0.15, 1)
	emitter.Parent = attachment
	local light = Instance.new("PointLight")
	light.Color = def.color
	light.Brightness = def.lightBrightness
	light.Range = def.lightRange
	light.Parent = root
end

function DeathValleyLoadoutVisuals.applyLoadoutToCharacter(character: Model, title: string?, cosmeticId: string?)
	DeathValleyLoadoutVisuals.stripForDisplay(character)
	if title and title ~= "" then
		DeathValleyLoadoutVisuals.applyTitleBillboard(character, title)
	end
	if cosmeticId and cosmeticId ~= "" then
		DeathValleyLoadoutVisuals.applyCosmeticFx(character, cosmeticId)
	end
end

function DeathValleyLoadoutVisuals.addMirrorNameTag(character: Model, displayName: string)
	local adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not adornee or not adornee:IsA("BasePart") then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DV_MirrorNameTag"
	billboard.Size = UDim2.fromOffset(180, 24)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = adornee
	billboard.Parent = character
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(200, 220, 255)
	label.TextStrokeTransparency = 0.5
	label.Text = displayName
	label.Parent = billboard
end

return DeathValleyLoadoutVisuals
