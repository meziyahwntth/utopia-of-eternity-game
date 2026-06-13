--!strict
--[[
	VisiblePowerService (P7) — tier change → notify clients for aura/glow
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlayerTierConfig"))

local VisiblePowerService = {}

local remotes: Folder? = nil

function VisiblePowerService.onLevelChanged(player: Player, newLevel: number)
	if not remotes then
		return
	end
	local tier = PlayerTierConfig.getTierForLevel(newLevel)

	local tierChanged = remotes:FindFirstChild("TierChanged") :: RemoteEvent?
	if tierChanged then
		tierChanged:FireClient(player, tier.tier, tier.auraEnabled, tier.auraColor, tier.glowIntensity)
	end

	local tierChangedOther = remotes:FindFirstChild("PlayerTierBroadcast") :: RemoteEvent?
	if tierChangedOther then
		tierChangedOther:FireAllClients(player.UserId, tier.tier, tier.auraEnabled, tier.auraColor, tier.glowIntensity)
	end
end

function VisiblePowerService.init(remotesFolder: Folder)
	remotes = remotesFolder
end

return VisiblePowerService
