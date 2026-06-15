--!strict
-- RaceHandlers — wire Race remotes → RaceService + init
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RaceService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("RaceService"))

local remotes = ReplicatedStorage:WaitForChild("RaceRemotes")
local requestSelect = remotes:WaitForChild("RequestRaceSelect") :: RemoteFunction
local getMyRace = remotes:WaitForChild("GetMyRace") :: RemoteFunction

RaceService.init()

requestSelect.OnServerInvoke = function(player: Player, raceId: any)
	local ok, msg = RaceService.requestSelect(player, raceId)
	return ok, msg
end

getMyRace.OnServerInvoke = function(player: Player)
	return RaceService.getRace(player)
end

print("[Race] handlers online")
