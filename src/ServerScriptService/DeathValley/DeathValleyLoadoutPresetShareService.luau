--!strict
--[[
	Phase M — Share loadout presets with Roblox friends (inbox + apply if owned).
	Phase N — Cross-server notify, share codes / redeem links.
]]

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleySocialNotifyService = require(script.Parent:WaitForChild("DeathValleySocialNotifyService"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))
local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

local DeathValleyLoadoutPresetShareService = {}

local MAX_INBOX = 12
local MAX_ACTIVE_CODES = 5
local CODE_TTL_SECONDS = 86400
local CODE_MAP_NAME = "UtopiaDV_PresetCode_v1"
local TOPIC = "UtopiaDV_PRESET_SHARE_v1"
local CODE_CHARSET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local codeMap: any = nil
do
	local ok, result = pcall(function()
		return MemoryStoreService:GetHashMap(CODE_MAP_NAME)
	end)
	if ok then
		codeMap = result
	else
		warn("[DeathValley] MemoryStore GetHashMap failed (PresetShareService):", result)
	end
end
local subscribed = false

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local presetShareReceived = remotes:WaitForChild("PresetShareReceived") :: RemoteEvent

local function resolveTitleText(userId: number, seasonId: string?): string?
	if not seasonId or seasonId == "" then
		return nil
	end
	local data = DeathValleyPlayerStore.load(userId)
	if data and data.earnedTitles then
		return data.earnedTitles[seasonId]
	end
	return nil
end

local function resolveCosmeticName(cosmeticId: string?): string?
	if not cosmeticId or cosmeticId == "" then
		return nil
	end
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	return if def then def.displayName else cosmeticId
end

local function normalizeCode(raw: string): string
	return string.upper(string.gsub(raw, "[^%w]", ""))
end

local function randomCode(length: number): string
	local parts: { string } = {}
	for _ = 1, length do
		local index = math.random(1, #CODE_CHARSET)
		table.insert(parts, string.sub(CODE_CHARSET, index, index))
	end
	return table.concat(parts)
end

local function deliverPresetShareNotify(target: Player, message: string, fromDisplayName: string)
	target:SetAttribute("DV_PresetShareMsg", message)
	presetShareReceived:FireClient(target, {
		message = message,
		fromDisplayName = fromDisplayName,
	})
end

function DeathValleyLoadoutPresetShareService.ensureSubscribed()
	if subscribed then
		return
	end
	subscribed = true
	task.spawn(function()
		local ok = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				local data = message.Data
				if typeof(data) ~= "table" or data.jobId == game.JobId then
					return
				end
				if data.action ~= "share" or typeof(data.targetUserId) ~= "number" then
					return
				end
				local target = Players:GetPlayerByUserId(data.targetUserId)
				if not target then
					return
				end
				local msg = if typeof(data.message) == "string"
					then data.message
					else "A friend shared a loadout preset with you"
				local fromName = if typeof(data.fromDisplayName) == "string" then data.fromDisplayName else "Friend"
				deliverPresetShareNotify(target, msg, fromName)
			end)
		end)
		if not ok then
			warn("[DeathValley] Preset share MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

local function notifyTarget(targetUserId: number, message: string, fromDisplayName: string)
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		deliverPresetShareNotify(target, message, fromDisplayName)
		return
	end
	DeathValleyLoadoutPresetShareService.ensureSubscribed()
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = "share",
				jobId = game.JobId,
				targetUserId = targetUserId,
				message = message,
				fromDisplayName = fromDisplayName,
			})
		end)
	end)
end

local function addInboxEntry(
	targetUserId: number,
	fromUserId: number,
	fromDisplayName: string,
	titleSeasonId: string?,
	cosmeticId: string?
): string
	local shareId = HttpService:GenerateGUID(false)
	DeathValleyPlayerStore.addPresetInbox(targetUserId, {
		shareId = shareId,
		fromUserId = fromUserId,
		fromDisplayName = fromDisplayName,
		titleSeasonId = titleSeasonId,
		cosmeticId = cosmeticId,
		titleText = resolveTitleText(fromUserId, titleSeasonId),
		cosmeticName = resolveCosmeticName(cosmeticId),
		sharedAt = os.time(),
	}, MAX_INBOX)
	DeathValleySocialNotifyService.queueNotify(targetUserId, {
		type = "preset_share",
		title = "Loadout Shared",
		body = string.format("%s shared a loadout preset with you", fromDisplayName),
		data = {
			shareId = shareId,
			fromUserId = fromUserId,
		},
	})
	return shareId
