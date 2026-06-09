--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getLfgListings = remotes:WaitForChild("GetLfgListings") :: RemoteFunction
local postLfgListing = remotes:WaitForChild("PostLfgListing") :: RemoteFunction
local joinLfgListing = remotes:WaitForChild("JoinLfgListing") :: RemoteFunction
local leaveLfgListing = remotes:WaitForChild("LeaveLfgListing") :: RemoteFunction
local enqueueLfgQueue = remotes:WaitForChild("EnqueueLfgQueue") :: RemoteFunction
local dequeueLfgQueue = remotes:WaitForChild("DequeueLfgQueue") :: RemoteFunction
local getLfgQueueState = remotes:WaitForChild("GetLfgQueueState") :: RemoteFunction
local sendLfgInvite = remotes:WaitForChild("SendLfgInvite") :: RemoteFunction
local getLfgFriendsList = remotes:WaitForChild("GetLfgFriendsList") :: RemoteFunction
local sendLfgFriendInvite = remotes:WaitForChild("SendLfgFriendInvite") :: RemoteFunction
local acceptLfgInvite = remotes:WaitForChild("AcceptLfgInvite") :: RemoteFunction
local declineLfgInvite = remotes:WaitForChild("DeclineLfgInvite") :: RemoteFunction
local lfgChanged = remotes:WaitForChild("LfgListingsChanged") :: RemoteEvent
local queueChanged = remotes:WaitForChild("LfgQueueStateChanged") :: RemoteEvent
local inviteReceived = remotes:WaitForChild("LfgInviteReceived") :: RemoteEvent

local function friendStatusTag(friend: { [string]: any }): string
	if friend.inThisServer == true then
		local city = if typeof(friend.placeDisplayName) == "string" and friend.placeDisplayName ~= ""
			then friend.placeDisplayName
			else "Here"
		return " [Here · " .. city .. "]"
	end
	if friend.online == true then
		local city = if typeof(friend.placeDisplayName) == "string" and friend.placeDisplayName ~= ""
			then friend.placeDisplayName
			else "Utopia"
		return " [Online · " .. city .. "]"
	end
	return " [Offline]"
end

local ZONE_OPTIONS = {
	{ id = "duo_depth", label = "Zone 1 Duo (2)" },
	{ id = "squad_hollow", label = "Zone 2 Squad (5)" },
	{ id = "raid_cavern", label = "Zone 3 Raid (10)" },
	{ id = "legion_pass", label = "Zone 4 Legion (20)" },
	{ id = "abyss_throne", label = "Zone 5 Abyss (50)" },
}

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleyLfgUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(380, 360)
frame.Position = UDim2.new(0.5, -190, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(16, 12, 24)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.fromOffset(8, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(0, 229, 255)
title.Text = "Mega Dungeon LFG"
title.Parent = frame

local queueStatus = Instance.new("TextLabel")
queueStatus.Size = UDim2.new(1, -16, 0, 32)
queueStatus.Position = UDim2.fromOffset(8, 34)
queueStatus.BackgroundTransparency = 1
queueStatus.Font = Enum.Font.Gotham
queueStatus.TextSize = 11
queueStatus.TextXAlignment = Enum.TextXAlignment.Left
queueStatus.TextWrapped = true
queueStatus.TextColor3 = Color3.fromRGB(180, 200, 255)
queueStatus.Text = "Queue: —"
queueStatus.Parent = frame

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -16, 1, -130)
list.Position = UDim2.fromOffset(8, 68)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.Parent = frame

local postBtn = Instance.new("TextButton")
postBtn.Size = UDim2.fromOffset(72, 32)
postBtn.Position = UDim2.fromOffset(8, 318)
postBtn.Text = "Post Z2"
postBtn.Font = Enum.Font.GothamBold
postBtn.TextSize = 10
postBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
postBtn.TextColor3 = Color3.new(1, 1, 1)
postBtn.Parent = frame

local matchBtn = Instance.new("TextButton")
matchBtn.Size = UDim2.fromOffset(72, 32)
matchBtn.Position = UDim2.fromOffset(84, 318)
matchBtn.Text = "Match"
matchBtn.Font = Enum.Font.GothamBold
matchBtn.TextSize = 10
matchBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 90)
matchBtn.TextColor3 = Color3.new(1, 1, 1)
matchBtn.Parent = frame

