--!strict
--[[
	TradingService (P4) — P2P trade window: propose → lock → confirm → execute (server-authoritative)
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemTierConfig"))
local PlayerItemStore = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))
local WeightService = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("WeightService"))
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))

local remotesFolder = ReplicatedStorage:WaitForChild("CommerceRemotes")

local TradingService = {}

export type TradeOffer = { [string]: number }

export type TradeSideState = {
	userId: number,
	offer: TradeOffer,
	creditOffer: number,
	locked: boolean,
	confirmed: boolean,
}

export type TradeSession = {
	id: string,
	a: TradeSideState,
	b: TradeSideState,
	state: "open" | "executed" | "cancelled",
}

local sessions: { [string]: TradeSession } = {}
local sessionByUser: { [number]: string } = {}

local function sideFor(session: TradeSession, userId: number): TradeSideState?
	if session.a.userId == userId then
		return session.a
	end
	if session.b.userId == userId then
		return session.b
	end
	return nil
end

local function otherSide(session: TradeSession, userId: number): TradeSideState?
	if session.a.userId == userId then
		return session.b
	end
	if session.b.userId == userId then
		return session.a
	end
	return nil
end

local function cloneOffer(offer: TradeOffer): TradeOffer
	local copy: TradeOffer = {}
	for id, qty in offer do
		copy[id] = qty
	end
	return copy
end

local function publish(session: TradeSession)
	local ev = remotesFolder:FindFirstChild("TradeSessionUpdate")
	if ev and ev:IsA("RemoteEvent") then
		local payload = {
			sessionId = session.id,
			state = session.state,
			a = {
				userId = session.a.userId,
				offer = cloneOffer(session.a.offer),
				creditOffer = session.a.creditOffer,
				locked = session.a.locked,
				confirmed = session.a.confirmed,
			},
			b = {
				userId = session.b.userId,
				offer = cloneOffer(session.b.offer),
				creditOffer = session.b.creditOffer,
				locked = session.b.locked,
				confirmed = session.b.confirmed,
			},
		}
		local tradeEv = ev :: RemoteEvent
		local playerA = Players:GetPlayerByUserId(session.a.userId)
		local playerB = Players:GetPlayerByUserId(session.b.userId)
		if playerA then
			tradeEv:FireClient(playerA, payload)
		end
		if playerB then
			tradeEv:FireClient(playerB, payload)
		end
	end
end

local function validateOffer(userId: number, offer: TradeOffer): (boolean, string?)
	for itemId, qty in offer do
		if typeof(qty) ~= "number" or qty <= 0 or math.floor(qty) ~= qty then
			return false, "invalid_qty"
		end
		if not ItemTierConfig.get(itemId) then
			return false, "unknown_item"
		end
		local def = ItemTierConfig.get(itemId)
		if def and not def.tradeable then
			return false, "not_tradeable"
		end
		if PlayerItemStore.getQty(userId, itemId) < qty then
			return false, "insufficient_items"
		end
	end
	return true, nil
end

local function validateCreditOffer(userId: number, amount: number): (boolean, string?)
	if amount < 0 or math.floor(amount) ~= amount then
		return false, "invalid_credits"
	end
	if amount == 0 then
		return true, nil
	end
	if CurrencyService.getBalance(userId) < amount then
		return false, "insufficient_credits"
	end
	return true, nil
end

local function cancelSession(sessionId: string, reason: string)
	local session = sessions[sessionId]
	if not session or session.state ~= "open" then
		return
	end
	session.state = "cancelled"
	sessionByUser[session.a.userId] = nil
	sessionByUser[session.b.userId] = nil
	publish(session)
	warn("[Trading] cancelled", sessionId, reason)
end

function TradingService.getSessionForUser(userId: number): TradeSession?
	local id = sessionByUser[userId]
	if not id then
		return nil
	end
	return sessions[id]
end

function TradingService.startSession(initiator: Player, partnerUserId: number): (boolean, string | TradeSession)
	if partnerUserId == initiator.UserId then
		return false, "self_trade"
	end
	if sessionByUser[initiator.UserId] then
		return false, "already_in_trade"
	end
	if sessionByUser[partnerUserId] then
		return false, "partner_busy"
	end
	local partner = Players:GetPlayerByUserId(partnerUserId)
	if not partner then
		return false, "partner_left"
	end

	local session: TradeSession = {
		id = HttpService:GenerateGUID(false),
		a = {
			userId = initiator.UserId,
			offer = {},
			creditOffer = 0,
			locked = false,
			confirmed = false,
		},
		b = {
			userId = partnerUserId,
			offer = {},
			creditOffer = 0,
			locked = false,
			confirmed = false,
		},
		state = "open",
	}
	sessions[session.id] = session
	sessionByUser[initiator.UserId] = session.id
	sessionByUser[partnerUserId] = session.id
	publish(session)
	return true, session
end

function TradingService.updateOffer(player: Player, offer: TradeOffer): (boolean, string)
	local session = TradingService.getSessionForUser(player.UserId)
	if not session or session.state ~= "open" then
		return false, "no_session"
	end
	local side = sideFor(session, player.UserId)
	if not side or side.locked then
		return false, "locked"
	end
	local ok, err = validateOffer(player.UserId, offer)
	if not ok then
		return false, err or "invalid_offer"
	end
	side.offer = cloneOffer(offer)
	side.confirmed = false
	local other = otherSide(session, player.UserId)
	if other then
		other.confirmed = false
	end
	publish(session)
	return true, "ok"
end

