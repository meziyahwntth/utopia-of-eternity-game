--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getLeaderboard = remotes:WaitForChild("GetLeaderboard") :: RemoteFunction
local getSeasonHistory = remotes:WaitForChild("GetSeasonHistory") :: RemoteFunction
local getSeasonRewardStatus = remotes:WaitForChild("GetSeasonRewardStatus") :: RemoteFunction
local claimSeasonReward = remotes:WaitForChild("ClaimSeasonReward") :: RemoteFunction
local getSeasonalRingStatus = remotes:WaitForChild("GetSeasonalRingStatus") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleyGlobalLeaderboardUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(440, 500)
panel.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 32)
title.Position = UDim2.fromOffset(12, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 179, 71)
title.Text = "Global Season Leaderboard"
title.Parent = panel

local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.fromOffset(36, 28)
prevBtn.Position = UDim2.fromOffset(12, 44)
prevBtn.Text = "◀"
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 14
prevBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 56)
prevBtn.TextColor3 = Color3.new(1, 1, 1)
prevBtn.Parent = panel

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.fromOffset(36, 28)
nextBtn.Position = UDim2.fromOffset(392, 44)
nextBtn.Text = "▶"
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 14
nextBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 56)
nextBtn.TextColor3 = Color3.new(1, 1, 1)
nextBtn.Parent = panel

local seasonLabel = Instance.new("TextLabel")
seasonLabel.Size = UDim2.new(1, -100, 0, 28)
seasonLabel.Position = UDim2.fromOffset(52, 44)
seasonLabel.BackgroundTransparency = 1
seasonLabel.Font = Enum.Font.Gotham
seasonLabel.TextSize = 12
seasonLabel.TextXAlignment = Enum.TextXAlignment.Center
seasonLabel.TextColor3 = Color3.fromRGB(180, 170, 220)
seasonLabel.Text = ""
seasonLabel.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -158)
list.Position = UDim2.fromOffset(12, 78)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.Parent = panel

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -24, 0, 32)
footer.Position = UDim2.fromOffset(12, 388)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamBold
footer.TextSize = 12
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.TextYAlignment = Enum.TextYAlignment.Top
footer.TextWrapped = true
footer.TextColor3 = Color3.fromRGB(0, 229, 255)
footer.Text = ""
footer.Parent = panel

local claimBtn = Instance.new("TextButton")
claimBtn.Size = UDim2.fromOffset(140, 32)
claimBtn.Position = UDim2.fromOffset(12, 428)
claimBtn.Text = "Claim Season Reward"
claimBtn.Font = Enum.Font.GothamBold
claimBtn.TextSize = 11
claimBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
claimBtn.TextColor3 = Color3.new(1, 1, 1)
claimBtn.Visible = false
claimBtn.Parent = panel
Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(100, 32)
closeBtn.Position = UDim2.new(1, -112, 1, -44)
closeBtn.Text = "Close (L)"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local seasonHistory: { any } = {}
local seasonIndex = 1

local function currentSeasonId(): string
	local entry = seasonHistory[seasonIndex]
	if typeof(entry) == "table" and typeof(entry.seasonId) == "string" then
		return entry.seasonId
	end
	return ""
end

