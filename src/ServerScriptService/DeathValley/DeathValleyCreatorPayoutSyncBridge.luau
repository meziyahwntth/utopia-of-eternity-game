--!strict
--[[
	Phase T — Poll Bridge payout sync and mirror exportedAt / paid into PlayerStore.
]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local DeathValleyCreatorPayoutSyncBridge = {}

local function getSyncUrl(): string
	local bridge = GameConfig.Bridge :: any
	if typeof(bridge.CREATOR_PAYOUT_SYNC_URL) == "string" and bridge.CREATOR_PAYOUT_SYNC_URL ~= "" then
		return bridge.CREATOR_PAYOUT_SYNC_URL
	end
	local pushUrl = bridge.CREATOR_PAYOUT_PUSH_URL
	if typeof(pushUrl) == "string" and pushUrl ~= "" then
		return (string.gsub(pushUrl, "/push$", "/sync"))
	end
	return ""
end

local function getBridgeKey(): string
	if GameConfig.Bridge.BRIDGE_KEY ~= "" then
		return GameConfig.Bridge.BRIDGE_KEY
	end
	local ok, secrets = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Secrets"):WaitForChild("BridgeSecrets"))
	end)
	if ok and typeof(secrets) == "table" and typeof(secrets.BRIDGE_KEY) == "string" then
		return secrets.BRIDGE_KEY
	end
	return ""
end

local function parseIsoTimestamp(iso: string?): number?
	if typeof(iso) ~= "string" or iso == "" then
		return nil
	end
	local year, month, day, hour, min, sec = string.match(iso, "^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
	if not year then
		return nil
	end
	return os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec),
	})
end

function DeathValleyCreatorPayoutSyncBridge:ApplyUpdate(update: { [string]: any }): boolean
	if typeof(update) ~= "table" then
		return false
	end
	local requestId = update.requestId
	local creatorUserId = update.creatorUserId
	local status = update.status
	if typeof(requestId) ~= "string" or typeof(creatorUserId) ~= "number" or typeof(status) ~= "string" then
		return false
	end

	local patch: { [string]: any } = { status = status }
	local exportedAt = parseIsoTimestamp(update.exportedAt)
	if exportedAt then
		patch.exportedAt = exportedAt
	end
	local paidAt = parseIsoTimestamp(update.paidAt)
	if paidAt then
		patch.paidAt = paidAt
	end

	return DeathValleyPlayerStore.patchCreatorPayoutRequest(creatorUserId, requestId, patch)
end

function DeathValleyCreatorPayoutSyncBridge:PollOnce(): boolean
	local url = getSyncUrl()
	if url == "" or not HttpService.HttpEnabled then
		return false
	end

	local headers: { [string]: string } = {}
	local bridgeKey = getBridgeKey()
	if bridgeKey ~= "" then
		headers["X-Utopia-Bridge-Key"] = bridgeKey
	end

	local ok, raw = pcall(function()
		return HttpService:GetAsync(url, false, headers)
	end)
	if not ok or typeof(raw) ~= "string" then
		warn("[Utopia] CreatorPayoutSyncBridge poll failed")
		return false
	end

	local decodeOk, payload = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decodeOk or typeof(payload) ~= "table" then
		return false
	end

	local updates = payload.updates
	if typeof(updates) ~= "table" then
		return true
	end

	local applied = 0
	for _, update in updates do
		if self:ApplyUpdate(update) then
			applied += 1
		end
	end
	if applied > 0 then
		print(string.format("[Utopia] CreatorPayoutSyncBridge applied %d update(s)", applied))
	end
	return true
end

function DeathValleyCreatorPayoutSyncBridge:StartPolling()
	local bridge = GameConfig.Bridge :: any
	local interval = bridge.CREATOR_PAYOUT_SYNC_POLL_SECONDS
	if typeof(interval) ~= "number" or interval < 60 then
		interval = 300
	end
	task.spawn(function()
		while true do
			self:PollOnce()
			task.wait(interval)
		end
	end)
end

return DeathValleyCreatorPayoutSyncBridge
