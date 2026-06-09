--!strict
--[[
	Phase I — Overhead season title billboard for all players.
]]

local Players = game:GetService("Players")

local TITLE_ATTR = "DV_EquippedTitle"
local BILLBOARD_NAME = "DV_SeasonTitleBillboard"

local function getAdornee(character: Model): BasePart?
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function removeBillboard(character: Model)
	local existing = character:FindFirstChild(BILLBOARD_NAME)
	if existing then
		existing:Destroy()
	end
end

local function applyTitle(character: Model, title: string?)
	removeBillboard(character)
	if not title or title == "" then
		return
	end
	local adornee = getAdornee(character)
	if not adornee then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = BILLBOARD_NAME
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(220, 36)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 215, 120)
	label.TextStrokeTransparency = 0.4
	label.Text = title
	label.Parent = billboard
end

local function bindPlayer(target: Player)
	local function refresh()
		local character = target.Character
		if not character then
			return
		end
		local title = target:GetAttribute(TITLE_ATTR)
		if typeof(title) == "string" then
			applyTitle(character, title)
		else
			removeBillboard(character)
		end
	end

	target:GetAttributeChangedSignal(TITLE_ATTR):Connect(refresh)
	target.CharacterAdded:Connect(function()
		task.defer(refresh)
	end)
	if target.Character then
		task.defer(refresh)
	end
end

for _, target in Players:GetPlayers() do
	bindPlayer(target)
end
Players.PlayerAdded:Connect(bindPlayer)

print("[DeathValley] Season title billboards ready")
