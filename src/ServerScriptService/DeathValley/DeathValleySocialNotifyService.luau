--!strict
--[[
	Phase O — Offline social notification queue (join digest) + optional bridge push hook.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))

export type NotifyEntry = {
	id: string,
	type: string,
	title: string,
	body: string,
	createdAt: number,
	data: { [string]: any }?,
}

export type NotifyPrefs = {
	presetShare: boolean,
	friendOnline: boolean,
	marketFeatured: boolean,
	pushOptIn: boolean,
}

local DeathValleySocialNotifyService = {}

local MAX_QUEUE = 20
local DEFAULT_PREFS: NotifyPrefs = {
	presetShare = true,
	friendOnline = true,
	marketFeatured = true,
	pushOptIn = false,
}

local function getBridgePushUrl(): string?
	local ok, bridgeSecrets = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Secrets"):WaitForChild("BridgeSecrets"))
	end)
	if not ok or typeof(bridgeSecrets) ~= "table" then
		return nil
	end
	local url = bridgeSecrets.SOCIAL_NOTIFY_PUSH_URL
	if typeof(url) == "string" and url ~= "" then
		return url
	end
	return nil
end

local function getBridgeKey(): string?
	local ok, bridgeSecrets = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Secrets"):WaitForChild("BridgeSecrets"))
	end)
	if not ok or typeof(bridgeSecrets) ~= "table" then
		return nil
	end
	local key = bridgeSecrets.BRIDGE_KEY
	if typeof(key) == "string" and key ~= "" then
		return key
	end
	return nil
end

function DeathValleySocialNotifyService.getPrefs(userId: number): NotifyPrefs
	local data = DeathValleyPlayerStore.load(userId)
	local stored = if data and data.notifyPrefs then data.notifyPrefs else nil
	return {
		presetShare = if stored and stored.presetShare ~= nil then stored.presetShare else DEFAULT_PREFS.presetShare,
		friendOnline = if stored and stored.friendOnline ~= nil
			then stored.friendOnline
			else DEFAULT_PREFS.friendOnline,
		marketFeatured = if stored and stored.marketFeatured ~= nil
			then stored.marketFeatured
			else DEFAULT_PREFS.marketFeatured,
		pushOptIn = if stored and stored.pushOptIn ~= nil then stored.pushOptIn else DEFAULT_PREFS.pushOptIn,
	}
end

function DeathValleySocialNotifyService.setPrefs(userId: number, prefs: NotifyPrefs): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = 1 }
	existing.notifyPrefs = prefs
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleySocialNotifyService.queueNotify(
	targetUserId: number,
	entry: {
		type: string,
		title: string,
		body: string,
		data: { [string]: any }?,
	}
): boolean
	local existing = DeathValleyPlayerStore.load(targetUserId) or { version = 1 }
	if not existing.socialNotifyQueue then
		existing.socialNotifyQueue = {}
	end
	table.insert(existing.socialNotifyQueue, 1, {
		id = HttpService:GenerateGUID(false),
		type = entry.type,
		title = entry.title,
		body = entry.body,
		createdAt = os.time(),
		data = entry.data,
	})
	while #existing.socialNotifyQueue > MAX_QUEUE do
		table.remove(existing.socialNotifyQueue)
	end
	local saved = DeathValleyPlayerStore.save(targetUserId, existing)
	if saved then
		DeathValleySocialNotifyService.tryBridgePush(targetUserId, entry)
	end
	return saved
end

function DeathValleySocialNotifyService.tryBridgePush(
	targetUserId: number,
	entry: { type: string, title: string, body: string, data: { [string]: any }? }
)
	local prefs = DeathValleySocialNotifyService.getPrefs(targetUserId)
	if not prefs.pushOptIn then
		return
	end
	local pushUrl = getBridgePushUrl()
	local bridgeKey = getBridgeKey()
	if not pushUrl or not bridgeKey then
		return
	end
	task.spawn(function()
		pcall(function()
			HttpService:PostAsync(pushUrl, HttpService:JSONEncode({
				targetUserId = targetUserId,
				type = entry.type,
				title = entry.title,
				body = entry.body,
				data = entry.data,
			}), Enum.HttpContentType.ApplicationJson, false, {
				["X-Utopia-Bridge-Key"] = bridgeKey,
			})
		end)
	end)
end

function DeathValleySocialNotifyService.drainQueue(player: Player): { NotifyEntry }
	local data = DeathValleyPlayerStore.load(player.UserId)
	if not data or not data.socialNotifyQueue or #data.socialNotifyQueue == 0 then
		return {}
	end
	local queue = data.socialNotifyQueue
	data.socialNotifyQueue = {}
	DeathValleyPlayerStore.save(player.UserId, data)
	return queue
end

function DeathValleySocialNotifyService.getQueuePreview(player: Player): { count: number, items: { NotifyEntry } }
	local data = DeathValleyPlayerStore.load(player.UserId)
	local queue = if data and data.socialNotifyQueue then data.socialNotifyQueue else {}
	local items: { NotifyEntry } = {}
	for index, entry in queue do
		if index > 5 then
			break
		end
		if typeof(entry) == "table" then
			table.insert(items, entry :: NotifyEntry)
		end
	end
	return {
		count = #queue,
		items = items,
	}
end

return DeathValleySocialNotifyService
