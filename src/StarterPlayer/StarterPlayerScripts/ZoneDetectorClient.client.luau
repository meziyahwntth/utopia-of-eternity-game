--!strict
--[[
	ZoneDetectorClient — XZ proximity check → ZoneVisited remote for visit_zone quests
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ZoneConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ZoneConfig"))

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local zoneVisitedEv: RemoteEvent? = nil
task.spawn(function()
	zoneVisitedEv = remotes:WaitForChild("ZoneVisited", 10) :: RemoteEvent?
end)

local visitedThisSession: { [string]: boolean } = {}
local timeSinceCheck = 0.0

RunService.Heartbeat:Connect(function(dt)
	timeSinceCheck += dt
	if timeSinceCheck < ZoneConfig.CHECK_INTERVAL then
		return
	end
	timeSinceCheck = 0.0

	local char = localPlayer.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local playerPos = hrp.Position

	for _, zone in ZoneConfig.Zones do
		if visitedThisSession[zone.id] then
			continue
		end

		local dx = playerPos.X - zone.center.X
		local dz = playerPos.Z - zone.center.Z
		local distXZ = math.sqrt(dx * dx + dz * dz)

		if distXZ <= zone.radius then
			visitedThisSession[zone.id] = true
			if zoneVisitedEv then
				zoneVisitedEv:FireServer(zone.id)
			end
		end
	end
end)
