--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DungeonRemotes")
local enterZone = remotes:WaitForChild("EnterZone") :: RemoteFunction
local startBoss = remotes:WaitForChild("StartBoss") :: RemoteFunction
local healAlly = remotes:WaitForChild("HealAlly") :: RemoteFunction
local recordAssist = remotes:WaitForChild("RecordAssist") :: RemoteFunction
local zoneStateChanged = remotes:WaitForChild("ZoneStateChanged") :: RemoteEvent
local healChannelComplete = remotes:WaitForChild("HealChannelComplete") :: RemoteEvent

local ZONE_ID = "duo_depth"
local activeZoneId = ZONE_ID

local hud = Instance.new("ScreenGui")
hud.Name = "DungeonZone1HUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ZonePanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(12, 120)
panel.Size = UDim2.fromOffset(300, 220)
panel.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = hud
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 22)
title.Position = UDim2.fromOffset(8, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 179, 71)
title.Text = "Mega Dungeon Zone"
title.Parent = panel

local teamLabel = Instance.new("TextLabel")
teamLabel.BackgroundTransparency = 1
teamLabel.Size = UDim2.new(1, -12, 0, 18)
teamLabel.Position = UDim2.fromOffset(8, 28)
teamLabel.Font = Enum.Font.Gotham
teamLabel.TextSize = 12
teamLabel.TextXAlignment = Enum.TextXAlignment.Left
teamLabel.TextColor3 = Color3.fromRGB(0, 229, 255)
teamLabel.Text = "Team: 0 / 2"
teamLabel.Parent = panel

local bossBarBg = Instance.new("Frame")
bossBarBg.Name = "BossBarBg"
bossBarBg.Position = UDim2.fromOffset(8, 50)
bossBarBg.Size = UDim2.new(1, -16, 0, 14)
bossBarBg.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
bossBarBg.BorderSizePixel = 0
bossBarBg.Visible = false
bossBarBg.Parent = panel
Instance.new("UICorner", bossBarBg).CornerRadius = UDim.new(0, 4)

local bossBarFill = Instance.new("Frame")
bossBarFill.Name = "Fill"
bossBarFill.Size = UDim2.fromScale(1, 1)
bossBarFill.BackgroundColor3 = Color3.fromRGB(160, 40, 200)
bossBarFill.BorderSizePixel = 0
bossBarFill.Parent = bossBarBg
Instance.new("UICorner", bossBarFill).CornerRadius = UDim.new(0, 4)

local bossHpLabel = Instance.new("TextLabel")
bossHpLabel.BackgroundTransparency = 1
bossHpLabel.Size = UDim2.new(1, 0, 1, 0)
bossHpLabel.Font = Enum.Font.GothamBold
bossHpLabel.TextSize = 10
bossHpLabel.TextColor3 = Color3.new(1, 1, 1)
bossHpLabel.Text = ""
bossHpLabel.Parent = bossBarBg

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, -12, 0, 44)
statusLabel.Position = UDim2.fromOffset(8, 68)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextWrapped = true
statusLabel.Text = ""
statusLabel.Parent = panel

local contribLabel = Instance.new("TextLabel")
contribLabel.BackgroundTransparency = 1
contribLabel.Size = UDim2.new(1, -12, 0, 28)
contribLabel.Position = UDim2.fromOffset(8, 112)
contribLabel.Font = Enum.Font.Gotham
contribLabel.TextSize = 10
contribLabel.TextXAlignment = Enum.TextXAlignment.Left
contribLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
contribLabel.TextWrapped = true
contribLabel.Text = ""
contribLabel.Parent = panel

local healBtn = Instance.new("TextButton")
healBtn.Size = UDim2.fromOffset(130, 32)
healBtn.Position = UDim2.fromOffset(8, 148)
healBtn.Font = Enum.Font.GothamBold
healBtn.TextSize = 12
healBtn.Text = "Heal Ally (E)"
healBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 100)
healBtn.TextColor3 = Color3.new(1, 1, 1)
healBtn.Visible = false
healBtn.Parent = panel
Instance.new("UICorner", healBtn).CornerRadius = UDim.new(0, 6)

