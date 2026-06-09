--!strict
--[[
	Client: hide ground players during cloud/heaven shuttle phases for passengers.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local function setGroundHidden(hideBelowY: number)
	for _, player in Players:GetPlayers() do
		if player == localPlayer then
			continue
		end
		local char = player.Character
		if not char then
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local hide = hideBelowY > 0 and root.Position.Y < hideBelowY
		for _, desc in char:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = if hide then 1 else 0
			end
		end
	end
end

local function clearHidden()
	setGroundHidden(0)
end

local folder = ReplicatedStorage:WaitForChild("ShuttleRemotes", 30)
if not folder then
	return
end
local ev = folder:WaitForChild("ShuttlePhase", 10) :: RemoteEvent?
if not ev then
	return
end

ev.OnClientEvent:Connect(function(phase: string, _altitude: number, hideBelow: number)
	if phase == "LowCruise" or phase == "LowApproach" then
		clearHidden()
	elseif phase == "AscendCloud" or phase == "HeavenSky" or phase == "ArrivalHeaven" or phase == "Descend" then
		setGroundHidden(hideBelow)
	else
		clearHidden()
	end
end)
