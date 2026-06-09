--!strict
--[[
	Utopia Shield + Sentinel bootstrap.
	Phase 0.5 + Category I griefing / economy / severe offense layers.
]]
local Players = game:GetService("Players")

local securityFolder = script.Parent:WaitForChild("Security")

require(script.Parent:WaitForChild("BridgeBootstrap")):Apply()

local SuspicionTracker = require(securityFolder.SuspicionTracker)
local RateLimiter = require(securityFolder.RateLimiter)
local EconomyGuard = require(securityFolder.EconomyGuard)
local EconomyInflationGuard = require(securityFolder.EconomyInflationGuard)
local GriefingGuard = require(securityFolder.GriefingGuard)
local SevereOffenseGate = require(securityFolder.SevereOffenseGate)
local EmulatorDetector = require(securityFolder.EmulatorDetector)
local LogExportBridge = require(securityFolder.LogExportBridge)
local BanRegistry = require(securityFolder.BanRegistry)
local BanBroadcast = require(securityFolder.BanBroadcast)
local EvasionDetector = require(securityFolder.EvasionDetector)
local LineNotifier = require(securityFolder.LineNotifier)
local SentinelStrike = require(securityFolder.SentinelStrike)
local RemoteGuard = require(securityFolder.RemoteGuard)
local MovementValidator = require(securityFolder.MovementValidator)
local HoneypotRemotes = require(securityFolder.HoneypotRemotes)
local FanExperienceGuard = require(securityFolder.FanExperienceGuard)
local FanScanBridge = require(securityFolder.FanScanBridge)
local BackdoorScanner = require(securityFolder.BackdoorScanner)

SentinelStrike:Init({
	BanRegistry = BanRegistry,
	BanBroadcast = BanBroadcast,
	EvasionDetector = EvasionDetector,
	LineNotifier = LineNotifier,
	SuspicionTracker = SuspicionTracker,
})

SevereOffenseGate:Init({ SentinelStrike = SentinelStrike, LogExportBridge = LogExportBridge })
EmulatorDetector:Init({ SentinelStrike = SentinelStrike, LogExportBridge = LogExportBridge })

EconomyInflationGuard:Init({
	EconomyGuard = EconomyGuard,
	SuspicionTracker = SuspicionTracker,
	SentinelStrike = SentinelStrike,
	LogExportBridge = LogExportBridge,
})

GriefingGuard:Init({ SuspicionTracker = SuspicionTracker, SentinelStrike = SentinelStrike })
FanExperienceGuard:Init({ LogExportBridge = LogExportBridge })
FanScanBridge:Init({ FanExperienceGuard = FanExperienceGuard })

BanBroadcast:Init({ BanRegistry = BanRegistry })
BanBroadcast:StartListening()

RemoteGuard:Init({
	RateLimiter = RateLimiter,
	SuspicionTracker = SuspicionTracker,
	SentinelStrike = SentinelStrike,
	SevereOffenseGate = SevereOffenseGate,
})

MovementValidator:Init({
	SuspicionTracker = SuspicionTracker,
	SentinelStrike = SentinelStrike,
})

HoneypotRemotes:Init({
	SuspicionTracker = SuspicionTracker,
	SentinelStrike = SentinelStrike,
	SevereOffenseGate = SevereOffenseGate,
})

BackdoorScanner:Scan()
HoneypotRemotes:Deploy()
MovementValidator:Start()
LogExportBridge:StartAutoFlush()
FanScanBridge:StartPolling()

local function onPlayerAdded(player: Player)
	if BanRegistry:IsBanned(player.UserId) then
		player:Kick("คุณถูกระงับจาก Utopia of Eternity — อุทธรณ์ผ่าน Support Desk")
		return
	end
	local evasionScore = EvasionDetector:ScoreJoin(player)
	if EvasionDetector:ShouldBlock(evasionScore) then
		SentinelStrike:TempBan(player, "Evasion detected on join", 86400)
		LineNotifier:Alert("EVASION", player, evasionScore)
		return
	end
	if EvasionDetector:ShouldFlag(evasionScore) then
		player:Kick("ตรวจพบบัญชีที่อาจเกี่ยวข้องกับผู้เล่นที่ถูกระงับ — รอแอดมินตรวจสอบ")
		LineNotifier:Alert("EVASION_FLAG", player, evasionScore)
		return
	end
	task.defer(function()
		local platformName: string? = nil
		pcall(function()
			local UIS = game:GetService("UserInputService")
			platformName = tostring(UIS:GetPlatform())
		end)
		local emuScore = EmulatorDetector:ScoreSession(player, platformName)
		if EmulatorDetector:ShouldPunish(emuScore) then
			EmulatorDetector:Punish(player, platformName, string.format("score=%d cluster", emuScore))
		end
	end)
end

local function onPlayerRemoving(player: Player)
	RateLimiter:ClearPlayer(player)
	MovementValidator:ClearPlayer(player)
	SuspicionTracker:ClearPlayer(player)
	GriefingGuard:ClearPlayer(player.UserId)
	EconomyInflationGuard:ClearPlayer(player.UserId)
	EmulatorDetector:ClearPlayer(player.UserId)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

print("[Utopia of Eternity] Shield + Sentinel + Category I + Eternity Forge guards online.")

_G.UtopiaSecurity = {
	RemoteGuard = RemoteGuard,
	RateLimiter = RateLimiter,
	EconomyGuard = EconomyGuard,
	EconomyInflationGuard = EconomyInflationGuard,
	GriefingGuard = GriefingGuard,
	FanExperienceGuard = FanExperienceGuard,
	FanScanBridge = FanScanBridge,
	SevereOffenseGate = SevereOffenseGate,
	EmulatorDetector = EmulatorDetector,
	LogExportBridge = LogExportBridge,
	SuspicionTracker = SuspicionTracker,
	SentinelStrike = SentinelStrike,
	BanRegistry = BanRegistry,
	LineNotifier = LineNotifier,
}