local function renderEntries(data: any, rewardStatus: any)
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if typeof(data) ~= "table" then
		return
	end
	local season = data.season
	if typeof(season) == "table" then
		local pastTag = if data.isPastSeason == true then " · Past" else " · Current"
		local sourceTag = if data.crossPlace == true then " · ODS" else ""
		seasonLabel.Text = string.format("%s %s%s%s", tostring(season.seasonName), tostring(season.year), pastTag, sourceTag)
	end
	local y = 0
	if typeof(data.entries) == "table" then
		for _, entry in data.entries do
			if typeof(entry) ~= "table" then
				continue
			end
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, 0, 0, 22)
			row.Position = UDim2.fromOffset(0, y)
			row.BackgroundTransparency = 1
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextColor3 = Color3.fromRGB(230, 220, 255)
			row.Text = string.format(
				"#%-2d  %-18s  %d nights",
				entry.rank or 0,
				tostring(entry.displayName or "?"),
				entry.nightsSurvived or 0
			)
			row.Parent = list
			y += 24
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, y)

	if data.myBestNights and (data.myBestNights :: number) > 0 then
		local rankText = tostring(data.myRank or "—")
		if data.myRank == nil then
			rankText = "25+"
		end
		footer.Text = string.format("Your best: %d nights · Global rank: %s", data.myBestNights, rankText)
	else
		footer.Text = "Survive nights to appear on the leaderboard!"
	end

	if typeof(rewardStatus) == "table" then
		if rewardStatus.autoDelivered == true then
			claimBtn.Visible = true
			claimBtn.Text = "Auto-delivered (Top 25)"
			claimBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 120)
			if rewardStatus.displayTitle then
				footer.Text ..= string.format("\nTitle: %s", rewardStatus.displayTitle)
			end
		elseif rewardStatus.claimed == true then
			claimBtn.Visible = true
			claimBtn.Text = "Reward Claimed"
			claimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			if rewardStatus.displayTitle then
				footer.Text ..= string.format("\nTitle: %s", rewardStatus.displayTitle)
			end
		elseif rewardStatus.claimable == true then
			claimBtn.Visible = true
			local cosmeticLine = if rewardStatus.cosmeticId then " + cosmetic" else ""
			claimBtn.Text = string.format(
				"Claim %s (+%d%s)",
				rewardStatus.tier or "Reward",
				rewardStatus.shards or 0,
				cosmeticLine
			)
			claimBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
			if rewardStatus.displayTitle then
				footer.Text ..= string.format("\nEarn: %s", rewardStatus.displayTitle)
			end
		else
			claimBtn.Visible = data.isPastSeason == true
			claimBtn.Text = if data.isPastSeason then "No reward tier" else "Current season — no claim yet"
			claimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		end
	else
		claimBtn.Visible = false
	end
end

local function refresh()
	local sid = currentSeasonId()
	if sid == "" then
		return
	end
	local data = getLeaderboard:InvokeServer(sid)
	local rewardStatus = getSeasonRewardStatus:InvokeServer(sid)
	renderEntries(data, rewardStatus)
	local ringStatus = getSeasonalRingStatus:InvokeServer()
	if typeof(ringStatus) == "table" and ringStatus.ring4Unlocked == true and seasonIndex == 1 then
		seasonLabel.Text ..= " · Ring 4"
	end
end

local function loadHistory()
	seasonHistory = getSeasonHistory:InvokeServer()
	if typeof(seasonHistory) ~= "table" or #seasonHistory == 0 then
		seasonHistory = {}
		seasonIndex = 1
		return
	end
	seasonIndex = 1
end

prevBtn.MouseButton1Click:Connect(function()
	if seasonIndex < #seasonHistory then
		seasonIndex += 1
		refresh()
	end
end)

nextBtn.MouseButton1Click:Connect(function()
	if seasonIndex > 1 then
		seasonIndex -= 1
		refresh()
	end
end)

claimBtn.MouseButton1Click:Connect(function()
	local sid = currentSeasonId()
	if sid == "" then
		return
	end
	local ok, msg = claimSeasonReward:InvokeServer(sid)
	footer.Text = msg
	if ok then
		refresh()
	end
end)

local function setVisible(visible: boolean)
	gui.Enabled = visible
	if visible then
		loadHistory()
		refresh()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

backdrop.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setVisible(false)
	end
end)

local function toggleLeaderboard(_actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	setVisible(not gui.Enabled)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("ToggleDVGlobalLeaderboard", toggleLeaderboard, false, Enum.KeyCode.L)

player:GetAttributeChangedSignal("DV_OpenGlobalLeaderboard"):Connect(function()
	if player:GetAttribute("DV_OpenGlobalLeaderboard") == true then
		player:SetAttribute("DV_OpenGlobalLeaderboard", false)
		setVisible(true)
	end
end)

player:GetAttributeChangedSignal("DV_RolloverRewardMsg"):Connect(function()
	local msg = player:GetAttribute("DV_RolloverRewardMsg")
	if typeof(msg) == "string" and msg ~= "" then
		footer.Text = msg
	end
end)

print("[DeathValley] Global Leaderboard UI ready")
