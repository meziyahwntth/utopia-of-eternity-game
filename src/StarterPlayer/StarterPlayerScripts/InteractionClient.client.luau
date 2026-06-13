--!strict
--[[
	InteractionClient (P3-C) — Player Interaction Context Menu
	  • คลิก/แตะตัวละครผู้เล่น → popup menu 9 ปุ่ม
	  • ปุ่ม: View Equipment | Duel | Trade | Whisper | Add Friend |
	           Party Invite | Clan Invite | Carry | Block/Report
	  • Mobile: touch-friendly (ปุ่มสูง 44px)
	  • Duel/Trade/Carry → แสดง popup ยืนยันที่ฝั่งเป้าหมาย
	  • Follow → client-side (HumanoidRootPart lookAt loop)
]]
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local duelSend     = remotes:WaitForChild("DuelSend")     :: RemoteFunction
local duelAccept   = remotes:WaitForChild("DuelAccept")   :: RemoteFunction
local duelRcv      = remotes:WaitForChild("DuelReceived") :: RemoteEvent
local tradeSend    = remotes:WaitForChild("TradeSend")    :: RemoteFunction
local tradeRcv     = remotes:WaitForChild("TradeReceived") :: RemoteEvent
local carryReq     = remotes:WaitForChild("CarryRequest") :: RemoteFunction
local uncarryReq   = remotes:WaitForChild("UncarryRequest") :: RemoteEvent
local carryStarted = remotes:WaitForChild("CarryStarted") :: RemoteEvent
local carryEnded   = remotes:WaitForChild("CarryEnded")   :: RemoteEvent
local blockPlayer  = remotes:WaitForChild("BlockPlayer")  :: RemoteFunction
local partyInvite  = remotes:WaitForChild("InteractionPartyInvite") :: RemoteFunction
local clanInvite   = remotes:WaitForChild("InteractionClanInvite")  :: RemoteFunction

----------------------------------------------------------------
-- GUI Setup
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InteractionClient"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10  -- above ChatClient
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Context menu frame
local menuFrame = Instance.new("Frame")
menuFrame.Name = "ContextMenu"
menuFrame.Size = UDim2.new(0, 180, 0, 0)
menuFrame.AutomaticSize = Enum.AutomaticSize.Y
menuFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
menuFrame.BackgroundTransparency = 0.08
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.ZIndex = 20
menuFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = menuFrame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 1)
	layout.Parent = menuFrame
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = menuFrame
end

-- Header label (target name)
local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "Header"
headerLabel.Size = UDim2.new(1, 0, 0, 24)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = ""
headerLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 13
headerLabel.TextXAlignment = Enum.TextXAlignment.Center
headerLabel.LayoutOrder = 0
headerLabel.Parent = menuFrame

-- Divider
local div = Instance.new("Frame")
div.Name = "Divider"
div.Size = UDim2.new(1, 0, 0, 1)
div.BackgroundColor3 = Color3.fromRGB(60, 80, 130)
div.BorderSizePixel = 0
div.LayoutOrder = 1
div.Parent = menuFrame

-- Confirmation popup (for Duel/Trade/Carry received)
local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "ConfirmPopup"
confirmFrame.Size = UDim2.new(0, 260, 0, 110)
confirmFrame.Position = UDim2.new(0.5, -130, 0.5, -55)
confirmFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
confirmFrame.BackgroundTransparency = 0.05
confirmFrame.BorderSizePixel = 0
confirmFrame.Visible = false
confirmFrame.ZIndex = 30
confirmFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = confirmFrame
end

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, 0, 0, 40)
confirmTitle.Position = UDim2.new(0, 0, 0, 8)
confirmTitle.BackgroundTransparency = 1
confirmTitle.TextColor3 = Color3.fromRGB(255, 240, 160)
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextSize = 14
confirmTitle.TextWrapped = true
confirmTitle.Text = ""
confirmTitle.Parent = confirmFrame

