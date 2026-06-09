--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local HeavenSkyController = {}

local saved: {
	Brightness: number,
	ClockTime: number,
	FogEnd: number,
	FogColor: Color3,
	Ambient: Color3,
}? = nil

function HeavenSkyController:SaveDefaults()
	if saved then
		return
	end
	saved = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogColor = Lighting.FogColor,
		Ambient = Lighting.Ambient,
	}
end

function HeavenSkyController:ApplyHeaven()
	self:SaveDefaults()
	Lighting.ClockTime = 7
	Lighting.Brightness = 2.8
	Lighting.FogEnd = GameConfig.HoverFlight.HeavenLayerStuds * 1.5
	Lighting.FogColor = Color3.fromRGB(200, 230, 255)
	Lighting.Ambient = Color3.fromRGB(180, 210, 255)
end

function HeavenSkyController:ApplyCloudLayer()
	self:SaveDefaults()
	Lighting.ClockTime = 8
	Lighting.Brightness = 2
	Lighting.FogEnd = GameConfig.HoverFlight.CloudLayerStuds * 0.8
	Lighting.FogColor = Color3.fromRGB(160, 190, 220)
	Lighting.Ambient = Color3.fromRGB(140, 160, 190)
end

function HeavenSkyController:ApplyLowCruise()
	self:Restore()
end

function HeavenSkyController:Restore()
	if not saved then
		return
	end
	Lighting.Brightness = saved.Brightness
	Lighting.ClockTime = saved.ClockTime
	Lighting.FogEnd = saved.FogEnd
	Lighting.FogColor = saved.FogColor
	Lighting.Ambient = saved.Ambient
end

return HeavenSkyController
