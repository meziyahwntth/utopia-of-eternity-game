--!strict
--[[
	P2 — Support Desk UI: fan-game reports + ban appeals (kick message links here).
	Toggle: , (comma) or Support button bottom-right.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SupportDeskRemotes")
local submitFanReport = remotes:WaitForChild("SubmitFanReport") :: RemoteFunction
local submitBanAppeal = remotes:WaitForChild("SubmitBanAppeal") :: RemoteFunction
local getSupportDeskInfo = remotes:WaitForChild("GetSupportDeskInfo") :: RemoteFunction

local info = getSupportDeskInfo:InvokeServer()
local webUrl = if typeof(info.webUrl) == "string" then info.webUrl else "https://utopiaofeternity.com"
local programName = if typeof(info.programName) == "string" then info.programName else "Eternity Forge"
local communityUrl = if typeof(info.communityUrl) == "string" then info.communityUrl else ""
local communityGroupId = if typeof(info.communityGroupId) == "number" then info.communityGroupId else 0
local fanReportEnabled = info.fanReportEnabled == true

local gui = Instance.new("ScreenGui")
gui.Name = "SupportDeskUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local openGui = Instance.new("ScreenGui")
openGui.Name = "SupportDeskOpenButton"
openGui.ResetOnSpawn = false
openGui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Name = "SupportOpenButton"
openBtn.Size = UDim2.fromOffset(88, 32)
-- moved up out of the bottom-right combat cluster (Skill Bar + Lock button)
openBtn.AnchorPoint = Vector2.new(1, 1)
openBtn.Position = UDim2.new(1, -8, 1, -240)
openBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
openBtn.TextColor3 = Color3.fromRGB(0, 229, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Text = "Support"
openBtn.Parent = openGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

local panelVisible = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(420, 440)
frame.Position = UDim2.new(0.5, -210, 0.5, -220)
frame.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 32)
title.Position = UDim2.fromOffset(8, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(0, 229, 255)
title.Text = "Utopia Support Desk"
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
closeBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 36)
status.Position = UDim2.fromOffset(8, 40)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(160, 180, 210)
status.Text = "Report unlicensed fan games or submit a ban appeal."
if communityGroupId > 0 then
	status.Text ..= string.format("\nOfficial Community: Utopia of Eternity (Group %d)", communityGroupId)
end
if not fanReportEnabled then
	status.Text ..= "\nFan reports queue locally until Bridge fan-scan is configured."
end
status.Parent = frame

local tabFan = Instance.new("TextButton")
tabFan.Size = UDim2.fromOffset(120, 28)
tabFan.Position = UDim2.fromOffset(8, 78)
tabFan.Text = programName .. " Report"
tabFan.Font = Enum.Font.GothamBold
tabFan.TextSize = 11
tabFan.BackgroundColor3 = Color3.fromRGB(40, 70, 110)
tabFan.TextColor3 = Color3.new(1, 1, 1)
tabFan.Parent = frame

local tabAppeal = Instance.new("TextButton")
tabAppeal.Size = UDim2.fromOffset(120, 28)
tabAppeal.Position = UDim2.fromOffset(132, 78)
tabAppeal.Text = "Ban Appeal"
tabAppeal.Font = Enum.Font.GothamBold
tabAppeal.TextSize = 11
tabAppeal.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
tabAppeal.TextColor3 = Color3.fromRGB(180, 180, 200)
tabAppeal.Parent = frame

local fanPanel = Instance.new("Frame")
fanPanel.Size = UDim2.new(1, -16, 1, -130)
fanPanel.Position = UDim2.fromOffset(8, 112)
fanPanel.BackgroundTransparency = 1
fanPanel.Parent = frame

local appealPanel = Instance.new("Frame")
appealPanel.Size = fanPanel.Size
appealPanel.Position = fanPanel.Position
appealPanel.BackgroundTransparency = 1
appealPanel.Visible = false
appealPanel.Parent = frame

local function makeField(parent: Instance, labelText: string, y: number, height: number, multiline: boolean): TextBox
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(140, 160, 190)
	label.Text = labelText
	label.Parent = parent

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, height)
	box.Position = UDim2.fromOffset(0, y + 20)
	box.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = if multiline then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
	box.ClearTextOnFocus = false
	box.MultiLine = multiline
	box.Text = ""
	box.Parent = parent
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	return box
end

local expIdBox = makeField(fanPanel, "Experience ID (numbers from game URL)", 0, 32, false)
local titleBox = makeField(fanPanel, "Game title", 62, 32, false)
local descBox = makeField(fanPanel, "Why does this use Utopia IP?", 124, 120, true)

local appealBox = makeField(appealPanel, "Explain why your ban should be reviewed", 0, 200, true)

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.fromOffset(120, 36)
submitBtn.Position = UDim2.fromOffset(8, 392)
submitBtn.Text = "Submit"
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextSize = 13
submitBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
submitBtn.TextColor3 = Color3.new(1, 1, 1)
submitBtn.Parent = frame
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 8)

