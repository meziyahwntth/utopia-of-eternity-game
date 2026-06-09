--!strict
--[[
	Phase O — LaunchData / TeleportData deep links + join social digest delivery.
]]

local Players = game:GetService("Players")

local DeathValleyFriendJoinService = require(script.Parent:WaitForChild("DeathValleyFriendJoinService"))
local DeathValleyLoadoutPresetShareService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetShareService"))
local DeathValleySocialNotifyService = require(script.Parent:WaitForChild("DeathValleySocialNotifyService"))

local DeathValleyJoinDataService = {}

local remotes = game:GetService("ReplicatedStorage"):WaitForChild("DeathValleyRemotes")
local socialNotifyDigest = remotes:WaitForChild("SocialNotifyDigest") :: RemoteEvent

local function extractPresetCode(raw: any): string?
	if typeof(raw) ~= "string" or raw == "" then
		return nil
	end
	local normalized = string.upper(string.gsub(raw, "[^%w]", ""))
	if string.sub(normalized, 1, 6) == "UTOPIA" then
		normalized = string.sub(normalized, 7)
	end
	if #normalized >= 6 then
		return normalized
	end
	return nil
end

local function readLaunchPresetCode(player: Player): string?
	local joinData = player:GetJoinData()
	local launchData = joinData.LaunchData
	if typeof(launchData) == "table" then
		local direct = extractPresetCode(launchData.utopiaPresetCode)
		if direct then
			return direct
		end
		local nested = launchData.utopia
		if typeof(nested) == "table" then
			return extractPresetCode(nested.presetCode)
		end
	end
	local teleportData = joinData.TeleportData
	if typeof(teleportData) == "table" then
		return extractPresetCode(teleportData.utopiaPresetCode)
	end
	return nil
end

function DeathValleyJoinDataService.handlePlayerJoin(player: Player)
	task.defer(function()
		DeathValleyFriendJoinService.handleArrival(player)

		local presetCode = readLaunchPresetCode(player)
		if presetCode then
			local ok, msg = DeathValleyLoadoutPresetShareService.redeemShareCode(player, presetCode)
			player:SetAttribute("DV_LaunchPresetMsg", msg)
			if ok then
				player:SetAttribute("DV_OpenUnifiedLoadoutTab", "shared")
			end
		end

		local queue = DeathValleySocialNotifyService.drainQueue(player)
		if #queue > 0 then
			player:SetAttribute("DV_SocialNotifyCount", #queue)
			socialNotifyDigest:FireClient(player, queue)
		end
	end)
end

function DeathValleyJoinDataService.start()
	Players.PlayerAdded:Connect(DeathValleyJoinDataService.handlePlayerJoin)
end

return DeathValleyJoinDataService
