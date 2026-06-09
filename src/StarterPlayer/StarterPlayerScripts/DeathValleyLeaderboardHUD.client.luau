--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getLeaderboard = remotes:WaitForChild("GetLeaderboard") :: RemoteFunction
local nightSurvived = remotes:WaitForChild("NightSurvived") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "DeathValleyLeaderboardHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 12, 1, -12)
panel.Size = UDim2.fromOffset(260, 160)
panel.BackgroundColor3 = Color3.fromRGB(14, 10, 22)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = hud
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 20)
title.Position = UDim2.fromOffset(8, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 179, 71)
title.Text = "Season Leaderboard"
title.Parent = panel

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, -12, 1, -32)
body.Position = UDim2.fromOffset(8, 26)
body.Font = Enum.Font.Gotham
body.TextSize = 11
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.TextColor3 = Color3.fromRGB(220, 210, 255)
body.Text = "Loading..."
body.Parent = panel

local function refresh()
	local data = getLeaderboard:InvokeServer()
	if typeof(data) ~= "table" then
		return
	end
	local lines: { string } = {}
	local season = data.season
	if typeof(season) == "table" then
		title.Text = "Season · " .. tostring(season.seasonName or season.seasonId)
	end
	if typeof(data.entries) == "table" then
		for _, entry in data.entries do
			if typeof(entry) == "table" then
				table.insert(
					lines,
					string.format("#%d %s — %d nights", entry.rank or 0, entry.displayName or "?", entry.nightsSurvived or 0)
				)
			end
		end
	end
	if data.myBestNights and (data.myBestNights :: number) > 0 then
		table.insert(lines, string.format("You: %d nights (rank %s)", data.myBestNights, tostring(data.myRank or "—")))
	end
	body.Text = if #lines > 0 then table.concat(lines, "\n") else "No entries yet — survive nights!"
end

nightSurvived.OnClientEvent:Connect(function()
	task.defer(refresh)
end)

task.spawn(function()
	while true do
		refresh()
		task.wait(30)
	end
end)

print("[DeathValley] Leaderboard HUD ready")
