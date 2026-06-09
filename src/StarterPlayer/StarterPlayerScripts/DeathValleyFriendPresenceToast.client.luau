--!strict
--[[
	Phase N — Toast when a Roblox friend comes online (with city name).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local friendPresenceNotify = remotes:WaitForChild("FriendPresenceNotify") :: RemoteEvent
local teleportToFriend = remotes:WaitForChild("TeleportToFriend") :: RemoteFunction

local pendingFriendUserId: number? = nil

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleyFriendPresenceToast"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Parent = playerGui

local toast = Instance.new("Frame")
toast.Name = "Toast"
toast.Size = UDim2.fromOffset(320, 72)
toast.Position = UDim2.new(1, -336, 0, 72)
toast.BackgroundColor3 = Color3.fromRGB(22, 18, 36)
toast.BorderSizePixel = 0
toast.Visible = false
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 90, 180)
stroke.Thickness = 1
stroke.Parent = toast

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 0, 18)
titleLabel.Position = UDim2.fromOffset(8, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
titleLabel.Text = "Friend Online"
titleLabel.Parent = toast

local bodyLabel = Instance.new("TextLabel")
bodyLabel.Size = UDim2.new(1, -90, 0, 22)
bodyLabel.Position = UDim2.fromOffset(8, 24)
bodyLabel.BackgroundTransparency = 1
bodyLabel.Font = Enum.Font.Gotham
bodyLabel.TextSize = 11
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
bodyLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
bodyLabel.TextWrapped = true
bodyLabel.Text = ""
bodyLabel.Parent = toast

local joinBtn = Instance.new("TextButton")
joinBtn.Size = UDim2.fromOffset(72, 24)
joinBtn.Position = UDim2.new(1, -80, 1, -32)
joinBtn.Text = "Join"
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextSize = 10
joinBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 90)
joinBtn.TextColor3 = Color3.new(1, 1, 1)
joinBtn.Visible = false
joinBtn.Parent = toast
Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 5)

joinBtn.MouseButton1Click:Connect(function()
	if pendingFriendUserId then
		local ok, msg = teleportToFriend:InvokeServer(pendingFriendUserId)
		player:SetAttribute("DV_FriendJoinMsg", msg)
		toast.Visible = false
	end
end)

local hideThread: thread? = nil

local function showToast(body: string, heading: string?, friendUserId: number?)
	if hideThread then
		task.cancel(hideThread)
		hideThread = nil
	end
	pendingFriendUserId = friendUserId
	joinBtn.Visible = typeof(friendUserId) == "number"
	titleLabel.Text = heading or "Friend Online"
	bodyLabel.Text = body
	toast.Visible = true
	toast.BackgroundTransparency = 0.1
	local tweenIn = TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 })
	tweenIn:Play()
	hideThread = task.delay(5, function()
		local tweenOut = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		tweenOut:Play()
		tweenOut.Completed:Wait()
		toast.Visible = false
		hideThread = nil
	end)
end

friendPresenceNotify.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	if payload.eventType == "offline" then
		return
	end
	local placeText = if typeof(payload.placeDisplayName) == "string" and payload.placeDisplayName ~= ""
		then payload.placeDisplayName
		else "Utopia"
	local nameText = if typeof(payload.displayName) == "string" then payload.displayName else "Friend"
	local friendUserId = if typeof(payload.friendUserId) == "number" then payload.friendUserId else nil
	showToast(string.format("%s is online in %s", nameText, placeText), nil, friendUserId)
end)

player:GetAttributeChangedSignal("DV_FriendPresenceMsg"):Connect(function()
	local msg = player:GetAttribute("DV_FriendPresenceMsg")
	if typeof(msg) == "string" and msg ~= "" then
		showToast(msg)
	end
end)
