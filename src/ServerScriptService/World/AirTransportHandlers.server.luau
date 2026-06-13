--!strict
-- AirTransportHandlers — BoardAirTransport RF + starter tickets on Neon
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local AirTransportService = require(script.Parent:WaitForChild("AirTransportService"))
local WorldPlaceGuard = require(script.Parent:WaitForChild("WorldPlaceGuard"))
local TravelTicketWallet = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("TravelTicketWallet"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

ensure("RemoteEvent", "ShowAirTransportUI")

local BoardTransportRF = ensure("RemoteFunction", "BoardAirTransport") :: RemoteFunction
local GetTravelTicketsRF = ensure("RemoteFunction", "GetTravelTickets") :: RemoteFunction

BoardTransportRF.OnServerInvoke = function(player: Player)
	return AirTransportService.boardTransport(player)
end

GetTravelTicketsRF.OnServerInvoke = function(player: Player)
	return TravelTicketWallet.get(player)
end

local function maybeGrantStarter(player: Player)
	if WorldPlaceGuard:GetCurrentPlaceKey() ~= "NeonUtopia" then
		return
	end
	task.wait(3)
	if TravelTicketWallet.get(player) <= 0 then
		AirTransportService.grantStarterTickets(player, 5)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		maybeGrantStarter(player)
	end)
end)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		maybeGrantStarter(player)
	end)
end

print("[World] AirTransportHandlers online")
