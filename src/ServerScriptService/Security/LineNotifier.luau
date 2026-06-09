--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local LineNotifier = {}

local BRIDGE_URL = "" -- set via ServerStorage config in production — never commit secrets

function LineNotifier:SetBridgeUrl(url: string)
	BRIDGE_URL = url
end

function LineNotifier:Alert(alertType: string, player: Player, detail: string | number)
	if BRIDGE_URL == "" then
		warn(string.format("[Utopia Sentinel] %s | %s (%d) | %s", alertType, player.Name, player.UserId, tostring(detail)))
		return
	end
	local payload = {
		type = alertType,
		playerName = player.Name,
		userId = player.UserId,
		jobId = game.JobId,
		detail = tostring(detail),
		time = DateTime.now():ToIsoDate(),
	}
	task.spawn(function()
		pcall(function()
			HttpService:PostAsync(
				BRIDGE_URL .. "/sentinel/alert",
				HttpService:JSONEncode(payload),
				Enum.HttpContentType.ApplicationJson
			)
		end)
	end)
end

return LineNotifier
