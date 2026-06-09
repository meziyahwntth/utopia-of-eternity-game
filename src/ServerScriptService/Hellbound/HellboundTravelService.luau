--!strict
--[[
	Phase C — Playable Hellbound travel pipeline inside Death Valley greybox.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismHellboundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismHellboundConfig"))

local HellboundTravelService = {}

export type TravelState = {
	phaseIndex: number,
	phaseEndsAt: number,
	active: boolean,
	mode: string?,
}

local playerStates: { [number]: TravelState } = {}

local remotes = ReplicatedStorage:FindFirstChild("HellboundRemotes")
local travelChanged: RemoteEvent? = nil
local spectatorEvent: RemoteEvent? = nil

local function ensureRemotes()
	if remotes then
		travelChanged = remotes:FindFirstChild("TravelStateChanged") :: RemoteEvent?
		spectatorEvent = remotes:FindFirstChild("HellboundJumpSpectator") :: RemoteEvent?
		return
	end
	remotes = Instance.new("Folder")
	remotes.Name = "HellboundRemotes"
	remotes.Parent = ReplicatedStorage
	travelChanged = Instance.new("RemoteEvent")
	travelChanged.Name = "TravelStateChanged"
	travelChanged.Parent = remotes
	spectatorEvent = Instance.new("RemoteEvent")
	spectatorEvent.Name = "HellboundJumpSpectator"
	spectatorEvent.Parent = remotes
end

local function getPhase(index: number): PrismHellboundConfig.TravelPhase?
	return PrismHellboundConfig.TravelPhases[index]
end

function HellboundTravelService.buildPublicState(player: Player): { [string]: any }
	local state = playerStates[player.UserId]
	if not state or not state.active then
		return { active = false }
	end
	local phase = getPhase(state.phaseIndex)
	return {
		active = true,
		phaseIndex = state.phaseIndex,
		phaseId = if phase then phase.id else "Unknown",
		phaseName = if phase then phase.displayName else "Travel",
		phaseEndsAt = state.phaseEndsAt,
		totalPhases = #PrismHellboundConfig.TravelPhases,
		mode = state.mode,
	}
end

local function fireSpectator(mode: string?, phaseId: string)
	if spectatorEvent then
		spectatorEvent:FireAllClients({
			mode = mode,
			phaseId = phaseId,
			planet = PrismHellboundConfig.PlanetName,
		})
	end
end

local function broadcast(player: Player)
	if travelChanged then
		travelChanged:FireClient(player, HellboundTravelService.buildPublicState(player))
	end
end

local function advancePhase(player: Player)
	local state = playerStates[player.UserId]
	if not state or not state.active then
		return
	end

	state.phaseIndex += 1
	local phase = getPhase(state.phaseIndex)
	if not phase then
		state.active = false
		player:SetAttribute("HellboundTravelComplete", true)
		player:SetAttribute("HellboundArrivalReady", true)
		broadcast(player)
		return
	end

	state.phaseEndsAt = os.clock() + phase.durationSeconds
	if phase.spectatorVisible then
		fireSpectator(state.mode, phase.id)
	end
	broadcast(player)

	task.delay(phase.durationSeconds, function()
		if player.Parent and playerStates[player.UserId] == state and state.active then
			advancePhase(player)
		end
	end)
end

function HellboundTravelService.beginTravel(player: Player, mode: string?): (boolean, string)
	ensureRemotes()
	playerStates[player.UserId] = {
		phaseIndex = 0,
		phaseEndsAt = 0,
		active = true,
		mode = mode or "PublicAirplane",
	}
	player:SetAttribute("HellboundTravelComplete", false)
	advancePhase(player)
	return true, "Hellbound travel started"
end

function HellboundTravelService.skipToDock(player: Player): (boolean, string)
	ensureRemotes()
	for i, phase in PrismHellboundConfig.TravelPhases do
		if phase.id == "PeakColonyDock" then
			playerStates[player.UserId] = {
				phaseIndex = i,
				phaseEndsAt = os.clock(),
				active = false,
				mode = "StudioSkip",
			}
			player:SetAttribute("HellboundTravelComplete", true)
			player:SetAttribute("HellboundArrivalReady", true)
			broadcast(player)
			return true, "Arrived at Peak Colony"
		end
	end
	return false, "Dock phase missing"
end

function HellboundTravelService.markArrivedFromTerminal(player: Player, mode: string?)
	ensureRemotes()
	playerStates[player.UserId] = {
		phaseIndex = #PrismHellboundConfig.TravelPhases,
		phaseEndsAt = os.clock(),
		active = false,
		mode = mode or "PublicAirplane",
	}
	player:SetAttribute("HellboundTravelComplete", false)
	player:SetAttribute("HellboundArrivalFromTerminal", true)
	player:SetAttribute("HellboundAtPeakColony", true)
	broadcast(player)
end

function HellboundTravelService.onPlayerRemoving(player: Player)
	playerStates[player.UserId] = nil
end

function HellboundTravelService.init()
	ensureRemotes()
	Players.PlayerRemoving:Connect(function(player)
		HellboundTravelService.onPlayerRemoving(player)
	end)
end

return HellboundTravelService
