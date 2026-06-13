--!strict
--[[
	InteractionClient (P3-C+) — Radial interaction wheel + target lock
	  • คลิก/แตะตัวละครผู้เล่น → 8-direction radial menu
	  • Trade | Whisper | Party | Clan | Follow | Carry | Block | Report
	  • Mobile: touch zones ≥48×48px, tween open animation
	  • Target lock: Highlight + name billboard while menu open
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RadialMenuConfig = require(Modules:WaitForChild("RadialMenuConfig"))

type ActionId = RadialMenuConfig.ActionId

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local duelAccept = remotes:WaitForChild("DuelAccept") :: RemoteFunction
local duelRcv = remotes:WaitForChild("DuelReceived") :: RemoteEvent
local tradeSend = remotes:WaitForChild("TradeSend") :: RemoteFunction
local tradeRcv = remotes:WaitForChild("TradeReceived") :: RemoteEvent
local carryReq = remotes:WaitForChild("CarryRequest") :: RemoteFunction
local uncarryReq = remotes:WaitForChild("UncarryRequest") :: RemoteEvent
local carryStarted = remotes:WaitForChild("CarryStarted") :: RemoteEvent
local carryEnded = remotes:WaitForChild("CarryEnded") :: RemoteEvent
local blockPlayer = remotes:WaitForChild("BlockPlayer") :: RemoteFunction
local partyInvite = remotes:WaitForChild("InteractionPartyInvite") :: RemoteFunction
local clanInvite = remotes:WaitForChild("InteractionClanInvite") :: RemoteFunction

----------------------------------------------------------------
-- GUI Setup
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InteractionClient"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local wheelSize = RadialMenuConfig.WheelSize
local btnSize = RadialMenuConfig.ButtonSize
local radius = RadialMenuConfig.Radius

local radialFrame = Instance.new("Frame")
radialFrame.Name = "RadialWheel"
radialFrame.Size = UDim2.fromOffset(wheelSize, wheelSize)
radialFrame.BackgroundTransparency = 1
radialFrame.Visible = false
radialFrame.ZIndex = 20
radialFrame.Parent = screenGui

local radialScale = Instance.new("UIScale")
radialScale.Scale = 0
radialScale.Parent = radialFrame

local hub = Instance.new("Frame")
hub.Name = "Hub"
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.Size = UDim2.fromOffset(72, 72)
hub.BackgroundColor3 = RadialMenuConfig.HubBackground
hub.BackgroundTransparency = RadialMenuConfig.HubTransparency
hub.BorderSizePixel = 0
hub.ZIndex = 21
hub.Parent = radialFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = hub
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 110, 180)
	stroke.Thickness = 1.5
	stroke.Parent = hub
end

local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "Header"
headerLabel.Size = UDim2.new(1, -8, 1, -8)
headerLabel.Position = UDim2.fromOffset(4, 4)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = ""
headerLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 11
headerLabel.TextWrapped = true
headerLabel.TextXAlignment = Enum.TextXAlignment.Center
headerLabel.TextYAlignment = Enum.TextYAlignment.Center
headerLabel.ZIndex = 22
headerLabel.Parent = hub

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
local radialButtons: { TextButton } = {}
local openTween: Tween? = nil

local targetHighlight: Highlight? = nil
local targetBillboard: BillboardGui? = nil

local function clearTargetLock()
	if targetHighlight then
		targetHighlight:Destroy()
		targetHighlight = nil
	end
	if targetBillboard then
		targetBillboard:Destroy()
		targetBillboard = nil
	end
end

local function applyTargetLock(target: Player)
	clearTargetLock()
	local char = target.Character
	if not char then
		return
	end

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(80, 140, 255)
	hl.FillTransparency = 0.65
	hl.OutlineColor = Color3.fromRGB(255, 220, 120)
	hl.OutlineTransparency = 0
	hl.Parent = char
	targetHighlight = hl

	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 22)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = root
	bb.Parent = root
	targetBillboard = bb

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "👤 " .. target.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = bb
end

local function closeMenu()
	radialFrame.Visible = false
	radialScale.Scale = 0
	if openTween then
		openTween:Cancel()
		openTween = nil
	end
	clearTargetLock()
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
-- Follow mode
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
		local dist = (tRoot.Position - myRoot.Position).Magnitude
		if dist > 4 then
			local hum = myChar:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:MoveTo(tRoot.Position)
			end
		end
	end)
end

----------------------------------------------------------------
-- Radial action dispatch
----------------------------------------------------------------
local function runAction(actionId: ActionId, target: Player)
	if actionId == "Trade" then
		local ok, msg = tradeSend:InvokeServer(target.UserId)
		if not ok then
			warn("[Interaction] trade: " .. tostring(msg))
		end
	elseif actionId == "Whisper" then
		local be = ReplicatedStorage:FindFirstChild("ChatClientWhisperTo")
		if be and be:IsA("BindableEvent") then
			(be :: BindableEvent):Fire(target.Name)
		end
	elseif actionId == "Party" then
		local ok, msg = partyInvite:InvokeServer(target.Name)
		if not ok then
			warn("[Interaction] party invite: " .. tostring(msg))
		end
	elseif actionId == "Clan" then
		local ok, msg = clanInvite:InvokeServer(target.Name)
		if not ok then
			warn("[Interaction] clan invite: " .. tostring(msg))
		end
	elseif actionId == "Follow" then
		if followTarget == target then
			stopFollow()
		else
			startFollow(target)
		end
	elseif actionId == "Carry" then
		local ok, msg = carryReq:InvokeServer(target.UserId)
		if not ok then
			warn("[Interaction] carry: " .. tostring(msg))
		else
			_carryingState = true
		end
	elseif actionId == "Block" then
		showConfirm(
			string.format("บล็อก %s?\nเขาจะไม่สามารถ whisper หรือ duel คุณได้", target.DisplayName),
			function()
				local ok, msg = blockPlayer:InvokeServer(target.UserId)
				if not ok then
					warn("[Interaction] block: " .. tostring(msg))
				end
			end
		)
	elseif actionId == "Report" then
		pcall(function()
			StarterGui:SetCore("PromptReportPlayer", target :: any)
		end)
	end
