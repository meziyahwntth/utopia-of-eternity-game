--!strict
--[[
	VFX for coquette_soft_aura — no mesh, particle only.
	Blockbench brief: docs/ugc/blockbench-briefs/01-coquette-ribbon-dream.md
]]
local CoquetteSoftAura = {}

local PINK = Color3.fromRGB(255, 182, 193)

function CoquetteSoftAura:Attach(character: Model): ParticleEmitter?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	local att = Instance.new("Attachment")
	att.Name = "CoquetteSoftAura"
	att.Parent = root

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "SoftPinkMotes"
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(PINK)
	pe.Size = NumberSequence.new(0.15, 0.35)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rate = 8
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 0.6
	pe.Parent = att

	local light = Instance.new("PointLight")
	light.Color = PINK
	light.Brightness = 0.4
	light.Range = 6
	light.Parent = root

	return pe
end

return CoquetteSoftAura
