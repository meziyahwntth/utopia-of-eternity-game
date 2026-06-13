--!strict
--[[
	GuildClient (P3-B) — แคลน/กิลด์ client-side
	  slash commands:
	    /clancreate <ชื่อ>   — สร้างแคลน
	    /claninvite <ชื่อ>  — เชิญผู้เล่น
	    /clanleave           — ออกจากแคลน
	    /clan                — เปิด/ปิดแผง guild panel
	  + invite popup (รับ/ปฏิเสธ)
	  + guild panel (ชื่อแคลน / เลเวล / rep / สมาชิก+ยศ)
	  แม่แบบ: PartyClient.client.luau
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local guildCreate        = remotes:WaitForChild("GuildCreate")        :: RemoteFunction
local guildInviteSend    = remotes:WaitForChild("GuildInviteSend")    :: RemoteFunction
local guildAccept        = remotes:WaitForChild("GuildAccept")        :: RemoteFunction
local guildDecline       = remotes:WaitForChild("GuildDecline")       :: RemoteEvent
local guildLeave         = remotes:WaitForChild("GuildLeave")         :: RemoteEvent
local guildGet           = remotes:WaitForChild("GuildGet")           :: RemoteFunction
local guildInviteReceived = remotes:WaitForChild("GuildInviteReceived") :: RemoteEvent
local guildStateChanged  = remotes:WaitForChild("GuildStateChanged")  :: RemoteEvent
-- chunk2
local guildChatSend      = remotes:WaitForChild("GuildChatSend")         :: RemoteFunction
local guildChatReceived  = remotes:WaitForChild("GuildChatReceived")     :: RemoteEvent
local guildMemberJoined  = remotes:WaitForChild("GuildMemberJoined")     :: RemoteEvent
local allianceCreate     = remotes:WaitForChild("AllianceCreate")        :: RemoteFunction
local allianceAccept     = remotes:WaitForChild("AllianceAccept")        :: RemoteFunction
local allianceDecline    = remotes:WaitForChild("AllianceDecline")       :: RemoteEvent
local allianceLeave      = remotes:WaitForChild("AllianceLeave")         :: RemoteEvent
local allianceInviteReceived = remotes:WaitForChild("AllianceInviteReceived") :: RemoteEvent

-- state ฝั่ง client
local _currentGuild: { [string]: any }? = nil

----------------------------------------------------------------
-- systemMsg helper (เหมือน PartyClient)
----------------------------------------------------------------
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
-- GUI — Guild Panel (มุมซ้ายบน ต่ำจาก PartyList)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GuildGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Panel หลัก
local panel = Instance.new("Frame")
panel.Name = "GuildPanel"
panel.Size = UDim2.fromOffset(200, 260)
panel.Position = UDim2.fromOffset(12, 330) -- ต่ำจาก PartyList (120+200+10)
panel.BackgroundColor3 = Color3.fromRGB(18, 26, 50)
panel.BackgroundTransparency = 0.12
panel.Visible = false
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel
local panelPad = Instance.new("UIPadding")
panelPad.PaddingTop = UDim.new(0, 8)
panelPad.PaddingLeft = UDim.new(0, 8)
panelPad.PaddingRight = UDim.new(0, 8)
panelPad.Parent = panel
local panelLayout = Instance.new("UIListLayout")
panelLayout.Padding = UDim.new(0, 4)
panelLayout.Parent = panel

-- หัว panel
local panelTitle = Instance.new("TextLabel")
panelTitle.Name = "GuildTitle"
panelTitle.Size = UDim2.new(1, 0, 0, 22)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "⚔ แคลน"
panelTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
panelTitle.TextScaled = true
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.Parent = panel

local panelInfo = Instance.new("TextLabel")
panelInfo.Name = "GuildInfo"
panelInfo.Size = UDim2.new(1, 0, 0, 36)
panelInfo.BackgroundTransparency = 1
panelInfo.Text = "(ยังไม่มีแคลน)"
panelInfo.TextColor3 = Color3.fromRGB(200, 210, 230)
panelInfo.TextScaled = true
panelInfo.TextWrapped = true
panelInfo.Font = Enum.Font.Gotham
panelInfo.TextXAlignment = Enum.TextXAlignment.Left
panelInfo.Parent = panel

-- divider
local div = Instance.new("Frame")
div.Name = "Divider"
div.Size = UDim2.new(1, 0, 0, 1)
div.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
div.BackgroundTransparency = 0
div.BorderSizePixel = 0
div.Parent = panel

-- member list container (scrollable)
local memberScroll = Instance.new("ScrollingFrame")
memberScroll.Name = "MemberScroll"
memberScroll.Size = UDim2.new(1, 0, 0, 170)
memberScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
memberScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
memberScroll.ScrollBarThickness = 4
memberScroll.BackgroundTransparency = 1
memberScroll.Parent = panel
local memberLayout = Instance.new("UIListLayout")
memberLayout.Padding = UDim.new(0, 3)
memberLayout.Parent = memberScroll

----------------------------------------------------------------
-- อัปเดต panel จาก guild state
----------------------------------------------------------------
local RANK_COLOR: { [string]: Color3 } = {
	Leader  = Color3.fromRGB(255, 215, 80),
	Officer = Color3.fromRGB(130, 200, 255),
	Veteran = Color3.fromRGB(180, 220, 160),
	Member  = Color3.fromRGB(210, 215, 225),
}
local RANK_PREFIX: { [string]: string } = {
	Leader  = "♛ ",
	Officer = "◈ ",
	Veteran = "◆ ",
	Member  = "• ",
}

local function rebuildPanel(state: { [string]: any }?)
	-- ล้าง member rows เดิม
	for _, c in memberScroll:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end

	if state == nil or (state.id == nil or state.id == "") then
		panelTitle.Text = "⚔ แคลน"
		panelInfo.Text = "(ยังไม่มีแคลน)"
		return
	end

	local lvl = state.level or 1
	local rep = state.reputation or 0
	panelTitle.Text = "⚔ " .. tostring(state.name)
	panelInfo.Text = string.format("Lv%d  REP %d", lvl, rep)

	if typeof(state.members) == "table" then
		-- เรียง Leader ก่อน
		local rows: { { uid: string, rank: string } } = {}
		for uidStr, rank in state.members do
			table.insert(rows, { uid = uidStr, rank = tostring(rank) })
		end
		table.sort(rows, function(a, b)
			local order = { Leader = 1, Officer = 2, Veteran = 3, Member = 4 }
			return (order[a.rank] or 9) < (order[b.rank] or 9)
		end)
		for _, row in rows do
			local uid = tonumber(row.uid)
			local displayName = row.uid
			if uid then
				local p = Players:GetPlayerByUserId(uid)
				displayName = if p then p.DisplayName else tostring(uid)
			end
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = RANK_COLOR[row.rank] or Color3.fromRGB(210, 215, 225)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.Gotham
			local prefix = RANK_PREFIX[row.rank] or "• "
			lbl.Text = prefix .. displayName
			lbl.Parent = memberScroll
		end
	end
end

----------------------------------------------------------------
-- Invite Popup
----------------------------------------------------------------
local function showInvitePopup(data: any)
	local guildName = if typeof(data) == "table" then tostring(data.guildName) else "แคลน"
	local fromPlayer = if typeof(data) == "table" then tostring(data.fromPlayer) else "ใครบางคน"

	local popup = Instance.new("Frame")
	popup.Size = UDim2.fromOffset(300, 130)
	popup.Position = UDim2.new(0.5, 0, 0.25, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(18, 26, 50)
	popup.ZIndex = 10
	popup.Parent = gui
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 12)
	pc.Parent = popup

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -16, 0, 64)
	msg.Position = UDim2.fromOffset(8, 8)
	msg.BackgroundTransparency = 1
	msg.Text = string.format("[%s] %s เชิญเข้าแคลน", guildName, fromPlayer)
	msg.TextColor3 = Color3.fromRGB(230, 240, 255)
	msg.TextScaled = true
	msg.TextWrapped = true
	msg.Font = Enum.Font.GothamMedium
	msg.ZIndex = 10
	msg.Parent = popup

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0.45, 0, 0, 40)
	acceptBtn.Position = UDim2.new(0.03, 0, 1, -48)
	acceptBtn.Text = "รับ"
	acceptBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 100)
	acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	acceptBtn.TextScaled = true
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.ZIndex = 11
	acceptBtn.Parent = popup
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 8)
	ac.Parent = acceptBtn

	local declineBtn = Instance.new("TextButton")
	declineBtn.Size = UDim2.new(0.45, 0, 0, 40)
	declineBtn.Position = UDim2.new(0.52, 0, 1, -48)
	declineBtn.Text = "ปฏิเสธ"
	declineBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
	declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	declineBtn.TextScaled = true
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.ZIndex = 11
	declineBtn.Parent = popup
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = declineBtn

	acceptBtn.Activated:Connect(function()
		popup:Destroy()
		local _ok, m = guildAccept:InvokeServer()
		systemMsg("[แคลน] " .. tostring(m))
	end)
	declineBtn.Activated:Connect(function()
		popup:Destroy()
		guildDecline:FireServer()
		systemMsg("[แคลน] ปฏิเสธคำเชิญแล้ว")
	end)

	-- auto-expire ตามหลัง server (120 วินาที แต่ใช้ 90 วิฝั่ง client กันเผื่อ)
	task.delay(90, function()
		if popup.Parent then
			popup:Destroy()
		end
	end)
