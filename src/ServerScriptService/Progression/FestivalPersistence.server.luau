--!strict
--[[
	Festival Phase 2 — Daily Festival Persistence Bootstrap
	Hydrates DailyStreakService + DailyQuestService on join/leave
	Follows PrismKeyPersistence.server.luau pattern
]]
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DailyStreakService = require(script.Parent:WaitForChild("DailyStreakService"))
local DailyQuestService = require(script.Parent:WaitForChild("DailyQuestService"))

local function onPlayerAdded(player: Player)
	task.spawn(function()
		DailyStreakService.onPlayerAdded(player)
		DailyQuestService.onPlayerAdded(player)
	end)
end

local function onPlayerRemoving(player: Player)
	DailyStreakService.onPlayerRemoving(player)
	DailyQuestService.onPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print("[Festival] Daily persistence ready")