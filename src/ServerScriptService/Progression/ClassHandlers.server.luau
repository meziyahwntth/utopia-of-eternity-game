--!strict
-- ClassHandlers — wire Class remotes → ClassService + init service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("ClassService"))

local remotes = ReplicatedStorage:WaitForChild("ClassRemotes")
local requestChange = remotes:WaitForChild("RequestClassChange") :: RemoteFunction
local getMyClass = remotes:WaitForChild("GetMyClass") :: RemoteFunction

ClassService.init()

requestChange.OnServerInvoke = function(player: Player, targetClassId: any)
	local ok, msg = ClassService.requestChange(player, targetClassId)
	return ok, msg
end

getMyClass.OnServerInvoke = function(player: Player)
	local def = ClassService.getClassDef(player)
	if not def then
		return nil
	end
	return def.id, def.skills
end

print("[Class] handlers online")
