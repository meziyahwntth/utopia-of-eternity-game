--!strict
--[[
	Mega Dungeon zones 1–5 — shared handlers via DungeonZoneRuntime.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DungeonContributionChecker = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DungeonContributionChecker"))
local DungeonLoadoutCalculator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DungeonLoadoutCalculator"))
local PrismDeathValleyDungeonConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleyDungeonConfig"))

local DungeonZoneRuntime = require(script.Parent:WaitForChild("DungeonZoneRuntime"))
local LoadoutService = require(script.Parent:WaitForChild("DungeonLoadoutService"))
local PrismKeyService = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("PrismKeyService"))

-- Rate limiter สำหรับป้องกัน healChannelComplete spam
local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))
local HEAL_RATE = { maxTokens = 5, refillPerSecond = 0.25 } -- max 5 heals burst, ~15/min

local remotes = ReplicatedStorage:WaitForChild("DungeonRemotes")
local enterZone = remotes:WaitForChild("EnterZone") :: RemoteFunction
local startBoss = remotes:WaitForChild("StartBoss") :: RemoteFunction
local healAlly = remotes:WaitForChild("HealAlly") :: RemoteFunction
local recordAssist = remotes:WaitForChild("RecordAssist") :: RemoteFunction
local zoneStateChanged = remotes:WaitForChild("ZoneStateChanged") :: RemoteEvent
local healChannelComplete = remotes:WaitForChild("HealChannelComplete") :: RemoteEvent

local DEFAULT_DAMAGE = 15

local runtimes: { [string]: DungeonZoneRuntime.ZoneRuntime } = {}

for _, zoneDef in PrismDeathValleyDungeonConfig.Zones do
	runtimes[zoneDef.id] = DungeonZoneRuntime.create(zoneDef)
end

local function getRuntime(zoneId: string): DungeonZoneRuntime.ZoneRuntime?
	return runtimes[zoneId]
end

local function grantKey(player: Player, zoneId: string, zoneIndex: number): (boolean, string)
	return PrismKeyService.grantZoneKey(player, zoneId, zoneIndex)
end

local function broadcastState(runtime: DungeonZoneRuntime.ZoneRuntime)
	zoneStateChanged:FireAllClients(DungeonZoneRuntime.buildPublicState(runtime))
end

local function broadcastPersonalClear(
	runtime: DungeonZoneRuntime.ZoneRuntime,
	player: Player,
	keyGranted: boolean,
	keyMessage: string?,
	contributionMet: boolean
)
	local role = player:GetAttribute("DungeonRole")
	local state = runtime.zonePlayers[player.UserId]
	local progress = if typeof(role) == "string" and state
		then DungeonContributionChecker.getProgress(role, state)
		else nil

	zoneStateChanged:FireClient(player, {
		zoneId = runtime.zoneDef.id,
		displayName = runtime.zoneDef.displayName,
		bossCleared = runtime.bossCleared,
		bossActive = runtime.bossActive,
		myKeyGranted = keyGranted,
		myKeyMessage = keyMessage,
		contributionMet = contributionMet,
		contributionProgress = progress,
		prismKeyCount = PrismKeyService.getKeyCount(player),
	})
end

enterZone.OnServerInvoke = function(player: Player, zoneId: string)
	local runtime = getRuntime(zoneId)
	if not runtime then
		return { ok = false, message = "Unknown zone" }
	end
	local hasLoadout, err = LoadoutService.requireLoadout(player)
	if not hasLoadout then
		return { ok = false, message = err }
	end
	if runtime.zonePlayers[player.UserId] then
		return {
			ok = true,
			message = "Already in zone",
			playerCount = #DungeonZoneRuntime.getPlayersInZone(runtime),
			zone = runtime.zoneDef,
		}
	end

	DungeonZoneRuntime.initContribution(runtime, player)
	broadcastState(runtime)
	return {
		ok = true,
		message = "Entered " .. runtime.zoneDef.displayName,
		playerCount = #DungeonZoneRuntime.getPlayersInZone(runtime),
		zone = runtime.zoneDef,
	}
end

startBoss.OnServerInvoke = function(player: Player, zoneId: string)
	local runtime = getRuntime(zoneId)
	if not runtime then
		return { ok = false, message = "Unknown zone" }
	end
	if not runtime.zonePlayers[player.UserId] then
		return { ok = false, message = "Enter the zone first" }
	end
	if runtime.bossActive then
		return { ok = false, message = "Boss already active" }
	end
	if runtime.bossCleared then
		return { ok = false, message = "Boss already cleared" }
	end

	local zoneDef = runtime.zoneDef
	local count = DungeonZoneRuntime.getPartyCount(runtime)
	if count < zoneDef.minToEnterBoss then
		return {
			ok = false,
			message = string.format("Need %d players (have %d)", zoneDef.minToEnterBoss, count),
		}
	end

	runtime.bossActive = true
	DungeonZoneRuntime.prepareBossEncounter(runtime)
	broadcastState(runtime)

	local canWin = count >= zoneDef.minToSucceed
	return {
		ok = true,
		message = if canWin
			then string.format("%s engaged — press F to attack!", zoneDef.bossName)
			else string.format("Engaged with %d/%d — defeat won't count", count, zoneDef.minToSucceed),
		canSucceed = canWin,
		bossHp = runtime.bossHp,
		bossMaxHp = runtime.bossMaxHp,
	}
end

