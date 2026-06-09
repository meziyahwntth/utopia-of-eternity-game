--!strict
--[[
	Phase O — Join digest for offline social notifications (preset share, market, etc.).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local socialNotifyDigest = remotes:WaitForChild("SocialNotifyDigest") :: RemoteEvent
local teleportToFriend = remotes:WaitForChild("TeleportToFriend") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleySocialJoinDigest"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.Parent = playerGui

local toast = Instance.new("Frame")
toast.Size = UDim2.fromOffset(360, 72)
toast.Position = UDim2.new(0.5, -180, 0, 96)
toast.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
toast.BorderSizePixel = 0
toast.Visible = false
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 0, 18)
titleLabel.Position = UDim2.fromOffset(8, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
titleLabel.Text = "While you were away"
titleLabel.Parent = toast

local bodyLabel = Instance.new("TextLabel")
bodyLabel.Size = UDim2.new(1, -16, 0, 36)
bodyLabel.Position = UDim2.fromOffset(8, 26)
bodyLabel.BackgroundTransparency = 1
bodyLabel.Font = Enum.Font.Gotham
bodyLabel.TextSize = 11
bodyLabel.TextWrapped = true
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
bodyLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
bodyLabel.Text = ""
bodyLabel.Parent = toast

local function showDigest(entries: { any })
	if typeof(entries) ~= "table" or #entries == 0 then
		return
	end
	local lines: { string } = {}
	for index, entry in entries do
		if index > 3 then
			break
		end
		if typeof(entry) == "table" and typeof(entry.body) == "string" then
			table.insert(lines, entry.body)
		end
	end
	if #entries > 3 then
		table.insert(lines, string.format("+%d more notifications", #entries - 3))
	end
	bodyLabel.Text = table.concat(lines, "\n")
	toast.Visible = true
	local tweenIn = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0 })
	tweenIn:Play()
	task.delay(8, function()
		local tweenOut = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		tweenOut:Play()
		tweenOut.Completed:Wait()
		toast.Visible = false
	end)
end

socialNotifyDigest.OnClientEvent:Connect(function(entries)
	showDigest(entries)
end)

player:GetAttributeChangedSignal("DV_LaunchPresetMsg"):Connect(function()
	local msg = player:GetAttribute("DV_LaunchPresetMsg")
	if typeof(msg) == "string" and msg ~= "" then
		bodyLabel.Text = msg
		titleLabel.Text = "Preset Link"
		toast.Visible = true
	end
end)

player:GetAttributeChangedSignal("DV_FriendJoinMsg"):Connect(function()
	local msg = player:GetAttribute("DV_FriendJoinMsg")
	if typeof(msg) == "string" and msg ~= "" then
		bodyLabel.Text = msg
		titleLabel.Text = "Friend Join"
		toast.Visible = true
	end
end)

-- Expose join helper for other UI modules via attribute routing
player:GetAttributeChangedSignal("DV_JoinFriendRequest"):Connect(function()
	local targetUserId = player:GetAttribute("DV_JoinFriendRequest")
	if typeof(targetUserId) == "number" then
		player:SetAttribute("DV_JoinFriendRequest", nil)
		teleportToFriend:InvokeServer(targetUserId)
	end
end)
