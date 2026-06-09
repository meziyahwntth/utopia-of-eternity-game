--!strict
--[[
	Hellbound planet travel pipeline — Eternity City → Hyperspace → Colony → หุบเขามรณะ
	Design: docs/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md
]]

export type TransportMode = "PublicAirplane" | "PrivateJet"

export type TravelPhase = {
	id: string,
	displayName: string,
	durationSeconds: number,
	spectatorVisible: boolean,
}

export type SpiritChamber = {
	index: number,
	name: string,
	walkOnly: boolean,
	particleTurrets: number,
	bulletTurrets: number,
	robotGuards: number,
	controlRoomsEmbedded: number,
}

local PrismHellboundConfig = {}

PrismHellboundConfig.PlanetName = "Hellbound"
PrismHellboundConfig.PlanetSubtitle = "มุ่งหน้าสู่ขุมนรก"

PrismHellboundConfig.DeparturePlaceKey = "EternityCity"
PrismHellboundConfig.DestinationPlaceKey = "DeathValley"
PrismHellboundConfig.TerminalZoneId = "HellboundInterstellarTerminal"

PrismHellboundConfig.Transport = {
	PublicAirplane = {
		mode = "PublicAirplane" :: TransportMode,
		displayName = "Hellbound Public Transport Airplane",
		departureIntervalSeconds = 900,
		seatCount = 40,
		requiresTicket = true,
	},
	PrivateJet = {
		mode = "PrivateJet" :: TransportMode,
		displayName = "Hellbound Private Jet",
		departureIntervalSeconds = 0,
		seatCount = 8,
		requiresTicket = false,
		robuxProductKey = "hellbound_private_jet",
	},
}

PrismHellboundConfig.Hyperdrive = {
	EngineName = "Hyperdrive",
	SpoolSeconds = 4,
	TransitSeconds = 12,
	SpeedLabel = "FTL — above light speed",
	SpectatorEventName = "HellboundJumpSpectator",
}

PrismHellboundConfig.TravelPhases = {
	{ id = "Boarding", displayName = "Boarding", durationSeconds = 30, spectatorVisible = false },
	{ id = "HyperspaceSpool", displayName = "Hyperdrive Spool", durationSeconds = 4, spectatorVisible = true },
	{ id = "HyperspaceTransit", displayName = "Hyperspace", durationSeconds = 12, spectatorVisible = true },
	{ id = "HellboundAtmosphere", displayName = "Hellbound Atmosphere", durationSeconds = 8, spectatorVisible = false },
	{ id = "LavaDescent", displayName = "Lava Descent", durationSeconds = 10, spectatorVisible = false },
	{ id = "PeakColonyDock", displayName = "Peak Colony Dock", durationSeconds = 15, spectatorVisible = false },
}

PrismHellboundConfig.PeakColony = {
	DomeName = "Hellbound Colony Barrier Dome",
	HasSanctuary = true,
	ElevatorToUndergroundSeconds = 6,
}

PrismHellboundConfig.UndermountainRail = {
	displayName = "Hellbound High-Speed Rail",
	tunnelTransitSeconds = 45,
	stationName = "Undermountain Research Rail Station",
}

PrismHellboundConfig.MilitaryBase = {
	displayName = "Undermountain Military Research Base",
	tunnelExitName = "Spirit Lock Tunnel Entry",
}

PrismHellboundConfig.SpiritChambers = {
	{
		index = 1,
		name = "Spirit Lock Chamber I — Entry Lock",
		walkOnly = true,
		particleTurrets = 8,
		bulletTurrets = 4,
		robotGuards = 12,
		controlRoomsEmbedded = 2,
	},
	{
		index = 2,
		name = "Spirit Lock Chamber II — Mid Lock",
		walkOnly = true,
		particleTurrets = 12,
		bulletTurrets = 6,
		robotGuards = 16,
		controlRoomsEmbedded = 3,
	},
	{
		index = 3,
		name = "Spirit Lock Chamber III — Final Lock",
		walkOnly = true,
		particleTurrets = 16,
		bulletTurrets = 8,
		robotGuards = 20,
		controlRoomsEmbedded = 4,
	},
}

PrismHellboundConfig.SpiritTunnelRules = {
	walkOnly = true,
	vehiclesAllowed = false,
	controlRoomWallLayer = 2,
	controlRoomIndestructible = true,
	particleWeaponPurpose = "spirit_suppression",
}

function PrismHellboundConfig.getPhase(id: string): TravelPhase?
	for _, phase in PrismHellboundConfig.TravelPhases do
		if phase.id == id then
			return phase
		end
	end
	return nil
end

return PrismHellboundConfig