end

function DeathValleyLoadoutPresetShareService.getSharedPresetsPayload(player: Player): { [string]: any }
	local inbox = DeathValleyPlayerStore.listPresetInbox(player.UserId)
	local data = DeathValleyPlayerStore.load(player.UserId)
	local earned = if data and data.earnedTitles then data.earnedTitles else {}
	local items: { { [string]: any } } = {}
	for _, entry in inbox do
		if typeof(entry) ~= "table" then
			continue
		end
		local titleSeasonId = entry.titleSeasonId
		local cosmeticId = entry.cosmeticId
		table.insert(items, {
			shareId = entry.shareId,
			fromUserId = entry.fromUserId,
			fromDisplayName = entry.fromDisplayName,
			titleSeasonId = titleSeasonId,
			cosmeticId = cosmeticId,
			titleText = entry.titleText,
			cosmeticName = entry.cosmeticName,
			sharedAt = entry.sharedAt,
			canApplyTitle = typeof(titleSeasonId) == "string"
				and titleSeasonId ~= ""
				and earned[titleSeasonId] ~= nil,
			canApplyCosmetic = typeof(cosmeticId) == "string"
				and cosmeticId ~= ""
				and DeathValleyPlayerStore.hasOwnedCosmetic(player.UserId, cosmeticId),
		})
	end
	return {
		count = #items,
		items = items,
	}
end

function DeathValleyLoadoutPresetShareService.getActiveShareCodesPayload(player: Player): { [string]: any }
	local now = os.time()
	local codes: { { [string]: any } } = {}
	for _, entry in DeathValleyPlayerStore.listActiveShareCodes(player.UserId) do
		if typeof(entry) ~= "table" then
			continue
		end
		local expiresAt = if typeof(entry.expiresAt) == "number" then entry.expiresAt else 0
		if expiresAt <= now then
			continue
		end
		table.insert(codes, {
			code = entry.code,
			slotIndex = entry.slotIndex,
			createdAt = entry.createdAt,
			expiresAt = expiresAt,
			shareLink = string.format("UTOPIA-%s", entry.code),
		})
	end
	return {
		count = #codes,
		codes = codes,
	}
end

function DeathValleyLoadoutPresetShareService.sharePresetWithFriend(
	sender: Player,
	slotIndex: number,
	targetUserId: number
): (boolean, string)
	if targetUserId == sender.UserId then
		return false, "Cannot share with yourself"
	end
	local okFriend, isFriend = pcall(function()
		return sender:IsFriendsWith(targetUserId)
	end)
	if not okFriend or not isFriend then
		return false, "Player is not on your friends list"
	end

	local stored = DeathValleyPlayerStore.getLoadoutPresets(sender.UserId)
	local entry = stored[slotIndex]
	if not entry then
		return false, "Preset slot is empty"
	end
	if (not entry.titleSeasonId or entry.titleSeasonId == "") and (not entry.cosmeticId or entry.cosmeticId == "") then
		return false, "Nothing to share in that slot"
	end

	addInboxEntry(targetUserId, sender.UserId, sender.DisplayName, entry.titleSeasonId, entry.cosmeticId)

	local targetName = "friend"
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		targetName = target.DisplayName
	end
	notifyTarget(
		targetUserId,
		string.format("%s shared a loadout preset with you", sender.DisplayName),
		sender.DisplayName
	)
	return true, string.format("Preset shared with %s", targetName)
end

