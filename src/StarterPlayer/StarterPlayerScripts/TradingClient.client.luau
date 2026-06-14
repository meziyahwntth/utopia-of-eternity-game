--!strict
--[[
	TradingClient (P4) — 2-party trade window: offer → lock → confirm → execute
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ItemTierConfig = require(Modules:WaitForChild("ItemTierConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local tradeAccept = remotes:WaitForChild("TradeAccept") :: RemoteFunction
local tradeUpdateOffer = remotes:WaitForChild("TradeUpdateOffer") :: RemoteFunction
local tradeUpdateCreditOffer = remotes:WaitForChild("TradeUpdateCreditOffer") :: RemoteFunction
local tradeLock = remotes:WaitForChild("TradeLock") :: RemoteFunction
local tradeConfirm = remotes:WaitForChild("TradeConfirm") :: RemoteFunction
local tradeCancel = remotes:WaitForChild("TradeCancel") :: RemoteFunction
local _tradeGetInventory = remotes:WaitForChild("TradeGetInventory") :: RemoteFunction
local tradeSessionUpdate = remotes:WaitForChild("TradeSessionUpdate") :: RemoteEvent

type TradeOffer = { [string]: number }

local function removeOfferItem(offer: TradeOffer, itemId: string): TradeOffer
	local copy: TradeOffer = {}
	for id, qty in offer do
		if id ~= itemId then
			copy[id] = qty
		end
	end
	return copy
end

local sessionId: string? = nil
local myUserId = localPlayer.UserId
local myOffer: TradeOffer = {}
local myCreditOffer = 0
local partnerCreditOffer = 0
local myLocked = false
local partnerLocked = false
local partnerName = "ผู้เล่น"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TradingClient"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 12
screenGui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "TradeWindow"
window.Size = UDim2.fromOffset(420, 320)
window.Position = UDim2.new(0.5, -210, 0.5, -160)
window.BackgroundColor3 = Color3.fromRGB(12, 18, 36)
window.BorderSizePixel = 0
window.Visible = false
window.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = window
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "💼 แลกเปลี่ยน"
title.TextColor3 = Color3.fromRGB(255, 230, 140)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = window

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 24)
statusLabel.Position = UDim2.fromOffset(8, 36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = window

local myPanel = Instance.new("Frame")
myPanel.Size = UDim2.new(0.48, 0, 0, 150)
myPanel.Position = UDim2.fromOffset(8, 68)
myPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
myPanel.BorderSizePixel = 0
myPanel.Parent = window
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = myPanel
end

local partnerPanel = Instance.new("Frame")
partnerPanel.Size = UDim2.new(0.48, 0, 0, 150)
partnerPanel.Position = UDim2.new(0.52, -8, 0, 68)
partnerPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
partnerPanel.BorderSizePixel = 0
partnerPanel.Parent = window
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = partnerPanel
end

local myList = Instance.new("TextLabel")
myList.Size = UDim2.new(1, -8, 1, -34)
myList.Position = UDim2.fromOffset(4, 4)
myList.BackgroundTransparency = 1
myList.Text = ""
myList.TextColor3 = Color3.fromRGB(220, 230, 255)
myList.Font = Enum.Font.Gotham
myList.TextSize = 11
myList.TextXAlignment = Enum.TextXAlignment.Left
myList.TextYAlignment = Enum.TextYAlignment.Top
myList.TextWrapped = true
myList.Parent = myPanel

local creditBox = Instance.new("TextBox")
creditBox.Name = "CreditOffer"
creditBox.Size = UDim2.new(1, -8, 0, 24)
creditBox.Position = UDim2.new(0, 4, 1, -28)
creditBox.BackgroundColor3 = Color3.fromRGB(28, 40, 70)
creditBox.BorderSizePixel = 0
creditBox.ClearTextOnFocus = false
creditBox.Text = "0"
creditBox.PlaceholderText = "💰 เครดิต"
creditBox.TextColor3 = Color3.fromRGB(255, 230, 140)
creditBox.PlaceholderColor3 = Color3.fromRGB(150, 160, 190)
creditBox.Font = Enum.Font.GothamBold
creditBox.TextSize = 12
creditBox.Parent = myPanel
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = creditBox
end

local partnerList = Instance.new("TextLabel")
partnerList.Size = UDim2.new(1, -8, 1, -34)
partnerList.Position = UDim2.fromOffset(4, 4)
partnerList.BackgroundTransparency = 1
partnerList.Text = ""
partnerList.TextColor3 = Color3.fromRGB(200, 220, 200)
partnerList.Font = Enum.Font.Gotham
partnerList.TextSize = 11
partnerList.TextXAlignment = Enum.TextXAlignment.Left
partnerList.TextYAlignment = Enum.TextYAlignment.Top
partnerList.TextWrapped = true
partnerList.Parent = partnerPanel

local partnerCreditLabel = Instance.new("TextLabel")
partnerCreditLabel.Name = "PartnerCreditOffer"
partnerCreditLabel.Size = UDim2.new(1, -8, 0, 24)
partnerCreditLabel.Position = UDim2.new(0, 4, 1, -28)
partnerCreditLabel.BackgroundTransparency = 1
partnerCreditLabel.Text = "💰 0"
partnerCreditLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
partnerCreditLabel.Font = Enum.Font.GothamBold
partnerCreditLabel.TextSize = 12
partnerCreditLabel.TextXAlignment = Enum.TextXAlignment.Left
partnerCreditLabel.Parent = partnerPanel

local function makeBtn(text: string, x: number, color: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(92, 40)
	btn.Position = UDim2.fromOffset(x, 232)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 240, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = window
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	return btn
end

local addBtn = makeBtn("+ Stone×10", 8, Color3.fromRGB(50, 80, 130))
local lockBtn = makeBtn("🔒 Lock", 108, Color3.fromRGB(80, 120, 60))
local confirmBtn = makeBtn("✔ Confirm", 208, Color3.fromRGB(40, 100, 70))
local cancelBtn = makeBtn("✘ Cancel", 308, Color3.fromRGB(120, 50, 50))

local function formatOffer(offer: TradeOffer): string
	local lines: { string } = {}
	for itemId, qty in offer do
		local def = ItemTierConfig.get(itemId)
		local name = if def then def.name else itemId
		table.insert(lines, string.format("%s ×%d", name, qty))
	end
	if #lines == 0 then
		return "(ว่าง)"
	end
	return table.concat(lines, "\n")
end

local function refreshUi(partnerOffer: TradeOffer)
	myList.Text = formatOffer(myOffer)
	partnerList.Text = formatOffer(partnerOffer)
	local lockTxt = if myLocked then "🔒" else "—"
	local partnerLockTxt = if partnerLocked then "🔒" else "—"
	statusLabel.Text = string.format(
		"กับ %s · คุณ %s · เขา %s",
		partnerName,
		lockTxt,
		partnerLockTxt
	)
	if not creditBox:IsFocused() then
		creditBox.Text = tostring(myCreditOffer)
	end
	creditBox.TextEditable = not myLocked
	partnerCreditLabel.Text = "💰 " .. tostring(partnerCreditOffer)
	lockBtn.Text = if myLocked then "🔒 Locked" else "🔒 Lock"
	lockBtn.AutoButtonColor = not myLocked
	confirmBtn.Visible = myLocked and partnerLocked
end

local function closeWindow()
	window.Visible = false
	sessionId = nil
	myOffer = {}
	myCreditOffer = 0
	partnerCreditOffer = 0
	myLocked = false
	partnerLocked = false
end

local function openWindow(partnerDisplayName: string)
	partnerName = partnerDisplayName
	window.Visible = true
	refreshUi({})
end

addBtn.MouseButton1Click:Connect(function()
	if myLocked then
		return
	end
	myOffer.StoneFragment = (myOffer.StoneFragment or 0) + 10
	local ok, msg = tradeUpdateOffer:InvokeServer(myOffer)
	if not ok then
		local nextQty = math.max(0, (myOffer.StoneFragment or 0) - 10)
		if nextQty <= 0 then
			myOffer = removeOfferItem(myOffer, "StoneFragment")
		else
			myOffer.StoneFragment = nextQty
		end
		warn("[Trading] update offer:", msg)
	end
end)

creditBox.FocusLost:Connect(function()
	if myLocked then
		creditBox.Text = tostring(myCreditOffer)
		return
	end
	local amount = math.floor(tonumber(creditBox.Text) or 0)
	if amount < 0 then
		amount = 0
	end
	local ok, msg = tradeUpdateCreditOffer:InvokeServer(amount)
	if ok then
		myCreditOffer = amount
		creditBox.Text = tostring(amount)
	else
		warn("[Trading] update credit:", msg)
		creditBox.Text = tostring(myCreditOffer)
	end
end)

lockBtn.MouseButton1Click:Connect(function()
	if myLocked then
		return
	end
	local ok, msg = tradeLock:InvokeServer()
	if not ok then
		warn("[Trading] lock:", msg)
	else
		myLocked = true
		refreshUi({})
	end
end)

confirmBtn.MouseButton1Click:Connect(function()
	local ok, msg = tradeConfirm:InvokeServer()
	if not ok then
		warn("[Trading] confirm:", msg)
	elseif msg == "executed" then
		closeWindow()
	end
end)

cancelBtn.MouseButton1Click:Connect(function()
	tradeCancel:InvokeServer()
	closeWindow()
end)

tradeSessionUpdate.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	sessionId = if typeof(payload.sessionId) == "string" then payload.sessionId else sessionId

	local a = payload.a
	local b = payload.b
	if typeof(a) ~= "table" or typeof(b) ~= "table" then
		return
	end

	local mySide = if a.userId == myUserId then a elseif b.userId == myUserId then b else nil
	local theirSide = if a.userId == myUserId then b elseif b.userId == myUserId then a else nil
	if not mySide or not theirSide then
		return
	end

	myOffer = if typeof(mySide.offer) == "table" then mySide.offer :: TradeOffer else {}
	myLocked = mySide.locked == true
	partnerLocked = theirSide.locked == true
	myCreditOffer = if typeof(mySide.creditOffer) == "number" then mySide.creditOffer else 0
	partnerCreditOffer = if typeof(theirSide.creditOffer) == "number" then theirSide.creditOffer else 0

	if payload.state == "executed" or payload.state == "cancelled" then
		closeWindow()
		return
	end

	local partnerId = if typeof(theirSide.userId) == "number" then theirSide.userId else 0
	local partner = Players:GetPlayerByUserId(partnerId)
	partnerName = if partner then partner.DisplayName else ("User " .. tostring(partnerId))

	if not window.Visible then
		window.Visible = true
	end
	refreshUi(if typeof(theirSide.offer) == "table" then theirSide.offer :: TradeOffer else {})
end)

local TradingClient = {}

function TradingClient.acceptIncomingTrade(fromUserId: number, fromName: string)
	local ok, result = tradeAccept:InvokeServer(fromUserId)
	if not ok then
		warn("[Trading] accept failed:", result)
		return
	end
	openWindow(fromName)
end

function TradingClient.requestTrade(_partnerUserId: number, _partnerName: string)
	-- initiator uses TradeSend via InteractionClient; window opens on TradeSessionUpdate
end

-- expose accept for InteractionClient
local acceptBE = Instance.new("BindableEvent")
acceptBE.Name = "TradingClientAccept"
acceptBE.Parent = ReplicatedStorage
acceptBE.Event:Connect(function(data: any)
	if typeof(data) ~= "table" then
		return
	end
	local uid = data.fromUserId
	local name = data.fromName
	if typeof(uid) == "number" and typeof(name) == "string" then
		TradingClient.acceptIncomingTrade(uid, name)
	end
end)

print("[Trading] TradingClient online (P4)")

return TradingClient
