--!strict
--[[
	ChatClient (P3-C) — Lineage II-style custom chat GUI
	  • ปิด Roblox default chat (SetCoreGuiEnabled)
	  • แท็บ: General | Party | Clan | Alliance | Whisper
	  • history scrollable + สีแยกตาม channel
	  • input TextBox + Send button + 🎤 voice toggle (per channel)
	  • target input (Whisper only)
	  • slash-command parser: /invite /p /leave /dismiss /claninvite /clanleave
	    /allianceinvite /allianceleave /friendinvite /frienddel /loc /time /trade /sit /stand /unstuck
	  • admin ':' command parser (server-validated)
	  • server → client: ChatReceive (RE) / GuildChatReceived / AllianceChatReceived / PartyChatReceived / WhisperReceive
]]
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui     = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ChatConfig = require(Modules:WaitForChild("ChatConfig"))

-- disable Roblox default chat
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local chatSend        = remotes:WaitForChild("ChatSend")         :: RemoteFunction
local chatReceive     = remotes:WaitForChild("ChatReceive")      :: RemoteEvent
local guildChatRcv    = remotes:WaitForChild("GuildChatReceived") :: RemoteEvent
local alliChatRcv     = remotes:WaitForChild("AllianceChatReceived") :: RemoteEvent
local partyChatRcv    = remotes:WaitForChild("PartyChatReceived") :: RemoteEvent
local whisperRcv      = remotes:WaitForChild("WhisperReceive")   :: RemoteEvent
local guildMemberJoin = remotes:WaitForChild("GuildMemberJoined") :: RemoteEvent
local voiceToggleMute = remotes:WaitForChild("VoiceToggleMute")  :: RemoteEvent
local voiceStateChg   = remotes:WaitForChild("VoiceStateChanged") :: RemoteEvent
local adminCmd        = remotes:WaitForChild("AdminCmd")         :: RemoteFunction

local UI = ChatConfig.UI
local CC: { [Channel]: Color3 } = ChatConfig.ChannelColor
local CHANNEL_LABEL: { [Channel]: string } = ChatConfig.ChannelLabel

----------------------------------------------------------------
-- State
----------------------------------------------------------------
type Channel = ChatConfig.Channel
local activeChannel: Channel = "General"
local voiceMuted = false
local historyLines: { { channel: Channel, text: string } } = {}

----------------------------------------------------------------
-- GUI Build
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChatClient"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Root frame (bottom-left)
local root = Instance.new("Frame")
root.Name = "ChatRoot"
root.Size = UDim2.new(0, UI.Width, 0,
	UI.TabHeight + UI.HistoryHeight + UI.InputHeight + UI.PaddingV * 2)
root.Position = UDim2.new(0, 8, 1, -(UI.TabHeight + UI.HistoryHeight + UI.InputHeight + UI.PaddingV * 2 + 8))
root.BackgroundColor3 = UI.BgColor
root.BackgroundTransparency = UI.BgTransparency
root.BorderSizePixel = 0
root.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, UI.CornerRadius)
	c.Parent = root
end

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, UI.TabHeight)
tabBar.Position = UDim2.new(0, 0, 0, 0)
tabBar.BackgroundTransparency = 1
tabBar.Parent = root
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabBar
end

