--!strict
--[[
	Phase D — Hellbound Terminal departure from Eternity City → Death Valley.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local PrismHellboundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismHellboundConfig"))

local HellboundTravelService = require(script.Parent:WaitForChild("HellboundTravelService"))

local HellboundTerminalService = {}

local PEAK_COLONY_SPAWN = Vector3.new(-120, 5, 100)

local remotes = ReplicatedStorage:FindFirstChild("HellboundRemotes")
local spectatorEvent: RemoteEvent? = nil

local function ensureSpectatorRemote()
	if not remotes then
		remotes = ReplicatedStorage:WaitForChild("HellboundRemotes", 5)
	end
	if remotes then
		spectatorEvent = remotes:FindFirstChild("HellboundJumpSpectator") :: RemoteEvent?
	end
end

local function fireSpectator(mode: string)
	ensureSpectatorRemote()
	if spectatorEvent then
		spectatorEvent:FireAllClients({
			mode = mode,
			phaseId = "HyperspaceSpool",
			planet = PrismHellboundConfig.PlanetName,
			origin = "EternityCity",
		})
	end
end

function HellboundTerminalService.depart(player: Player, mode: string?): (boolean, string)
	local transportMode = mode or "PublicAirplane"

	-- V2 P2: เก็บค่าโดยสาร Hyper Space (ตั๋วโดยสาร) ก่อนข้ามมิติไป Hellbound
	local AirTransportService =
		require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("AirTransportService"))
	local paid, fareMsg = AirTransportService.payFareTickets(player, "UtopiaToHellbound")
	if not paid then
		player:SetAttribute("AirTransportMsg", fareMsg)
		return false, fareMsg
	end

	local deathValleyId = PlaceTeleport:GetPlaceId("DeathValley")

	fireSpectator(transportMode)

	if not deathValleyId or deathValleyId == 0 or deathValleyId == game.PlaceId then
		HellboundTravelService.beginTravel(player, transportMode)
		task.delay(PrismHellboundConfig.Hyperdrive.SpoolSeconds + 2, function()
			if not player.Parent then
				return
			end
			HellboundTravelService.markArrivedFromTerminal(player, transportMode)
			local char = player.Character
			if char then
				char:PivotTo(CFrame.new(PEAK_COLONY_SPAWN))
			end
		end)
		return true, "Local Hellbound departure — arriving at Peak Colony"
	end

	local teleportData = {
		origin = "HellboundTerminal",
		mode = transportMode,
		departedAt = os.time(),
		destination = PrismHellboundConfig.DestinationPlaceKey,
	}
	local ok, err = PlaceTeleport:TeleportPlayerWithData(player, "DeathValley", teleportData)
	if not ok then
		return false, err or "Teleport failed"
	end
	return true, "Hyperspace jump to Hellbound..."
end

function HellboundTerminalService.handleArrival(player: Player)
	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData
	if typeof(teleportData) ~= "table" then
		return
	end
	if teleportData.origin ~= "HellboundTerminal" then
		return
	end

	player:SetAttribute("HellboundArrivalFromTerminal", true)
	local mode = if typeof(teleportData.mode) == "string" then teleportData.mode else "PublicAirplane"
	HellboundTravelService.markArrivedFromTerminal(player, mode)

	task.defer(function()
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			char:PivotTo(CFrame.new(PEAK_COLONY_SPAWN))
		end
	end)
end

function HellboundTerminalService.init()
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			HellboundTerminalService.handleArrival(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.defer(function()
			HellboundTerminalService.handleArrival(player)
		end)
	end
end

return HellboundTerminalService
