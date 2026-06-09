--!strict
--[[
	Severe / malicious offenses → permanent ban immediately.
	Cheat, hack, server attack, honeypot, backdoor, exploit remotes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local SevereOffenseGate = {}

local SentinelStrike
local LogExportBridge

local SEVERE_PREFIXES = {
	"HONEYPOT_",
	"BACKDOOR_",
	"EXECUTOR_",
	"SERVER_FLOOD_",
	"REMOTE_INJECT_",
	"DATASTORE_ATTACK_",
	"MALICIOUS_",
}

function SevereOffenseGate:Init(deps: { SentinelStrike: any, LogExportBridge: any? })
	SentinelStrike = deps.SentinelStrike
	LogExportBridge = deps.LogExportBridge
end

function SevereOffenseGate:IsSevereReason(reason: string): boolean
	for _, prefix in SEVERE_PREFIXES do
		if string.sub(reason, 1, #prefix) == prefix then
			return true
		end
	end
	return GameConfig.Security.SEVERE_REASONS[reason] == true
end

function SevereOffenseGate:Handle(player: Player, reason: string, detail: string?)
	if not SentinelStrike then
		return
	end
	local full = if detail then reason .. " — " .. detail else reason
	if LogExportBridge then
		LogExportBridge:Enqueue("SEVERE_OFFENSE", {
			userId = player.UserId,
			name = player.Name,
			reason = full,
		})
	end
	SentinelStrike:PermanentBan(player, full, "SevereOffenseGate")
end

function SevereOffenseGate:HandleRemoteExploit(player: Player, remoteName: string)
	self:Handle(player, "EXECUTOR_REMOTE", remoteName)
end

function SevereOffenseGate:HandleServerFlood(player: Player, remoteName: string, count: number)
	self:Handle(player, "SERVER_FLOOD", string.format("%s x%d", remoteName, count))
end

return SevereOffenseGate
