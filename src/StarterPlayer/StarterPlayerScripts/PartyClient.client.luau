--!strict
--[[
	PartyClient (P3-A) — ปาร์ตี้: /invite <ชื่อ> · /p <ข้อความ> · /leave
	+ popup รับ/ปฏิเสธคำเชิญ + รายชื่อสมาชิก + แชทปาร์ตี้ในแชทหลัก
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local partyInviteSend = remotes:WaitForChild("PartyInviteSend") :: RemoteFunction
local partyAccept = remotes:WaitForChild("PartyAccept") :: RemoteFunction
local partyDecline = remotes:WaitForChild("PartyDecline") :: RemoteEvent
local partyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent
local partyChatSend = remotes:WaitForChild("PartyChatSend") :: RemoteFunction
local partyInviteReceived = remotes:WaitForChild("PartyInviteReceived") :: RemoteEvent
local partyStateChanged = remotes:WaitForChild("PartyStateChanged") :: RemoteEvent
local partyChatReceived = remotes:WaitForChild("PartyChatReceived") :: RemoteEvent

local function systemMsg(text: string)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(text)
		end
	end)
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "PartyGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- รายชื่อสมาชิก (มุมซ้ายบน)
local listFrame = Instance.new("Frame")
listFrame.Name = "PartyList"
listFrame.Size = UDim2.fromOffset(180, 200)
listFrame.Position = UDim2.fromOffset(12, 120)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
listFrame.BackgroundTransparency = 0.15
listFrame.Visible = false
listFrame.Parent = gui
local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 10)
lc.Parent = listFrame
local lpad = Instance.new("UIPadding")
lpad.PaddingTop = UDim.new(0, 8)
lpad.PaddingLeft = UDim.new(0, 8)
lpad.PaddingRight = UDim.new(0, 8)
lpad.Parent = listFrame
local llayout = Instance.new("UIListLayout")
llayout.Padding = UDim.new(0, 4)
llayout.Parent = listFrame

local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(1, 0, 0, 22)
listTitle.BackgroundTransparency = 1
listTitle.Text = "ปาร์ตี้"
listTitle.TextColor3 = Color3.fromRGB(255, 215, 120)
listTitle.TextScaled = true
listTitle.Font = Enum.Font.GothamBold
listTitle.Parent = listFrame

local function rebuildList(state: any)
	for _, c in listFrame:GetChildren() do
		if c:IsA("TextLabel") and c ~= listTitle then
			c:Destroy()
		end
	end
	if typeof(state) ~= "table" or typeof(state.members) ~= "table" or #state.members == 0 then
		listFrame.Visible = false
		return
	end
	listFrame.Visible = true
	for _, uid in state.members do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 20)
		row.BackgroundTransparency = 1
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if uid == state.leaderId then Color3.fromRGB(255, 215, 120) else Color3.fromRGB(235, 240, 250)
		row.TextScaled = true
		row.Font = Enum.Font.Gotham
		local nm = (typeof(state.names) == "table" and state.names[uid]) or tostring(uid)
		row.Text = (if uid == state.leaderId then "★ " else "• ") .. tostring(nm)
		row.Parent = listFrame
	end
end

-- popup คำเชิญ
local function showInvitePopup(invite: any)
	local fromName = if typeof(invite) == "table" then tostring(invite.fromName) else "ใครบางคน"
	local popup = Instance.new("Frame")
	popup.Size = UDim2.fromOffset(280, 120)
	popup.Position = UDim2.new(0.5, 0, 0.25, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
	popup.Parent = gui
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 12)
	pc.Parent = popup

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -16, 0, 56)
	msg.Position = UDim2.fromOffset(8, 8)
	msg.BackgroundTransparency = 1
	msg.Text = fromName .. " เชิญเข้าปาร์ตี้"
	msg.TextColor3 = Color3.fromRGB(235, 240, 250)
	msg.TextScaled = true
	msg.Font = Enum.Font.GothamMedium
	msg.Parent = popup

	local accept = Instance.new("TextButton")
	accept.Size = UDim2.new(0.45, 0, 0, 38)
	accept.Position = UDim2.new(0.03, 0, 1, -46)
	accept.Text = "รับ"
	accept.BackgroundColor3 = Color3.fromRGB(60, 170, 110)
	accept.TextColor3 = Color3.fromRGB(255, 255, 255)
	accept.TextScaled = true
	accept.Font = Enum.Font.GothamBold
	accept.Parent = popup
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 8)
	ac.Parent = accept

	local decline = Instance.new("TextButton")
	decline.Size = UDim2.new(0.45, 0, 0, 38)
	decline.Position = UDim2.new(0.52, 0, 1, -46)
	decline.Text = "ปฏิเสธ"
	decline.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	decline.TextColor3 = Color3.fromRGB(255, 255, 255)
	decline.TextScaled = true
	decline.Font = Enum.Font.GothamBold
	decline.Parent = popup
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = decline

	accept.Activated:Connect(function()
		popup:Destroy()
		local ok, m = partyAccept:InvokeServer()
		systemMsg("[ปาร์ตี้] " .. tostring(m))
	end)
	decline.Activated:Connect(function()
		popup:Destroy()
		partyDecline:FireServer()
	end)
	task.delay(60, function()
		if popup.Parent then
			popup:Destroy()
		end
	end)
end

----------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------
local function makeCommand(name: string, primary: string, secondary: string?)
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = name
	cmd.PrimaryAlias = primary
	if secondary then
		cmd.SecondaryAlias = secondary
	end
	cmd.Parent = TextChatService
	return cmd
end

local inviteCmd = makeCommand("PartyInviteCommand", "/invite", "/inv")
inviteCmd.Triggered:Connect(function(_o, text)
	local name = string.match(string.gsub(text, "^/%S+%s*", ""), "^(%S+)")
	if not name then
		systemMsg("[ระบบ] ใช้: /invite <ชื่อ>")
		return
	end
	local ok, m = partyInviteSend:InvokeServer(name)
	systemMsg("[ปาร์ตี้] " .. tostring(m))
end)

local pCmd = makeCommand("PartyChatCommand", "/p", nil)
pCmd.Triggered:Connect(function(_o, text)
	local msg = string.gsub(text, "^/%S+%s*", "")
	if msg == "" then
		return
	end
	local ok, m = partyChatSend:InvokeServer(msg)
	if not ok then
		systemMsg("[ระบบ] " .. tostring(m))
	end
end)

local leaveCmd = makeCommand("PartyLeaveCommand", "/leave", nil)
leaveCmd.Triggered:Connect(function()
	partyLeave:FireServer()
	systemMsg("[ปาร์ตี้] ออกจากปาร์ตี้แล้ว")
end)

----------------------------------------------------------------
partyInviteReceived.OnClientEvent:Connect(showInvitePopup)
partyStateChanged.OnClientEvent:Connect(rebuildList)
partyChatReceived.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end
	systemMsg(string.format("[ปาร์ตี้ %s] %s", tostring(data.fromName), tostring(data.message)))
end)
