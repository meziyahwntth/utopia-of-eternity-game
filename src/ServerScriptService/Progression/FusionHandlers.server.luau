--!strict
-- FusionHandlers — wire SocialRemotes → FusionService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FusionService = require(script.Parent:WaitForChild("FusionService"))
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local GetAllFusionRecipesRF = ensure("RemoteFunction", "GetAllFusionRecipes") :: RemoteFunction
local FuseItemRF = ensure("RemoteFunction", "FuseItem") :: RemoteFunction

GetAllFusionRecipesRF.OnServerInvoke = function(_player: Player)
	return FusionService.getAllRecipes()
end

FuseItemRF.OnServerInvoke = function(player: Player, inputItem: any)
	if typeof(inputItem) ~= "string" then
		return { ok = false, reason = "invalid input", output = nil }
	end
	return FusionService.fuse(player, inputItem)
end

print("[Progression] FusionHandlers online")
