--!strict
--[[
	Phase N — Cross-place friend presence (MemoryStore + MessagingService)
	and friend-online notifications with city name.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

export type PresenceRecord = {
	userId: number,
	displayName: string,
	placeKey: string,
	placeDisplayName: string,
	jobId: string,
	updatedAt: number,
}

export type FriendPresenceNotifyPayload = {
	eventType: "online" | "offline",
	friendUserId: number,
	displayName: string,
	placeKey: string?,
	placeDisplayName: string?,
}

local DeathValleyFriendPresenceService = {}

local TOPIC = "UtopiaDV_PRESENCE_v1"
local MAP_NAME = "UtopiaDV_Presence_v1"
local PRESENCE_TTL = 180
local HEARTBEAT_SECONDS = 60

local presenceMap: any = nil
do
	local ok, result = pcall(function()
		return MemoryStoreService:GetHashMap(MAP_NAME)
	end)
	if ok then
		presenceMap = result
	else
		warn("[DeathValley] MemoryStore GetHashMap failed (FriendPresenceService):", result)
	end
end
local remotePresence: { [number]: PresenceRecord } = {}
local subscribed = false
local started = false

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local friendPresenceNotify = remotes:WaitForChild("FriendPresenceNotify") :: RemoteEvent

local function getPlaceKey(): PlaceTeleport.PlaceKey
	return WorldPlaceGuard:GetCurrentPlaceKey()
end

local function buildRecord(player: Player): PresenceRecord
	local placeKey = getPlaceKey()
	return {
		userId = player.UserId,
		displayName = player.DisplayName,
		placeKey = placeKey,
		placeDisplayName = PlaceTeleport:GetDisplayName(placeKey),
		jobId = game.JobId,
		updatedAt = os.time(),
	}
end

local function isFresh(record: PresenceRecord?): boolean
	if not record then
		return false
	end
	return os.time() - record.updatedAt <= PRESENCE_TTL
end

local function publishPresence(action: string, record: PresenceRecord)
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				action = action,
				jobId = game.JobId,
				record = record,
			})
		end)
	end)
end

local function writeMemoryPresence(record: PresenceRecord)
	task.spawn(function()
		pcall(function()
			presenceMap:SetAsync(tostring(record.userId), record, PRESENCE_TTL)
		end)
	end)
end

local function clearMemoryPresence(userId: number)
	task.spawn(function()
		pcall(function()
			presenceMap:RemoveAsync(tostring(userId))
		end)
	end)
end

local function notifyLocalFriend(observer: Player, payload: FriendPresenceNotifyPayload)
	friendPresenceNotify:FireClient(observer, payload)
	local placeText = payload.placeDisplayName or "Utopia"
	local msg = if payload.eventType == "online"
		then string.format("%s is online in %s", payload.displayName, placeText)
		else string.format("%s went offline", payload.displayName)
	observer:SetAttribute("DV_FriendPresenceMsg", msg)
end

local function notifyMutualFriendsLocally(subject: Player, eventType: "online" | "offline", record: PresenceRecord?)
	for _, observer in Players:GetPlayers() do
		if observer == subject then
			continue
		end
		local ok, isFriend = pcall(function()
			return observer:IsFriendsWith(subject.UserId)
		end)
		if ok and isFriend then
			notifyLocalFriend(observer, {
				eventType = eventType,
				friendUserId = subject.UserId,
				displayName = subject.DisplayName,
				placeKey = if record then record.placeKey else nil,
				placeDisplayName = if record then record.placeDisplayName else nil,
			})
		end
	end
end

local function handleRemotePresence(data: { [string]: any })
	if typeof(data.record) ~= "table" then
		return
	end
	local record = data.record :: PresenceRecord
	if typeof(record.userId) ~= "number" then
		return
	end
	if data.action == "offline" then
		remotePresence[record.userId] = nil
	else
		record.updatedAt = if typeof(record.updatedAt) == "number" then record.updatedAt else os.time()
		remotePresence[record.userId] = record
	end
	if data.action ~= "online" then
		return
	end
	for _, observer in Players:GetPlayers() do
		if observer.UserId == record.userId then
			continue
		end
		local ok, isFriend = pcall(function()
			return observer:IsFriendsWith(record.userId)
		end)
		if ok and isFriend then
			notifyLocalFriend(observer, {
				eventType = "online",
				friendUserId = record.userId,
				displayName = record.displayName,
				placeKey = record.placeKey,
				placeDisplayName = record.placeDisplayName,
			})
		end
	end
end

function DeathValleyFriendPresenceService.ensureSubscribed()
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
				handleRemotePresence(data)
			end)
		end)
		if not ok then
			warn("[DeathValley] Friend presence MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

function DeathValleyFriendPresenceService.getPresence(userId: number): PresenceRecord?
	local localPlayer = Players:GetPlayerByUserId(userId)
	if localPlayer then
		return buildRecord(localPlayer)
	end
	local cached = remotePresence[userId]
	if isFresh(cached) then
		return cached
	end
	local ok, record = pcall(function()
		return presenceMap:GetAsync(tostring(userId))
	end)
	if ok and typeof(record) == "table" and isFresh(record :: PresenceRecord) then
		remotePresence[userId] = record :: PresenceRecord
		return record :: PresenceRecord
	end
	return nil
end

function DeathValleyFriendPresenceService.getPresenceBatch(userIds: { number }): { [number]: PresenceRecord }
	local result: { [number]: PresenceRecord } = {}
	for _, userId in userIds do
		local record = DeathValleyFriendPresenceService.getPresence(userId)
		if record then
			result[userId] = record
		end
	end
	return result
end

function DeathValleyFriendPresenceService.markOnline(player: Player)
	local record = buildRecord(player)
	writeMemoryPresence(record)
	remotePresence[player.UserId] = record
	DeathValleyFriendPresenceService.ensureSubscribed()
	publishPresence("online", record)
	notifyMutualFriendsLocally(player, "online", record)
end

function DeathValleyFriendPresenceService.markOffline(player: Player)
	local record = buildRecord(player)
	clearMemoryPresence(player.UserId)
	remotePresence[player.UserId] = nil
	publishPresence("offline", record)
	notifyMutualFriendsLocally(player, "offline", nil)
end

function DeathValleyFriendPresenceService.onPlayerAdded(player: Player)
	task.defer(function()
		DeathValleyFriendPresenceService.markOnline(player)
	end)
end

function DeathValleyFriendPresenceService.onPlayerRemoving(player: Player)
	DeathValleyFriendPresenceService.markOffline(player)
end

function DeathValleyFriendPresenceService.start()
	if started then
		return
	end
	started = true
	DeathValleyFriendPresenceService.ensureSubscribed()
	for _, player in Players:GetPlayers() do
		local record = buildRecord(player)
		writeMemoryPresence(record)
		remotePresence[player.UserId] = record
	end
	Players.PlayerAdded:Connect(DeathValleyFriendPresenceService.onPlayerAdded)
	Players.PlayerRemoving:Connect(DeathValleyFriendPresenceService.onPlayerRemoving)
	task.spawn(function()
		while started do
			task.wait(HEARTBEAT_SECONDS)
			for _, player in Players:GetPlayers() do
				local record = buildRecord(player)
				writeMemoryPresence(record)
				remotePresence[player.UserId] = record
			end
		end
	end)
end

return DeathValleyFriendPresenceService