local inviteBtn = Instance.new("TextButton")
inviteBtn.Size = UDim2.fromOffset(56, 32)
inviteBtn.Position = UDim2.fromOffset(160, 318)
inviteBtn.Text = "Invite"
inviteBtn.Font = Enum.Font.GothamBold
inviteBtn.TextSize = 10
inviteBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 120)
inviteBtn.TextColor3 = Color3.new(1, 1, 1)
inviteBtn.Parent = frame

local friendsBtn = Instance.new("TextButton")
friendsBtn.Size = UDim2.fromOffset(56, 32)
friendsBtn.Position = UDim2.fromOffset(220, 318)
friendsBtn.Text = "Friends"
friendsBtn.Font = Enum.Font.GothamBold
friendsBtn.TextSize = 10
friendsBtn.BackgroundColor3 = Color3.fromRGB(70, 90, 140)
friendsBtn.TextColor3 = Color3.new(1, 1, 1)
friendsBtn.Parent = frame

local leaveBtn = Instance.new("TextButton")
leaveBtn.Size = UDim2.fromOffset(56, 32)
leaveBtn.Position = UDim2.fromOffset(280, 318)
leaveBtn.Text = "Leave"
leaveBtn.Font = Enum.Font.GothamBold
leaveBtn.TextSize = 10
leaveBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
leaveBtn.TextColor3 = Color3.new(1, 1, 1)
leaveBtn.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(56, 32)
closeBtn.Position = UDim2.fromOffset(340, 318)
closeBtn.Text = "Close"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = frame

local zoneIndex = 2
local showInviteMode = false
local pendingInviteId: string? = nil

local function renderQueueState(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.queues) ~= "table" then
		return
	end
	if pendingInviteId then
		return
	end
	local opt = ZONE_OPTIONS[zoneIndex]
	local zoneState = payload.queues[opt.id]
	if typeof(zoneState) == "table" then
		queueStatus.Text = string.format(
			"Queue %s — %d/%d globally (%d local)",
			opt.label,
			zoneState.waiting or 0,
			zoneState.needed or 0,
			zoneState.localWaiting or 0
		)
	else
		queueStatus.Text = "Queue: no data"
	end
end

local function renderListings(payload: any)
	if showInviteMode then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local y = 0
	if typeof(payload) ~= "table" then
		return
	end
	for _, entry in payload do
		if typeof(entry) ~= "table" then
			continue
		end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 36)
		btn.Position = UDim2.fromOffset(0, y)
		btn.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.TextColor3 = Color3.new(1, 1, 1)
		local crossTag = if entry.crossServer == true then " [X]" else ""
		local matchTag = if entry.matchMade == true then " [M]" else ""
		btn.Text = string.format(
			"  %s · %s (%d/%d)%s%s",
			entry.displayName or entry.zoneId,
			entry.ownerName or "?",
			if typeof(entry.members) == "table" then #entry.members else (entry.memberCount or 0),
			entry.needed or 0,
			crossTag,
			matchTag
		)
		btn.Parent = list
		local listingId = entry.id
		btn.MouseButton1Click:Connect(function()
			if typeof(listingId) == "string" then
				joinLfgListing:InvokeServer(listingId)
			end
		end)
		y += 40
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
end

