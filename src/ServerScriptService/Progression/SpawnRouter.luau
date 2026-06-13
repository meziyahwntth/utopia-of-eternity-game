--!strict
--[[
	SpawnRouter — ผู้เล่นใหม่ (ยังไม่จบ Neon intro) → Teleport ไป Neon Utopia
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local SpawnRouter = {}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaSpawnRouter_v1")
end)

local memory: { [number]: boolean } = {}

local function hasCompletedNeonIntro(userId: number): boolean
	if memory[userId] ~= nil then
		return memory[userId]
	end
	if not ds then
		return false
	end
	local ok, value = pcall(function()
		return (ds :: GlobalDataStore):GetAsync("neon_intro_" .. userId)
	end)
	local done = ok and value == true
	memory[userId] = done
	return done
end

function SpawnRouter.markNeonIntroComplete(userId: number)
	memory[userId] = true
	if not ds then
		return
	end
	task.spawn(function()
		pcall(function()
			(ds :: GlobalDataStore):SetAsync("neon_intro_" .. userId, true)
		end)
	end)
end

function SpawnRouter.shouldRouteToNeon(userId: number): boolean
	if hasCompletedNeonIntro(userId) then
		return false
	end
	if WorldPlaceGuard:GetCurrentPlaceKey() == "NeonUtopia" then
		return false
	end
	local neonId = PlaceTeleport:GetPlaceId("NeonUtopia")
	return neonId ~= nil and neonId > 0
end

function SpawnRouter.tryRoutePlayer(player: Player)
	if not SpawnRouter.shouldRouteToNeon(player.UserId) then
		return
	end
	local ok, err = PlaceTeleport:TeleportPlayer(player, "NeonUtopia")
	if not ok then
		warn("[SpawnRouter] route to Neon failed:", err)
	end
end

function SpawnRouter.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			task.wait(4)
			SpawnRouter.tryRoutePlayer(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			task.wait(4)
			SpawnRouter.tryRoutePlayer(player)
		end)
	end
	print("[Progression] SpawnRouter online")
end

return SpawnRouter
