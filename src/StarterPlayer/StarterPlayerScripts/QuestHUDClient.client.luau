--!strict
--[[
	QuestHUDClient — daily quest panel, progress, claim button, notifications
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local QuestConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestConfig"))

type QuestProgress = {
	questId: string,
	progress: number,
	completed: boolean,
	claimed: boolean,
}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local getQuestsRF = remotes:WaitForChild("GetDailyQuests") :: RemoteFunction
local claimRewardRF = remotes:WaitForChild("ClaimQuestReward") :: RemoteFunction
local questUpdateEv = remotes:WaitForChild("QuestUpdate") :: RemoteEvent
local questDoneEv = remotes:WaitForChild("QuestCompleted") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 6
screenGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.92, 0.08)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextScaled = true
toggleBtn.Text = "📋"
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.2, 0)
toggleCorner.Parent = toggleBtn

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.3, 0.45)
panel.Position = UDim2.fromScale(0.69, 0.08)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0.03, 0)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.12)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Text = "📋 ภารกิจประจำวัน"
title.Font = Enum.Font.GothamBold
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.05, 0)
titleCorner.Parent = title

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.12, 0.1)
closeBtn.Position = UDim2.fromScale(0.87, 0.01)
closeBtn.Text = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.ZIndex = 2
closeBtn.Parent = panel

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(1, 0.86)
scroll.Position = UDim2.fromScale(0, 0.13)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0.02, 0)
scrollPadding.Parent = scroll

local notif = Instance.new("TextLabel")
notif.Size = UDim2.fromScale(0.5, 0.07)
notif.Position = UDim2.fromScale(0.25, -0.1)
notif.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
notif.BackgroundTransparency = 0.1
notif.TextColor3 = Color3.new(1, 1, 1)
notif.TextScaled = true
notif.Font = Enum.Font.GothamBold
notif.Text = ""
notif.Visible = false
notif.ZIndex = 20
notif.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0.2, 0)
notifCorner.Parent = notif

local rewardColor: { [QuestConfig.RewardType]: Color3 } = {
	xp = Color3.fromRGB(80, 220, 120),
	credits = Color3.fromRGB(255, 200, 50),
	item = Color3.fromRGB(160, 120, 255),
}

local function showNotif(text: string)
	notif.Text = text
	notif.Visible = true
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.25, 0.06),
	}):Play()
	task.delay(2.5, function()
		TweenService:Create(notif, TweenInfo.new(0.3), {
			Position = UDim2.fromScale(0.25, -0.1),
		}):Play()
		task.wait(0.35)
		notif.Visible = false
	end)
end

local function findTemplate(questId: string): QuestConfig.QuestTemplate?
	for _, tmpl in QuestConfig.Templates do
		if tmpl.id == questId then
			return tmpl
		end
	end
	return nil
end

local function buildQuestRow(q: QuestProgress, tmpl: QuestConfig.QuestTemplate): Frame
	local row = Instance.new("Frame")
	row.Name = q.questId
	row.Size = UDim2.fromScale(0.96, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundColor3 = if q.claimed
		then Color3.fromRGB(30, 40, 30)
		elseif q.completed then Color3.fromRGB(30, 50, 30)
		else Color3.fromRGB(30, 30, 45)
	row.BorderSizePixel = 0

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0.05, 0)
	rowCorner.Parent = row

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingTop = UDim.new(0, 6)
	rowPadding.PaddingBottom = UDim.new(0, 6)
	rowPadding.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0)
	nameLabel.AutomaticSize = Enum.AutomaticSize.Y
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = false
	nameLabel.TextSize = 14
	nameLabel.Text = (if q.completed then "✅ " else "⬜ ") .. tmpl.nameTH
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.fromScale(1, 0)
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.BackgroundTransparency = 1
	desc.TextColor3 = Color3.fromRGB(180, 180, 180)
	desc.TextScaled = false
	desc.TextSize = 12
	desc.Text = string.format("%s (%d/%d)", tmpl.descTH, q.progress, tmpl.targetCount)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = row

	local rw = tmpl.reward
	local rwText = if rw.rewardType == "xp"
		then "+" .. tostring(rw.amount) .. " XP"
		elseif rw.rewardType == "credits" then "+" .. tostring(rw.amount) .. " 💰"
		else "+" .. tostring(rw.itemQty or 1) .. " " .. (rw.itemId or "item")

	local chip = Instance.new("TextLabel")
	chip.Size = UDim2.fromScale(0.4, 0)
	chip.AutomaticSize = Enum.AutomaticSize.Y
	chip.BackgroundColor3 = rewardColor[rw.rewardType] or Color3.fromRGB(100, 100, 100)
	chip.BackgroundTransparency = 0.4
	chip.TextColor3 = Color3.new(1, 1, 1)
	chip.TextScaled = false
	chip.TextSize = 12
	chip.Text = rwText
	chip.Font = Enum.Font.GothamBold
	chip.Parent = row

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0.3, 0)
	chipCorner.Parent = chip

	if q.completed and not q.claimed then
		local claimBtn = Instance.new("TextButton")
		claimBtn.Size = UDim2.fromScale(0.35, 0)
		claimBtn.AutomaticSize = Enum.AutomaticSize.Y
		claimBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
		claimBtn.TextColor3 = Color3.new(1, 1, 1)
		claimBtn.TextScaled = false
		claimBtn.TextSize = 13
		claimBtn.Text = "รับรางวัล"
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.Parent = row

		local claimCorner = Instance.new("UICorner")
		claimCorner.CornerRadius = UDim.new(0.2, 0)
		claimCorner.Parent = claimBtn

		claimBtn.MouseButton1Click:Connect(function()
			local ok, msg = claimRewardRF:InvokeServer(q.questId)
			if ok then
				showNotif("🎁 " .. rwText)
			else
				showNotif("❌ " .. tostring(msg))
			end
		end)
	end

	return row
end

local function refreshPanel(quests: { QuestProgress })
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, q in quests do
		local tmpl = findTemplate(q.questId)
		if tmpl then
			buildQuestRow(q, tmpl).Parent = scroll
		end
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		local ok, quests = pcall(function()
			return getQuestsRF:InvokeServer()
		end)
		if ok and typeof(quests) == "table" then
			refreshPanel(quests :: { QuestProgress })
		end
	end
end)

questUpdateEv.OnClientEvent:Connect(function(quests)
	if panel.Visible and typeof(quests) == "table" then
		refreshPanel(quests :: { QuestProgress })
	end
end)

questDoneEv.OnClientEvent:Connect(function(questId)
	if typeof(questId) ~= "string" then
		return
	end
	local tmpl = findTemplate(questId)
	if tmpl then
		showNotif("🎯 ภารกิจสำเร็จ: " .. tmpl.nameTH)
	end
end)
