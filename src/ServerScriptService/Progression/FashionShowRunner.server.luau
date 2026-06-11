--!strict
--[[
	Fashion Show — boot state machine after Eternity City world build.
]]
local ServerScriptService = game:GetService("ServerScriptService")

local FashionShowService = require(script.Parent:WaitForChild("FashionShowService"))

FashionShowService.start()
print("[FashionShow] Runner online")
