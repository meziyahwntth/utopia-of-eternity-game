--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local chamberChanged = remotes:WaitForChild("SpiritChamberStateChanged") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "DeathValleySpiritChamberHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 100)
banner.Size = UDim2.fromOffset(320, 52)
banner.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
banner.BackgroundTransparency = 0.2
banner.Visible = false
banner.Parent = hud
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 8)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -12, 1, -8)
label.Position = UDim2.fromOffset(6, 4)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.TextWrapped = true
label.TextColor3 = Color3.fromRGB(180, 220, 255)
label.Text = ""
label.Parent = banner

chamberChanged.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" or typeof(payload.chambers) ~= "table" then
		return
	end
	local activeLine = ""
	for _, chamber in payload.chambers do
		if typeof(chamber) == "table" and chamber.active then
			local coOp = if typeof(payload.coOpSize) == "number" and payload.coOpSize > 1
				then string.format(" · %d co-op", payload.coOpSize)
				else ""
			activeLine = string.format(
				"Spirit Lock %d — %d robots left%s",
				chamber.chamberIndex or 0,
				chamber.remaining or 0,
				coOp
			)
			break
		end
	end
	if activeLine ~= "" then
		banner.Visible = true
		label.Text = activeLine
	elseif payload.allCleared == true then
		banner.Visible = true
		label.Text = "All Spirit Lock chambers cleared!"
		task.delay(4, function()
			banner.Visible = false
		end)
	else
		banner.Visible = false
	end
end)

player:GetAttributeChangedSignal("DV_SpiritMsg"):Connect(function()
	local msg = player:GetAttribute("DV_SpiritMsg")
	if typeof(msg) == "string" and msg ~= "" then
		banner.Visible = true
		label.Text = msg
		task.delay(3, function()
			banner.Visible = false
		end)
	end
end)

print("[DeathValley] Spirit Chamber HUD ready")