local assistBtn = Instance.new("TextButton")
assistBtn.Size = UDim2.fromOffset(130, 32)
assistBtn.Position = UDim2.fromOffset(150, 148)
assistBtn.Font = Enum.Font.GothamBold
assistBtn.TextSize = 12
assistBtn.Text = "Attack Boss (F)"
assistBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
assistBtn.TextColor3 = Color3.new(1, 1, 1)
assistBtn.Visible = false
assistBtn.Parent = panel
Instance.new("UICorner", assistBtn).CornerRadius = UDim.new(0, 6)

local inZone = false
local healing = false

local function nearestTeammate(): Player?
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	local best: Player? = nil
	local bestDist = 18
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("DungeonZoneId") == activeZoneId then
			local oc = other.Character
			if oc and oc:FindFirstChild("HumanoidRootPart") then
				local d = (char.HumanoidRootPart.Position - oc.HumanoidRootPart.Position).Magnitude
				if d < bestDist then
					bestDist = d
					best = other
				end
			end
		end
	end
	return best
end

local function formatContribution(progress: any?): string
	if not progress then
		return ""
	end
	local parts: { string } = {}
	if progress.bossHitRequired then
		table.insert(parts, string.format("Hits %d/%d", progress.bossHitCount or 0, progress.bossHitRequired))
	end
	if progress.healRequired then
		table.insert(parts, string.format("Heals %d/%d", progress.healCount or 0, progress.healRequired))
	end
	if progress.assistRequired then
		table.insert(parts, string.format("Assists %d/%d", progress.assistCount or 0, progress.assistRequired))
	end
	if progress.met then
		return "Contribution: ready for key"
	end
	if #parts > 0 then
		return "Contribution: " .. table.concat(parts, " · ")
	end
	return ""
end

local function updateBossBar(state: any?)
	if not state or not state.bossActive then
		bossBarBg.Visible = false
		return
	end

	bossBarBg.Visible = true
	local maxHp = state.bossMaxHp or 1
	local hp = state.bossHp or 0
	local ratio = math.clamp(hp / maxHp, 0, 1)
	bossBarFill.Size = UDim2.fromScale(ratio, 1)
	bossHpLabel.Text = string.format("%s  %d / %d", state.bossName or "Boss", hp, maxHp)
end

local function updateHud(state: any?)
	if not state then
		return
	end

	if state.displayName then
		title.Text = state.displayName
	elseif state.zoneId then
		title.Text = tostring(state.zoneId)
	end

	if state.zoneId and state.zoneId ~= activeZoneId and state.myKeyGranted == nil and not inZone then
		return
	end

	teamLabel.Text = string.format(
		"Team: %d / %d (need %d to win)",
		state.playerCount or 0,
		state.nominalTeamSize or 2,
		state.minToSucceed or 2
	)

	updateBossBar(state)

	if state.bossOutcomeMessage then
		statusLabel.TextColor3 = Color3.fromRGB(255, 179, 71)
		statusLabel.Text = state.bossOutcomeMessage
		return
	end

	if state.myKeyGranted == true then
		statusLabel.Text = state.myKeyMessage or "Prism Key earned!"
		statusLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
	elseif state.myKeyGranted == false and state.bossCleared then
		statusLabel.Text = state.myKeyMessage or "Zone cleared — contribution too low for key"
		statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif state.bossActive then
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
		statusLabel.Text = "Boss active — press F to damage Wraith Pair"
	elseif state.bossCleared then
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
		statusLabel.Text = "Zone cleared"
	elseif state.canEnterBoss then
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
		statusLabel.Text = "Ready for boss · need 2 players to count as win"
	else
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
		statusLabel.Text = string.format("Need %d+ players for boss", state.minToEnterBoss or 1)
	end

	if state.contributionProgress then
		contribLabel.Text = formatContribution(state.contributionProgress)
	elseif inZone then
		local role = player:GetAttribute("DungeonRole")
		if typeof(role) == "string" then
			contribLabel.Text = string.format("Role: %s — hit boss / heal / assist for key", role)
		end
	end
end

