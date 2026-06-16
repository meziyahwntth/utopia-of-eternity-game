--!strict
-- RaceHandlers (Racing) — wire remotes to RaceTrackService + init
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceTrackService = require(script.Parent:WaitForChild("RaceTrackService"))

local remotes = ReplicatedStorage:WaitForChild("RacingRemotes")
local startRace = remotes:WaitForChild("StartRace")
local checkpointPing = remotes:WaitForChild("CheckpointPing")
local getBest = remotes:WaitForChild("GetBest")

RaceTrackService.init()

local startRaceFn = startRace :: RemoteFunction
startRaceFn.OnServerInvoke = function(player, trackId)
	local ok, msg = RaceTrackService.startRun(player, trackId)
	return ok, msg
end

local pingEvent = checkpointPing :: RemoteEvent
pingEvent.OnServerEvent:Connect(function(player, trackId, index)
	RaceTrackService.checkpointReached(player, trackId, index)
end)

local getBestFn = getBest :: RemoteFunction
getBestFn.OnServerInvoke = function(player, trackId)
	return RaceTrackService.getBest(player, trackId)
end

print("[Racing] handlers online")