end

----------------------------------------------------------------
-- Slash Commands
----------------------------------------------------------------
local function makeCmd(cmdName: string, primary: string, secondary: string?): TextChatCommand
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = cmdName
	cmd.PrimaryAlias = primary
	if secondary then
		cmd.SecondaryAlias = secondary
	end
	cmd.Parent = TextChatService
	return cmd
end

-- /clancreate <ชื่อ>
local createCmd = makeCmd("ClanCreateCommand", "/clancreate", nil)
createCmd.Triggered:Connect(function(_o, text)
	local name = string.match(string.gsub(text, "^/%S+%s*", ""), "^(.+)$")
	if not name or string.gsub(name, "%s", "") == "" then
		systemMsg("[แคลน] ใช้: /clancreate <ชื่อแคลน>")
		return
	end
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	local _ok, msg = guildCreate:InvokeServer(name)
	systemMsg("[แคลน] " .. tostring(msg))
end)

-- /claninvite <ชื่อ>
local inviteCmd = makeCmd("ClanInviteCommand", "/claninvite", nil)
inviteCmd.Triggered:Connect(function(_o, text)
	local name = string.match(string.gsub(text, "^/%S+%s*", ""), "^(%S+)")
	if not name then
		systemMsg("[แคลน] ใช้: /claninvite <ชื่อผู้เล่น>")
		return
	end
	local _ok, msg = guildInviteSend:InvokeServer(name)
	systemMsg("[แคลน] " .. tostring(msg))
end)