zoneStateChanged.OnClientEvent:Connect(function(state)
	if state.zoneId then
		activeZoneId = state.zoneId
	end
	if state.zoneId == activeZoneId or state.myKeyGranted ~= nil or inZone then
		panel.Visible = inZone or (state.playerCount or 0) > 0 or state.myKeyGranted ~= nil
		updateHud(state)
	end
end)

local function refreshContributionFromAssist(result: any)
	if result and result.contributionProgress then
		contribLabel.Text = formatContribution(result.contributionProgress)
	end
end

local function tryEnterZone(zoneId: string)
	if player:GetAttribute("DungeonLoadoutLocked") ~= true then
		statusLabel.Text = "Lock loadout at kiosk first"
		panel.Visible = true
		return
	end
	local result = enterZone:InvokeServer(zoneId)
	if result and result.ok then
		inZone = true
		activeZoneId = zoneId
		panel.Visible = true
		if result.zone and result.zone.displayName then
			title.Text = result.zone.displayName
		end
		statusLabel.Text = result.message or "In zone"
		healBtn.Visible = player:GetAttribute("DungeonRole") == "CombatMedic"
			or (player:GetAttribute("DungeonLoadoutItems") or ""):find("personal_medic_kit") ~= nil
		assistBtn.Visible = true
		updateHud(result)
	else
		statusLabel.Text = result and result.message or "Enter failed"
		panel.Visible = true
	end
end

local function tryStartBoss(zoneId: string)
	local result = startBoss:InvokeServer(zoneId)
	statusLabel.Text = result and result.message or "Boss start failed"
	panel.Visible = true
	if result and result.ok then
		updateHud({
			zoneId = zoneId,
			bossActive = true,
			bossHp = result.bossHp,
			bossMaxHp = result.bossMaxHp,
			bossName = result.bossName or "Boss",
		})
	end
end

local function tryHeal()
	if healing then
		return
	end
	local target = nearestTeammate()
	if not target then
		statusLabel.Text = "No teammate in range"
		return
	end
	local result = healAlly:InvokeServer(target.UserId)
	if not result or not result.ok then
		statusLabel.Text = result and result.message or "Heal failed"
		return
	end
	healing = true
	statusLabel.Text = string.format("Healing %s… %.0fs", target.DisplayName, result.channelSeconds)
	task.wait(result.channelSeconds)
	healChannelComplete:FireServer(target.UserId)
	healing = false
	statusLabel.Text = "Heal complete"
end

local function tryAttackBoss()
	local result = recordAssist:InvokeServer("attack")
	if result and result.ok then
		refreshContributionFromAssist(result)
		if result.bossActive and result.bossHp ~= nil then
			updateBossBar({
				bossActive = true,
				bossHp = result.bossHp,
				bossMaxHp = result.bossMaxHp,
				bossName = "Boss",
			})
		end
	else
		statusLabel.Text = result and result.message or "Attack failed"
	end
end

assistBtn.MouseButton1Click:Connect(tryAttackBoss)
healBtn.MouseButton1Click:Connect(tryHeal)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not inZone then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		tryHeal()
	elseif input.KeyCode == Enum.KeyCode.F then
		tryAttackBoss()
	end
end)

local function bindPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("ZoneHudBound") then
		return
	end
	prompt:SetAttribute("ZoneHudBound", true)
	prompt.Triggered:Connect(function()
		local parent = prompt.Parent
		if not parent or not parent:IsA("BasePart") then
			return
		end
		local zoneId = parent:GetAttribute("ZoneId")
		if typeof(zoneId) ~= "string" then
			return
		end
		if parent.Name == "Zone1Gate" or parent.Name == "DungeonZoneGate" then
			tryEnterZone(zoneId)
		elseif parent.Name == "BossArena" then
			tryStartBoss(zoneId)
		end
	end)
end

local function scan()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("ProximityPrompt") and inst.Name == "DungeonPrompt" then
			local parent = inst.Parent
			if parent and parent:IsA("BasePart") then
				if parent.Name == "Zone1Gate" or parent.Name == "DungeonZoneGate" or parent.Name == "BossArena" then
					bindPrompt(inst)
				end
			end
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") and inst.Name == "DungeonPrompt" then
		task.defer(scan)
	end
end)

task.defer(scan)

print("[Dungeon] Mega zone HUD ready — zones 1–5")
