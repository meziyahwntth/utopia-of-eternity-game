--!strict
-- VisiblePowerHandlers (P7) — init PlayerLevelService + tier remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerLevelService = require(script.Parent:WaitForChild("PlayerLevelService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
PlayerLevelService.init(remotes)

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
	PlayerLevelService.onPlayerReady(player)
end

print("[Progression] VisiblePowerHandlers online (P7)")
