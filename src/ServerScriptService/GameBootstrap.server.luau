--!strict
--[[
	Hub place bootstrap — greybox + teleport wiring order.
	BridgeBootstrap must run first (loads PlaceSecrets into GameConfig).
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Studio (local rbxlx + cloud place): block default spawn until world greybox exists.
local studioDeferSpawn = RunService:IsStudio()
if studioDeferSpawn then
	Players.CharacterAutoLoads = false
end

require(ServerScriptService:WaitForChild("BridgeBootstrap")):Apply()

local WorldBootstrap = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldBootstrap"))
local WorldStudioSpawnGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldStudioSpawnGuard"))

WorldBootstrap:BuildCurrent()

if studioDeferSpawn then
	WorldStudioSpawnGuard.start()
end

if studioDeferSpawn then
	local guard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))
	print("[Utopia] GameBootstrap Studio — PlaceId=", game.PlaceId, "placeKey=", guard:GetCurrentPlaceKey())
	WorldStudioSpawnGuard.waitForWorldReady(60)
	WorldStudioSpawnGuard.ensureEmergencyFloor()
	WorldStudioSpawnGuard.loadDeferredCharacters()
end
