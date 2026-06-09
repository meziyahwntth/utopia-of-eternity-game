--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MountRewardService = require(script.Parent:WaitForChild("MountRewardService"))
local EternityVehicleShop = require(script.Parent:WaitForChild("EternityVehicleShop"))

local remotes = ReplicatedStorage:WaitForChild("MountRemotes")
local getRewardCatalog = remotes:WaitForChild("GetRewardCatalog") :: RemoteFunction
local claimMountReward = remotes:WaitForChild("ClaimMountReward") :: RemoteFunction
local getEternityShopCatalog = remotes:WaitForChild("GetEternityShopCatalog") :: RemoteFunction
local devGrantEternityItem = remotes:WaitForChild("DevGrantEternityItem") :: RemoteFunction
local mountRewardResult = remotes:WaitForChild("MountRewardResult") :: RemoteEvent

local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

getRewardCatalog.OnServerInvoke = function(player: Player)
	if not allow(player, "GetRewardCatalog", 10, 60) then
		return { ok = false, message = "Rate limited" }
	end
	return MountRewardService.getRewardCatalog(player)
end

claimMountReward.OnServerInvoke = function(player: Player, choiceId: string, kind: string?)
	if not allow(player, "ClaimMountReward", 5, 60) then
		return false, "Rate limited"
	end
	if typeof(choiceId) ~= "string" or choiceId == "" then
		return false, "Invalid choice"
	end

	local ok: boolean
	local msg: string
	local rewardKind = if typeof(kind) == "string" then kind else "auto"

	if rewardKind == "weapon" or MountRewardService.getPendingReward(player) == 20 then
		ok, msg = MountRewardService.claimWeaponReward(player, choiceId)
	elseif rewardKind == "vehicle" or MountRewardService.getPendingReward(player) == 15 then
		ok, msg = MountRewardService.claimVehicleReward(player, choiceId)
	else
		ok, msg = MountRewardService.claimPetReward(player, choiceId)
	end

	mountRewardResult:FireClient(player, ok, msg)
	return ok, msg
end

getEternityShopCatalog.OnServerInvoke = function(player: Player)
	if not allow(player, "GetEternityShopCatalog", 10, 60) then
		return { ok = false, message = "Rate limited" }
	end
	return EternityVehicleShop.getCatalog(player)
end

-- DISABLED: DevGrantEternityItem is not available in production.
-- To re-enable for internal testing, set ENABLE_DEV_GRANT = true in a private Studio session only.
local ENABLE_DEV_GRANT = false
devGrantEternityItem.OnServerInvoke = function(player: Player, _itemId: string, _kind: string)
	if not ENABLE_DEV_GRANT then
		warn(string.format("[Mount] DevGrantEternityItem blocked for userId=%d — disabled in production", player.UserId))
		return false, "Not available"
	end
	-- Dead code path — only reachable if ENABLE_DEV_GRANT manually flipped in Studio
	return false, "Not configured"
end

MountRewardService.start()
print("[Mount] Handlers online")
