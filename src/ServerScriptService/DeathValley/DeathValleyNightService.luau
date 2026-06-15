--!strict
--[[
	Night cycle — Prep → Wave → Night Survived · Phase B modifiers + expansion.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PartySizeScaling = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PartySizeScaling"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local WorldPlaceGuard = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local DeathValleyBeaconService = require(script.Parent:WaitForChild("DeathValleyBeaconService"))
local DeathValleyWraithFactory = require(script.Parent:WaitForChild("DeathValleyWraithFactory"))
local DeathValleyNightModifierService = require(script.Parent:WaitForChild("DeathValleyNightModifierService"))
local DeathValleyCheckpointService = require(script.Parent:WaitForChild("DeathValleyCheckpointService"))
local DeathValleyExpansionService = require(script.Parent:WaitForChild("DeathValleyExpansionService"))
local DeathValleyLeaderboardService = require(script.Parent:WaitForChild("DeathValleyLeaderboardService"))

local DeathValleyNightService = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local stateChanged = remotes:WaitForChild("SurvivalStateChanged") :: RemoteEvent
local nightSurvivedEvent = remotes:WaitForChild("NightSurvived") :: RemoteEvent
local wraithAlert = remotes:WaitForChild("WraithAlert") :: RemoteEvent
local ringUnlockedEvent = remotes:WaitForChild("HorizonRingUnlocked") :: RemoteEvent

local phase: PrismDeathValleySurvivalConfig.NightPhase = "prep"
local currentNight = 1
local nightsSurvived = 0
local phaseEndsAt = 0
local waveActive = false
local currentWaveSeconds = PrismDeathValleySurvivalConfig.WaveSeconds
local heartbeatConn: RBXScriptConnection? = nil
local wraithFolderParent: Instance? = nil
local lastWaveBroadcast = 0

local function getPartySize(): number
	return PartySizeScaling.countInPlace()
end

local function syncPlayerMeta()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("DV_NightsSurvived", nightsSurvived)
		player:SetAttribute("DV_CurrentNight", currentNight)
		player:SetAttribute("DV_NightPhase", phase)
		player:SetAttribute("DV_UnlockedRing", DeathValleyExpansionService.getUnlockedRing())
	end
end

function DeathValleyNightService.buildPublicState(): { [string]: any }
	local modifier = DeathValleyNightModifierService.toPublicPayload(currentNight)
	return {
		phase = phase,
		currentNight = currentNight,
		nightsSurvived = nightsSurvived,
		phaseEndsAt = phaseEndsAt,
		partySize = getPartySize(),
		beacon = DeathValleyBeaconService.snapshot(),
		activeWraiths = DeathValleyWraithFactory.getActiveCount(),
		prepSeconds = PrismDeathValleySurvivalConfig.PrepSeconds,
		waveSeconds = currentWaveSeconds,
		nightModifier = modifier,
		expansion = DeathValleyExpansionService.toPublicPayload(),
		checkpoint = DeathValleyCheckpointService.toPublicPayload(),
	}
end

local function broadcast()
	stateChanged:FireAllClients(DeathValleyNightService.buildPublicState())
	syncPlayerMeta()
end

local function applyNightModifierForWave()
	local multiplier = DeathValleyNightModifierService.getFuelDrainMultiplier(currentNight)
	DeathValleyBeaconService.setFuelDrainMultiplier(multiplier)
	currentWaveSeconds = DeathValleyNightModifierService.getWaveSeconds(currentNight)
end

local function onRingUnlocked(newRing: number, previousRing: number)
	if newRing <= previousRing then
		return
	end
	local def = PrismDeathValleySurvivalConfig.getRingDef(newRing)
	ringUnlockedEvent:FireAllClients({
		ring = newRing,
		displayName = if def then def.displayName else ("Ring " .. newRing),
	})
	wraithAlert:FireAllClients({
		kind = "RingUnlocked",
		message = string.format("Horizon Ring %d unlocked — %s", newRing, if def then def.displayName else ""),
	})
end

local function syncExpansion()
	local previousRing = DeathValleyExpansionService.getUnlockedRing()
	local newRing = DeathValleyExpansionService.syncFromNights(nightsSurvived)
	onRingUnlocked(newRing, previousRing)
end

local function beginPrep()
	phase = "prep"
	DeathValleyWraithFactory.clearAll()
	waveActive = false
	DeathValleyBeaconService.setFuelDrainMultiplier(1)
	phaseEndsAt = os.clock() + PrismDeathValleySurvivalConfig.PrepSeconds
	broadcast()
end

local function beginWave()
	if DeathValleyBeaconService.getFuel() <= 0 then
		phase = "intermission"
		phaseEndsAt = os.clock() + PrismDeathValleySurvivalConfig.IntermissionSeconds
		wraithAlert:FireAllClients({ kind = "Breach", message = "Beacon fuel empty — wraiths breach!" })
		broadcast()
		task.delay(PrismDeathValleySurvivalConfig.IntermissionSeconds, beginPrep)
		return
	end

	applyNightModifierForWave()
	local modifier = DeathValleyNightModifierService.getForNight(currentNight)

	phase = "wave"
	waveActive = true
	phaseEndsAt = os.clock() + currentWaveSeconds
	local parent = wraithFolderParent or workspace:FindFirstChild("UtopiaDeathValley") or workspace
	local spawned = DeathValleyWraithFactory.spawnWave(currentNight, parent, modifier)
	wraithAlert:FireAllClients({
		kind = "WaveStart",
		message = string.format(
			"Night %d · %s — %d wraiths",
			currentNight,
			modifier.displayName,
			spawned
		),
		night = currentNight,
		modifier = modifier.id,
	})
	broadcast()
end

local function completeWave(success: boolean)
	waveActive = false
	DeathValleyWraithFactory.clearAll()
	if success then
		nightsSurvived += 1
		currentNight += 1
		syncExpansion()
		local saved = DeathValleyCheckpointService.save(nightsSurvived, currentNight)
		nightSurvivedEvent:FireAllClients({
			nightsSurvived = nightsSurvived,
			night = currentNight - 1,
			checkpointSaved = saved ~= nil,
		})
		for _, player in Players:GetPlayers() do
			DeathValleyLeaderboardService.recordNightSurvived(player, nightsSurvived)
		end
		if saved then
			wraithAlert:FireAllClients({
				kind = "Checkpoint",
				message = string.format("Checkpoint saved — Night %d · Beacon Lv%d", saved.nightsSurvived, saved.beaconLevel),
			})
		end
	end
	phase = "intermission"
	phaseEndsAt = os.clock() + PrismDeathValleySurvivalConfig.IntermissionSeconds
	broadcast()
	task.delay(PrismDeathValleySurvivalConfig.IntermissionSeconds, beginPrep)
end

local function onHeartbeat()
	if phase ~= "wave" then
		if phase == "prep" and os.clock() >= phaseEndsAt then
			beginWave()
		end
		return
	end

	local fuelOk = DeathValleyBeaconService.drainFuel(1 / 30)
	if not fuelOk then
		completeWave(false)
		return
	end

	if os.clock() >= phaseEndsAt or DeathValleyWraithFactory.getActiveCount() == 0 then
		completeWave(true)
		return
	end

	if os.clock() - lastWaveBroadcast > 4 then
		lastWaveBroadcast = os.clock()
		broadcast()
	end
end

function DeathValleyNightService.onPlayerRemoving()
	if GameConfig.DeathValley.DifficultyDownscaleOnLeave and waveActive then
		broadcast()
	end
end

function DeathValleyNightService.applyCheckpoint(snap: DeathValleyCheckpointService.CheckpointSnapshot)
	nightsSurvived = snap.nightsSurvived
	currentNight = snap.currentNight
	DeathValleyBeaconService.restore(snap.beaconLevel, snap.beaconFuel)
	DeathValleyExpansionService.restoreRing(PrismDeathValleySurvivalConfig.getUnlockedRing(nightsSurvived))
	syncPlayerMeta()
	broadcast()
end

function DeathValleyNightService.restoreFromCheckpoint()
	local snap = DeathValleyCheckpointService.tryRestore()
	if not snap then
		return false
	end
	nightsSurvived = snap.nightsSurvived
	currentNight = snap.currentNight
	DeathValleyExpansionService.restoreRing(PrismDeathValleySurvivalConfig.getUnlockedRing(nightsSurvived))
	syncPlayerMeta()
	broadcast()
	return true
end

function DeathValleyNightService.start(parent: Instance?)
	if WorldPlaceGuard:GetCurrentPlaceKey() ~= "DeathValley" then
		return
	end
	wraithFolderParent = parent
	DeathValleyBeaconService.init()

	if parent and parent:IsA("Model") then
		DeathValleyExpansionService.bindWorld(parent)
	end

	if DeathValleyCheckpointService.hasCheckpoint() and DeathValleyNightService.restoreFromCheckpoint() then
		beginPrep()
	else
		syncExpansion()
		beginPrep()
	end

	if heartbeatConn then
		heartbeatConn:Disconnect()
	end
	heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)

	Players.PlayerRemoving:Connect(function()
		DeathValleyNightService.onPlayerRemoving()
	end)

	print("[DeathValley] Night service online — Phase C persistence + weekly boss")
end

return DeathValleyNightService
