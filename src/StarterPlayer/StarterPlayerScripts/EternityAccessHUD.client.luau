--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Dark = Color3.fromRGB(18, 22, 32),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EternityAccessHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local banner = Instance.new("Frame")
banner.Name = "PreviewTourBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 12)
banner.Size = UDim2.fromOffset(520, 56)
banner.BackgroundColor3 = PALETTE.Dark
banner.BackgroundTransparency = 0.15
banner.Visible = false
banner.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = banner

local stroke = Instance.new("UIStroke")
stroke.Color = PALETTE.Gold
stroke.Thickness = 2
stroke.Parent = banner

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.TextColor3 = PALETTE.Pearl
label.TextWrapped = true
label.Text = string.format(
	"Preview Tour — Eternity Sanctuary only · Collect %d keys to explore the full city",
	GameConfig.EternityCityAccess.FreeRoamMinKeys
)
label.Parent = banner

local tierBadge = Instance.new("TextLabel")
tierBadge.Name = "TierBadge"
tierBadge.AnchorPoint = Vector2.new(1, 1)
tierBadge.Position = UDim2.new(1, -12, 1, -8)
tierBadge.Size = UDim2.fromOffset(160, 22)
tierBadge.BackgroundTransparency = 1
tierBadge.Font = Enum.Font.Gotham
tierBadge.TextSize = 12
tierBadge.TextColor3 = PALETTE.Cyan
tierBadge.TextXAlignment = Enum.TextXAlignment.Right
tierBadge.Text = ""
tierBadge.Parent = banner

local function refresh()
	local preview = player:GetAttribute("EternityPreviewTour") == true
	banner.Visible = preview
	local tier = player:GetAttribute("EternityAccessTier")
	if typeof(tier) == "string" and tier ~= "" then
		tierBadge.Text = "Tier: " .. tier
	else
		tierBadge.Text = ""
	end
end

player:GetAttributeChangedSignal("EternityPreviewTour"):Connect(refresh)
player:GetAttributeChangedSignal("EternityAccessTier"):Connect(refresh)
player:GetAttributeChangedSignal("PrismKeyCount"):Connect(refresh)
task.defer(refresh)
