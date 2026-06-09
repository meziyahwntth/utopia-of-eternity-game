--!strict
--[[
	Poll Bridge fan-scan feed and score candidates via FanExperienceGuard.
]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local FanScanBridge = {}

local FanExperienceGuard

function FanScanBridge:Init(deps: { FanExperienceGuard: any })
	FanExperienceGuard = deps.FanExperienceGuard
end

function FanScanBridge:PollOnce(): boolean
	local url = GameConfig.Bridge.FAN_SCAN_URL
	if url == "" or not HttpService.HttpEnabled then
		return false
	end
	local headers = {}
	if GameConfig.Bridge.BRIDGE_KEY ~= "" then
		headers["X-Utopia-Bridge-Key"] = GameConfig.Bridge.BRIDGE_KEY
	end
	local ok, raw = pcall(function()
		return HttpService:GetAsync(url, false, headers)
	end)
	if not ok or typeof(raw) ~= "string" then
		warn("[Utopia] FanScanBridge poll failed")
		return false
	end
	local decodeOk, payload = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decodeOk or typeof(payload) ~= "table" then
		return false
	end
	local candidates = payload.candidates
	if typeof(candidates) ~= "table" then
		return true
	end
	for _, candidate in candidates do
		if typeof(candidate) == "table" and FanExperienceGuard then
			FanExperienceGuard:Evaluate(candidate)
		end
	end
	return true
end

function FanScanBridge:StartPolling()
	task.spawn(function()
		while true do
			self:PollOnce()
			task.wait(GameConfig.Bridge.FAN_SCAN_POLL_SECONDS)
		end
	end)
end

return FanScanBridge
