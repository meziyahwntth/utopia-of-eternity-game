--!strict
-- MercenaryHandlers (P5+) — wire SocialRemotes → Mercenary + Bounty services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MercenaryService = require(script.Parent:WaitForChild("MercenaryService"))
local BountyService = require(script.Parent:WaitForChild("BountyService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function RF(name: string): RemoteFunction
	return remotes:WaitForChild(name) :: RemoteFunction
end

RF("PostEscort").OnServerInvoke = function(player: Player, pay: any, destination: any)
	if typeof(pay) ~= "number" or typeof(destination) ~= "string" then
		return false, "invalid"
	end
	return MercenaryService.postEscort(player, pay, destination)
end

RF("AcceptEscort").OnServerInvoke = function(player: Player, jobId: any)
	if typeof(jobId) ~= "string" then
		return false, "invalid"
	end
	return MercenaryService.acceptEscort(player, jobId)
end

RF("CompleteEscort").OnServerInvoke = function(player: Player, jobId: any)
	if typeof(jobId) ~= "string" then
		return false, "invalid"
	end
	return MercenaryService.completeEscort(player, jobId)
end

RF("GetEscortJobs").OnServerInvoke = function(_player: Player)
	return MercenaryService.getOpenJobs()
end

RF("PostBounty").OnServerInvoke = function(player: Player, targetId: any, amount: any)
	if typeof(targetId) ~= "number" or typeof(amount) ~= "number" then
		return false, "invalid"
	end
	return BountyService.post(player, targetId, amount)
end

RF("GetBounties").OnServerInvoke = function(_player: Player)
	return BountyService.getActiveBounties()
end

RF("GetBountyOn").OnServerInvoke = function(_player: Player, targetId: any)
	if typeof(targetId) ~= "number" then
		return 0
	end
	return BountyService.getBountiesOnTarget(targetId)
end

local function hookPlayerDeath(player: Player)
	player.CharacterAdded:Connect(function(char: Model)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.Died:Connect(function()
			local killerRaw = hum:GetAttribute("LastAttackerUserId")
			if typeof(killerRaw) == "number" and killerRaw ~= player.UserId then
				BountyService.onTargetKilled(killerRaw, player.UserId)
			end
		end)
	end)
end

Players.PlayerAdded:Connect(hookPlayerDeath)
for _, player in Players:GetPlayers() do
	hookPlayerDeath(player)
end

print("[Mercenary] MercenaryHandlers online (P5+)")
