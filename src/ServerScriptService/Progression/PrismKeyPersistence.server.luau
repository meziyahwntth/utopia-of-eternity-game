--!strict
--[[
	P1 — Load/save Prism Key DataStore on join/leave; wire world pickups.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PrismKeyService = require(script.Parent:WaitForChild("PrismKeyService"))
local PrismKeyPickupService = require(script.Parent:WaitForChild("PrismKeyPickupService"))

local function onPlayerAdded(player: Player)
	task.spawn(function()
		PrismKeyService.hydratePlayer(player)
	end)
end

local function onPlayerRemoving(player: Player)
	PrismKeyService.persistPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

task.defer(function()
	PrismKeyPickupService.start()
end)

print("[PrismKey] Persistence + pickups ready")
