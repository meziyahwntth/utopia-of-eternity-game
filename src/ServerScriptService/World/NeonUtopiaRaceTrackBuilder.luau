--!strict
-- NeonUtopiaRaceTrackBuilder — start gate + checkpoint markers (Neon Grand Prix)
-- called from NeonUtopiaWorldBuilder:Build (NeonUtopia place only)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RacingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RacingConfig"))

local NeonUtopiaRaceTrackBuilder = {}

local function labelGui(parent: Instance, text: string, yOff: number, w: number)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(w, 30)
	g.StudsOffset = Vector3.new(0, yOff, 0)
	g.AlwaysOnTop = true
	g.Parent = parent
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextStrokeTransparency = 0.4
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Text = text
	l.Parent = g
end

local function makeCheckpoint(parent: Instance, trackId: string, cp, isFinish: boolean)
	local name = "RaceCheckpoint_"
	local color = Color3.fromRGB(64, 196, 224)
	local text = "CP " .. tostring(cp.index)
	if isFinish then
		name = "RaceFinish_"
		color = Color3.fromRGB(90, 230, 120)
		text = "FINISH"
	end

	local part = Instance.new("Part")
	part.Name = name .. tostring(cp.index)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.Size = Vector3.new(cp.radius * 2, 16, 2)
	part.CFrame = CFrame.lookAt(cp.position, Vector3.new(0, cp.position.Y, 0))
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.55
	part:SetAttribute(RacingConfig.CheckpointAttribute, cp.index)
	part:SetAttribute(RacingConfig.TrackIdAttribute, trackId)
	part.Parent = parent

	labelGui(part, text, 10, 70)
end

function NeonUtopiaRaceTrackBuilder.build(parent: Instance?)
	local track = RacingConfig.all()[1]
	if not track then
		return
	end
	local model = Instance.new("Model")
	model.Name = "NeonRaceTrack"
	model.Parent = parent or workspace

	local gate = Instance.new("Part")
	gate.Name = "RaceStartGate"
	gate.Anchored = true
	gate.CanCollide = false
	gate.CanTouch = false
	gate.Size = Vector3.new(track.checkpointRadius * 2, 18, 2)
	gate.CFrame = CFrame.lookAt(track.startPosition, track.startLookAt)
	gate.Material = Enum.Material.Neon
	gate.Color = Color3.fromRGB(240, 210, 90)
	gate.Transparency = 0.4
	gate:SetAttribute("RaceStartTrackId", track.id)
	gate.Parent = model
	labelGui(gate, "Race: " .. track.name, 11, 170)

	local n = #track.checkpoints
	for i = 1, n do
		makeCheckpoint(model, track.id, track.checkpoints[i], i == n)
	end

	print("[Racing] Neon Grand Prix track built - " .. tostring(n) .. " checkpoints")
end

return NeonUtopiaRaceTrackBuilder
