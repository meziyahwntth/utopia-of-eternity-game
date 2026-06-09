--!strict
--[[
	Economy inflation / duping circuit breaker.
	Server-authoritative velocity limits + dump detection (Grow a Garden / trade dupe patterns).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EconomyInflationGuard = {}

export type VelocityBucket = {
	windowStart: number,
	totalIn: number,
	totalOut: number,
	txCount: number,
}

export type ItemFlowEntry = {
	itemId: string,
	userId: number,
	amount: number,
	at: number,
}

local velocity: { [number]: VelocityBucket } = {}
local itemFlows: { ItemFlowEntry } = {}
local circuitBroken: { [string]: number } = {}

local EconomyGuard
local SuspicionTracker
local SentinelStrike
local LogExportBridge

function EconomyInflationGuard:Init(deps: {
	EconomyGuard: any,
	SuspicionTracker: any,
	SentinelStrike: any,
	LogExportBridge: any?,
})
	EconomyGuard = deps.EconomyGuard
	SuspicionTracker = deps.SuspicionTracker
	SentinelStrike = deps.SentinelStrike
	LogExportBridge = deps.LogExportBridge
end

function EconomyInflationGuard:IsCircuitBroken(itemId: string): boolean
	local untilAt = circuitBroken[itemId]
	return untilAt ~= nil and untilAt > os.time()
end

function EconomyInflationGuard:_tripCircuit(itemId: string, reason: string)
	local cfg = GameConfig.Security
	circuitBroken[itemId] = os.time() + cfg.ECONOMY_CIRCUIT_BREAK_SECONDS
	warn("[EconomyInflationGuard] CIRCUIT BREAK", itemId, reason)
	if LogExportBridge then
		LogExportBridge:Enqueue("ECONOMY_CIRCUIT", { itemId = itemId, reason = reason })
	end
end

function EconomyInflationGuard:ValidateGrant(userId: number, delta: number, reason: string): (boolean, string?)
	local cfg = GameConfig.Security
	if math.abs(delta) > cfg.ECONOMY_MAX_SINGLE_DELTA then
		return false, "SINGLE_DELTA_EXCEEDED"
	end
	local bucket = velocity[userId]
	local now = os.time()
	if not bucket or (now - bucket.windowStart) > cfg.ECONOMY_VELOCITY_WINDOW_SECONDS then
		bucket = { windowStart = now, totalIn = 0, totalOut = 0, txCount = 0 }
		velocity[userId] = bucket
	end
	bucket.txCount += 1
	if delta >= 0 then
		bucket.totalIn += delta
	else
		bucket.totalOut += math.abs(delta)
	end
	if bucket.totalIn > cfg.ECONOMY_MAX_IN_PER_WINDOW then
		return false, "VELOCITY_IN_EXCEEDED"
	end
	if bucket.txCount > cfg.ECONOMY_MAX_TX_PER_WINDOW then
		return false, "TX_FREQUENCY_EXCEEDED"
	end
	if EconomyGuard then
		local ok, nextAmount = EconomyGuard:ValidateDelta(0, delta)
		if not ok then
			return false, "CAP_EXCEEDED"
		end
		EconomyGuard:LogTransaction(userId, delta, reason, nextAmount :: number)
	end
	return true, nil
end

function EconomyInflationGuard:RecordItemFlow(itemId: string, userId: number, amount: number)
	local cfg = GameConfig.Security
	table.insert(itemFlows, { itemId = itemId, userId = userId, amount = amount, at = os.time() })
	while #itemFlows > cfg.ECONOMY_FLOW_LOG_MAX do
		table.remove(itemFlows, 1)
	end
	self:_checkDumpPattern(itemId)
end

function EconomyInflationGuard:_checkDumpPattern(itemId: string)
	local cfg = GameConfig.Security
	local now = os.time()
	local sellers: { [number]: boolean } = {}
	local totalAmount = 0
	local uniqueSellers = 0
	for _, entry in itemFlows do
		if entry.itemId ~= itemId or (now - entry.at) > cfg.ECONOMY_DUMP_WINDOW_SECONDS then
			continue
		end
		totalAmount += entry.amount
		if not sellers[entry.userId] then
			sellers[entry.userId] = true
			uniqueSellers += 1
		end
	end
	if uniqueSellers >= cfg.ECONOMY_DUMP_UNIQUE_SELLERS then
		self:_tripCircuit(itemId, string.format("dump:%d sellers", uniqueSellers))
	end
	if totalAmount >= cfg.ECONOMY_DUMP_VOLUME_THRESHOLD then
		self:_tripCircuit(itemId, string.format("volume:%d", totalAmount))
	end
end

function EconomyInflationGuard:FlagPlayerInflation(player: Player, reason: string, severity: number?)
	if not SuspicionTracker or not SentinelStrike then
		return
	end
	local score = SuspicionTracker:Add(player, severity or 40, "ECON_INFLATION_" .. reason)
	if score >= GameConfig.Security.GRIEFING_INSTANT_BAN then
		SentinelStrike:PermanentBan(player, reason, "EconomyInflationGuard")
	elseif score >= GameConfig.Security.GRIEFING_TEMP_BAN then
		SentinelStrike:TempBan(player, reason, GameConfig.Security.STRIKE2_BAN_SECONDS)
	end
	if LogExportBridge then
		LogExportBridge:Enqueue("ECONOMY_FLAG", { userId = player.UserId, reason = reason, score = score })
	end
end

function EconomyInflationGuard:ClearPlayer(userId: number)
	velocity[userId] = nil
end

return EconomyInflationGuard