healAlly.OnServerInvoke = function(player: Player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return { ok = false, message = "Invalid target" }
	end
	local zoneId = player:GetAttribute("DungeonZoneId")
	if typeof(zoneId) ~= "string" then
		return { ok = false, message = "Not in zone" }
	end
	local runtime = getRuntime(zoneId)
	if not runtime or not runtime.zonePlayers[player.UserId] then
		return { ok = false, message = "Not in zone" }
	end

	local loadout = LoadoutService.getLoadout(player)
	if not loadout or not DungeonLoadoutCalculator.canHeal(loadout) then
		return { ok = false, message = "Cannot heal with this loadout" }
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or not runtime.zonePlayers[target.UserId] then
		return { ok = false, message = "Target not in zone" }
	end
	if target == player then
		return { ok = false, message = "Heal a teammate" }
	end

	local char = player.Character
	local targetChar = target.Character
	if not char or not targetChar or not char:FindFirstChild("HumanoidRootPart") or not targetChar:FindFirstChild("HumanoidRootPart") then
		return { ok = false, message = "Character missing" }
	end
	local dist = (char.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
	if dist > 18 then
		return { ok = false, message = "Move closer to ally" }
	end

	return {
		ok = true,
		message = "Channel started",
		channelSeconds = DungeonLoadoutCalculator.getHealChannelSeconds(loadout),
		slowPercent = DungeonLoadoutCalculator.getHealSlowPercent(loadout),
		targetUserId = targetUserId,
	}
end

healChannelComplete.OnServerEvent:Connect(function(player: Player, targetUserId: number)
	-- Rate limit: ป้องกัน client spam heal ไม่จำกัด
	if not RateLimiter:TryConsume(player, "HealChannelComplete", HEAL_RATE) then
		return
	end
	if typeof(targetUserId) ~= "number" then
		return
	end
	local zoneId = player:GetAttribute("DungeonZoneId")
	if typeof(zoneId) ~= "string" then
		return
	end
	local runtime = getRuntime(zoneId)
	local state = runtime and runtime.zonePlayers[player.UserId]
	if not state then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or not runtime.zonePlayers[target.UserId] then
		return
	end

	state.healCount += 1
	DungeonZoneRuntime.syncContributionAttributes(player, state)

	local hum = target:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = math.min(hum.MaxHealth, hum.Health + 15)
	end
end)

recordAssist.OnServerInvoke = function(player: Player, assistType: string)
	if typeof(assistType) ~= "string" then
		return { ok = false }
	end
	local zoneId = player:GetAttribute("DungeonZoneId")
	if typeof(zoneId) ~= "string" then
		return { ok = false, message = "Not in zone" }
	end
	local runtime = getRuntime(zoneId)
	local state = runtime and runtime.zonePlayers[player.UserId]
	if not runtime or not state then
		return { ok = false, message = "Not in zone" }
	end

	if assistType == "attack" then
		if runtime.bossActive then
			local loadout = LoadoutService.getLoadout(player)
			local damagePerHit = runtime.zoneDef.damagePerAssistHit or DEFAULT_DAMAGE
			local won = DungeonZoneRuntime.applyBossDamage(runtime, player, state, loadout, damagePerHit)
			if won then
				runtime.bossActive = false
				runtime.bossCleared = true
				runtime.bossHp = 0
				runtime.lastOutcomeMessage = nil
				for _, p in DungeonZoneRuntime.getPlayersInZone(runtime) do
					local pState = runtime.zonePlayers[p.UserId]
					local role = p:GetAttribute("DungeonRole")
					local contributionMet = true
					local contributionReason: string? = nil
					if typeof(role) == "string" and pState then
						contributionMet, contributionReason = DungeonContributionChecker.meetsThreshold(role, pState)
					end
					local granted = false
					local message = contributionReason or "Contribution not met"
					if contributionMet then
						granted, message = grantKey(p, runtime.zoneDef.id, runtime.zoneDef.zoneIndex)
						DungeonZoneRuntime.grantShardReward(p, runtime.scaledShardReward)
					end
					p:SetAttribute("DungeonZone" .. runtime.zoneDef.zoneIndex .. "Cleared", true)
					broadcastPersonalClear(runtime, p, granted, message, contributionMet)
				end
			elseif runtime.bossHp <= 0 then
				DungeonZoneRuntime.finishBoss(runtime, false, grantKey)
			end
			broadcastState(runtime)
		else
			state.assistCount += 1
			DungeonZoneRuntime.syncContributionAttributes(player, state)
		end
	elseif assistType == "ammo" then
		state.ammoTransferCount += 1
		DungeonZoneRuntime.syncContributionAttributes(player, state)
	elseif assistType == "grenade" then
		state.grenadeCount += 1
		DungeonZoneRuntime.syncContributionAttributes(player, state)
	end

	local role = player:GetAttribute("DungeonRole")
	local progress = nil
	if typeof(role) == "string" then
		progress = DungeonContributionChecker.getProgress(role, state)
	end

	return {
		ok = true,
		counts = state,
		bossHp = runtime.bossHp,
		bossActive = runtime.bossActive,
		bossMaxHp = runtime.bossMaxHp,
		contributionProgress = progress,
	}
end

Players.PlayerRemoving:Connect(function(player)
	for _, runtime in runtimes do
		if runtime.zonePlayers[player.UserId] then
			DungeonZoneRuntime.clearContribution(runtime, player)
			broadcastState(runtime)
		end
	end
end)

print("[Dungeon] Mega zone handlers online — zones 1–5")
