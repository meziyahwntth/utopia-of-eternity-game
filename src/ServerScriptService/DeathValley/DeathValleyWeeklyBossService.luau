--!strict
--[[
	Phase C — Weekly rotating boss (Ring 3 / 20 nights).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartySizeScaling = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PartySizeScaling"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyExpansionService = require(script.Parent:WaitForChild("DeathValleyExpansionService"))

local DeathValleyWeeklyBossService = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local weeklyStateChanged = remotes:WaitForChild("WeeklyBossStateChanged") :: RemoteEvent

local bossActive = false
local bossHp = 0
local bossMaxHp = 0
local currentBossId = ""
local encounterPartyCount = 1
local participants: { [number]: boolean } = {}

function DeathValleyWeeklyBossService.getWeekId(): string
	return os.date("!%Y-W%V")
end

function DeathValleyWeeklyBossService.getBossDef(weekId: string?): PrismDeathValleySurvivalConfig.WeeklyBossDef
	local id = weekId or DeathValleyWeeklyBossService.getWeekId()
	local bosses = PrismDeathValleySurvivalConfig.WeeklyBosses
	local hash = 0
	for i = 1, #id do
		hash = (hash + string.byte(id, i) * i) % #bosses
	end
	local index = hash + 1
	return bosses[index]
end

function DeathValleyWeeklyBossService.canAccess(): boolean
	return DeathValleyExpansionService.getUnlockedRing() >= PrismDeathValleySurvivalConfig.WeeklyBossMinRing
end

function DeathValleyWeeklyBossService.buildPublicState(): { [string]: any }
	local boss = DeathValleyWeeklyBossService.getBossDef()
	return {
		weekId = DeathValleyWeeklyBossService.getWeekId(),
		bossId = if bossActive then currentBossId else boss.id,
		bossName = boss.displayName,
		bossActive = bossActive,
		bossHp = bossHp,
		bossMaxHp = bossMaxHp,
		canAccess = DeathValleyWeeklyBossService.canAccess(),
		minRing = PrismDeathValleySurvivalConfig.WeeklyBossMinRing,
		participantCount = 0,
	}
end

local function broadcast()
	weeklyStateChanged:FireAllClients(DeathValleyWeeklyBossService.buildPublicState())
end

function DeathValleyWeeklyBossService.startBoss(player: Player): (boolean, string)
	if not DeathValleyWeeklyBossService.canAccess() then
		return false, string.format("Unlock at Ring %d (20 nights survived)", PrismDeathValleySurvivalConfig.WeeklyBossMinRing)
	end
	if bossActive then
		return false, "Weekly boss already active"
	end
	if DeathValleyPlayerStore.hasWeeklyBossClear(player.UserId, DeathValleyWeeklyBossService.getWeekId()) then
		return false, "You already cleared this week's boss"
	end

	local boss = DeathValleyWeeklyBossService.getBossDef()
	encounterPartyCount = PartySizeScaling.countInPlace()
	bossMaxHp = PartySizeScaling.scaleHp(boss.baseHp, encounterPartyCount)
	bossHp = bossMaxHp
	bossActive = true
	currentBossId = boss.id
	table.clear(participants)
	participants[player.UserId] = true
	broadcast()
	return true, string.format("%s awakens — press G to strike!", boss.displayName)
end

function DeathValleyWeeklyBossService.attackBoss(player: Player): (boolean, string, number?)
	if not bossActive then
		return false, "No active weekly boss", nil
	end
	participants[player.UserId] = true
	local boss = DeathValleyWeeklyBossService.getBossDef()
	bossHp = math.max(0, bossHp - boss.damagePerHit)
	broadcast()

	if bossHp <= 0 then
		bossActive = false
		local shardReward = PartySizeScaling.scaleReward(boss.shardReward, encounterPartyCount)
		for userId, _ in participants do
			DeathValleyPlayerStore.markWeeklyBossClear(userId, DeathValleyWeeklyBossService.getWeekId())
			local p = Players:GetPlayerByUserId(userId)
			if p then
				local shards = p:GetAttribute("DV_LuminiteShards")
				if typeof(shards) ~= "number" then
					shards = 0
				end
				p:SetAttribute("DV_LuminiteShards", shards + shardReward)
				p:SetAttribute("DV_WeeklyBossCleared", DeathValleyWeeklyBossService.getWeekId())
			end
		end
		broadcast()
		return true, string.format("%s defeated! +%d Luminite shards", boss.displayName, shardReward), 0
	end
	return true, string.format("%s — %d HP left", boss.displayName, bossHp), bossHp
end

return DeathValleyWeeklyBossService
