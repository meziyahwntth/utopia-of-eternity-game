--!strict
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local PlaceTeleport = {}

export type PlaceKey = "Hub" | "Solhaven" | "Nocturne" | "EternityCity" | "DeathValley" | "NeonUtopia"

local KEY_TO_CONFIG: { [PlaceKey]: string } = {
	Hub = "Hub",
	Solhaven = "Solhaven",
	Nocturne = "Nocturne",
	EternityCity = "EternityCity",
	DeathValley = "DeathValley",
	NeonUtopia = "NeonUtopia",
}

function PlaceTeleport:GetPlaceId(placeKey: PlaceKey): number?
	local cfgKey = KEY_TO_CONFIG[placeKey]
	if not cfgKey then
		return nil
	end
	local places = GameConfig.Places :: any
	local entry = places[cfgKey]
	if entry and typeof(entry.id) == "number" and entry.id > 0 then
		return entry.id
	end
	return nil
end

function PlaceTeleport:GetDisplayName(placeKey: PlaceKey): string
	local cfgKey = KEY_TO_CONFIG[placeKey]
	local places = GameConfig.Places :: any
	local entry = places[cfgKey]
	return if entry then entry.name else placeKey
end

function PlaceTeleport:ListDestinations(): { PlaceKey }
	return { "Solhaven", "Nocturne", "EternityCity", "DeathValley" }
end

function PlaceTeleport:TeleportPlayer(player: Player, placeKey: PlaceKey): (boolean, string?)
	return self:TeleportPlayerWithData(player, placeKey, nil)
end

function PlaceTeleport:TeleportPlayerWithData(
	player: Player,
	placeKey: PlaceKey,
	teleportData: { [string]: any }?
): (boolean, string?)
	local placeId = self:GetPlaceId(placeKey)
	if not placeId then
		return false, "Place ID not configured — edit PlaceSecrets.luau"
	end
	if placeId == game.PlaceId then
		return false, "Already in this place"
	end
	local ok, err = pcall(function()
		if teleportData then
			local options = Instance.new("TeleportOptions")
			options:SetTeleportData(teleportData)
			TeleportService:TeleportAsync(placeId, { player }, options)
		else
			TeleportService:TeleportAsync(placeId, { player })
		end
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

return PlaceTeleport
