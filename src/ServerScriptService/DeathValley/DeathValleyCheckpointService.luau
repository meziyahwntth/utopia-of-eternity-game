--!strict
--[[
	Phase B/C — Session + DataStore checkpoint when Beacon Lv3+.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyBeaconService = require(script.Parent:WaitForChild("DeathValleyBeaconService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))

export type CheckpointSnapshot = {
	nightsSurvived: number,
	currentNight: number,
	beaconLevel: number,
	beaconFuel: number,
	savedAt: number,
}

local DeathValleyCheckpointService = {}

local checkpoint: CheckpointSnapshot? = nil
local serverRestored = false

function DeathValleyCheckpointService.hasCheckpoint(): boolean
	return checkpoint ~= nil
end

function DeathValleyCheckpointService.getSnapshot(): CheckpointSnapshot?
	return checkpoint
end

function DeathValleyCheckpointService.canSave(beaconLevel: number): boolean
	return beaconLevel >= PrismDeathValleySurvivalConfig.CheckpointMinBeaconLevel
end

function DeathValleyCheckpointService.save(
	nightsSurvived: number,
	currentNight: number
): CheckpointSnapshot?
	local beaconLevel = DeathValleyBeaconService.getLevel()
	if not DeathValleyCheckpointService.canSave(beaconLevel) then
		return nil
	end

	checkpoint = {
		nightsSurvived = nightsSurvived,
		currentNight = currentNight,
		beaconLevel = beaconLevel,
		beaconFuel = DeathValleyBeaconService.getFuel(),
		savedAt = os.clock(),
	}

	for _, player in Players:GetPlayers() do
		player:SetAttribute("DV_CheckpointSaved", true)
		player:SetAttribute("DV_Checkpoint_Nights", nightsSurvived)
		task.spawn(function()
			DeathValleyCheckpointService.persistForPlayer(player, checkpoint :: CheckpointSnapshot)
		end)
	end

	return checkpoint
end

function DeathValleyCheckpointService.persistForPlayer(player: Player, snap: CheckpointSnapshot)
	DeathValleyPlayerStore.updateCheckpoint(player.UserId, {
		nightsSurvived = snap.nightsSurvived,
		currentNight = snap.currentNight,
		beaconLevel = snap.beaconLevel,
		beaconFuel = snap.beaconFuel,
		savedAt = snap.savedAt,
	})
end

function DeathValleyCheckpointService.loadForPlayer(player: Player): CheckpointSnapshot?
	local data = DeathValleyPlayerStore.load(player.UserId)
	if data and data.checkpoint then
		return data.checkpoint
	end
	return nil
end

function DeathValleyCheckpointService.tryRestoreServerFromPlayer(player: Player): CheckpointSnapshot?
	if serverRestored then
		return checkpoint
	end
	local snap = DeathValleyCheckpointService.loadForPlayer(player)
	if not snap then
		return nil
	end
	if not DeathValleyCheckpointService.canSave(snap.beaconLevel) then
		return nil
	end
	checkpoint = snap
	DeathValleyBeaconService.restore(snap.beaconLevel, snap.beaconFuel)
	serverRestored = true
	player:SetAttribute("DV_CheckpointRestored", true)
	return snap
end

function DeathValleyCheckpointService.tryRestore(): CheckpointSnapshot?
	if not checkpoint then
		return nil
	end
	DeathValleyBeaconService.restore(checkpoint.beaconLevel, checkpoint.beaconFuel)
	serverRestored = true
	return checkpoint
end

function DeathValleyCheckpointService.toPublicPayload(): { [string]: any }?
	if not checkpoint then
		return nil
	end
	return {
		nightsSurvived = checkpoint.nightsSurvived,
		currentNight = checkpoint.currentNight,
		beaconLevel = checkpoint.beaconLevel,
		beaconFuel = checkpoint.beaconFuel,
		savedAt = checkpoint.savedAt,
		persisted = true,
	}
end

return DeathValleyCheckpointService
