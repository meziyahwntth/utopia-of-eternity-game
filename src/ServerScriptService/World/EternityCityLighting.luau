--!strict
--[[
	Eternity City ambient lighting — pearl/gold/cyan solarpunk.
]]

local EternityCityLighting = {}

function EternityCityLighting.apply(model: Model, palette: { Pearl: Color3, Gold: Color3, Cyan: Color3 })
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 16.5
	lighting.Brightness = 2.2
	lighting.Ambient = Color3.fromRGB(120, 130, 150)
	lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 170)
	lighting.EnvironmentDiffuseScale = 0.4
	lighting.EnvironmentSpecularScale = 0.6

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = lighting
	end
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = palette.Pearl
	atmosphere.Decay = palette.Cyan
	atmosphere.Glare = 0.35
	atmosphere.Haze = 1.2

	local bloom = lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = lighting
	end
	bloom.Intensity = 0.45
	bloom.Size = 18
	bloom.Threshold = 0.85

	local folder = model:FindFirstChild("EternityLighting")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "EternityLighting"
		folder.Parent = model
	end

	local function addLight(name: string, cf: CFrame, color: Color3, range: number, brightness: number)
		local existing = folder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local light = Instance.new("PointLight")
		light.Name = name
		light.Color = color
		light.Range = range
		light.Brightness = brightness
		light.Parent = Instance.new("Part")
		light.Parent.Anchored = true
		light.Parent.CanCollide = false
		light.Parent.Transparency = 1
		light.Parent.Size = Vector3.new(1, 1, 1)
		light.Parent.CFrame = cf
		light.Parent.Name = name .. "_Anchor"
		light.Parent.Parent = folder
	end

	addLight("SanctuaryGlow", CFrame.new(0, 40, 0), palette.Cyan, 280, 2)
	addLight("AuroraSpireGlow", CFrame.new(0, 80, -120), palette.Gold, 200, 1.8)
	addLight("MarinaGlow", CFrame.new(180, 20, -80), palette.Cyan, 160, 1.2)
	addLight("SkyRailGlow", CFrame.new(0, 35, -40), palette.Gold, 120, 1)
end

return EternityCityLighting
