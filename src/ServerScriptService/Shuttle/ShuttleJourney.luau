--!strict
--[[
	Shuttle journey state machine — cinematic hover legs between Sanctuary stops.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local HoverFlightController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HoverFlightController"))

local HeavenSkyController = require(script.Parent.HeavenSkyController)
local ShuttlePassengerManager = require(script.Parent.ShuttlePassengerManager)

local ShuttleGreyboxBuilder = require(script.Parent.Parent.ShuttleGreyboxBuilder)

export type PhaseName = "LowCruise" | "AscendCloud" | "HeavenSky" | "ArrivalHeaven" | "Descend" | "LowApproach"

local ShuttleJourney = {}

local phaseEvent: RemoteEvent?

local function getPhaseEvent(): RemoteEvent
	if phaseEvent then
		return phaseEvent
	end
	local folder = ReplicatedStorage:FindFirstChild("ShuttleRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ShuttleRemotes"
		folder.Parent = ReplicatedStorage
	end
	local ev = folder:FindFirstChild("ShuttlePhase")
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = "ShuttlePhase"
		ev.Parent = folder
	end
	phaseEvent = ev :: RemoteEvent
	return phaseEvent
end

local function firePhase(players: { Player }, phase: PhaseName, altitude: number)
	getPhaseEvent():FireAllClients(phase, altitude, GameConfig.HoverFlight.PlayerHideBelowStuds)
end

function ShuttleJourney:RunLeg(shuttle: ShuttleGreyboxBuilder.ShuttleBuild, fromPlace: ShuttlePassengerManager.PlaceKey): boolean
	local cfg = GameConfig.HoverFlight
	local transit = GameConfig.PublicTransit
	local hover = HoverFlightController
	local vehicle = hover:Bind(shuttle.Root)
	shuttle.Root.Anchored = false

	local dock = shuttle.DockCFrame
	local passengers = ShuttlePassengerManager:GetOccupants(shuttle.Seats)
	ShuttlePassengerManager:SetSeatsDisabled(shuttle.Seats, true)

	local nextPlace = ShuttlePassengerManager:GetNextPlace(fromPlace)
	if not nextPlace then
		ShuttlePassengerManager:SetSeatsDisabled(shuttle.Seats, false)
		return false
	end

	-- Phase: Low cruise — see city and players below
	HeavenSkyController:ApplyLowCruise()
	firePhase(passengers, "LowCruise", cfg.LowAltitudeStuds)
	local lowEnd = hover:AltitudeCFrame(dock, cfg.LowAltitudeStuds)
	hover:MoveToOverSeconds(vehicle, dock, lowEnd * CFrame.new(0, 0, -60), cfg.LowCruiseSeconds)

	-- Phase: Ascend to cloud layer
	HeavenSkyController:ApplyCloudLayer()
	firePhase(passengers, "AscendCloud", cfg.CloudLayerStuds)
	local cloudEnd = hover:AltitudeCFrame(lowEnd, cfg.CloudLayerStuds)
	hover:MoveToOverSeconds(vehicle, lowEnd, cloudEnd, cfg.AscendSeconds)

	-- Phase: Heaven sky
	HeavenSkyController:ApplyHeaven()
	firePhase(passengers, "HeavenSky", cfg.HeavenLayerStuds)
	local heavenEnd = hover:AltitudeCFrame(cloudEnd, cfg.HeavenLayerStuds)
	hover:MoveToOverSeconds(vehicle, cloudEnd, heavenEnd, cfg.HeavenSeconds)

	-- Cross-place teleport (passengers only; vehicle resets on this server)
	local nextId = PlaceTeleport:GetPlaceId(nextPlace)
	local teleported = false
	if nextId and nextId > 0 and nextId ~= game.PlaceId and #passengers > 0 then
		local ok, err = ShuttlePassengerManager:TeleportPartyToPlace(passengers, nextPlace)
		if ok then
			teleported = true
		else
			warn("[Utopia Shuttle] Teleport skipped:", err)
		end
	end

	if not teleported then
		-- Same-place MVP: arrival + descend back to dock
		firePhase(passengers, "ArrivalHeaven", cfg.HeavenLayerStuds)
		task.wait(cfg.ArrivalHeavenSeconds)
		firePhase(passengers, "Descend", cfg.CloudLayerStuds)
		HeavenSkyController:ApplyCloudLayer()
		hover:MoveToOverSeconds(vehicle, heavenEnd, cloudEnd, cfg.DescendSeconds)
		firePhase(passengers, "LowApproach", cfg.LowAltitudeStuds)
		HeavenSkyController:ApplyLowCruise()
		hover:MoveToOverSeconds(vehicle, cloudEnd, lowEnd, cfg.LowApproachSeconds)
		hover:MoveToOverSeconds(vehicle, lowEnd, dock, cfg.LowApproachSeconds)
	end

	HeavenSkyController:Restore()
	firePhase({}, "LowApproach", 0)
	hover:Unbind(vehicle)
	shuttle.Root.CFrame = dock
	shuttle.Root.Anchored = true
	ShuttlePassengerManager:SetSeatsDisabled(shuttle.Seats, false)

	print("[Utopia Shuttle] Leg complete:", fromPlace, "→", nextPlace, teleported and "(teleport)" or "(local loop)")
	return true
end

return ShuttleJourney
