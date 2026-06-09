--!strict
--[[
	Phase I — Studio-only season rollover admin helpers.
]]

local RunService = game:GetService("RunService")

local DeathValleySeasonRolloverService = require(script.Parent:WaitForChild("DeathValleySeasonRolloverService"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))

local DeathValleySeasonAdminService = {}

local function isStudioAdmin(player: Player): boolean
	if not RunService:IsStudio() then
		return false
	end
	local creatorId = game.CreatorId
	if creatorId > 0 and player.UserId == creatorId then
		return true
	end
	return player.UserId > 0
end

function DeathValleySeasonAdminService.canUseAdmin(player: Player): boolean
	return isStudioAdmin(player)
end

function DeathValleySeasonAdminService.forceSeasonRollover(player: Player): (boolean, string)
	if not isStudioAdmin(player) then
		return false, "Studio admin only"
	end
	return DeathValleySeasonRolloverService.adminForceRollover()
end

function DeathValleySeasonAdminService.deliverRolloverRewards(player: Player): (boolean, string)
	if not isStudioAdmin(player) then
		return false, "Studio admin only"
	end
	DeathValleySeasonRolloverService.deliverPendingForPlayer(player)
	local msg = player:GetAttribute("DV_RolloverRewardMsg")
	if typeof(msg) == "string" and msg ~= "" then
		return true, msg
	end
	return true, "No pending auto rewards (queue top-25 first via Force Rollover)"
end

function DeathValleySeasonAdminService.resetSeasonPointer(player: Player): (boolean, string)
	if not isStudioAdmin(player) then
		return false, "Studio admin only"
	end
	return DeathValleySeasonRolloverService.adminResetSeasonPointer()
end

function DeathValleySeasonAdminService.toPublicPayload(player: Player): { [string]: any }
	return {
		studioAdmin = isStudioAdmin(player),
		currentSeasonId = DeathValleySeasonService.getCurrentSeasonId(),
		rollover = DeathValleySeasonRolloverService.toPublicPayload(),
	}
end

return DeathValleySeasonAdminService
