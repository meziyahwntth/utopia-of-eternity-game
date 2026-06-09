--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local DungeonLoadoutService = require(script.Parent:WaitForChild("DungeonLoadoutService"))
DungeonLoadoutService.start()
