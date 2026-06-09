--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SupportDeskService = require(script.Parent:WaitForChild("SupportDeskService"))
local LogExportBridge = require(script.Parent:WaitForChild("LogExportBridge"))
local RateLimiter = require(script.Parent:WaitForChild("RateLimiter"))

SupportDeskService.init({ LogExportBridge = LogExportBridge })

local remotes = ReplicatedStorage:WaitForChild("SupportDeskRemotes")
local submitFanReport = remotes:WaitForChild("SubmitFanReport") :: RemoteFunction
local submitBanAppeal = remotes:WaitForChild("SubmitBanAppeal") :: RemoteFunction
local getSupportDeskInfo = remotes:WaitForChild("GetSupportDeskInfo") :: RemoteFunction

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

getSupportDeskInfo.OnServerInvoke = function(_player: Player)
	local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
	local community = (GameConfig :: any).Community
	local communityUrl = if typeof(community) == "table" and typeof(community.url) == "string"
		then community.url
		else ""
	local communityGroupId = if typeof(community) == "table" and typeof(community.groupId) == "number"
		then community.groupId
		else 0
	return {
		ok = true,
		webUrl = GameConfig.WEB_URL,
		programName = GameConfig.FanLicense.ProgramName,
		communityUrl = communityUrl,
		communityGroupId = communityGroupId,
		fanReportEnabled = SupportDeskService.getFanReportUrl() ~= "",
	}
end

submitFanReport.OnServerInvoke = function(
	player: Player,
	experienceId: number,
	title: string,
	description: string
)
	if not allow(player, "SupportFanReport", 3, 3600) then
		return false, "Rate limited — max 3 fan reports per hour"
	end
	if typeof(experienceId) ~= "number" then
		return false, "Invalid Experience ID"
	end
	if typeof(title) ~= "string" or typeof(description) ~= "string" then
		return false, "Invalid form data"
	end
	return SupportDeskService.submitFanReport(player, math.floor(experienceId), title, description)
end

submitBanAppeal.OnServerInvoke = function(player: Player, message: string)
	if not allow(player, "SupportBanAppeal", 1, 86400) then
		return false, "Rate limited — max 1 appeal per day"
	end
	if typeof(message) ~= "string" then
		return false, "Invalid appeal message"
	end
	return SupportDeskService.submitBanAppeal(player, message)
end

print("[SupportDesk] Handlers ready")
