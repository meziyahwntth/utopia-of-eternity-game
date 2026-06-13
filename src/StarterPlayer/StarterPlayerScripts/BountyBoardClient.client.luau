--!strict
--[[
	BountyBoardClient (P5+) — NPC board UI: Escort jobs + Bounties tabs
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local getJobsRF = remotes:WaitForChild("GetEscortJobs") :: RemoteFunction
local getBountiesRF = remotes:WaitForChild("GetBounties") :: RemoteFunction
local acceptEscortRF = remotes:WaitForChild("AcceptEscort") :: RemoteFunction

type PublicEscortJob = {
	jobId: string,
	clientId: number,
	pay: number,
	destination: string,
	postedAt: number,
}

type PublicBounty = {
	bountyId: string,
	targetId: number,
	amount: number,
	postedAt: number,
	expiresAt: number,
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BountyBoardGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 11
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.5, 0.7)
frame.Position = UDim2.fromScale(0.25, 0.15)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = frame
end

local tabEscort = Instance.new("TextButton")
tabEscort.Size = UDim2.fromScale(0.5, 0.08)
tabEscort.Position = UDim2.fromScale(0, 0)
tabEscort.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
tabEscort.BorderSizePixel = 0
tabEscort.Text = "📦 Escort Jobs"
tabEscort.TextColor3 = Color3.new(1, 1, 1)
tabEscort.Font = Enum.Font.GothamBold
tabEscort.TextSize = 14
tabEscort.Parent = frame

local tabBounty = Instance.new("TextButton")
tabBounty.Size = UDim2.fromScale(0.5, 0.08)
tabBounty.Position = UDim2.fromScale(0.5, 0)
tabBounty.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
tabBounty.BorderSizePixel = 0
tabBounty.Text = "🏴‍☠️ Bounties"
tabBounty.TextColor3 = Color3.new(1, 1, 1)
tabBounty.Font = Enum.Font.GothamBold
tabBounty.TextSize = 14
tabBounty.Parent = frame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.fromScale(1, 0.85)
listFrame.Position = UDim2.fromScale(0, 0.1)
listFrame.BackgroundTransparency = 1
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new()
listFrame.ScrollBarThickness = 6
listFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.1, 0.07)
closeBtn.Position = UDim2.fromScale(0.89, 0.005)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = closeBtn
end

local currentTab = "escort"

local function clearList()
	for _, child in listFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function addRow(text: string, btnText: string, onAccept: () -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	row.BorderSizePixel = 0
	row.Parent = listFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = row
	end

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.74, 1)
	lbl.Position = UDim2.fromOffset(8, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.22, 0.76)
	btn.Position = UDim2.fromScale(0.76, 0.12)
	btn.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = btnText
	btn.Parent = row
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
	end
	btn.MouseButton1Click:Connect(onAccept)
end

local function loadEscortJobs()
	clearList()
	local ok, jobs = pcall(function()
		return getJobsRF:InvokeServer()
	end)
	if not ok or typeof(jobs) ~= "table" then
		return
	end
	local hasRows = false
	for _, jobAny in jobs :: { any } do
		if typeof(jobAny) ~= "table" then
			continue
		end
		local job = jobAny :: PublicEscortJob
		if typeof(job.jobId) ~= "string" then
			continue
		end
		local pay = if typeof(job.pay) == "number" then job.pay else 0
		local dest = if typeof(job.destination) == "string" then job.destination else "?"
		addRow(string.format("📦 → %s | 💰 %d credits", dest, pay), "รับงาน", function()
			local success, msg = acceptEscortRF:InvokeServer(job.jobId)
			if not success then
				warn("[BountyBoard] accept escort:", msg)
			end
			loadEscortJobs()
		end)
		hasRows = true
	end
	if not hasRows then
		addRow("(ไม่มีงาน escort เปิดอยู่)", "—", function() end)
	end
end

local function loadBounties()
	clearList()
	local ok, bList = pcall(function()
		return getBountiesRF:InvokeServer()
	end)
	if not ok or typeof(bList) ~= "table" then
		return
	end
	local hasRows = false
	for _, bAny in bList :: { any } do
		if typeof(bAny) ~= "table" then
			continue
		end
		local bData = bAny :: PublicBounty
		if typeof(bData.targetId) ~= "number" then
			continue
		end
		local amount = if typeof(bData.amount) == "number" then bData.amount else 0
		local target = Players:GetPlayerByUserId(bData.targetId)
		local targetName = if target then target.DisplayName else ("UserId:" .. tostring(bData.targetId))
		addRow(string.format("🏴‍☠️ %s | 💰 %d credits", targetName, amount), "ล่า", function()
			print("[BountyBoard] Hunting:", targetName)
		end)
		hasRows = true
	end
	if not hasRows then
		addRow("(ไม่มี bounty ที่ active)", "—", function() end)
	end
end

local function openBoard()
	screenGui.Enabled = true
	if currentTab == "escort" then
		loadEscortJobs()
	else
		loadBounties()
	end
end

tabEscort.MouseButton1Click:Connect(function()
	currentTab = "escort"
	tabEscort.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
	tabBounty.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	loadEscortJobs()
end)

tabBounty.MouseButton1Click:Connect(function()
	currentTab = "bounty"
	tabBounty.BackgroundColor3 = Color3.fromRGB(80, 50, 100)
	tabEscort.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	loadBounties()
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local openBountyBoard = Instance.new("BindableEvent")
openBountyBoard.Name = "OpenBountyBoard"
openBountyBoard.Parent = ReplicatedStorage
openBountyBoard.Event:Connect(openBoard)

print("[Mercenary] BountyBoardClient online (P5+)")
