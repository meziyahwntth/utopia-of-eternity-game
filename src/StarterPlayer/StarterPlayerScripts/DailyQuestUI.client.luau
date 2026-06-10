--!strict
--[[
	Festival Phase 2 — Daily Quest UI (Client)
	Uses RemoteEvents (not RemoteFunction)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getQuestInfo = remotes:WaitForChild("GetQuestInfo") :: RemoteEvent
local claimQuestReward = remotes:WaitForChild("ClaimQuestReward") :: RemoteEvent
local claimQuestBonus = remotes:WaitForChild("ClaimQuestBonus") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyQuestUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.45)
root.Size = UDim2.fromOffset(440, 380)
root.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
root.BorderSizePixel = 0
root.Visible = false
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(212, 175, 55)
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 16)
title.Size = UDim2.new(1, -80, 0, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(212, 175, 55)
title.Text = "Daily Quests"
title.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(15, 20, 35)
closeBtn.Text = "X"
closeBtn.Parent = root

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	root.Visible = false
end)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.fromOffset(16, 56)
listFrame.Size = UDim2.new(1, -32, 0, 260)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 5
listFrame.CanvasSize = UDim2.new()
listFrame.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = listFrame

local bonusBtn = Instance.new("TextButton")
bonusBtn.AnchorPoint = Vector2.new(0, 0)
bonusBtn.Position = UDim2.new(0, 16, 0, 324)
bonusBtn.Size = UDim2.new(1, -32, 0, 36)
bonusBtn.BackgroundColor3 = Color3.fromRGB(255, 179, 71)
bonusBtn.Font = Enum.Font.GothamBold
bonusBtn.TextSize = 14
bonusBtn.TextColor3 = Color3.fromRGB(15, 20, 35)
bonusBtn.Text = "Complete All: +15 Luminite Bonus"
bonusBtn.Visible = false
bonusBtn.Parent = root

local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 8)
btnCorner2.Parent = bonusBtn

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(16, 0)
statusText.Size = UDim2.new(1, -32, 0, 20)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 12
statusText.TextColor3 = Color3.fromRGB(0, 229, 255)
statusText.Text = ""
statusText.Parent = root

local function clearList()
	for _, child in listFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function renderQuests(data)
	clearList()
	if typeof(data) ~= "table" then return end
	local d = data :: any
	local quests = d.quests
	if typeof(quests) ~= "table" then return end

	for _, q in quests do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(25, 32, 48)
		row.BorderSizePixel = 0
		row.Parent = listFrame

		local rcorner = Instance.new("UICorner")
		rcorner.CornerRadius = UDim.new(0, 8)
		rcorner.Parent = row

		local icon = Instance.new("TextLabel")
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.fromOffset(8, 0)
		icon.Size = UDim2.fromOffset(40, 56)
		icon.Font = Enum.Font.Gotham
		icon.TextSize = 22
		icon.Text = (q :: any).icon or "?"
		icon.Parent = row

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(48, 8)
		name.Size = UDim2.new(1, -140, 0, 16)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 13
		name.TextColor3 = Color3.fromRGB(245, 245, 240)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = (q :: any).displayName or (q :: any).id
		name.Parent = row

		local prog = Instance.new("TextLabel")
		prog.BackgroundTransparency = 1
		prog.Position = UDim2.fromOffset(48, 28)
		prog.Size = UDim2.new(1, -140, 0, 16)
		prog.Font = Enum.Font.Gotham
		prog.TextSize = 11
		prog.TextColor3 = Color3.fromRGB(0, 229, 255)
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Text = (q :: any).progress .. " / " .. (q :: any).goal
		prog.Parent = row

		if not (q :: any).claimed then
			local btn = Instance.new("TextButton")
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, -8, 0.5, 0)
			btn.Size = UDim2.fromOffset(72, 28)
			btn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			btn.TextColor3 = Color3.fromRGB(15, 20, 35)
			btn.Text = if (q :: any).progress >= (q :: any).goal then "Claim" else "..."
			btn.Parent = row

			local bcorner = Instance.new("UICorner")
			bcorner.CornerRadius = UDim.new(0, 6)
			bcorner.Parent = btn

			btn.MouseButton1Click:Connect(function()
				claimQuestReward:FireServer((q :: any).id)
			end)
		end
	end

	if d.allComplete then
		bonusBtn.Visible = true
	else
		bonusBtn.Visible = false
	end
end

-- Listen for quest info refresh
getQuestInfo.OnClientEvent:Connect(renderQuests)

-- Listen for claim results
claimQuestReward.OnClientEvent:Connect(function(result)
	if typeof(result) == "table" then
		local r = result :: any
		statusText.Text = r.message or ""
	end
	getQuestInfo:FireServer() -- refresh
end)

claimQuestBonus.OnClientEvent:Connect(function(result)
	if typeof(result) == "table" then
		local r = result :: any
		statusText.Text = r.message or ""
	end
	getQuestInfo:FireServer() -- refresh
end)

bonusBtn.MouseButton1Click:Connect(function()
	claimQuestBonus:FireServer()
end)

-- Open quest UI from ProximityPrompt
local function onPromptFired()
	root.Visible = not root.Visible
	if root.Visible then
		getQuestInfo:FireServer()
	end
end

-- Listen for QuestBoard prompts in workspace
workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") and inst:GetFullName():find("QuestBoard") then
		inst.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer == player then
				onPromptFired()
			end
		end)
	end
end)

-- Bind existing prompts
task.defer(function()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("ProximityPrompt") and inst:GetFullName():find("QuestBoard") then
			inst.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					onPromptFired()
				end
			end)
		end
	end
end)