--!strict
-- SpawnRouterBootstrap — route new players to Neon Utopia
local ServerScriptService = game:GetService("ServerScriptService")

local SpawnRouter = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("SpawnRouter"))

task.defer(function()
	SpawnRouter.init()
end)
