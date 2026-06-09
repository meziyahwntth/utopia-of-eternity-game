--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local SentinelStrike = {}

local strikeCounts: { [number]: { count: number, lastAt: number } } = {}

local BanRegistry
local BanBroadcast
local EvasionDetector
local LineNotifier
local SuspicionTracker

function SentinelStrike:Init(deps: {
	BanRegistry: any,
	BanBroadcast: any,
	EvasionDetector: any,
	LineNotifier: any,
	SuspicionTracker: any,
})
	BanRegistry = deps.BanRegistry
	BanBroadcast = deps.BanBroadcast
	EvasionDetector = deps.EvasionDetector
	LineNotifier = deps.LineNotifier
	SuspicionTracker = deps.SuspicionTracker
end

function SentinelStrike:GetStrikes(userId: number): number
	local entry = strikeCounts[userId]
	return if entry then entry.count else 0
end

function SentinelStrike:Warn(player: Player, reason: string, score: number)
	if LineNotifier then
		LineNotifier:Alert("WARN", player, string.format("%s | score=%d", reason, score))
	end
	warn(string.format("[Utopia Sentinel] WARN %s (%d): %s", player.Name, player.UserId, reason))
end

function SentinelStrike:TempBan(player: Player, reason: string, durationSeconds: number)
	self:BanPlayer(player, reason, durationSeconds, "Sentinel temp ban")
end

function SentinelStrike:_BanInternal(
	player: Player,
	reason: string,
	durationSeconds: number?,
	by: string,
	opts: { deviceBlock: boolean, kickMessage: string, alertKind: string }
)
	local userId = player.UserId
	if BanRegistry then
		BanRegistry:Ban(userId, reason, durationSeconds, by)
	end
	local profile = if EvasionDetector then EvasionDetector:SaveProfile(player, reason) else nil
	if BanBroadcast then
		BanBroadcast:Publish({
			userId = userId,
			reason = reason,
			durationSeconds = durationSeconds,
			by = by,
			profile = profile,
		})
	end
	pcall(function()
		local banParams: any = {
			UserIds = { userId },
			DisplayReason = opts.kickMessage,
			PrivateReason = reason,
			ExcludeAltAccounts = true,
			ApplyToUniverse = true,
			ApplyDeviceBlock = opts.deviceBlock,
		}
		if durationSeconds then
			banParams.Duration = durationSeconds
		end
		Players:BanAsync(banParams)
	end)
	if player.Parent then
		player:Kick(opts.kickMessage)
	end
	if LineNotifier then
		LineNotifier:Alert(opts.alertKind, player, reason)
	end
end

function SentinelStrike:BanPlayer(player: Player, reason: string, durationSeconds: number?, by: string)
	self:_BanInternal(player, reason, durationSeconds, by, {
		deviceBlock = true,
		kickMessage = "คุณถูกระงับชั่วคราวจาก Utopia of Eternity — อุทธรณ์ผ่าน Support Desk",
		alertKind = "TEMP_BAN",
	})
end

function SentinelStrike:PermanentBan(player: Player, reason: string, by: string)
	self:_BanInternal(player, reason, nil, by, {
		deviceBlock = true,
		kickMessage = "คุณถูกระงับถาวรจาก Utopia of Eternity — อุทธรณ์ผ่าน Support Desk",
		alertKind = "PERM_BAN",
	})
end

function SentinelStrike:DeviceBan(player: Player, reason: string, durationSeconds: number)
	self:_BanInternal(player, reason, durationSeconds, "DeviceBan", {
		deviceBlock = true,
		kickMessage = "อุปกรณ์นี้ถูกระงับ 7 วัน — multi-account/emulator ตรวจพบ",
		alertKind = "DEVICE_BAN_7D",
	})
end

function SentinelStrike:PermanentDeviceBan(player: Player, reason: string)
	self:PermanentBan(player, reason, "PermanentDeviceBan")
end

function SentinelStrike:Strike(player: Player, anomalyType: string, score: number, detail: string)
	local userId = player.UserId
	local now = os.time()
	local entry = strikeCounts[userId]
	if not entry or (now - entry.lastAt) > 86400 then
		entry = { count = 0, lastAt = now }
		strikeCounts[userId] = entry
	end
	entry.count += 1
	entry.lastAt = now
	if entry.count >= 2 or score >= GameConfig.Security.SUSPICION_KICK then
		self:BanPlayer(
			player,
			string.format("Sentinel strike 2: %s — %s", anomalyType, detail),
			GameConfig.Security.STRIKE2_BAN_SECONDS,
			"SentinelStrike"
		)
		return
	end
	self:Warn(player, string.format("%s — %s", anomalyType, detail), score)
end

function SentinelStrike:ClearPlayer(userId: number)
	strikeCounts[userId] = nil
	if SuspicionTracker then
		-- SuspicionTracker uses Player object for Clear — skip here
	end
end

return SentinelStrike