-- /clanleave
local leaveCmd = makeCmd("ClanLeaveCommand", "/clanleave", nil)
leaveCmd.Triggered:Connect(function()
	guildLeave:FireServer()
	systemMsg("[แคลน] ออกจากแคลนแล้ว")
end)

-- /clan → toggle panel
local panelCmd = makeCmd("ClanPanelCommand", "/clan", nil)
panelCmd.Triggered:Connect(function()
	if not panel.Visible then
		-- โหลดข้อมูลใหม่จาก server ก่อนเปิด
		local state = guildGet:InvokeServer()
		_currentGuild = state
		rebuildPanel(state)
		panel.Visible = true
	else
		panel.Visible = false
	end
end)

----------------------------------------------------------------
-- Remote Listeners
----------------------------------------------------------------
guildInviteReceived.OnClientEvent:Connect(function(data: any)
	showInvitePopup(data)
end)

guildStateChanged.OnClientEvent:Connect(function(state: any)
	if typeof(state) ~= "table" then
		return
	end
	if typeof(state.error) == "string" then
		systemMsg("[แคลน] ⚠ " .. state.error)
		return
	end
	_currentGuild = state
	rebuildPanel(state)
	-- ซ่อน panel อัตโนมัติถ้าออกจากแคลน
	if state.id == "" and panel.Visible then
		panel.Visible = false
	end
end)

----------------------------------------------------------------
-- chunk2: Slash Commands — Clan Chat + Alliance
----------------------------------------------------------------

-- /g <ข้อความ>
local gCmd = makeCmd("ClanChatCommand", "/g", nil)
gCmd.Triggered:Connect(function(_o, text)
	local msg = string.gsub(text, "^/%S+%s*", "")
	if msg == "" then return end
	local ok, m = guildChatSend:InvokeServer(msg)
	if not ok then
		systemMsg("[ระบบ] " .. tostring(m))
	end
end)

