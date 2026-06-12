--!strict
--[[
	Shop rental UI — NPC dialog, room panel, rent flow (Phase A).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopRentalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopRentalConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local getDirectory = remotes:WaitForChild("GetShopDirectory") :: RemoteFunction
local rentShop = remotes:WaitForChild("RentShop") :: RemoteFunction
local setShopName = remotes:WaitForChild("SetShopName") :: RemoteFunction
local openPromoter = remotes:WaitForChild("OpenShopPromoterDialog") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopRentalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 480)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(212, 175, 55)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -80, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(212, 175, 55)
title.Text = "เช่าร้านค้า"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Position = UDim2.new(1, -44, 0, 8)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.BackgroundColor3 = Color3.fromRGB(55, 68, 88)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = panel

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(16, 48)
body.Size = UDim2.new(1, -32, 0, 140)
body.Font = Enum.Font.Gotham
body.TextSize = 14
body.TextColor3 = Color3.fromRGB(245, 245, 240)
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Text = ""
body.Parent = panel

local nameBox = Instance.new("TextBox")
nameBox.Name = "ShopNameBox"
nameBox.Position = UDim2.fromOffset(16, 196)
nameBox.Size = UDim2.new(1, -32, 0, 32)
nameBox.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
nameBox.TextColor3 = Color3.new(1, 1, 1)
nameBox.PlaceholderText = "ชื่อร้าน (เจ้าของเท่านั้น)"
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 14
nameBox.ClearTextOnFocus = false
nameBox.Visible = false
nameBox.Parent = panel

local actionScroll = Instance.new("ScrollingFrame")
actionScroll.Name = "ActionScroll"
actionScroll.Position = UDim2.fromOffset(16, 236)
actionScroll.Size = UDim2.new(1, -32, 1, -252)
actionScroll.BackgroundTransparency = 1
actionScroll.BorderSizePixel = 0
actionScroll.ScrollBarThickness = 6
actionScroll.CanvasSize = UDim2.fromOffset(0, 0)
actionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
actionScroll.Parent = panel

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Vertical
actionLayout.Padding = UDim.new(0, 6)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = actionScroll

local directoryCache: { any }? = nil
local activeWaypoint: Beam? = nil

local function clearWaypoint()
	if activeWaypoint then
		activeWaypoint:Destroy()
		activeWaypoint = nil
	end
	for _, inst in workspace:GetChildren() do
		if inst.Name == "ShopWaypointAnchor" then
			inst:Destroy()
		end
	end
end

local function findCityModel(): Model?
	local city = workspace:FindFirstChild("UtopiaEternityCity")
	if city and city:IsA("Model") then
		return city
	end
	return nil
end

local function findNearestVacantUnit(): (string?, BasePart?)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return nil, nil
	end
	local city = findCityModel()
	if not city then
		return nil, nil
	end
	local bestId: string? = nil
	local bestPart: BasePart? = nil
	local bestDist = math.huge
	for _, desc in city:GetDescendants() do
		if desc:IsA("Model") and desc:GetAttribute("ShopRoomId") then
			local vacant = desc:GetAttribute("ShopVacant")
			if vacant == true or vacant == nil then
				local primary = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
				if primary then
					local dist = (primary.Position - hrp.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestId = desc:GetAttribute("ShopRoomId") :: string
						bestPart = primary
					end
				end
			end
		end
	end
	return bestId, bestPart
end

local function showWaypoint(targetPart: BasePart)
	clearWaypoint()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local attach0 = Instance.new("Attachment")
	attach0.Name = "ShopWaypointAnchor"
	attach0.Parent = hrp
	local attach1 = Instance.new("Attachment")
	attach1.Name = "ShopWaypointAnchor"
	attach1.Parent = targetPart
	local beam = Instance.new("Beam")
	beam.Name = "ShopWaypointBeam"
	beam.Attachment0 = attach0
	beam.Attachment1 = attach1
	beam.Color = ColorSequence.new(Color3.fromRGB(0, 229, 255))
	beam.Width0 = 0.4
	beam.Width1 = 0.4
	beam.FaceCamera = true
	beam.Parent = hrp
	activeWaypoint = beam
	task.delay(45, clearWaypoint)
end

local function clearActions()
	for _, child in actionScroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function makeButton(text: string, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(45, 115, 135)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextWrapped = true
	btn.Text = text
	btn.Parent = actionScroll
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function refreshDirectory(): boolean
	local result = getDirectory:InvokeServer()
	if typeof(result) == "table" and result.ok and typeof(result.rooms) == "table" then
		directoryCache = result.rooms
		return true
	end
	return false
end

local function showNpcDialog()
	title.Text = "เจ้าหน้าที่เช่าร้าน"
	body.Text = "เลือกคำถามด้านล่าง หรือกดพาไปดูห้องว่าง"
	nameBox.Visible = false
	clearActions()
	openPromoter:FireServer()
	for _, qa in ShopRentalConfig.PromoterQA do
		makeButton(qa.q, function()
			body.Text = qa.q .. "\n\n" .. qa.a
		end)
	end
	makeButton("พาไปดูห้องว่าง", function()
		refreshDirectory()
		local targetId, targetPart = findNearestVacantUnit()
		if targetId and targetPart then
			body.Text = "ห้องว่างใกล้สุด: " .. targetId .. "\nเดินตาม Beam สีฟ้าไปที่ป้าย FOR RENT"
			showWaypoint(targetPart)
		else
			body.Text = "ไม่พบห้องว่างในขณะนี้ (หรือเมืองยังโหลดไม่ครบ)"
		end
	end)
	panel.Visible = true
end

local function showRoomPanel(roomId: string, entry: any)
	title.Text = roomId
	nameBox.Visible = false
	clearActions()
	if entry.vacant then
		body.Text = string.format(
			"ชั้น %d · โซน %s · %s\nสถานะ: ว่าง — เลือกแพ็กเกจเช่า",
			entry.floor,
			entry.zone,
			entry.building
		)
		for i, tier in ShopRentalConfig.RentTiers do
			makeButton(string.format("เช่า %d วัน (~%d R$)", tier.days, tier.robuxHint), function()
				local result = rentShop:InvokeServer(roomId, i)
				if typeof(result) == "table" then
					body.Text = result.message or (if result.ok then "เปิดหน้าชำระแล้ว" else "เช่าไม่สำเร็จ")
				end
			end)
		end
	else
		body.Text = string.format(
			"ชื่อร้าน: %s\nเจ้าของ: %s\nหมดอายุ: %s",
			entry.shopName,
			tostring(entry.ownerId),
			os.date("%Y-%m-%d", entry.expiresAt or 0)
		)
		if entry.ownerId == player.UserId then
			nameBox.Visible = true
			nameBox.Text = if entry.shopName ~= "FOR RENT" and entry.shopName ~= "OPEN" then entry.shopName else ""
			makeButton("บันทึกชื่อร้าน", function()
				local newName = nameBox.Text
				if newName == "" then
					body.Text = "กรุณาใส่ชื่อร้าน"
					return
				end
				local result = setShopName:InvokeServer(roomId, newName)
				if typeof(result) == "table" and result.ok then
					body.Text = "ตั้งชื่อเป็น: " .. tostring(result.message)
				elseif typeof(result) == "table" then
					body.Text = result.message or "ตั้งชื่อไม่สำเร็จ"
				end
			end)
		end
	end
	panel.Visible = true
end

local function onShopPrompt(roomId: string)
	if not refreshDirectory() or not directoryCache then
		body.Text = "โหลดรายการร้านไม่สำเร็จ — ลองใหม่"
		panel.Visible = true
		return
	end
	for _, entry in directoryCache do
		if entry.roomId == roomId then
			showRoomPanel(roomId, entry)
			return
		end
	end
end

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
	clearWaypoint()
end)

openPromoter.OnClientEvent:Connect(function()
	showNpcDialog()
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, inst in workspace:GetDescendants() do
			if inst:IsA("ProximityPrompt") and inst.Name == "ShopRentPrompt" and not inst:GetAttribute("ShopUiHooked") then
				inst:SetAttribute("ShopUiHooked", true)
				inst.Triggered:Connect(function(triggerPlayer)
					if triggerPlayer ~= player then
						return
					end
					local pad = inst.Parent
					if not pad or not pad:IsA("BasePart") then
						return
					end
					local unit = pad.Parent
					while unit and not unit:GetAttribute("ShopRoomId") do
						unit = unit.Parent
					end
					if unit then
						local roomId = unit:GetAttribute("ShopRoomId")
						if typeof(roomId) == "string" then
							onShopPrompt(roomId)
						end
					end
				end)
			end
			if inst:IsA("ProximityPrompt") and inst.Name == "ShopPromoterPrompt" and not inst:GetAttribute("ShopUiHooked") then
				inst:SetAttribute("ShopUiHooked", true)
				inst.Triggered:Connect(function(triggerPlayer)
					if triggerPlayer ~= player then
						return
					end
					showNpcDialog()
				end)
			end
		end
	end
end)

player:GetAttributeChangedSignal("ShopRentMessage"):Connect(function()
	local msg = player:GetAttribute("ShopRentMessage")
	if typeof(msg) == "string" and msg ~= "" then
		body.Text = msg
		panel.Visible = true
		player:SetAttribute("ShopRentMessage", "")
	end
end)
