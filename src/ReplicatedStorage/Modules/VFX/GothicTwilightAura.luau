--!strict
--[[
	VFX for gothic_dark_aura — purple smoke + rare rose petal.
	Blockbench brief: docs/ugc/blockbench-briefs/03-twilight-gothic-rose.md
]]
local GothicTwilightAura = {}

local PURPLE = Color3.fromRGB(107, 45, 91)
local CRIMSON = Color3.fromRGB(139, 21, 56)

function GothicTwilightAura:Attach(character: Model): ParticleEmitter?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	local att = Instance.new("Attachment")
	att.Name = "GothicTwilightAura"
	att.Position = Vector3.new(0, -1, 0)
	att.Parent = root

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "TwilightSmoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(PURPLE, Color3.fromRGB(26, 26, 36))
	smoke.Size = NumberSequence.new(1, 2.5)
	smoke.Lifetime = NumberRange.new(1.2, 2)
	smoke.Rate = 6
	smoke.Speed = NumberRange.new(0.3, 0.8)
	smoke.SpreadAngle = Vector2.new(30, 30)
	smoke.Transparency = NumberSequence.new(0.4, 1)
	smoke.Parent = att

	local petal = Instance.new("ParticleEmitter")
	petal.Name = "RosePetal"
	petal.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	petal.Color = ColorSequence.new(CRIMSON)
	petal.Size = NumberSequence.new(0.1, 0.2)
	petal.Lifetime = NumberRange.new(0.6, 1)
	petal.Rate = 1
	petal.Speed = NumberRange.new(0.2, 0.5)
	petal.Parent = att

	local light = Instance.new("PointLight")
	light.Color = PURPLE
	light.Brightness = 0.5
	light.Range = 8
	light.Parent = root

	return smoke
end

return GothicTwilightAura