-- /allianceinvite <ชื่อแคลน>
local aInviteCmd = makeCmd("AllianceInviteCommand", "/allianceinvite", nil)
aInviteCmd.Triggered:Connect(function(_o, text)
	local name = string.match(string.gsub(text, "^/%S+%s*", ""), "^(.-)%s*$")
	if not name or name == "" then
		systemMsg("[พันธมิตร] ใช้: /allianceinvite <ชื่อแคลน>")
		return
	end
	local _ok, msg = allianceCreate:InvokeServer(name)
	systemMsg("[พันธมิตร] " .. tostring(msg))
end)

-- /allianceleave
local aLeaveCmd = makeCmd("AllianceLeaveCommand", "/allianceleave", nil)
aLeaveCmd.Triggered:Connect(function()
	allianceLeave:FireServer()
	systemMsg("[พันธมิตร] ออกจากพันธมิตรแล้ว")
end)

----------------------------------------------------------------
-- Alliance Invite Popup
----------------------------------------------------------------
local function showAllianceInvitePopup(data: any)
	local clanName = if typeof(data) == "table" then tostring(data.fromClanName) else "แคลน"
	local leaderName = if typeof(data) == "table" then tostring(data.fromLeaderName) else "ใครบางคน"

	local popup = Instance.new("Frame")
	popup.Size = UDim2.fromOffset(300, 130)
	popup.Position = UDim2.new(0.5, 0, 0.35, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(28, 18, 50)
	popup.ZIndex = 10
	popup.Parent = gui
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 12)
	pc.Parent = popup

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -16, 0, 66)
	msg.Position = UDim2.fromOffset(8, 8)
	msg.BackgroundTransparency = 1
	msg.Text = string.format("[%s] %s ชวนเป็นพันธมิตร", clanName, leaderName)
	msg.TextColor3 = Color3.fromRGB(230, 200, 255)
	msg.TextScaled = true
	msg.TextWrapped = true
	msg.Font = Enum.Font.GothamMedium
	msg.ZIndex = 10
	msg.Parent = popup

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0.45, 0, 0, 40)
	acceptBtn.Position = UDim2.new(0.03, 0, 1, -48)
	acceptBtn.Text = "รับ"
	acceptBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
	acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	acceptBtn.TextScaled = true
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.ZIndex = 11
	acceptBtn.Parent = popup
	local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 8); ac.Parent = acceptBtn

	local declineBtn = Instance.new("TextButton")
	declineBtn.Size = UDim2.new(0.45, 0, 0, 40)
	declineBtn.Position = UDim2.new(0.52, 0, 1, -48)
	declineBtn.Text = "ปฏิเสธ"
	declineBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
	declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	declineBtn.TextScaled = true
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.ZIndex = 11
	declineBtn.Parent = popup
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 8); dc.Parent = declineBtn

	acceptBtn.Activated:Connect(function()
		popup:Destroy()
		local _ok, m = allianceAccept:InvokeServer()
		systemMsg("[พันธมิตร] " .. tostring(m))
	end)
	declineBtn.Activated:Connect(function()
		popup:Destroy()
		allianceDecline:FireServer()
		systemMsg("[พันธมิตร] ปฏิเสธคำเชิญแล้ว")
	end)
	task.delay(90, function()
		if popup.Parent then popup:Destroy() end
	end)
end

----------------------------------------------------------------
-- chunk2: Remote Listeners
----------------------------------------------------------------
guildChatReceived.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	systemMsg(string.format("[แคลน %s] %s: %s",
		tostring(data.guildName), tostring(data.fromName), tostring(data.message)))
end)

guildMemberJoined.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	systemMsg("[แคลน] 🟢 " .. tostring(data.displayName) .. " ออนไลน์แล้ว")
end)

allianceInviteReceived.OnClientEvent:Connect(function(data: any)
	showAllianceInvitePopup(data)
end)

----------------------------------------------------------------
-- โหลดสถานะแรกเมื่อเข้าเกม
----------------------------------------------------------------
task.delay(2, function()
	local ok, state = pcall(function()
		return guildGet:InvokeServer()
	end)
	if ok and typeof(state) == "table" then
		_currentGuild = state
		rebuildPanel(state)
	end
end)
