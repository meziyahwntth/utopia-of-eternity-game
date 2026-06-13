--!strict
--[[
	EmoteClient (P8) — 4-slot emote wheel + stop button (Scale-based)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoteConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EmoteConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local emotePlayed = remotes:WaitForChild("EmotePlayed") :: RemoteEvent
local emoteStopped = remotes:WaitForChild("EmoteStopped") :: RemoteEvent
local playEmoteRF = remotes:WaitForChild("PlayEmote") :: RemoteFunction
local stopEmoteRF = remotes:WaitForChild("StopEmote") :: RemoteFunction

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EmoteHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 4
screenGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.01, 0.88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextScaled = true
toggleBtn.Text = "😄"
toggleBtn.Parent = screenGui

local wheel = Instance.new("Frame")
wheel.Size = UDim2.fromScale(0.22, 0.25)
wheel.Position = UDim2.fromScale(0.01, 0.62)
wheel.BackgroundTransparency = 1
wheel.Visible = false
wheel.Parent = screenGui

local emotes = EmoteConfig.Emotes
for i, emote in ipairs(emotes) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.45, 0.45)
	btn.Position = UDim2.fromScale(((i - 1) % 2) * 0.52, math.floor((i - 1) / 2) * 0.52)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
	btn.BackgroundTransparency = 0.15
	btn.TextScaled = true
	btn.Text = emote.icon .. " " .. emote.nameTH
	btn.Parent = wheel

	btn.MouseButton1Click:Connect(function()
		wheel.Visible = false
		playEmoteRF:InvokeServer(emote.id)
	end)
end

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.fromScale(0.07, 0.05)
stopBtn.Position = UDim2.fromScale(0.09, 0.88)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
stopBtn.BackgroundTransparency = 0.15
stopBtn.TextScaled = true
stopBtn.Text = "⛔"
stopBtn.Visible = false
stopBtn.Parent = screenGui

stopBtn.MouseButton1Click:Connect(function()
	stopEmoteRF:InvokeServer()
	stopBtn.Visible = false
end)

toggleBtn.MouseButton1Click:Connect(function()
	wheel.Visible = not wheel.Visible
end)

local activeAnims: { [number]: AnimationTrack? } = {}

local function getAnimator(character: Model): Animator?
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	return hum:FindFirstChildOfClass("Animator")
end

emotePlayed.OnClientEvent:Connect(function(userId, _emoteId, animId, looped, duration)
	local uid = userId :: number
	local target = Players:GetPlayerByUserId(uid)
	if not target then
		return
	end
	local char = target.Character
	if not char then
		return
	end

	local animator = getAnimator(char)
	if not animator then
		return
	end

	local old = activeAnims[uid]
	if old then
		old:Stop()
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId :: string
	local track = animator:LoadAnimation(anim)
	track.Looped = looped :: boolean
	track:Play()
	activeAnims[uid] = track

	if not (looped :: boolean) and (duration :: number) > 0 then
		task.delay(duration :: number, function()
			if activeAnims[uid] == track then
				track:Stop()
				activeAnims[uid] = nil
			end
		end)
	end

	if uid == localPlayer.UserId and (looped :: boolean) then
		stopBtn.Visible = true
	end
end)

emoteStopped.OnClientEvent:Connect(function(userId)
	local uid = userId :: number
	local track = activeAnims[uid]
	if track then
		track:Stop()
		activeAnims[uid] = nil
	end
	if uid == localPlayer.UserId then
		stopBtn.Visible = false
	end
end)