function DeathValleyLoadoutPresetShareService.generateShareCode(player: Player, slotIndex: number): (boolean, string | { [string]: any })
	local stored = DeathValleyPlayerStore.getLoadoutPresets(player.UserId)
	local entry = stored[slotIndex]
	if not entry then
		return false, "Preset slot is empty"
	end
	if (not entry.titleSeasonId or entry.titleSeasonId == "") and (not entry.cosmeticId or entry.cosmeticId == "") then
		return false, "Nothing to share in that slot"
	end

	local now = os.time()
	local expiresAt = now + CODE_TTL_SECONDS
	local code = ""
	for _ = 1, 8 do
		local candidate = randomCode(8)
		local ok, existing = pcall(function()
			return codeMap:GetAsync(candidate)
		end)
		if ok and existing == nil then
			code = candidate
			break
		end
	end
	if code == "" then
		return false, "Could not generate share code — try again"
	end

	local payload = {
		fromUserId = player.UserId,
		fromDisplayName = player.DisplayName,
		titleSeasonId = entry.titleSeasonId,
		cosmeticId = entry.cosmeticId,
		titleText = resolveTitleText(player.UserId, entry.titleSeasonId),
		cosmeticName = resolveCosmeticName(entry.cosmeticId),
		expiresAt = expiresAt,
	}
	local wrote, writeErr = pcall(function()
		codeMap:SetAsync(code, payload, CODE_TTL_SECONDS)
	end)
	if not wrote then
		return false, tostring(writeErr)
	end

	DeathValleyPlayerStore.addActiveShareCode(
		player.UserId,
		{ code = code, slotIndex = slotIndex, createdAt = now, expiresAt = expiresAt },
		MAX_ACTIVE_CODES
	)

	return true, {
		code = code,
		shareLink = string.format("UTOPIA-%s", code),
		slotIndex = slotIndex,
		expiresAt = expiresAt,
	}
end

function DeathValleyLoadoutPresetShareService.redeemShareCode(player: Player, rawCode: string): (boolean, string)
	if typeof(rawCode) ~= "string" or rawCode == "" then
		return false, "Enter a share code"
	end
	local code = normalizeCode(rawCode)
	if #code < 6 then
		return false, "Invalid share code"
	end

	local ok, payload = pcall(function()
		return codeMap:GetAsync(code)
	end)
	if not ok or typeof(payload) ~= "table" then
		return false, "Share code not found or expired"
	end
	local expiresAt = if typeof(payload.expiresAt) == "number" then payload.expiresAt else 0
	if expiresAt <= os.time() then
		return false, "Share code expired"
	end

	local fromUserId = if typeof(payload.fromUserId) == "number" then payload.fromUserId else 0
	if fromUserId == player.UserId then
		return false, "This is your own share code"
	end

	local fromDisplayName = if typeof(payload.fromDisplayName) == "string"
		then payload.fromDisplayName
		else "Friend"
	local titleSeasonId = payload.titleSeasonId
	local cosmeticId = payload.cosmeticId

	addInboxEntry(player.UserId, fromUserId, fromDisplayName, titleSeasonId, cosmeticId)
	notifyTarget(
		player.UserId,
		string.format("Redeemed preset from %s — check Shared inbox", fromDisplayName),
		fromDisplayName
	)
	return true, string.format("Preset added from %s", fromDisplayName)
end

function DeathValleyLoadoutPresetShareService.applySharedPreset(player: Player, shareId: string): (boolean, string)
	local entry = DeathValleyPlayerStore.getPresetInboxEntry(player.UserId, shareId)
	if not entry then
		return false, "Shared preset not found"
	end

	local applied: { string } = {}
	local skipped: { string } = {}

	if entry.titleSeasonId and entry.titleSeasonId ~= "" then
		local ok, msg = DeathValleyTitleService.equipTitle(player, entry.titleSeasonId)
		if ok then
			table.insert(applied, "title")
		else
			table.insert(skipped, msg)
		end
	end

	if entry.cosmeticId and entry.cosmeticId ~= "" then
		local ok, msg = DeathValleyCosmeticService.equipCosmetic(player, entry.cosmeticId)
		if ok then
			table.insert(applied, "cosmetic")
		else
			table.insert(skipped, msg)
		end
	end

	if #applied == 0 then
		return false, if #skipped > 0 then skipped[1] else "Nothing you can equip from this share"
	end

	local suffix = if #skipped > 0 then " (some items skipped — not owned)" else ""
	return true, "Applied shared loadout: " .. table.concat(applied, " + ") .. suffix
end

function DeathValleyLoadoutPresetShareService.dismissSharedPreset(player: Player, shareId: string): (boolean, string)
	if not DeathValleyPlayerStore.removePresetInbox(player.UserId, shareId) then
		return false, "Shared preset not found"
	end
	return true, "Shared preset removed"
end

DeathValleyLoadoutPresetShareService.ensureSubscribed()

return DeathValleyLoadoutPresetShareService