function TradingService.updateCreditOffer(player: Player, amount: number): (boolean, string)
	local session = TradingService.getSessionForUser(player.UserId)
	if not session or session.state ~= "open" then
		return false, "no_session"
	end
	local side = sideFor(session, player.UserId)
	if not side or side.locked then
		return false, "locked"
	end
	local ok, err = validateCreditOffer(player.UserId, amount)
	if not ok then
		return false, err or "invalid_credits"
	end
	side.creditOffer = amount
	side.confirmed = false
	local other = otherSide(session, player.UserId)
	if other then
		other.confirmed = false
	end
	publish(session)
	return true, "ok"
end

function TradingService.lockOffer(player: Player): (boolean, string)
	local session = TradingService.getSessionForUser(player.UserId)
	if not session or session.state ~= "open" then
		return false, "no_session"
	end
	local side = sideFor(session, player.UserId)
	if not side then
		return false, "no_side"
	end
	local ok, err = validateOffer(player.UserId, side.offer)
	if not ok then
		return false, err or "invalid_offer"
	end
	local creditOk, creditErr = validateCreditOffer(player.UserId, side.creditOffer)
	if not creditOk then
		return false, creditErr or "invalid_credits"
	end
	side.locked = true
	side.confirmed = false
	publish(session)
	return true, "locked"
end

function TradingService.confirmTrade(player: Player): (boolean, string)
	local session = TradingService.getSessionForUser(player.UserId)
	if not session or session.state ~= "open" then
		return false, "no_session"
	end
	local side = sideFor(session, player.UserId)
	local other = otherSide(session, player.UserId)
	if not side or not other then
		return false, "no_side"
	end
	if not side.locked or not other.locked then
		return false, "both_must_lock"
	end
	side.confirmed = true
	publish(session)

	if side.confirmed and other.confirmed then
		return TradingService.execute(session.id)
	end
	return true, "waiting_partner"
end

function TradingService.execute(sessionId: string): (boolean, string)
	local session = sessions[sessionId]
	if not session or session.state ~= "open" then
		return false, "no_session"
	end
	if not session.a.locked or not session.b.locked then
		return false, "not_locked"
	end
	if not session.a.confirmed or not session.b.confirmed then
		return false, "not_confirmed"
	end

	local okA, errA = validateOffer(session.a.userId, session.a.offer)
	local okB, errB = validateOffer(session.b.userId, session.b.offer)
	if not okA then
		cancelSession(sessionId, errA or "invalid_a")
		return false, errA or "invalid_a"
	end
	if not okB then
		cancelSession(sessionId, errB or "invalid_b")
		return false, errB or "invalid_b"
	end

	local creditOkA, creditErrA = validateCreditOffer(session.a.userId, session.a.creditOffer)
	if not creditOkA then
		cancelSession(sessionId, creditErrA or "invalid_credits_a")
		return false, creditErrA or "invalid_credits_a"
	end
	local creditOkB, creditErrB = validateCreditOffer(session.b.userId, session.b.creditOffer)
	if not creditOkB then
		cancelSession(sessionId, creditErrB or "invalid_credits_b")
		return false, creditErrB or "invalid_credits_b"
	end

	for itemId, qty in session.a.offer do
		if not PlayerItemStore.transfer(session.a.userId, session.b.userId, itemId, qty) then
			cancelSession(sessionId, "transfer_failed_a")
			return false, "transfer_failed"
		end
	end
	for itemId, qty in session.b.offer do
		if not PlayerItemStore.transfer(session.b.userId, session.a.userId, itemId, qty) then
			cancelSession(sessionId, "transfer_failed_b")
			return false, "transfer_failed"
		end
	end

	if session.a.creditOffer > 0 then
		local deducted, msg = CurrencyService.deductCredits(session.a.userId, session.a.creditOffer)
		if not deducted then
			cancelSession(sessionId, "credit_transfer_failed_a")
			return false, "ยอด credits ไม่พอ: " .. msg
		end
		CurrencyService.addCredits(session.b.userId, session.a.creditOffer)
	end
	if session.b.creditOffer > 0 then
		local deducted, msg = CurrencyService.deductCredits(session.b.userId, session.b.creditOffer)
		if not deducted then
			cancelSession(sessionId, "credit_transfer_failed_b")
			return false, "ยอด credits ไม่พอ: " .. msg
		end
		CurrencyService.addCredits(session.a.userId, session.b.creditOffer)
	end

	session.state = "executed"
	sessionByUser[session.a.userId] = nil
	sessionByUser[session.b.userId] = nil
	publish(session)

	local playerA = Players:GetPlayerByUserId(session.a.userId)
	local playerB = Players:GetPlayerByUserId(session.b.userId)
	if playerA then
		WeightService.refreshPlayer(playerA)
	end
	if playerB then
		WeightService.refreshPlayer(playerB)
	end

	local tradeComplete = ReplicatedStorage:FindFirstChild("TradeCompleteEvent") :: BindableEvent?
	if tradeComplete then
		if playerA then
			tradeComplete:Fire(playerA)
		end
		if playerB then
			tradeComplete:Fire(playerB)
		end
	end

	return true, "executed"
end

function TradingService.cancel(player: Player): (boolean, string)
	local session = TradingService.getSessionForUser(player.UserId)
	if not session then
		return false, "no_session"
	end
	cancelSession(session.id, "user_cancel")
	return true, "cancelled"
end

Players.PlayerRemoving:Connect(function(player: Player)
	local session = TradingService.getSessionForUser(player.UserId)
	if session then
		cancelSession(session.id, "player_left")
	end
end)

return TradingService
