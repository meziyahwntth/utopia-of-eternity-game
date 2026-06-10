--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local RemoteGuard = {}

export type BucketConfig = {
	maxTokens: number,
	refillPerSecond: number,
}

export type SchemaField = {
	name: string,
	type: string,
	maxLen: number?,
	min: number?,
	max: number?,
}

export type RemoteConfig = {
	rateLimit: BucketConfig?,
	allowedStates: { string }?,
	schema: { SchemaField }?,
	handler: (Player, ...any) -> (),
}

local registry: { [string]: RemoteConfig } = {}
local remotesFolder: Folder? = nil

local RateLimiter
local SuspicionTracker
local SentinelStrike
local SevereOffenseGate
local floodCounts: { [number]: { [string]: number } } = {}

local function ensureRemotesFolder(): Folder
	local current = remotesFolder
	if current and current.Parent then
		return current
	end
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		remotesFolder = existing
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	remotesFolder = folder
	return folder
end

function RemoteGuard:Init(deps: {
	RateLimiter: any,
	SuspicionTracker: any,
	SentinelStrike: any,
	SevereOffenseGate: any?,
})
	RateLimiter = deps.RateLimiter
	SuspicionTracker = deps.SuspicionTracker
	SentinelStrike = deps.SentinelStrike
	SevereOffenseGate = deps.SevereOffenseGate
	ensureRemotesFolder()
end

local function validateField(field: SchemaField, value: any): boolean
	if typeof(value) ~= field.type then
		return false
	end
	if field.type == "string" then
		local maxLen = field.maxLen or 256
		if #value > maxLen then
			return false
		end
	elseif field.type == "number" then
		if field.min and value < field.min then
			return false
		end
		if field.max and value > field.max then
			return false
		end
	end
	return true
end

local function validateArgs(schema: { SchemaField }?, args: { any }): boolean
	if not schema then
		return true
	end
	if #args ~= #schema then
		return false
	end
	for index, field in schema do
		if not validateField(field, args[index]) then
			return false
		end
	end
	return true
end

function RemoteGuard:Register(name: string, config: RemoteConfig)
	registry[name] = config
	local folder = ensureRemotesFolder()
	local existing = folder:FindFirstChild(name)
	local remote: RemoteEvent
	if existing and existing:IsA("RemoteEvent") then
		remote = existing
	else
		if existing then
			existing:Destroy()
		end
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	remote.OnServerEvent:Connect(function(player: Player, ...)
		local args = { ... }
		local entry = registry[name]
		if not entry then
			return
		end
		if entry.rateLimit and RateLimiter then
			if not RateLimiter:TryConsume(player, name, entry.rateLimit) then
				local uid = player.UserId
				local bucket = floodCounts[uid]
				if not bucket then
					bucket = {}
					floodCounts[uid] = bucket
				end
				bucket[name] = (bucket[name] or 0) + 1
				if bucket[name] >= 50 and SevereOffenseGate then
					SevereOffenseGate:HandleServerFlood(player, name, bucket[name])
				end
				return
			end
		end
		if not validateArgs(entry.schema, args) then
			if SuspicionTracker then
				local score = SuspicionTracker:Add(player, 15, "REMOTE_SCHEMA_" .. name)
				if score >= GameConfig.Security.SUSPICION_KICK and SentinelStrike then
					SentinelStrike:Warn(player, "Invalid remote payload: " .. name, score)
				end
			end
			return
		end
		entry.handler(player, table.unpack(args))
	end)
end

function RemoteGuard:GetRegistry(): { [string]: RemoteConfig }
	return registry
end

return RemoteGuard