local confirmAcceptBtn = Instance.new("TextButton")
confirmAcceptBtn.Size = UDim2.new(0, 100, 0, 36)
confirmAcceptBtn.Position = UDim2.new(0, 16, 0, 66)
confirmAcceptBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
confirmAcceptBtn.BorderSizePixel = 0
confirmAcceptBtn.Text = "✔ ยอมรับ"
confirmAcceptBtn.TextColor3 = Color3.fromRGB(220, 255, 220)
confirmAcceptBtn.Font = Enum.Font.GothamBold
confirmAcceptBtn.TextSize = 13
confirmAcceptBtn.Parent = confirmFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = confirmAcceptBtn
end

local confirmDeclineBtn = Instance.new("TextButton")
confirmDeclineBtn.Size = UDim2.new(0, 100, 0, 36)
confirmDeclineBtn.Position = UDim2.new(0, 144, 0, 66)
confirmDeclineBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
confirmDeclineBtn.BorderSizePixel = 0
confirmDeclineBtn.Text = "✘ ปฏิเสธ"
confirmDeclineBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
confirmDeclineBtn.Font = Enum.Font.GothamBold
confirmDeclineBtn.TextSize = 13
confirmDeclineBtn.Parent = confirmFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = confirmDeclineBtn
end

----------------------------------------------------------------
-- State
----------------------------------------------------------------
local _targetPlayer: Player? = nil
local _carryingState = false
local currentConfirmAction: (() -> ())? = nil

local function closeMenu()
	menuFrame.Visible = false
	_targetPlayer = nil
end

local function closeConfirm()
	confirmFrame.Visible = false
	currentConfirmAction = nil
end

local function showConfirm(title: string, onAccept: () -> ())
	confirmTitle.Text = title
	currentConfirmAction = onAccept
	confirmFrame.Visible = true
	-- auto-expire in 30 seconds
	task.delay(30, function()
		if confirmFrame.Visible then
			closeConfirm()
		end
	end)
end

confirmAcceptBtn.MouseButton1Click:Connect(function()
	if currentConfirmAction then
		currentConfirmAction()
	end
	closeConfirm()
end)
confirmDeclineBtn.MouseButton1Click:Connect(function()
	closeConfirm()
end)

----------------------------------------------------------------
-- Menu button builder
----------------------------------------------------------------
type MenuAction = {
	label: string,
	color: Color3,
	order: number,
	action: () -> (),
}

local function makeMenuBtn(item: MenuAction): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = Color3.fromRGB(18, 28, 55)
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 0
	btn.Text = item.label
	btn.TextColor3 = item.color
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = item.order
	btn.Parent = menuFrame
	do
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.Parent = btn
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
	end
	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0.1
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 0.3
	end)
	btn.MouseButton1Click:Connect(function()
		closeMenu()
		task.defer(item.action)
	end)
	return btn
end

