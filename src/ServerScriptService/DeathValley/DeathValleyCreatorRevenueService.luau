--!strict
--[[
	Phase Q/R — Creator revenue ledger + group payout export queue.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyUgcCreatorPackService = require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

export type SaleRecord = {
	buyerUserId: number,
	grossRobux: number,
	creatorShare: number,
	source: string,
	packId: string?,
	listingId: string?,
	createdAt: number,
}

export type PayoutRequest = {
	requestId: string,
	amount: number,
	status: string,
	createdAt: number,
	exportedAt: number?,
}

local DeathValleyCreatorRevenueService = {}

local DEFAULT_CREATOR_PERCENT = 0.70
local MAX_LEDGER = 50
local MAX_PAYOUT_HISTORY = 20
local MIN_PAYOUT_CREDITS = 100

local function getPayoutConfig(): any
	local dv = GameConfig.DeathValley :: any
	if dv and typeof(dv.CreatorPayout) == "table" then
		return dv.CreatorPayout
	end
	return {}
end

local function getMinPayout(): number
	local config = getPayoutConfig()
	local minCredits = config.minCredits
	if typeof(minCredits) == "number" and minCredits > 0 then
		return math.floor(minCredits)
	end
	return MIN_PAYOUT_CREDITS
end

local function getGroupId(): number
	local config = getPayoutConfig()
	if typeof(config.groupId) == "number" and config.groupId > 0 then
		return config.groupId
	end
	return 0
end

local function getBridgePushUrl(): string?
	local ok, secrets = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Secrets"):WaitForChild("BridgeSecrets"))
	end)
	if ok and typeof(secrets) == "table" and secrets.CREATOR_PAYOUT_PUSH_URL then
		return secrets.CREATOR_PAYOUT_PUSH_URL
	end
	local bridge = GameConfig.Bridge :: any
	if bridge and typeof(bridge.CREATOR_PAYOUT_PUSH_URL) == "string" and bridge.CREATOR_PAYOUT_PUSH_URL ~= "" then
		return bridge.CREATOR_PAYOUT_PUSH_URL
	end
	return nil
end

local function getBridgeKey(): string?
	local ok, secrets = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Secrets"):WaitForChild("BridgeSecrets"))
	end)
	if ok and typeof(secrets) == "table" and secrets.BRIDGE_KEY then
		return secrets.BRIDGE_KEY
	end
	if GameConfig.Bridge.BRIDGE_KEY ~= "" then
		return GameConfig.Bridge.BRIDGE_KEY
	end
	return nil
end

function DeathValleyCreatorRevenueService.getCreatorPercent(packCreatorPercent: number?): number
	if typeof(packCreatorPercent) == "number" and packCreatorPercent > 0 and packCreatorPercent <= 1 then
		return packCreatorPercent
	end
	if typeof(packCreatorPercent) == "number" and packCreatorPercent > 1 and packCreatorPercent <= 100 then
		return packCreatorPercent / 100
	end
	return DEFAULT_CREATOR_PERCENT
end

function DeathValleyCreatorRevenueService.recordPackSale(
	creatorUserId: number,
	buyerUserId: number,
	grossRobux: number,
	packId: string,
	creatorPercent: number?
)
	if creatorUserId <= 0 or grossRobux <= 0 then
		return
	end
	local shareRate = DeathValleyCreatorRevenueService.getCreatorPercent(creatorPercent)
	local creatorShare = math.floor(grossRobux * shareRate)
	if creatorShare <= 0 then
		return
	end

	local existing = DeathValleyPlayerStore.load(creatorUserId) or { version = 1 }
	existing.creatorBalance = (existing.creatorBalance or 0) + creatorShare
	if not existing.creatorSalesLedger then
		existing.creatorSalesLedger = {}
	end
	table.insert(existing.creatorSalesLedger, 1, {
		buyerUserId = buyerUserId,
		grossRobux = grossRobux,
		creatorShare = creatorShare,
		source = "preset_pack",
		packId = packId,
		createdAt = os.time(),
	})
	while #existing.creatorSalesLedger > MAX_LEDGER do
		table.remove(existing.creatorSalesLedger)
	end
	DeathValleyPlayerStore.save(creatorUserId, existing)
end

