--!strict
--[[
	Category I — Griefing that ruins real player experience.
	Sanctuary violations, PvP zone abuse, co-op instance sabotage (หุบเขามรณะ).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local GriefingGuard = {}

export type GriefEvent = {
	kind: string,
	targetUserId: number?,
	detail: string,
	severity: number,
}

local sanctuaryViolations: { [number]: { count: number, lastAt: number } } = {}
local pvpKillStreak: { [number]: { victimId: number, count: number, windowStart: number } } = {}
local coOpSabotage: { [number]: { count: number, lastAt: number } } = {}

local SuspicionTracker
local SentinelStrike

function GriefingGuard:Init(deps: { SuspicionTracker: any, SentinelStrike: any })
	SuspicionTracker = deps.SuspicionTracker
	SentinelStrike = deps.SentinelStrike
end

function GriefingGuard:_apply(player: Player, event: GriefEvent)
	if not SuspicionTracker or not SentinelStrike then
		return
	end
	local score = SuspicionTracker:Add(player, event.severity, "GRIEF_" .. event.kind)
	if score >= GameConfig.Security.GRIEFING_INSTANT_BAN then
		SentinelStrike:PermanentBan(player, event.detail, "GriefingGuard:" .. event.kind)
	elseif score >= GameConfig.Security.GRIEFING_TEMP_BAN then
		SentinelStrike:TempBan(player, event.detail, GameConfig.Security.STRIKE2_BAN_SECONDS)
	elseif score >= GameConfig.Security.SUSPICION_WARN then
		SentinelStrike:Warn(player, event.detail, score)
	end
end

function GriefingGuard:RecordSanctuaryViolation(player: Player, zoneName: string)
	local cfg = GameConfig.Security
	local userId = player.UserId
	local entry = sanctuaryViolations[userId]
	local now = os.time()
	if not entry or (now - entry.lastAt) > cfg.GRIEFING_WINDOW_SECONDS then
		entry = { count = 0, lastAt = now }
		sanctuaryViolations[userId] = entry
	end
	entry.count += 1
	entry.lastAt = now
	local severity = if entry.count >= cfg.SANCTUARY_STRIKE_THRESHOLD then 80 else 35
	self:_apply(player, {
		kind = "SANCTUARY",
		detail = string.format("Sanctuary violation in %s (%d)", zoneName, entry.count),
		severity = severity,
	})
end

function GriefingGuard:RecordPvPKill(attacker: Player, victimUserId: number)
	local cfg = GameConfig.Security
	local userId = attacker.UserId
	local now = os.time()
	local entry = pvpKillStreak[userId]
	if not entry or entry.victimId ~= victimUserId or (now - entry.windowStart) > cfg.PVP_GRIEF_WINDOW_SECONDS then
		entry = { victimId = victimUserId, count = 0, windowStart = now }
		pvpKillStreak[userId] = entry
	end
	entry.count += 1
	if entry.count < cfg.PVP_SAME_VICTIM_KILL_LIMIT then
		return
	end
	self:_apply(attacker, {
		kind = "PVP_ZONE",
		targetUserId = victimUserId,
		detail = string.format("PvP grief: %d kills on same victim in window", entry.count),
		severity = 55,
	})
end

function GriefingGuard:RecordCoOpSabotage(player: Player, action: string)
	local cfg = GameConfig.Security
	local userId = player.UserId
	local entry = coOpSabotage[userId]
	local now = os.time()
	if not entry or (now - entry.lastAt) > cfg.GRIEFING_WINDOW_SECONDS then
		entry = { count = 0, lastAt = now }
		coOpSabotage[userId] = entry
	end
	entry.count += 1
	entry.lastAt = now
	local severity = if entry.count >= cfg.DEATH_VALLEY_SABOTAGE_BAN_THRESHOLD then 100 else 45
	self:_apply(player, {
		kind = "COOP_SABOTAGE",
		detail = string.format("Co-op sabotage (%s) x%d", action, entry.count),
		severity = severity,
	})
end

function GriefingGuard:RecordTradeGrief(player: Player, reason: string)
	self:_apply(player, {
		kind = "TRADE_GRIEF",
		detail = reason,
		severity = 30,
	})
end

function GriefingGuard:ClearPlayer(userId: number)
	sanctuaryViolations[userId] = nil
	pvpKillStreak[userId] = nil
	coOpSabotage[userId] = nil
end

return GriefingGuard