end

local function clearRadialButtons()
	for _, btn in radialButtons do
		btn:Destroy()
	end
	table.clear(radialButtons)
end

local function makeRadialBtn(
	spec: RadialMenuConfig.RadialAction,
	displayIcon: string,
	displayLabel: string,
	onClick: () -> ()
): TextButton
	local rad = math.rad(spec.angleDeg - 90)
	local offsetX = math.cos(rad) * radius
	local offsetY = math.sin(rad) * radius

	local btn = Instance.new("TextButton")
	btn.Name = spec.id
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Size = UDim2.fromOffset(btnSize, btnSize)
	btn.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
	btn.BackgroundColor3 = Color3.fromRGB(18, 28, 55)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 0
	btn.Text = displayIcon .. "\n" .. displayLabel
	btn.TextColor3 = spec.color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextWrapped = true
	btn.ZIndex = 23
	btn.Parent = radialFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = btn
		local stroke = Instance.new("UIStroke")
		stroke.Color = spec.color
		stroke.Thickness = 1
		stroke.Transparency = 0.35
		stroke.Parent = btn
	end
	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0.05
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 0.15
	end)
	btn.MouseButton1Click:Connect(function()
		closeMenu()
		task.defer(onClick)
	end)
	table.insert(radialButtons, btn)
	return btn
end

local function buildRadial(target: Player)
	clearRadialButtons()
	headerLabel.Text = target.DisplayName

	for _, spec in RadialMenuConfig.Actions do
		local icon = spec.icon
		local label = spec.label
		if spec.id == "Follow" and followTarget == target then
			icon = "🛑"
			label = "Stop"
		end
		makeRadialBtn(spec, icon, label, function()
			runAction(spec.id, target)
		end)
	end
end

local function animateOpen()
	radialScale.Scale = 0
	if openTween then
		openTween:Cancel()
	end
	local tween = TweenService:Create(
		radialScale,
		TweenInfo.new(RadialMenuConfig.OpenTweenDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	openTween = tween
	tween:Play()
end

----------------------------------------------------------------
-- Detect click on player character
----------------------------------------------------------------
local function getPlayerFromPart(part: Instance?): Player?
	if not part then
		return nil
	end
	for _, p in Players:GetPlayers() do
		if p ~= localPlayer and p.Character and p.Character:IsAncestorOf(part) then
			return p
		end
	end
	return nil
end

local function screenPosForCharacter(char: Model): Vector2?
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local pos, onScreen = camera:WorldToScreenPoint(root.Position + Vector3.new(0, 2.5, 0))
	if onScreen then
		return Vector2.new(pos.X, pos.Y)
	end
	return nil
end

local function isPointInsideRadial(screenPos: Vector2): boolean
	if not radialFrame.Visible then
		return false
	end
	local absPos = radialFrame.AbsolutePosition
	local absSize = radialFrame.AbsoluteSize
	local center = absPos + absSize / 2
	return (screenPos - center).Magnitude <= (wheelSize / 2 + 8)
end

local function showMenuAt(target: Player, screenPos: Vector2)
	_targetPlayer = target
	buildRadial(target)
	applyTargetLock(target)

	local vp = camera.ViewportSize
	local half = wheelSize / 2
	local x = math.clamp(screenPos.X - half, 0, vp.X - wheelSize)
	local y = math.clamp(screenPos.Y - half, 0, vp.Y - wheelSize)
	radialFrame.Position = UDim2.fromOffset(x, y)
	radialFrame.Visible = true
	animateOpen()
end

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		local clickPos = Vector2.new(input.Position.X, input.Position.Y)

		if radialFrame.Visible then
			if not isPointInsideRadial(clickPos) then
				closeMenu()
			end
			return
		end

		local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500)
		if not result then
			return
		end
		local hitPlayer = getPlayerFromPart(result.Instance)
		if not hitPlayer or not hitPlayer.Character then
			return
		end

		local screenPos = screenPosForCharacter(hitPlayer.Character :: Model)
		if screenPos then
			showMenuAt(hitPlayer, screenPos)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		closeMenu()
		closeConfirm()
	end
end)

----------------------------------------------------------------
-- Carry controls
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
	if typeof(data) ~= "table" then
		return
	end
	local fromName = tostring(data.fromName or "ผู้เล่น")
	local fromUid = data.fromUserId
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
	if typeof(data) ~= "table" then
		return
	end
	local fromName = tostring(data.fromName or "ผู้เล่น")
	local fromUid = data.fromUserId
	showConfirm(
		string.format("💼 %s ขอแลกเปลี่ยนกับคุณ!\nยอมรับหรือไม่?", fromName),
		function()
			if typeof(fromUid) == "number" then
				local be = ReplicatedStorage:FindFirstChild("TradingClientAccept")
				if be and be:IsA("BindableEvent") then
					(be :: BindableEvent):Fire({
						fromUserId = fromUid,
						fromName = fromName,
					})
				end
			end
		end
	)
end)

----------------------------------------------------------------
-- Whisper BindableEvent setup (ChatClient listens)
----------------------------------------------------------------
local whisperBE = Instance.new("BindableEvent")
whisperBE.Name = "ChatClientWhisperTo"
whisperBE.Parent = ReplicatedStorage

print("[Interaction] InteractionClient online (P3-C+ radial wheel)")
