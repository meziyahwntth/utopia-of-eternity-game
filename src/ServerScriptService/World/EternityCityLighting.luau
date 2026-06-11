--!strict
--[[
	Eternity City ambient lighting — pearl/gold/cyan solarpunk.
	Values driven by GameConfig.CityLighting; landmark lights snap to TerrainProfile.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EternityCityLighting = {}

function EternityCityLighting.apply(model: Model, palette: { Pearl: Color3, Gold: Color3, Cyan: Color3, Twilight: Color3 })
	local cfg = GameConfig.CityLighting
	local landmarks = GameConfig.TerrainProfile.Landmarks

	local lighting = game:GetService("Lighting")
	lighting.ClockTime = cfg.ClockTime
	lighting.GeographicLatitude = cfg.GeographicLatitude
	lighting.Brightness = cfg.Brightness
	lighting.Ambient = cfg.Ambient
	lighting.OutdoorAmbient = cfg.OutdoorAmbient
	lighting.EnvironmentDiffuseScale = cfg.EnvironmentDiffuseScale
	lighting.EnvironmentSpecularScale = cfg.EnvironmentSpecularScale

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = lighting
	end
	atmosphere.Density = cfg.Atmosphere.Density
	atmosphere.Offset = cfg.Atmosphere.Offset
	atmosphere.Color = palette.Twilight
	atmosphere.Decay = palette.Cyan
	atmosphere.Glare = cfg.Atmosphere.Glare
	atmosphere.Haze = cfg.Atmosphere.Haze

	local bloom = lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = lighting
	end
	bloom.Intensity = cfg.Bloom.Intensity
	bloom.Size = cfg.Bloom.Size
	bloom.Threshold = cfg.Bloom.Threshold

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
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(1, 1, 1)
		anchor.CFrame = cf
		anchor.Name = name .. "_Anchor"
		anchor.Parent = folder

		local light = Instance.new("PointLight")
		light.Name = name
		light.Color = color
		light.Range = range
		light.Brightness = brightness
		light.Parent = anchor
	end

	for _, spec in cfg.PointLights do
		local landmark = landmarks[spec.landmarkKey]
		if landmark then
			local color = palette[spec.colorKey]
			if color then
				local pos = Vector3.new(landmark.X, landmark.Y + spec.yOffset, landmark.Z)
				addLight(spec.name, CFrame.new(pos), color, spec.range, spec.brightness)
			end
		end
	end
end

return EternityCityLighting