local webBtn = Instance.new("TextButton")
webBtn.Size = UDim2.fromOffset(120, 36)
webBtn.Position = UDim2.fromOffset(136, 392)
webBtn.Text = "Open Website"
webBtn.Font = Enum.Font.Gotham
webBtn.TextSize = 12
webBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
webBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
webBtn.Parent = frame
Instance.new("UICorner", webBtn).CornerRadius = UDim.new(0, 8)

local communityBtn = Instance.new("TextButton")
communityBtn.Size = UDim2.fromOffset(140, 36)
communityBtn.Position = UDim2.fromOffset(264, 392)
communityBtn.Text = "Community"
communityBtn.Font = Enum.Font.Gotham
communityBtn.TextSize = 12
communityBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 90)
communityBtn.TextColor3 = Color3.fromRGB(220, 210, 255)
communityBtn.Visible = communityGroupId > 0
communityBtn.Parent = frame
Instance.new("UICorner", communityBtn).CornerRadius = UDim.new(0, 8)

local activeTab = "fan"

local function setTab(tab: string)
	activeTab = tab
	fanPanel.Visible = tab == "fan"
	appealPanel.Visible = tab == "appeal"
	tabFan.BackgroundColor3 = if tab == "fan"
		then Color3.fromRGB(40, 70, 110)
		else Color3.fromRGB(35, 35, 50)
	tabAppeal.BackgroundColor3 = if tab == "appeal"
		then Color3.fromRGB(40, 70, 110)
		else Color3.fromRGB(35, 35, 50)
	tabFan.TextColor3 = if tab == "fan" then Color3.new(1, 1, 1) else Color3.fromRGB(180, 180, 200)
	tabAppeal.TextColor3 = if tab == "appeal" then Color3.new(1, 1, 1) else Color3.fromRGB(180, 180, 200)
	status.Text = if tab == "fan"
		then "Report fan games using Utopia IP without an Eternity Forge license."
		else "Banned players: describe context — appeals reviewed within 72 hours."
end

local function toggle()
	panelVisible = not panelVisible
	frame.Visible = panelVisible
end

openBtn.MouseButton1Click:Connect(toggle)
closeBtn.MouseButton1Click:Connect(function()
	panelVisible = false
	frame.Visible = false
end)
tabFan.MouseButton1Click:Connect(function()
	setTab("fan")
end)
tabAppeal.MouseButton1Click:Connect(function()
	setTab("appeal")
end)

webBtn.MouseButton1Click:Connect(function()
	status.Text = "Visit " .. webUrl .. " in your browser for full policy docs."
end)

communityBtn.MouseButton1Click:Connect(function()
	if communityUrl ~= "" then
		status.Text = "Official community: " .. communityUrl
	else
		status.Text = string.format("Official Community Group ID: %d", communityGroupId)
	end
end)

submitBtn.MouseButton1Click:Connect(function()
	status.TextColor3 = Color3.fromRGB(160, 180, 210)
	if activeTab == "fan" then
		local expId = tonumber(expIdBox.Text)
		if not expId then
			status.Text = "Enter a numeric Experience ID."
			status.TextColor3 = Color3.fromRGB(255, 120, 120)
			return
		end
		local ok, msg = submitFanReport:InvokeServer(expId, titleBox.Text, descBox.Text)
		status.Text = msg
		status.TextColor3 = if ok then Color3.fromRGB(120, 220, 160) else Color3.fromRGB(255, 120, 120)
		if ok then
			expIdBox.Text = ""
			titleBox.Text = ""
			descBox.Text = ""
		end
	else
		local ok, msg = submitBanAppeal:InvokeServer(appealBox.Text)
		status.Text = msg
		status.TextColor3 = if ok then Color3.fromRGB(120, 220, 160) else Color3.fromRGB(255, 120, 120)
		if ok then
			appealBox.Text = ""
		end
	end
end)

ContextActionService:BindAction("ToggleSupportDesk", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggle()
	end
end, false, Enum.KeyCode.Comma)

setTab("fan")
print("[SupportDesk] UI ready — comma key or Support button")