local tabButtons: { [Channel]: TextButton } = {}
local tabChannels: { Channel } = ChatConfig.TabChannels
local tabW = math.floor(UI.Width / #tabChannels)

for i = 1, #tabChannels do
	local ch: Channel = tabChannels[i]
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. ch
	btn.Size = UDim2.new(0, tabW, 1, 0)
	btn.BackgroundColor3 = UI.TabInactiveColor
	btn.BorderSizePixel = 0
	btn.Text = CHANNEL_LABEL[ch]
	btn.TextColor3 = CC[ch]
	btn.Font = UI.FontBody
	btn.TextSize = UI.FontSize - 1
	btn.LayoutOrder = i
	btn.Parent = tabBar
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
	end
	tabButtons[ch] = btn
end

-- History ScrollingFrame
local historyFrame = Instance.new("ScrollingFrame")
historyFrame.Name = "History"
historyFrame.Size = UDim2.new(1, -UI.PaddingH * 2, 0, UI.HistoryHeight)
historyFrame.Position = UDim2.new(0, UI.PaddingH, 0, UI.TabHeight + UI.PaddingV)
historyFrame.BackgroundTransparency = 1
historyFrame.BorderSizePixel = 0
historyFrame.ScrollBarThickness = 4
historyFrame.ScrollingDirection = Enum.ScrollingDirection.Y
historyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
historyFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
historyFrame.Parent = root
do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = historyFrame
end

-- Input row (bottom)
local inputY = UI.TabHeight + UI.HistoryHeight + UI.PaddingV * 2
local inputRow = Instance.new("Frame")
inputRow.Name = "InputRow"
inputRow.Size = UDim2.new(1, -UI.PaddingH * 2, 0, UI.InputHeight)
inputRow.Position = UDim2.new(0, UI.PaddingH, 0, inputY)
inputRow.BackgroundTransparency = 1
inputRow.Parent = root

-- Whisper target label (hidden by default)
local whisperLabel = Instance.new("TextBox")
whisperLabel.Name = "WhisperTarget"
whisperLabel.Size = UDim2.new(0, 90, 1, 0)
whisperLabel.Position = UDim2.new(0, 0, 0, 0)
whisperLabel.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
whisperLabel.BorderSizePixel = 0
whisperLabel.Text = ""
whisperLabel.PlaceholderText = "ชื่อผู้รับ"
whisperLabel.TextColor3 = CC[("Whisper" :: Channel)]
whisperLabel.Font = UI.FontBody
whisperLabel.TextSize = UI.FontSize
whisperLabel.ClearTextOnFocus = false
whisperLabel.Visible = false
whisperLabel.Parent = inputRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = whisperLabel
end

-- Main text input
local inputBox = Instance.new("TextBox")
inputBox.Name = "Input"
inputBox.Size = UDim2.new(1, -48, 1, 0)  -- leave room for send+voice buttons
inputBox.Position = UDim2.new(0, 0, 0, 0)
inputBox.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
inputBox.BorderSizePixel = 0
inputBox.Text = ""
inputBox.PlaceholderText = "พูด... (/ สำหรับคำสั่ง)"
inputBox.TextColor3 = Color3.fromRGB(230, 230, 230)
inputBox.Font = UI.FontBody
inputBox.TextSize = UI.FontSize
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.Parent = inputRow
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.Parent = inputBox
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = inputBox
end

-- Voice toggle button
local voiceBtn = Instance.new("TextButton")
voiceBtn.Name = "VoiceBtn"
voiceBtn.Size = UDim2.new(0, 22, 1, 0)
voiceBtn.Position = UDim2.new(1, -46, 0, 0)
voiceBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 90)
voiceBtn.BorderSizePixel = 0
voiceBtn.Text = "🎤"
voiceBtn.TextSize = 14
voiceBtn.Parent = inputRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = voiceBtn
end