function DeathValleyCreatorRevenueService.recordMarketAcquire(
	creatorUserId: number,
	buyerUserId: number,
	listingId: string,
	tipCredits: number?
)
	if creatorUserId <= 0 then
		return
	end
	local credits = tipCredits or 5
	local existing = DeathValleyPlayerStore.load(creatorUserId) or { version = 1 }
	existing.creatorBalance = (existing.creatorBalance or 0) + credits
	if not existing.creatorSalesLedger then
		existing.creatorSalesLedger = {}
	end
	table.insert(existing.creatorSalesLedger, 1, {
		buyerUserId = buyerUserId,
		grossRobux = 0,
		creatorShare = credits,
		source = "market_acquire",
		listingId = listingId,
		createdAt = os.time(),
	})
	while #existing.creatorSalesLedger > MAX_LEDGER do
		table.remove(existing.creatorSalesLedger)
	end
	DeathValleyPlayerStore.save(creatorUserId, existing)
end

function DeathValleyCreatorRevenueService.tryBridgePayoutPush(
	player: Player,
	request: PayoutRequest
): boolean
	local pushUrl = getBridgePushUrl()
	local bridgeKey = getBridgeKey()
	if not pushUrl or pushUrl == "" or not HttpService.HttpEnabled then
		return false
	end
	local headers = { ["Content-Type"] = "application/json" }
	if bridgeKey and bridgeKey ~= "" then
		headers["X-Utopia-Bridge-Key"] = bridgeKey
	end
	local ok = pcall(function()
		HttpService:PostAsync(
			pushUrl,
			HttpService:JSONEncode({
				requestId = request.requestId,
				creatorUserId = player.UserId,
				amount = request.amount,
				groupId = getGroupId(),
				displayName = player.DisplayName,
				createdAt = request.createdAt,
			}),
			Enum.HttpContentType.ApplicationJson,
			false,
			headers
		)
	end)
	return ok
end

function DeathValleyCreatorRevenueService.requestPayout(player: Player): (boolean, string)
	local data = DeathValleyPlayerStore.load(player.UserId) or { version = 1 }
	local balance = if typeof(data.creatorBalance) == "number" then data.creatorBalance else 0
	local minPayout = getMinPayout()
	if balance < minPayout then
		return false, string.format("Need at least %d creator credits", minPayout)
	end

	local pending = DeathValleyPlayerStore.listCreatorPayoutRequests(player.UserId)
	for _, req in pending do
		if req.status == "pending" or req.status == "exported" then
			return false, "You already have a pending payout request"
		end
	end

	local request: PayoutRequest = {
		requestId = HttpService:GenerateGUID(false),
		amount = balance,
		status = "pending",
		createdAt = os.time(),
	}
	data.creatorBalance = 0
	DeathValleyPlayerStore.addCreatorPayoutRequest(player.UserId, request, MAX_PAYOUT_HISTORY)
	DeathValleyPlayerStore.save(player.UserId, data)
	DeathValleyCreatorRevenueService.tryBridgePayoutPush(player, request)
	return true, string.format("Payout queued (%d credits) — group treasurer export via Bridge", request.amount)
end

function DeathValleyCreatorRevenueService.getSummary(userId: number): { [string]: any }
	local data = DeathValleyPlayerStore.load(userId)
	local balance = if data and typeof(data.creatorBalance) == "number" then data.creatorBalance else 0
	local ledger = if data and data.creatorSalesLedger then data.creatorSalesLedger else {}
	local payoutHistory = DeathValleyPlayerStore.listCreatorPayoutRequests(userId)
	return {
		balance = balance,
		minPayout = getMinPayout(),
		groupId = getGroupId(),
		communityUrl = (function()
			local community = (GameConfig :: any).Community
			if typeof(community) == "table" and typeof(community.url) == "string" and community.url ~= "" then
				return community.url
			end
			local gid = getGroupId()
			if gid > 0 then
				return string.format("https://www.roblox.com/communities/%d/Utopia-of-Eternity", gid)
			end
			return ""
		end)(),
		creatorSharePercent = math.floor(DEFAULT_CREATOR_PERCENT * 100),
		recentSales = ledger,
		payoutHistory = payoutHistory,
		ugcPriceTiers = DeathValleyUgcCreatorPackService.getPriceTiers(),
		ugcMinRobux = DeathValleyUgcCreatorPackService.getMinRobux(),
		ugcMaxRobux = DeathValleyUgcCreatorPackService.getMaxRobux(),
	}
end

return DeathValleyCreatorRevenueService