----------------------------------------------------------------
-- Build menu for target player
----------------------------------------------------------------
local function buildMenu(target: Player)
	-- clear old buttons (keep header + divider)
	for _, ch in menuFrame:GetChildren() do
		if ch:IsA("TextButton") or (ch:IsA("TextLabel") and ch.Name ~= "Header") then
			ch:Destroy()
		end
	end

	headerLabel.Text = "👤 " .. target.DisplayName

	local actions: { MenuAction } = {
		{
			label = "🗡 ท้าดวล (Duel)",
			color = Color3.fromRGB(255, 140, 100),
			order = 10,
			action = function()
				local ok, msg = duelSend:InvokeServer(target.UserId)
				if not ok then
					warn("[Interaction] duel: " .. tostring(msg))
				end
			end,
		},
		{
			label = "💼 ขอแลกเปลี่ยน (Trade)",
			color = Color3.fromRGB(160, 230, 255),
			order = 20,
			action = function()
				local ok, msg = tradeSend:InvokeServer(target.UserId)
				if not ok then
					warn("[Interaction] trade: " .. tostring(msg))
				end
			end,
		},
		{
			label = "💬 กระซิบ (Whisper)",
			color = Color3.fromRGB(255, 220, 100),
			order = 30,
			action = function()
				-- switch ChatClient to Whisper tab + pre-fill target name
				-- ChatClient doesn't expose an API yet — use a BindableEvent pattern
				-- For now: open chat and set whisper target via game.ReplicatedStorage signal
				local be = ReplicatedStorage:FindFirstChild("ChatClientWhisperTo")
				if be and be:IsA("BindableEvent") then
					(be :: BindableEvent):Fire(target.Name)
				end
			end,
		},
		{
			label = "🤝 เพิ่มเพื่อน",
			color = Color3.fromRGB(150, 255, 150),
			order = 40,
			action = function()
				pcall(function()
					StarterGui:SetCore("PromptSendFriendRequest", target)
				end)
			end,
		},
		{
			label = "🎉 ชวนเข้าปาร์ตี้",
			color = Color3.fromRGB(100, 200, 255),
			order = 50,
			action = function()
				local ok, msg = partyInvite:InvokeServer(target.Name)
				if not ok then
					warn("[Interaction] party invite: " .. tostring(msg))
				end
			end,
		},
		{
			label = "⚔ ชวนเข้าแคลน",
			color = Color3.fromRGB(130, 255, 160),
			order = 60,
			action = function()
				local ok, msg = clanInvite:InvokeServer(target.Name)
				if not ok then
					warn("[Interaction] clan invite: " .. tostring(msg))
				end
			end,
		},
		{
			label = "🫂 อุ้ม (Carry)",
			color = Color3.fromRGB(220, 180, 255),
			order = 70,
			action = function()
				local ok, msg = carryReq:InvokeServer(target.UserId)
				if not ok then
					warn("[Interaction] carry: " .. tostring(msg))
				else
					_carryingState = true
				end
			end,
		},
		{
			label = "🚫 บล็อก",
			color = Color3.fromRGB(255, 100, 100),
			order = 80,
			action = function()
				showConfirm(
					string.format("บล็อก %s?\nเขาจะไม่สามารถ whisper หรือ duel คุณได้", target.DisplayName),
					function()
						local ok, msg = blockPlayer:InvokeServer(target.UserId)
						if not ok then warn("[Interaction] block: " .. tostring(msg)) end
					end
				)
			end,
		},
		{
			label = "🚩 รายงาน (Report)",
			color = Color3.fromRGB(255, 80, 80),
			order = 90,
			action = function()
				pcall(function()
					StarterGui:SetCore("PromptReportPlayer", target :: any)
				end)
			end,
		},
	}

	for _, item in actions do
		makeMenuBtn(item)
	end
end

----------------------------------------------------------------
-- Detect click on player character
----------------------------------------------------------------
local function getPlayerFromPart(part: Instance?): Player?
	if not part then return nil end
	for _, p in Players:GetPlayers() do
		if p ~= localPlayer and p.Character and p.Character:IsAncestorOf(part) then
			return p
		end
	end
	return nil
end

local function screenPosForCharacter(char: Model): Vector2?
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end
	local pos, onScreen = camera:WorldToScreenPoint((root :: BasePart).Position + Vector3.new(0, 2.5, 0))
	if onScreen then
		return Vector2.new(pos.X, pos.Y)
	end
	return nil
end

local function showMenuAt(target: Player, screenPos: Vector2)
	_targetPlayer = target
	buildMenu(target)
	-- clamp to screen
	local vp = camera.ViewportSize
	local menuW = 180
	local x = math.clamp(screenPos.X, 0, vp.X - menuW)
	local y = math.clamp(screenPos.Y, 0, vp.Y - 350)
	menuFrame.Position = UDim2.new(0, x, 0, y)
	menuFrame.Visible = true
end

-- Mouse click
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		-- if menu is open and user clicks outside it → close
		if menuFrame.Visible then
			closeMenu()
			return
		end

		-- Raycast to find character part
		local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500)
		if not result then return end
		local hitPlayer = getPlayerFromPart(result.Instance)
		if not hitPlayer or not hitPlayer.Character then return end

		local screenPos = screenPosForCharacter(hitPlayer.Character :: Model)
		if screenPos then
			showMenuAt(hitPlayer, screenPos)
		end
	end
end)

-- Close menu on Escape
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		closeMenu()
		closeConfirm()
	end
