--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EconomyGuard = {}

export type TransactionEntry = {
	timestamp: number,
	amount: number,
	reason: string,
	balanceAfter: number,
}

local transactionLogs: { [number]: { TransactionEntry } } = {}
local saveCooldowns: { [number]: number } = {}

function EconomyGuard:CanSave(userId: number): boolean
	local last = saveCooldowns[userId]
	if last and (os.clock() - last) < GameConfig.Security.SAVE_COOLDOWN then
		return false
	end
	saveCooldowns[userId] = os.clock()
	return true
end

function EconomyGuard:IsWithinCap(amount: number): boolean
	return amount >= 0 and amount <= GameConfig.MAX_UTOPIA
end

function EconomyGuard:ValidateDelta(current: number, delta: number): (boolean, number?)
	local nextAmount = current + delta
	if not self:IsWithinCap(nextAmount) then
		return false, nil
	end
	return true, nextAmount
end

function EconomyGuard:LogTransaction(userId: number, amount: number, reason: string, balanceAfter: number)
	local log = transactionLogs[userId]
	if not log then
		log = {}
		transactionLogs[userId] = log
	end
	table.insert(log, {
		timestamp = os.time(),
		amount = amount,
		reason = reason,
		balanceAfter = balanceAfter,
	})
	if #log > 100 then
		table.remove(log, 1)
	end
end

function EconomyGuard:GetLog(userId: number): { TransactionEntry }
	return transactionLogs[userId] or {}
end

function EconomyGuard:ClearPlayer(userId: number)
	transactionLogs[userId] = nil
	saveCooldowns[userId] = nil
end

return EconomyGuard
