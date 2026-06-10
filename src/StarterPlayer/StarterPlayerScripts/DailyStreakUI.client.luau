--!strict
--[[
	Festival Phase 2 — Daily Streak UI (Client)
	Popup on join showing streak day + claim button
	Uses RemoteEvents (not RemoteFunction) per project pattern
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getStreakInfo = remotes:WaitForChild("GetStreakInfo") :: RemoteEvent
local claimStreakReward = remotes:WaitForChild("ClaimStreakReward") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyStreakUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.35)
root.Size = UDim2.fromOffset(380, 260)
root.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
root.BorderSizePixel = 0
root.Visible = false
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(212, 175, 55)
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 16)
title.Size = UDim2.new(1, -40, 0, 32)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(212, 175, 55)
title.Text = "Eternity Soundwave"
title.Parent = root

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Position = UDim2.fromOffset(20, 48)
sub.Size = UDim2.new(1, -40, 0, 20)
sub.Font = Enum.Font.Gotham
sub.TextSize = 14
sub.TextColor3 = Color3.fromRGB(0, 229, 255)
sub.Text = "Daily Login Streak"
sub.Parent = root

local streakText = Instance.new("TextLabel")
streakText.Name = "StreakInfo"
streakText.BackgroundTransparency = 1
streakText.Position = UDim2.fromOffset(20, 80)
streakText.Size = UDim2.new(1, -40, 0, 40)
streakText.Font = Enum.Font.GothamBold
streakText.TextSize = 16
streakText.TextColor3 = Color3.fromRGB(245, 245, 240)
streakText.Text = "Loading..."
streakText.Parent = root

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "RewardInfo"
rewardLabel.BackgroundTransparency = 1
rewardLabel.Position = UDim2.fromOffset(20, 120)
rewardLabel.Size = UDim2.new(1, -40, 0, 24)
rewardLabel.Font = Enum.Font.Gotham
rewardLabel.TextSize = 13
rewardLabel.TextColor3 = Color3.fromRGB(255, 200, 40)
rewardLabel.Text = ""
rewardLabel.Parent = root

local claimBtn = Instance.new("TextButton")
claimBtn.AnchorPoint = Vector2.new(0.5, 0)
claimBtn.Position = UDim2.new(0.5, 0, 0, 160)
claimBtn.Size = UDim2.fromOffset(200, 44)
claimBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
claimBtn.Font = Enum.Font.GothamBold
claimBtn.TextSize = 16
claimBtn.TextColor3 = Color3.fromRGB(15, 20, 35)
claimBtn.Text = "Claim Reward"
claimBtn.Parent = root

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = claimBtn

local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(20, 215)
statusText.Size = UDim2.new(1, -40, 0, 20)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 12
statusText.TextColor3 = Color3.fromRGB(0, 229, 255)
statusText.Text = ""
statusText.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(15, 20, 35)
closeBtn.Text = "X"
closeBtn.Parent = root

local btnCloseCorner = Instance.new("UICorner")
btnCloseCorner.CornerRadius = UDim.new(0, 8)
btnCloseCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	root.Visible = false
end)

local function showPopup(data)
	root.Visible = true
	local day = data and (data :: any).day
	if typeof(day) == "number" and day > 0 then
		streakText.Text = "Day " .. tostring(day) .. " / 7"
		local rewards = {5, 8, 12, 15, 20, 25, 30}
		if day <= 7 then
			local r = rewards[day] or 0
			rewardLabel.Text = "Today: +" .. tostring(r) .. " Luminite"
			if day == 7 then
				rewardLabel.Text = "Today: +30 Luminite + Festival Streak title"
			end
		end
		claimBtn.Text = "Claim"
		claimBtn.Visible = true
	else
		streakText.Text = "Loading..."
		claimBtn.Visible = false
	end
end

-- Listen for streak info
getStreakInfo.OnClientEvent:Connect(showPopup)

-- Claim button
claimBtn.MouseButton1Click:Connect(function()
	claimStreakReward:FireServer()
end)

-- Listen for claim result
claimStreakReward.OnClientEvent:Connect(function(result)
	if typeof(result) == "table" then
		local r = result :: any
		statusText.Text = r.message or ""
		if r.ok then
			claimBtn.Visible = false
			statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end
end)

-- Show on join with delay for world build
player.CharacterAdded:Wait()
task.wait(4)
getStreakInfo:FireServer()