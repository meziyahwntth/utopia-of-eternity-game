--!strict
--[[
	Phase N — Start cross-place friend presence on all Utopia places.
]]

local DeathValleyFriendPresenceService = require(script.Parent:WaitForChild("DeathValleyFriendPresenceService"))

DeathValleyFriendPresenceService.start()

print("[DeathValley] Friend presence handlers online")
