--!strict
--[[
	MvpBossHUD — HP bar, attack button, spawn/defeat/MVP announcements
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local getMvpStateRF = remotes:WaitForChild("GetMvpBossState") :: RemoteFunction
local attackMvpRF = remotes:WaitForChild("AttackMvpBoss") :: RemoteFunction
local stateChangedEv = remotes:WaitForChild("MvpBossStateChanged") :: RemoteEvent
local spawnedEv = remotes:WaitForChild("MvpBossSpawned") :: RemoteEvent
local defeatedEv = remotes:WaitForChild("MvpBossDefeated") :: RemoteEvent
local mvpAnnounceEv = remotes:WaitForChild("MvpAnnounce") :: RemoteEvent

local sg = Instance.new("ScreenGui")
sg.Name = "MvpBossHUD"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 8
sg.Parent = playerGui

local hpFrame = Instance.new("Frame")
hpFrame.Name = "BossHpFrame"
hpFrame.Size = UDim2.fromOffset(400, 60)
hpFrame.Position = UDim2.new(0.5, -200, 0, 12)
hpFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
hpFrame.BorderSizePixel = 0
hpFrame.Visible = false
hpFrame.Parent = sg
local hpFrameCorner = Instance.new("UICorner")
hpFrameCorner.CornerRadius = UDim.new(0, 8)
hpFrameCorner.Parent = hpFrame

local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.Text = ""
bossNameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
bossNameLabel.Font = Enum.Font.GothamBold
bossNameLabel.TextSize = 14
bossNameLabel.Parent = hpFrame

local hpBar = Instance.new("Frame")
hpBar.Name = "HpBar"
hpBar.Size = UDim2.new(1, -16, 0, 12)
hpBar.Position = UDim2.new(0, 8, 0.6, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpFrame
local hpBarCorner = Instance.new("UICorner")
hpBarCorner.CornerRadius = UDim.new(0, 4)
hpBarCorner.Parent = hpBar

local hpFill = Instance.new("Frame")
hpFill.Name = "Fill"
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBar
local hpFillCorner = Instance.new("UICorner")
hpFillCorner.CornerRadius = UDim.new(0, 4)
hpFillCorner.Parent = hpFill

local attackBtn = Instance.new("TextButton")
attackBtn.Size = UDim2.fromOffset(120, 40)
attackBtn.Position = UDim2.new(0.5, -60, 0, 78)
attackBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
attackBtn.BorderSizePixel = 0
attackBtn.Text = "⚔️ โจมตี MVP"
attackBtn.TextColor3 = Color3.new(1, 1, 1)
attackBtn.Font = Enum.Font.GothamBold
attackBtn.TextSize = 13
attackBtn.Visible = false
attackBtn.Parent = sg
local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 8)
attackCorner.Parent = attackBtn

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromOffset(220, 24)
timerLabel.Position = UDim2.new(0.5, -110, 0, 78)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextSize = 12
timerLabel.Visible = false
timerLabel.Parent = sg

local announceBanner = Instance.new("Frame")
announceBanner.Size = UDim2.fromOffset(500, 60)
announceBanner.Position = UDim2.new(0.5, -250, 0.4, -30)
announceBanner.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
announceBanner.BorderSizePixel = 0
announceBanner.Visible = false
announceBanner.Parent = sg
local announceCorner = Instance.new("UICorner")
announceCorner.CornerRadius = UDim.new(0, 10)
announceCorner.Parent = announceBanner

local announceLabel = Instance.new("TextLabel")
announceLabel.Size = UDim2.fromScale(1, 1)
announceLabel.BackgroundTransparency = 1
announceLabel.TextColor3 = Color3.new(1, 1, 1)
announceLabel.Font = Enum.Font.GothamBold
announceLabel.TextSize = 16
announceLabel.Parent = announceBanner

local function showAnnounce(text: string, color: Color3)
	announceLabel.Text = text
	announceBanner.BackgroundColor3 = color
	announceBanner.Visible = true
	task.delay(4, function()
		announceBanner.Visible = false
	end)
end

local function updateHUD(state: { [string]: any })
	local active: boolean = state.bossActive == true
	hpFrame.Visible = active
	attackBtn.Visible = active
	timerLabel.Visible = not active

	if active then
		bossNameLabel.Text = string.format("%s %s", tostring(state.bossEmoji), tostring(state.bossName))
		local pct = if (state.bossMaxHp or 0) > 0
			then (state.bossHp or 0) / (state.bossMaxHp or 1)
			else 0
		TweenService:Create(hpFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(pct, 1) }):Play()
	else
		local secs: number = state.nextSpawnSec or 0
		local h = math.floor(secs / 3600)
		local m = math.floor((secs % 3600) / 60)
		timerLabel.Text = string.format("⏰ MVP Boss ถัดไปใน %dh %dm", h, m)
	end
end

stateChangedEv.OnClientEvent:Connect(updateHUD)

spawnedEv.OnClientEvent:Connect(function(bossName: string, emoji: string)
	showAnnounce(
		string.format("⚠️ %s %s ปรากฏแล้ว! รีบไปสู้!", emoji, bossName),
		Color3.fromRGB(180, 40, 40)
	)
end)

defeatedEv.OnClientEvent:Connect(function(bossName: string)
	showAnnounce(
		string.format("🏆 %s พ่ายแล้ว! ขอบคุณทุกคน!", bossName),
		Color3.fromRGB(40, 160, 80)
	)
end)

mvpAnnounceEv.OnClientEvent:Connect(function(bossName: string, itemId: string)
	showAnnounce(
		string.format("👑 MVP! คุณได้ %s จาก %s!", itemId, bossName),
		Color3.fromRGB(200, 150, 20)
	)
end)

attackBtn.MouseButton1Click:Connect(function()
	attackBtn.Active = false
	local ok, success, msg = pcall(function()
		return attackMvpRF:InvokeServer()
	end)
	if not ok then
		showAnnounce("❌ " .. tostring(success), Color3.fromRGB(160, 40, 40))
	elseif success ~= true then
		showAnnounce("❌ " .. tostring(msg), Color3.fromRGB(160, 40, 40))
	end
	task.delay(0.5, function()
		attackBtn.Active = true
	end)
end)

task.spawn(function()
	local ok, state = pcall(function()
		return getMvpStateRF:InvokeServer()
	end)
	if ok and state then
		updateHUD(state :: { [string]: any })
	end
end)