local function renderInviteTargets(useFriends: boolean)
	showInviteMode = true
	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local y = 0

	if useFriends then
		local friends = getLfgFriendsList:InvokeServer()
		if typeof(friends) == "table" then
			for _, friend in friends do
				if typeof(friend) ~= "table" then
					continue
				end
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 32)
				btn.Position = UDim2.fromOffset(0, y)
				btn.BackgroundColor3 = Color3.fromRGB(38, 34, 58)
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 12
				btn.TextColor3 = Color3.new(1, 1, 1)
				local onlineTag = friendStatusTag(friend)
				btn.Text = "  " .. tostring(friend.displayName or friend.username) .. onlineTag
				btn.Parent = list
				local targetId = friend.userId
				btn.MouseButton1Click:Connect(function()
					local ok, msg = sendLfgFriendInvite:InvokeServer(targetId)
					queueStatus.Text = msg
					showInviteMode = false
					title.Text = "Mega Dungeon LFG"
					refreshAll()
				end)
				y += 36
			end
		end
		title.Text = "Invite Friend"
		queueStatus.Text = "Friends only — post a party listing first"
	else
		for _, other in Players:GetPlayers() do
			if other == player then
				continue
			end
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.Position = UDim2.fromOffset(0, y)
			btn.BackgroundColor3 = Color3.fromRGB(42, 32, 58)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 12
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = "  Invite " .. other.DisplayName
			btn.Parent = list
			local targetId = other.UserId
			btn.MouseButton1Click:Connect(function()
				local ok, msg = sendLfgInvite:InvokeServer(targetId)
				queueStatus.Text = msg
				showInviteMode = false
				title.Text = "Mega Dungeon LFG"
				refreshAll()
			end)
			y += 36
		end
		title.Text = "Invite Player — click name"
		queueStatus.Text = "Post a party listing first, then invite"
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
end

local function refreshAll()
	showInviteMode = false
	title.Text = "Mega Dungeon LFG"
	renderListings(getLfgListings:InvokeServer())
	renderQueueState({ queues = getLfgQueueState:InvokeServer() })
end

lfgChanged.OnClientEvent:Connect(function(payload)
	if not showInviteMode then
		renderListings(payload)
	end
end)
queueChanged.OnClientEvent:Connect(renderQueueState)

postBtn.MouseButton1Click:Connect(function()
	local opt = ZONE_OPTIONS[zoneIndex]
	zoneIndex = (zoneIndex % #ZONE_OPTIONS) + 1
	postBtn.Text = "Post " .. (ZONE_OPTIONS[zoneIndex].label:match("Zone %d") or "Z")
	postLfgListing:InvokeServer(opt.id)
end)

matchBtn.MouseButton1Click:Connect(function()
	local opt = ZONE_OPTIONS[zoneIndex]
	enqueueLfgQueue:InvokeServer(opt.id)
	refreshAll()
end)

inviteBtn.MouseButton1Click:Connect(function()
	renderInviteTargets(false)
end)

friendsBtn.MouseButton1Click:Connect(function()
	renderInviteTargets(true)
end)

leaveBtn.MouseButton1Click:Connect(function()
	dequeueLfgQueue:InvokeServer()
	leaveLfgListing:InvokeServer()
	pendingInviteId = nil
	refreshAll()
end)

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
	showInviteMode = false
end)

inviteReceived.OnClientEvent:Connect(function(invite: any)
	if typeof(invite) ~= "table" or typeof(invite.id) ~= "string" then
		return
	end
	pendingInviteId = invite.id
	queueStatus.Text = string.format(
		"Invite from %s — %s [Accept: tap banner]",
		tostring(invite.fromName or "?"),
		tostring(invite.zoneId or "")
	)
	gui.Enabled = true
end)

queueStatus.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if pendingInviteId then
		local ok, msg = acceptLfgInvite:InvokeServer(pendingInviteId)
		queueStatus.Text = msg
		pendingInviteId = nil
		if ok then
			refreshAll()
		end
	end
end)

player:GetAttributeChangedSignal("DV_OpenLfgBoard"):Connect(function()
	if player:GetAttribute("DV_OpenLfgBoard") == true then
		gui.Enabled = true
		player:SetAttribute("DV_OpenLfgBoard", false)
		refreshAll()
	end
end)

player:GetAttributeChangedSignal("DV_LfgMatchMsg"):Connect(function()
	local msg = player:GetAttribute("DV_LfgMatchMsg")
	if typeof(msg) == "string" and msg ~= "" and gui.Enabled and not pendingInviteId then
		queueStatus.Text = msg
	end
end)

print("[DeathValley] LFG UI ready")
