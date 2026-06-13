--!strict
--[[
	LevelHUDClient — XP bar + level badge + level-up flash banner
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local levelUpEv = remotes:WaitForChild("LevelUp") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2
screenGui.Parent = playerGui

local badge = Instance.new("Frame")
badge.Size = UDim2.fromScale(0.09, 0.05)
badge.Position = UDim2.fromScale(0.01, 0.01)
badge.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
badge.BackgroundTransparency = 0.15
badge.BorderSizePixel = 0
badge.Parent = screenGui

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0.2, 0)
badgeCorner.Parent = badge

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.fromScale(1, 0.45)
levelLabel.Position = UDim2.fromScale(0, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
levelLabel.TextScaled = true
levelLabel.Text = "Lv 1"
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Parent = badge

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.fromScale(1, 0.28)
xpLabel.Position = UDim2.fromScale(0, 0.37)
xpLabel.BackgroundTransparency = 1
xpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
xpLabel.TextScaled = true
xpLabel.Text = "0 / 105 XP"
xpLabel.Font = Enum.Font.Gotham
xpLabel.Parent = badge

local xpBg = Instance.new("Frame")
xpBg.Size = UDim2.fromScale(1, 0.25)
xpBg.Position = UDim2.fromScale(0, 0.65)
xpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
xpBg.BorderSizePixel = 0
xpBg.Parent = badge

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBg

local flashBanner = Instance.new("TextLabel")
flashBanner.Size = UDim2.fromScale(0.4, 0.08)
flashBanner.Position = UDim2.fromScale(0.3, -0.1)
flashBanner.BackgroundColor3 = Color3.fromRGB(255, 220, 60)
flashBanner.BackgroundTransparency = 0.1
flashBanner.TextColor3 = Color3.fromRGB(20, 20, 20)
flashBanner.TextScaled = true
flashBanner.Font = Enum.Font.GothamBold
flashBanner.Text = "⬆ LEVEL UP!"
flashBanner.Visible = false
flashBanner.ZIndex = 10
flashBanner.Parent = screenGui

local flashCorner = Instance.new("UICorner")
flashCorner.CornerRadius = UDim.new(0.15, 0)
flashCorner.Parent = flashBanner

local function showFlash(newLevel: number)
	flashBanner.Text = string.format("⬆ LEVEL %d!", newLevel)
	flashBanner.Visible = true
	local tweenIn = TweenService:Create(
		flashBanner,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.3, 0.08) }
	)
	tweenIn:Play()
	tweenIn.Completed:Wait()
	task.wait(2)
	local tweenOut = TweenService:Create(flashBanner, TweenInfo.new(0.3), { Position = UDim2.fromScale(0.3, -0.1) })
	tweenOut:Play()
	tweenOut.Completed:Wait()
	flashBanner.Visible = false
end

local function updateHUD()
	local lv = localPlayer:GetAttribute("PlayerLevel")
	local xp = localPlayer:GetAttribute("PlayerXP")
	local xpMax = localPlayer:GetAttribute("PlayerXPMax")

	local levelNum = if typeof(lv) == "number" then lv else 1
	local xpNum = if typeof(xp) == "number" then xp else 0
	local xpMaxNum = if typeof(xpMax) == "number" and xpMax > 0 then xpMax else 100

	levelLabel.Text = "Lv " .. tostring(levelNum)
	xpLabel.Text = tostring(xpNum) .. " / " .. tostring(xpMaxNum) .. " XP"

	local ratio = math.clamp(xpNum / xpMaxNum, 0, 1)
	TweenService:Create(xpFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
end

localPlayer:GetAttributeChangedSignal("PlayerXP"):Connect(updateHUD)
localPlayer:GetAttributeChangedSignal("PlayerLevel"):Connect(updateHUD)
localPlayer:GetAttributeChangedSignal("PlayerXPMax"):Connect(updateHUD)

levelUpEv.OnClientEvent:Connect(function(newLevel)
	task.spawn(showFlash, newLevel :: number)
end)

task.defer(function()
	task.wait(1)
	updateHUD()
end)