end)

----------------------------------------------------------------
-- Follow mode (client-side loop)
----------------------------------------------------------------
local followTarget: Player? = nil
local followConn: RBXScriptConnection? = nil

local function stopFollow()
	followTarget = nil
	if followConn then
		followConn:Disconnect()
		followConn = nil
	end
end

local function startFollow(target: Player)
	stopFollow()
	followTarget = target
	followConn = RunService.Heartbeat:Connect(function()
		local t = followTarget
		if not t or not t.Character then
			stopFollow()
			return
		end
		local myChar = localPlayer.Character
		if not myChar then
			stopFollow()
			return
		end
		local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local tRoot = t.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not myRoot or not tRoot then
			stopFollow()
			return
		end
		local dist = (tRoot.Position - (myRoot :: BasePart).Position).Magnitude
		if dist > 4 then
			local hum = myChar:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:MoveTo(tRoot.Position)
			end
		end
	end)
end

-- Expose follow toggle via interact menu button (add dynamically)
local function addFollowButton(target: Player)
	local isFollowing = followTarget == target
	makeMenuBtn({
		label = if isFollowing then "🛑 หยุดตาม" else "🏃 ตาม (Follow)",
		color = Color3.fromRGB(200, 200, 255),
		order = 65,
		action = function()
			if isFollowing then
				stopFollow()
			else
				startFollow(target)
			end
		end,
	})
end
-- Inject follow button into buildMenu
local _origBuild = buildMenu
buildMenu = function(target: Player)
	_origBuild(target)
	addFollowButton(target)
end

----------------------------------------------------------------
-- Carry controls (show uncarry button when carrying)
----------------------------------------------------------------
local uncarryBtn = Instance.new("TextButton")
uncarryBtn.Size = UDim2.new(0, 140, 0, 36)
uncarryBtn.Position = UDim2.new(0.5, -70, 0, 120)
uncarryBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
uncarryBtn.BorderSizePixel = 0
uncarryBtn.Text = "🫂 วางลง (Uncarry)"
uncarryBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
uncarryBtn.Font = Enum.Font.GothamBold
uncarryBtn.TextSize = 13
uncarryBtn.Visible = false
uncarryBtn.ZIndex = 25
uncarryBtn.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = uncarryBtn
end

uncarryBtn.MouseButton1Click:Connect(function()
	uncarryReq:FireServer()
	uncarryBtn.Visible = false
	_carryingState = false
end)

carryStarted.OnClientEvent:Connect(function(data: any)
	if typeof(data) == "table" and data.targetUserId then
		_carryingState = true
		uncarryBtn.Visible = true
	end
end)
carryEnded.OnClientEvent:Connect(function(_data: any)
	_carryingState = false
	uncarryBtn.Visible = false
end)

----------------------------------------------------------------
-- Duel / Trade received popups
----------------------------------------------------------------
duelRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	local fromName = tostring(data.fromName or "ผู้เล่น")
	local fromUid  = data.fromUserId
	showConfirm(
		string.format("⚔ %s ท้าดวลคุณ!\nยอมรับหรือไม่?", fromName),
		function()
			if typeof(fromUid) == "number" then
				local _ok, _msg = duelAccept:InvokeServer(fromUid)
			end
		end
	)
end)

tradeRcv.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	local fromName = tostring(data.fromName or "ผู้เล่น")
	showConfirm(
		string.format("💼 %s ขอแลกเปลี่ยนกับคุณ!\n(Trade เปิดใน P4)", fromName),
		function()
			-- P4 stub: notify decline (no server call needed for stub)
		end
	)
end)

----------------------------------------------------------------
-- Whisper BindableEvent setup (ChatClient listens)
----------------------------------------------------------------
local whisperBE = Instance.new("BindableEvent")
whisperBE.Name = "ChatClientWhisperTo"
whisperBE.Parent = ReplicatedStorage

-- ChatClient can listen: ReplicatedStorage.ChatClientWhisperTo.Event:Connect(function(name) ... end)

print("[Interaction] InteractionClient online (P3-C)")
