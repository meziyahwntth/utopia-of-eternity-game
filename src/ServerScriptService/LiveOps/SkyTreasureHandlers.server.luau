--!strict
-- SkyTreasureHandlers (P6) — wire SocialRemotes → SkyTreasureService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkyTreasureService = require(script.Parent:WaitForChild("SkyTreasureService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local claimChest = remotes:WaitForChild("ClaimChest") :: RemoteFunction
claimChest.OnServerInvoke = function(player: Player, chestId: any)
	if typeof(chestId) ~= "string" then
		return false, "invalid"
	end
	return SkyTreasureService.claimChest(player, chestId)
end

SkyTreasureService.init(remotes)

print("[LiveOps] SkyTreasureHandlers online (P6)")
