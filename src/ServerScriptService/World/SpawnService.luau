--!strict
--[[
	SpawnService — ประตูเดียวของการปล่อย character (Blueprint §4.3)
	Always-on: ทำงานทั้ง Studio และ cloud (แก้ root cause C — เดิม guard
	ทำงานเฉพาะ IsStudio() และ GameBootstrap ไม่เคยคืน CharacterAutoLoads=true
	ทำให้ผู้เล่นที่ join หลัง boot ไม่ spawn เลย)

	Flow:
	  start({deferUntilReady=true})
	    → รอ WorldBuildState (ready/failed/timeout)
	    → failed/timeout: วาง emergency floor ก่อน (คนลงบน floor ไม่ตกเหว)
	    → CharacterAutoLoads = true  ← สำคัญ: ผู้เล่นอนาคต auto-load เสมอ
	    → loadDeferredCharacters()   ← ผู้เล่นที่ join ระหว่างรอ
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuildState = require(script.Parent:WaitForChild("WorldBuildState"))
local VoidRecovery = require(script.Parent:WaitForChild("VoidRecovery"))

local SpawnService = {}

local DEFAULT_READY_TIMEOUT = 60

local started = false

local function getReadyTimeout(): number
	local ok, value = pcall(function()
		local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig")) :: any
		return GameConfig.WorldBuild and GameConfig.WorldBuild.ReadyTimeoutSeconds
	end)
	if ok and typeof(value) == "number" and value > 0 then
		return value
	end
	return DEFAULT_READY_TIMEOUT
end

function SpawnService.loadDeferredCharacters()
	for _, player in Players:GetPlayers() do
		if not player.Character then
			player:LoadCharacter()
		end
	end
end

-- Respawn ผู้เล่นแบบปลอดภัย (ใช้โดย DeathValleyReviveService ผ่าน shim)
function SpawnService.respawnPlayer(player: Player)
	player:SetAttribute("DV_Downed", false)
	WorldBuildState.waitReady(15)
	VoidRecovery.ensureEmergencyFloor()

	local existing = player.Character
	if existing and existing:FindFirstChildOfClass("Humanoid") then
		VoidRecovery.recover(existing)
		return
	end

	player:LoadCharacter()
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	VoidRecovery.recover(character)
end

function SpawnService.start(opts: { deferUntilReady: boolean }?)
	if started then
		return
	end
	started = true

	local deferUntilReady = if opts then opts.deferUntilReady else true

	if deferUntilReady then
		Players.CharacterAutoLoads = false
		task.spawn(function()
			local ready = WorldBuildState.waitReady(getReadyTimeout())
			if not ready then
				warn("[SpawnService] world not ready (failed/timeout) — spawning on emergency floor")
				VoidRecovery.ensureEmergencyFloor()
			end
			Players.CharacterAutoLoads = true
			SpawnService.loadDeferredCharacters()
			print("[SpawnService] characters released — ready=", ready)
		end)
	else
		Players.CharacterAutoLoads = true
		SpawnService.loadDeferredCharacters()
	end

	local function onPlayerAddedForNeon(player: Player)
		task.spawn(function()
			local ok, WorldPlaceGuard = pcall(function()
				return require(script.Parent:WaitForChild("WorldPlaceGuard"))
			end)
			if not ok or WorldPlaceGuard:GetCurrentPlaceKey() ~= "NeonUtopia" then
				return
			end
			task.wait(5)
			local okAT, AirTransportService = pcall(function()
				return require(script.Parent:WaitForChild("AirTransportService"))
			end)
			if okAT then
				AirTransportService.grantStarterTickets(player, 5)
			end
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAddedForNeon)
	for _, player in Players:GetPlayers() do
		onPlayerAddedForNeon(player)
	end
end

return SpawnService
