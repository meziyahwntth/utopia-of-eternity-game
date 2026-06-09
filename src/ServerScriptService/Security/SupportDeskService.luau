--!strict
--[[
	P2 — Support Desk: fan-game reports → Bridge fan-scan/report; ban appeals → LogExportBridge.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local SupportDeskService = {}

local LogExportBridge

function SupportDeskService.init(deps: { LogExportBridge: any })
	LogExportBridge = deps.LogExportBridge
end

function SupportDeskService.getFanReportUrl(): string
	local configured = GameConfig.Bridge.FAN_SCAN_REPORT_URL
	if typeof(configured) == "string" and configured ~= "" then
		return configured
	end
	local base = GameConfig.Bridge.FAN_SCAN_URL
	if base == "" then
		return ""
	end
	if string.find(base, "/report", 1, true) then
		return base
	end
	return base .. "/report"
end

local function bridgeHeaders(): { [string]: string }
	local headers: { [string]: string } = {
		["Content-Type"] = "application/json",
	}
	if GameConfig.Bridge.BRIDGE_KEY ~= "" then
		headers["X-Utopia-Bridge-Key"] = GameConfig.Bridge.BRIDGE_KEY
	end
	return headers
end

function SupportDeskService.submitFanReport(
	player: Player,
	experienceId: number,
	title: string,
	description: string
): (boolean, string)
	if experienceId <= 0 then
		return false, "Enter a valid Experience ID"
	end
	if #title < 3 then
		return false, "Title must be at least 3 characters"
	end
	if #description < 10 then
		return false, "Description must be at least 10 characters"
	end
	if #title > 120 then
		return false, "Title too long"
	end
	if #description > 2000 then
		return false, "Description too long"
	end

	local url = SupportDeskService.getFanReportUrl()
	local payload = {
		experienceId = experienceId,
		title = title,
		description = description,
		creatorId = player.UserId,
	}

	if LogExportBridge then
		LogExportBridge:Enqueue("FAN_PLAYER_REPORT", {
			reporterUserId = player.UserId,
			reporterDisplayName = player.DisplayName,
			experienceId = experienceId,
			title = title,
			description = description,
		})
	end

	if url == "" or not HttpService.HttpEnabled then
		if LogExportBridge then
			LogExportBridge:Flush()
		end
		return true, "Report queued for review (offline mode)"
	end

	local body = HttpService:JSONEncode(payload)
	local ok, err = pcall(function()
		HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, bridgeHeaders())
	end)
	if not ok then
		warn("[SupportDesk] fan report POST failed:", err)
		if LogExportBridge then
			LogExportBridge:Flush()
		end
		return true, "Report saved locally — Bridge retry pending"
	end

	return true, "Report submitted — thank you"
end

function SupportDeskService.submitBanAppeal(player: Player, message: string): (boolean, string)
	if #message < 20 then
		return false, "Appeal must be at least 20 characters"
	end
	if #message > 4000 then
		return false, "Appeal too long"
	end

	if not LogExportBridge then
		return false, "Support system unavailable"
	end

	LogExportBridge:Enqueue("SUPPORT_APPEAL", {
		userId = player.UserId,
		displayName = player.DisplayName,
		accountAgeDays = player.AccountAge,
		message = message,
		universeId = GameConfig.UniverseId,
		at = os.time(),
	})

	local flushed = LogExportBridge:Flush()
	if flushed then
		return true, "Appeal submitted — team will review within 72 hours"
	end
	return true, "Appeal queued — will send when Bridge is reachable"
end

return SupportDeskService