-- Send button
local sendBtn = Instance.new("TextButton")
sendBtn.Name = "SendBtn"
sendBtn.Size = UDim2.new(0, 22, 1, 0)
sendBtn.Position = UDim2.new(1, -22, 0, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
sendBtn.BorderSizePixel = 0
sendBtn.Text = "▶"
sendBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
sendBtn.TextSize = 14
sendBtn.Parent = inputRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = sendBtn
end

----------------------------------------------------------------
-- History helpers
----------------------------------------------------------------
local lineCount = 0

local function addLine(channel: Channel, text: string)
	lineCount += 1
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Line" .. lineCount
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = CC[channel] or Color3.fromRGB(220, 220, 220)
	lbl.Font = UI.FontBody
	lbl.TextSize = UI.FontSize
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = text
	lbl.LayoutOrder = lineCount
	lbl.Parent = historyFrame

	table.insert(historyLines, { channel = channel, text = text })
	-- trim old lines
	if #historyLines > ChatConfig.MaxHistoryLines then
		local children = historyFrame:GetChildren()
		local labels: { TextLabel } = {}
		for _, ch in children do
			if ch:IsA("TextLabel") then
				table.insert(labels, ch :: TextLabel)
			end
		end
		table.sort(labels, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		if #labels > ChatConfig.MaxHistoryLines then
			labels[1]:Destroy()
			table.remove(historyLines, 1)
		end
	end

	-- auto-scroll
	task.defer(function()
		historyFrame.CanvasPosition = Vector2.new(0, math.huge)
	end)
end

local function systemMsg(text: string)
	addLine("System", "[ระบบ] " .. text)
end

----------------------------------------------------------------
-- Tab switching
----------------------------------------------------------------
local function setChannel(ch: Channel)
	activeChannel = ch
	for i = 1, #tabChannels do
		local c: Channel = tabChannels[i]
		local btn = tabButtons[c]
		if btn then
			btn.BackgroundColor3 = if c == ch then UI.TabActiveColor else UI.TabInactiveColor
		end
	end
	-- show/hide whisper target input
	local isWhisper = ch == "Whisper"
	whisperLabel.Visible = isWhisper
	if isWhisper then
		inputBox.Size = UDim2.new(1, -(90 + 4 + 48), 1, 0)
		inputBox.Position = UDim2.new(0, 94, 0, 0)
	else
		inputBox.Size = UDim2.new(1, -48, 1, 0)
		inputBox.Position = UDim2.new(0, 0, 0, 0)
	end
	-- update voice button visibility (voice not available in Whisper/System)
	voiceBtn.Visible = (ChatConfig.VoiceChannels :: { [Channel]: boolean })[ch] == true
end

for i = 1, #tabChannels do
	local ch: Channel = tabChannels[i]
	local btn = tabButtons[ch]
	if btn then
		btn.MouseButton1Click:Connect(function()
			setChannel(ch)
		end)
	end
end
setChannel("General")

----------------------------------------------------------------
-- Voice toggle
----------------------------------------------------------------
local function updateVoiceBtn()
	voiceBtn.Text = if voiceMuted then "🔇" else "🎤"
	voiceBtn.BackgroundColor3 = if voiceMuted
		then Color3.fromRGB(90, 30, 30)
		else Color3.fromRGB(30, 50, 90)
end

voiceBtn.MouseButton1Click:Connect(function()
	voiceMuted = not voiceMuted
	updateVoiceBtn()
	voiceToggleMute:FireServer()
end)

voiceStateChg.OnClientEvent:Connect(function(data: any)
	if typeof(data) == "table" and typeof(data.muted) == "boolean" then
		voiceMuted = data.muted
		updateVoiceBtn()
	end
end)

----------------------------------------------------------------
-- Slash-command + admin parser
----------------------------------------------------------------
local function parseSlashCommand(text: string): boolean
	local cmdRaw, restRaw = string.match(text, "^/(%S+)%s*(.*)")
	if not cmdRaw then
		return false
	end
	local cmd = string.lower(cmdRaw)
	local rest: string = restRaw or ""

	-- Party commands
	if cmd == "invite" or cmd == "p" then
		if rest == "" then
			systemMsg("/invite <ชื่อ>")
			return true
		end
		local pInvite = remotes:FindFirstChild("PartyInviteSend") :: RemoteFunction?
		if pInvite then
			local ok, msg = pInvite:InvokeServer(rest)
			systemMsg(if ok then msg else "❌ " .. msg)
		end
		return true
	elseif cmd == "leave" then
		local pLeave = remotes:FindFirstChild("PartyLeave") :: RemoteEvent?
		if pLeave then pLeave:FireServer() end
		systemMsg("ออกจากปาร์ตี้แล้ว")
		return true
	elseif cmd == "dismiss" then
		local pLeave = remotes:FindFirstChild("PartyLeave") :: RemoteEvent?
		if pLeave then pLeave:FireServer() end
		systemMsg("ยุบปาร์ตี้แล้ว")
		return true

	-- Clan commands
	elseif cmd == "clancreate" then
		if rest == "" then
			systemMsg("/clancreate <ชื่อ>")
			return true
		end
		local rf = remotes:FindFirstChild("GuildCreate") :: RemoteFunction?
		if rf then
			local ok, msg = rf:InvokeServer(rest)
			systemMsg(if ok then "✅ " .. msg else "❌ " .. msg)
		end
		return true
	elseif cmd == "claninvite" then
		if rest == "" then
			systemMsg("/claninvite <ชื่อ>")
			return true
		end
		local rf = remotes:FindFirstChild("GuildInviteSend") :: RemoteFunction?
		if rf then
			local ok, msg = rf:InvokeServer(rest)
			systemMsg(if ok then "✅ " .. msg else "❌ " .. msg)
		end
		return true
	elseif cmd == "clanleave" then
		local re = remotes:FindFirstChild("GuildLeave") :: RemoteEvent?
		if re then re:FireServer() end
		systemMsg("ออกจากแคลนแล้ว")
		return true

	-- Alliance commands
	elseif cmd == "allianceinvite" then
		if rest == "" then
			systemMsg("/allianceinvite <ชื่อแคลน>")
			return true
		end
		local rf = remotes:FindFirstChild("AllianceCreate") :: RemoteFunction?
		if rf then
			local ok, msg = rf:InvokeServer(rest)
			systemMsg(if ok then "✅ " .. msg else "❌ " .. msg)
		end
		return true
	elseif cmd == "allianceleave" then
		local re = remotes:FindFirstChild("AllianceLeave") :: RemoteEvent?
		if re then re:FireServer() end
		systemMsg("ออกจากพันธมิตรแล้ว")
		return true

	-- Friend commands
	elseif cmd == "friendinvite" then
		if rest == "" then
			systemMsg("/friendinvite <ชื่อ>")
			return true
		end
		for _, p in Players:GetPlayers() do
			if string.lower(p.Name) == string.lower(rest) then
				pcall(function()
					StarterGui:SetCore("PromptSendFriendRequest", p)
				end)
				return true
			end
		end
		systemMsg("ไม่พบผู้เล่น " .. rest .. " ในเซิร์ฟเวอร์นี้")
		return true
	elseif cmd == "frienddel" or cmd == "friendlist" then
		systemMsg("ใช้เมนูเพื่อน (กดไอคอนเพื่อน)")
		return true

	-- Utility
	elseif cmd == "loc" then
		local char = localPlayer.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local p = (root :: BasePart).Position
				systemMsg(string.format("ตำแหน่ง: %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
			end
		end
		return true
	elseif cmd == "time" then
		local lt = os.date("*t")
		systemMsg(string.format("เวลา: %02d:%02d:%02d", lt.hour, lt.min, lt.sec))
		return true
	elseif cmd == "target" then
		systemMsg("เลือกเป้าหมายโดยคลิกที่ตัวละคร")
		return true
	elseif cmd == "trade" then
		if rest == "" then
			systemMsg("/trade <ชื่อ>")
			return true
		end
		systemMsg("Trade (P4) ยังไม่เปิด")
		return true
	elseif cmd == "sit" then
		local char = localPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Sit = true end
		end
		return true
	elseif cmd == "stand" then
		local char = localPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Sit = false end
		end
		return true
	elseif cmd == "unstuck" then
		local char = localPlayer.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				(root :: BasePart).CFrame = (root :: BasePart).CFrame + Vector3.new(0, 5, 0)
			end
		end
		systemMsg("พยายามหลุดแล้ว")
		return true
	elseif cmd == "g" then
		if rest == "" then
			setChannel("Clan")
			return true
		end
		local ok, msg = chatSend:InvokeServer("Clan", rest, nil)
		if not ok then systemMsg("❌ " .. msg) end
		return true
	elseif cmd == "a" then
		if rest == "" then
			setChannel("Alliance")
			return true
		end
		local ok, msg = chatSend:InvokeServer("Alliance", rest, nil)
		if not ok then systemMsg("❌ " .. msg) end
		return true
	elseif cmd == "w" then
		-- /w targetName message
		local target, message = string.match(rest, "^(%S+)%s+(.*)")
		if not target or not message or message == "" then
			systemMsg("/w <ชื่อ> <ข้อความ>")
			return true
		end
		local ok, m = chatSend:InvokeServer("Whisper", message, target)
		if not ok then systemMsg("❌ " .. m) end
		return true
	end

	systemMsg("ไม่รู้จักคำสั่ง: /" .. cmd)
	return true
end

local function parseAdminCommand(text: string): boolean
	local cmdRaw, restRaw = string.match(text, "^:(%S+)%s*(.*)")
	if not cmdRaw then
		return false
	end
	local cmd = cmdRaw
	local rest: string = restRaw or ""
	local args: { string } = {}
	for w in string.gmatch(rest, "%S+") do
		table.insert(args, w)
	end
	local ok, msg = adminCmd:InvokeServer(cmd, table.unpack(args))
	systemMsg(if ok then "✅ " .. msg else "❌ " .. msg)
	return true
end

----------------------------------------------------------------
-- Send message
----------------------------------------------------------------
local function sendMessage()
	local text = inputBox.Text
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if text == "" then return end

	inputBox.Text = ""

	-- check slash / admin command
	if string.sub(text, 1, 1) == "/" then
		parseSlashCommand(text)
		return
	end
	if string.sub(text, 1, 1) == ":" then
		parseAdminCommand(text)
		return
	end

	-- regular chat → send to server
	local targetExtra: string? = nil
	if activeChannel == "Whisper" then
		targetExtra = whisperLabel.Text
		if targetExtra == "" then
			systemMsg("ระบุชื่อผู้รับก่อนกระซิบ")
			return
		end
	end

	local ok, msg = chatSend:InvokeServer(activeChannel, text, targetExtra)
	if not ok and msg ~= "" then
		systemMsg("❌ " .. msg)
	end
end

sendBtn.MouseButton1Click:Connect(sendMessage)

inputBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		sendMessage()
	end
end)

-- Enter key shortcut (even when not in textbox focus)
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		if not inputBox:IsFocused() then
			inputBox:CaptureFocus()
		end
	end
end)

----------------------------------------------------------------
-- Receive messages from server
----------------------------------------------------------------
-- Unified ChatReceive (General broadcast)
chatReceive.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then
		return
	end
	local ch: Channel = "General"
	if typeof(data.channel) == "string" then
		ch = data.channel :: Channel
	end
	local from = tostring(data.fromName or "")
	local msg  = tostring(data.message or "")
	local label = CHANNEL_LABEL[ch] or ch
	addLine(ch, string.format("[%s] %s: %s", label, from, msg))
end)

-- Clan chat backward-compat
guildChatRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	addLine("Clan",
		string.format("[แคลน] %s: %s", tostring(data.fromName or ""), tostring(data.message or "")))
end)

-- Alliance chat backward-compat
alliChatRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	addLine("Alliance",
		string.format("[พันธมิตร] %s: %s", tostring(data.fromName or ""), tostring(data.message or "")))
end)

-- Party chat backward-compat
partyChatRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	addLine("Party",
		string.format("[ปาร์ตี้] %s: %s", tostring(data.fromName or ""), tostring(data.message or "")))
end)

-- Whisper
whisperRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	addLine("Whisper",
		string.format("[กระซิบ] %s → คุณ: %s", tostring(data.fromName or ""), tostring(data.message or "")))
end)

-- Guild member online notify
guildMemberJoin.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	addLine("System", string.format("🟢 %s ออนไลน์ (แคลน)", tostring(data.displayName or "")))
end)

----------------------------------------------------------------
-- Startup
----------------------------------------------------------------
systemMsg("Chat พร้อมใช้งาน — พิมพ์ /help สำหรับคำสั่ง")
