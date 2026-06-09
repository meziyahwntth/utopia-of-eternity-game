--!strict
--[[
	Phase I — Client cosmetic aura / trail / badge FX from season rewards.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

local COSMETIC_ATTR = "DV_EquippedSeasonCosmetic"
local FX_FOLDER_NAME = "DV_SeasonCosmeticFx"

local function getRootPart(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function clearFx(character: Model)
	local existing = character:FindFirstChild(FX_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

local function createEmitter(parent: Instance, def: PrismDeathValleySeasonCosmetics.CosmeticFxDef, speed: number, spread: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(def.color, def.secondaryColor or def.color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new(0.35, 0)
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Rate = def.particleRate
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.Transparency = NumberSequence.new(0.2, 1)
	emitter.Parent = parent
	return emitter
end

local function applyFx(character: Model, cosmeticId: string?)
	clearFx(character)
	if not cosmeticId or cosmeticId == "" then
		return
	end
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	if not def then
		return
	end
	local root = getRootPart(character)
	if not root then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = FX_FOLDER_NAME
	folder.Parent = character

	local attachment = Instance.new("Attachment")
	attachment.Name = "DV_CosmeticAnchor"
	attachment.Parent = root

	if def.style == "aura" then
		createEmitter(attachment, def, 2, 360)
		local ring = Instance.new("ParticleEmitter")
		ring.Color = ColorSequence.new(def.color)
		ring.Size = NumberSequence.new(0.5, 0)
		ring.Lifetime = NumberRange.new(0.8, 1.2)
		ring.Rate = math.floor(def.particleRate * 0.6)
		ring.Speed = NumberRange.new(0.5, 1.5)
		ring.SpreadAngle = Vector2.new(180, 180)
		ring.EmissionDirection = Enum.NormalId.Top
		ring.LightEmission = 1
		ring.Parent = attachment
	elseif def.style == "trail" then
		createEmitter(attachment, def, 4, 25)
		local trail = Instance.new("Trail")
		trail.Color = ColorSequence.new(def.color, def.secondaryColor or def.color)
		trail.Lifetime = 0.35
		trail.MinLength = 0.1
		trail.LightEmission = 0.9
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0.8)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 1, -0.8)
		a1.Parent = root
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Parent = folder
	else
		createEmitter(attachment, def, 1, 45)
	end

	local light = Instance.new("PointLight")
	light.Color = def.color
	light.Brightness = def.lightBrightness
	light.Range = def.lightRange
	light.Parent = root
end

local function bindPlayer(target: Player)
	local function refresh()
		local character = target.Character
		if not character then
			return
		end
		local cosmeticId = target:GetAttribute(COSMETIC_ATTR)
		if typeof(cosmeticId) == "string" then
			applyFx(character, cosmeticId)
		else
			clearFx(character)
		end
	end

	target:GetAttributeChangedSignal(COSMETIC_ATTR):Connect(refresh)
	target.CharacterAdded:Connect(function()
		task.defer(refresh)
	end)
	if target.Character then
		task.defer(refresh)
	end
end

for _, target in Players:GetPlayers() do
	bindPlayer(target)
end
Players.PlayerAdded:Connect(bindPlayer)

print("[DeathValley] Season cosmetic FX ready")
