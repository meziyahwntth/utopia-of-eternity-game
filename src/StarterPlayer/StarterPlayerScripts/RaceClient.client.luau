--!strict
--[[
	RaceClient (Racing — NeonUtopia) — mobile-first HUD + checkpoint detection
	- หา start gate + checkpoint parts (attribute) ในแมพ (มีเฉพาะ NeonUtopia) — ถ้าไม่มี = เงียบ
	- ใกล้ start gate → ปุ่ม "เริ่มแข่ง" → StartRace
	- แตะ checkpoint → CheckpointPing (server validate order/proximity)
	- RaceState: timer / checkpoint X/N / finish (เวลา+รางวัล+best)
	- server เป็นผู้ตัดสินเวลา/รางวัล (client แค่แสดง)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RacingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RacingConfig"))

local remotes = ReplicatedStorage:WaitForChild("RacingRemotes", 15)
if not remotes then
	return
end
local startRace = remotes:WaitForChild("StartRace") :: RemoteFunction
local checkpointPing = remotes:WaitForChild("CheckpointPing") :: RemoteEvent
local raceState = remotes:WaitForChild("RaceState") :: RemoteEvent
local getBest = remotes:WaitForChild("GetBest") :: RemoteFunction

local CP_ATTR = RacingConfig.CheckpointAttribute
local TRACK_ATTR = RacingConfig.TrackIdAttribute

local raceActive = false
local activeTrackId: string? = nil
local clientStartClock = 0
local touchedCps: { [string]: boolean } = {} -- กัน fire ซ้ำต่อ checkpoint ต่อ run

local function getRoot(): BasePart?
	local char = localPlayer.Character
	local r = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	return if r and r:IsA("BasePart") then r else nil
end

----------------------------------------------------------------
-- HUD (mobile-first)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RaceHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = playerGui

-- ปุ่มเริ่มแข่ง (แสดงเมื่อใกล้ start gate)
local startBtn = Instance.new("TextButton")
startBtn.Name = "StartRaceBtn"
startBtn.AnchorPoint = Vector2.new(0.5, 1)
startBtn.Position = UDim2.new(0.5, 0, 0.86, 0)
startBtn.Size = UDim2.fromScale(0.32, 0.07)
startBtn.BackgroundColor3 = Color3.fromRGB(240, 200, 80)
startBtn.Text = "🏁 เริ่มแข่ง"
startBtn.TextScaled = true
startBtn.TextColor3 = Color3.fromRGB(30, 28, 20)
startBtn.Font = Enum.Font.GothamBold
startBtn.Visible = false
startBtn.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = startBtn
	local sz = Instance.new("UISizeConstraint")
	sz.MinSize = Vector2.new(140, 44)
	sz.Parent = startBtn
end

-- แผงสถานะแข่ง (timer + checkpoint)
local panel = Instance.new("Frame")
panel.Name = "RacePanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.04, 0)
panel.Size = UDim2.fromScale(0.36, 0.1)
panel.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
panel.BackgroundTransparency = 0.25
panel.Visible = false
panel.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.18, 0)
	c.Parent = panel
end
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromScale(1, 0.6)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.fromRGB(255, 240, 180)
timerLabel.Text = "0.0s"
timerLabel.Parent = panel
local cpLabel = Instance.new("TextLabel")
cpLabel.Position = UDim2.fromScale(0, 0.6)
cpLabel.Size = UDim2.fromScale(1, 0.4)
cpLabel.BackgroundTransparency = 1
cpLabel.Font = Enum.Font.Gotham
cpLabel.TextScaled = true
cpLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
cpLabel.Text = "CP 0/0"
cpLabel.Parent = panel

local function toast(text: string)
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.4)
	t.Size = UDim2.fromScale(0.6, 0.1)
	t.BackgroundColor3 = Color3.fromRGB(20, 30, 24)
	t.BackgroundTransparency = 0.15
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(160, 255, 180)
	t.Text = text
	t.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.2, 0)
	c.Parent = t
	task.delay(4, function()
		t:Destroy()
	end)
end

----------------------------------------------------------------
-- checkpoint touch detection
----------------------------------------------------------------
local function hookCheckpoint(part: BasePart)
	local idx = part:GetAttribute(CP_ATTR)
	local trackId = part:GetAttribute(TRACK_ATTR)
	if typeof(idx) ~= "number" or typeof(trackId) ~= "string" then
		return
	end
	part.Touched:Connect(function(hit: BasePart)
		if not raceActive or trackId ~= activeTrackId then
			return
		end
		local char = localPlayer.Character
		if not char or not hit:IsDescendantOf(char) then
			return
		end
		local k = trackId .. "_" .. idx
		if touchedCps[k] then
			return
		end
		touchedCps[k] = true
		checkpointPing:FireServer(trackId, idx)
	end)
end

for _, d in Workspace:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute(CP_ATTR) ~= nil then
		hookCheckpoint(d)
	end
end
Workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d:GetAttribute(CP_ATTR) ~= nil then
		hookCheckpoint(d)
	end
end)

----------------------------------------------------------------
-- start gate proximity → ปุ่มเริ่ม
----------------------------------------------------------------
local function findStartGate(): BasePart?
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("RaceStartTrackId") ~= nil then
			return d
		end
	end
	return nil
end

startBtn.Activated:Connect(function()
	local gate = findStartGate()
	local trackId = gate and gate:GetAttribute("RaceStartTrackId")
	if typeof(trackId) ~= "string" then
		return
	end
	local ok = pcall(function()
		return startRace:InvokeServer(trackId)
	end)
	if ok then
		startBtn.Visible = false
	end
end)

RunService.Heartbeat:Connect(function()
	-- ปุ่มเริ่ม: ใกล้ gate + ยังไม่แข่ง
	if not raceActive then
		local gate = findStartGate()
		local root = getRoot()
		if gate and root then
			startBtn.Visible = (root.Position - gate.Position).Magnitude < 28
		else
			startBtn.Visible = false
		end
	end
	-- timer
	if raceActive then
		timerLabel.Text = string.format("%.1fs", os.clock() - clientStartClock)
	end
end)

----------------------------------------------------------------
-- server state
----------------------------------------------------------------
raceState.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local phase = payload.phase
	if phase == "started" then
		raceActive = true
		activeTrackId = payload.trackId
		clientStartClock = os.clock()
		table.clear(touchedCps)
		panel.Visible = true
		startBtn.Visible = false
		cpLabel.Text = string.format("CP 0/%d", payload.totalCp or 0)
		toast("🏁 ออกตัว!")
	elseif phase == "checkpoint" then
		cpLabel.Text = string.format("CP %d/%d", payload.cpIndex or 0, payload.totalCp or 0)
	elseif phase == "finished" then
		raceActive = false
		activeTrackId = nil
		panel.Visible = false
		local msg = string.format("จบ! %.2fs (+%d เครดิต)", payload.time or 0, payload.reward or 0)
		if payload.isBest then
			msg ..= " ⭐สถิติใหม่!"
		end
		toast(msg)
	elseif phase == "cancelled" then
		raceActive = false
		activeTrackId = nil
		panel.Visible = false
		toast("ยกเลิก: " .. tostring(payload.msg))
	end
end)
