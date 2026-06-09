--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("HellboundRemotes")
local spectator = remotes:WaitForChild("HellboundJumpSpectator") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "HellboundSpectatorHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 0.15)
flash.Position = UDim2.fromScale(0, 0.42)
flash.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.fromOffset(400, 40)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = Color3.new(1, 1, 1)
label.Text = ""
label.Parent = flash

spectator.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	label.Text = string.format("Hellbound jump · %s", payload.phaseId or "Hyperspace")
	flash.BackgroundTransparency = 0.35
	task.delay(2.5, function()
		flash.BackgroundTransparency = 1
		label.Text = ""
	end)
end)

print("[Hellbound] Spectator HUD ready")
