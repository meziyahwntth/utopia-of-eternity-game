--!strict
--[[
	Fashion Show UI — round status, join, vote, winner announcement.
	Matches DailyStreakUI / DailyQuestUI style.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getFashionInfo = remotes:WaitForChild("GetFashionInfo") :: RemoteEvent
local joinFashionShow = remotes:WaitForChild("JoinFashionShow") :: RemoteEvent
local submitOutfit = remotes:WaitForChild("SubmitOutfit") :: RemoteEvent
local castFashionVote = remotes:WaitForChild("CastFashionVote") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FashionShowUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, -20, 0, 120)
root.Size = UDim2.fromOffset(340, 300)
root.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
root.BorderSizePixel = 0
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
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(212, 175, 55)
title.Text = "Eternity Fashion Show"
title.Parent = root

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(16, 44)
statusLabel.Size = UDim2.new(1, -32, 0, 48)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(0, 229, 255)
statusLabel.TextWrapped = true
statusLabel.Text = "Loading..."
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = root

local themeLabel = Instance.new("TextLabel")
themeLabel.Name = "Theme"
themeLabel.BackgroundTransparency = 1
themeLabel.Position = UDim2.fromOffset(16, 92)
themeLabel.Size = UDim2.new(1, -32, 0, 20)
themeLabel.Font = Enum.Font.Gotham
themeLabel.TextSize = 12
themeLabel.TextColor3 = Color3.fromRGB(245, 245, 240)
themeLabel.Text = ""
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.Parent = root

local actionBtn = Instance.new("TextButton")
actionBtn.Name = "ActionButton"
actionBtn.Position = UDim2.fromOffset(16, 200)
actionBtn.Size = UDim2.new(1, -32, 0, 36)
actionBtn.BackgroundColor3 = Color3.fromRGB(45, 115, 135)
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 14
actionBtn.TextColor3 = Color3.new(1, 1, 1)
actionBtn.Text = ""
actionBtn.Visible = false
actionBtn.Parent = root

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = actionBtn

local voteList = Instance.new("ScrollingFrame")
voteList.Name = "VoteList"
voteList.Position = UDim2.fromOffset(16, 120)
voteList.Size = UDim2.new(1, -32, 0, 72)
voteList.BackgroundTransparency = 1
voteList.ScrollBarThickness = 4
voteList.Visible = false
voteList.Parent = root

local voteLayout = Instance.new("UIListLayout")
voteLayout.Padding = UDim.new(0, 4)
voteLayout.Parent = voteList

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "Result"
resultLabel.BackgroundTransparency = 1
resultLabel.Position = UDim2.fromOffset(16, 240)
resultLabel.Size = UDim2.new(1, -32, 0, 48)
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 13
resultLabel.TextColor3 = Color3.fromRGB(255, 200, 40)
resultLabel.TextWrapped = true
resultLabel.Text = ""
resultLabel.Visible = false
resultLabel.Parent = root

local latestInfo: { [string]: any }? = nil
local countdownEndsAt = 0
local displayRound = 0
local displayState = "Idle"

local function updateStatusLabel(remaining: number)
	statusLabel.Text = string.format("Round %d · %s · %ds left", displayRound, displayState, remaining)
end

local function syncCountdownFromInfo(info: { [string]: any })
	displayRound = info.round :: number
	displayState = info.state :: string
	countdownEndsAt = os.clock() + math.max(0, info.secondsRemaining :: number)
	updateStatusLabel(math.max(0, math.ceil(countdownEndsAt - os.clock())))
end

local function clearVoteButtons()
	for _, child in voteList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function refreshUi(info: { [string]: any })
	latestInfo = info
	syncCountdownFromInfo(info)
	local theme = info.themeSet :: { id: string, displayName: string }

	themeLabel.Text = "Theme: " .. theme.displayName

	actionBtn.Visible = false
	voteList.Visible = false
	resultLabel.Visible = false
	clearVoteButtons()

	local state = info.state :: string

	if state == "Registration" and not info.isRegistered then
		actionBtn.Visible = true
		actionBtn.Text = "Join Fashion Show"
	elseif state == "Dressing" and info.isRegistered then
		actionBtn.Visible = true
		actionBtn.Text = "Submit Theme Outfit"
	elseif state == "Voting" then
		voteList.Visible = true
		local contestants = info.contestants :: { { userId: number, name: string, outfitName: string } }
		for _, c in contestants do
			if c.userId == player.UserId then
				continue
			end
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundColor3 = Color3.fromRGB(55, 68, 88)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 12
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = string.format("Vote: %s (%s)", c.name, c.outfitName)
			btn.Parent = voteList
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn
			btn.MouseButton1Click:Connect(function()
				castFashionVote:FireServer(c.userId)
			end)
		end
	elseif state == "Results" then
		resultLabel.Visible = true
		local contestants = info.contestants :: { { name: string } }
		if #contestants > 0 then
			resultLabel.Text = "Results announced! Check Luminite balance."
		else
			resultLabel.Text = "Round complete."
		end
	end
end

actionBtn.MouseButton1Click:Connect(function()
	if not latestInfo then
		return
	end
	local state = latestInfo.state :: string
	if state == "Registration" then
		joinFashionShow:FireServer()
	elseif state == "Dressing" then
		local theme = latestInfo.themeSet :: { id: string }
		submitOutfit:FireServer(theme.id)
	end
end)

getFashionInfo.OnClientEvent:Connect(refreshUi)
joinFashionShow.OnClientEvent:Connect(function(payload: { ok: boolean, message: string })
	resultLabel.Visible = true
	resultLabel.Text = payload.message
	getFashionInfo:FireServer()
end)
submitOutfit.OnClientEvent:Connect(function(payload: { ok: boolean, message: string })
	resultLabel.Visible = true
	resultLabel.Text = payload.message
	getFashionInfo:FireServer()
end)
castFashionVote.OnClientEvent:Connect(function(payload: { ok: boolean, message: string })
	resultLabel.Visible = true
	resultLabel.Text = payload.message
	getFashionInfo:FireServer()
end)

task.spawn(function()
	while true do
		getFashionInfo:FireServer()
		task.wait(10)
	end
end)

task.spawn(function()
	while true do
		if countdownEndsAt > 0 then
			updateStatusLabel(math.max(0, math.ceil(countdownEndsAt - os.clock())))
		end
		task.wait(1)
	end
end)
