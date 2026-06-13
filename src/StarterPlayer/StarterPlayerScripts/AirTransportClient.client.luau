--!strict
--[[
	AirTransportClient — boarding UI at DeparturePad (G key prompt)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local showUIEv = remotes:WaitForChild("ShowAirTransportUI") :: RemoteEvent
local boardRF = remotes:WaitForChild("BoardAirTransport") :: RemoteFunction
local getTicketsRF = remotes:WaitForChild("GetTravelTickets") :: RemoteFunction

local sg = Instance.new("ScreenGui")
sg.Name = "AirTransportGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 6
sg.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(320, 180)
panel.Position = UDim2.new(0.5, -160, 0.5, -90)
panel.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundTransparency = 1
title.Text = "✈️  Air Transport → Utopia"
title.TextColor3 = Color3.fromRGB(80, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -16, 0, 60)
info.Position = UDim2.fromOffset(8, 48)
info.BackgroundTransparency = 1
info.Text = "ค่าโดยสาร: 1 ตั๋วโดยสาร\nผู้เล่นใหม่ได้รับ 5 ตั๋วฟรี"
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 20)
statusLabel.Position = UDim2.fromOffset(8, 112)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = panel

local function makeBtn(text: string, x: number, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(130, 36)
	b.Position = UDim2.fromOffset(x, 136)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	return b
end

local boardBtn = makeBtn("✈️ ขึ้นยาน", 8, Color3.fromRGB(40, 120, 200))
local cancelBtn = makeBtn("✕ ยกเลิก", 150, Color3.fromRGB(100, 40, 40))

local function refreshTicketInfo()
	local tickets = localPlayer:GetAttribute("TravelTickets")
	if typeof(tickets) ~= "number" then
		local ok, count = pcall(function()
			return getTicketsRF:InvokeServer()
		end)
		tickets = if ok and typeof(count) == "number" then count else 0
	end
	info.Text = string.format(
		"ค่าโดยสาร: 1 ตั๋วโดยสาร\nตั๋วของคุณ: %d · ผู้เล่นใหม่ได้ 5 ตั๋วฟรี",
		tickets :: number
	)
end

boardBtn.MouseButton1Click:Connect(function()
	boardBtn.Active = false
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "กำลังประมวลผล..."
	local invokeOk, success, msg = pcall(function()
		return boardRF:InvokeServer()
	end)
	if invokeOk and success == true then
		statusLabel.Text = tostring(msg)
		statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
		task.delay(3, function()
			panel.Visible = false
		end)
	else
		statusLabel.Text = "❌ " .. tostring(if invokeOk then msg else success)
		statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
		boardBtn.Active = true
	end
end)

cancelBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

showUIEv.OnClientEvent:Connect(function()
	statusLabel.Text = ""
	boardBtn.Active = true
	refreshTicketInfo()
	panel.Visible = true
end)

localPlayer:GetAttributeChangedSignal("TravelTickets"):Connect(refreshTicketInfo)
