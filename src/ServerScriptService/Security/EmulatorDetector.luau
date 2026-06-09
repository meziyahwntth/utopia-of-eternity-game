--!strict
--[[
	PC + mobile emulator → multi-account farming.
	Roblox does not expose raw IP to Luau; we escalate via ApplyDeviceBlock + strike registry.
	Strike 1: device block 7 days · Strike 2: permanent device block.
]]
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EmulatorDetector = {}

local strikeStore: GlobalDataStore? = nil
pcall(function()
	strikeStore = DataStoreService:GetDataStore("UtopiaDeviceBlockStrikes_v1")
end)

local sessionClusters: { [string]: { userIds: { number }, firstSeen: number } } = {}

local SentinelStrike
local LogExportBridge

function EmulatorDetector:Init(deps: { SentinelStrike: any, LogExportBridge: any? })
	SentinelStrike = deps.SentinelStrike
	LogExportBridge = deps.LogExportBridge
end

local function clusterKey(player: Player): string
	return string.format("%s:%d:%s", player.LocaleId, player.AccountAge, tostring(player.MembershipType))
end

function EmulatorDetector:ScoreSession(player: Player, platformName: string?): number
	local score = 0
	local cfg = GameConfig.Security
	if platformName == "Mobile" or platformName == "Tablet" then
		score += 10
	end
	if player.AccountAge <= cfg.EMULATOR_MAX_ACCOUNT_AGE_DAYS then
		score += 25
	end
	local key = clusterKey(player)
	local cluster = sessionClusters[key]
	local now = os.time()
	if not cluster then
		cluster = { userIds = {}, firstSeen = now }
		sessionClusters[key] = cluster
	end
	local seen = false
	for _, id in cluster.userIds do
		if id == player.UserId then
			seen = true
			break
		end
	end
	if not seen then
		table.insert(cluster.userIds, player.UserId)
	end
	if #cluster.userIds >= cfg.EMULATOR_CLUSTER_ACCOUNT_LIMIT and (now - cluster.firstSeen) < cfg.EMULATOR_CLUSTER_WINDOW_SECONDS then
		score += 50
	end
	return score
end

function EmulatorDetector:GetDeviceStrikeCount(userId: number): number
	if not strikeStore then
		return 0
	end
	local ok, count = pcall(function()
		return strikeStore:GetAsync("strike:" .. tostring(userId))
	end)
	if ok and typeof(count) == "number" then
		return count
	end
	return 0
end

function EmulatorDetector:RecordDeviceStrike(userId: number): number
	local nextCount = self:GetDeviceStrikeCount(userId) + 1
	if strikeStore then
		pcall(function()
			strikeStore:SetAsync("strike:" .. tostring(userId), nextCount)
		end)
	end
	return nextCount
end

function EmulatorDetector:ShouldPunish(score: number): boolean
	return score >= GameConfig.Security.EMULATOR_PUNISH_THRESHOLD
end

function EmulatorDetector:Punish(player: Player, platformName: string?, detail: string)
	if not SentinelStrike then
		return
	end
	local strikes = self:RecordDeviceStrike(player.UserId)
	local cfg = GameConfig.Security
	local reason = string.format("Emulator/multi-account (strike %d): %s", strikes, detail)
	if LogExportBridge then
		LogExportBridge:Enqueue("EMULATOR_STRIKE", {
			userId = player.UserId,
			strikes = strikes,
			platform = platformName,
			detail = detail,
		})
	end
	if strikes >= 2 then
		SentinelStrike:PermanentDeviceBan(player, reason)
	else
		SentinelStrike:DeviceBan(player, reason, cfg.DEVICE_BAN_FIRST_SECONDS)
	end
end

function EmulatorDetector:ClearPlayer(userId: number)
	for key, cluster in sessionClusters do
		local filtered: { number } = {}
		for _, id in cluster.userIds do
			if id ~= userId then
				table.insert(filtered, id)
			end
		end
		if #filtered == 0 then
			sessionClusters[key] = nil
		else
			cluster.userIds = filtered
		end
	end
end

return EmulatorDetector
