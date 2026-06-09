--!strict
--[[
	วิญญาณแลกกุญแจ — ล่องลอยในด่าน 3–5 · 10 นาที/ด่าน · แลกภายใน 1 นาที
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PrismKeyRandomPools = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyRandomPools"))
local PrismKeyService = require(script.Parent:WaitForChild("PrismKeyService"))

local PrismKeyGhostNpcService = {}

local ghostConfig = PrismKeyRandomPools.GhostNpc

type Session = {
	player: Player,
	deadline: number,
	zoneIndex: number,
}

local npcModel: Model? = nil
local currentZoneIndex = ghostConfig.ZoneIndices[1]
local zoneAnchors: { [number]: CFrame } = {}
local activeSession: Session? = nil
local remotesFolder: Folder? = nil

local function getRemotes(): Folder
	if remotesFolder then
		return remotesFolder
	end
	remotesFolder = ReplicatedStorage:WaitForChild("PrismKeyRemotes") :: Folder
	return remotesFolder
end

local function showComplaint()
	if not npcModel then
		return
	end
	local head = npcModel:FindFirstChild("GhostCore") :: BasePart?
	if not head then
		return
	end
	local existing = head:FindFirstChild("ComplaintBillboard")
	if existing then
		existing:Destroy()
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ComplaintBillboard"
	billboard.Size = UDim2.fromOffset(320, 56)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 0.2
	lbl.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
	lbl.TextColor3 = Color3.fromRGB(255, 200, 120)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextWrapped = true
	lbl.Text = ghostConfig.ComplaintText
	lbl.Parent = billboard
	task.delay(5, function()
		if billboard.Parent then
			billboard:Destroy()
		end
	end)
	getRemotes():WaitForChild("GhostComplaint"):FireAllClients(ghostConfig.ComplaintText)
end

local function moveNpcToZone(zoneIndex: number)
	currentZoneIndex = zoneIndex
	local anchor = zoneAnchors[zoneIndex]
	if not anchor or not npcModel then
		return
	end
	local core = npcModel:FindFirstChild("GhostCore") :: BasePart?
	if not core then
		return
	end
	npcModel:PivotTo(anchor * CFrame.new(0, 4, 0))
	core:SetAttribute("GhostZoneIndex", zoneIndex)
	getRemotes():WaitForChild("GhostMoved"):FireAllClients({
		zoneIndex = zoneIndex,
		position = core.Position,
	})
end

local function advanceZone(reason: string?)
	if activeSession then
		activeSession = nil
		getRemotes():WaitForChild("TradeSessionEnded"):FireAllClients({ reason = reason or "timeout" })
	end
	if reason == "timeout" then
		showComplaint()
	end
	local zones = ghostConfig.ZoneIndices
	local idx = table.find(zones, currentZoneIndex) or 1
	local nextIdx = (idx % #zones) + 1
	moveNpcToZone(zones[nextIdx])
end

local function startFloatTween(core: BasePart)
	task.spawn(function()
		local baseY = core.Position.Y
		while core.Parent do
			local up = TweenService:Create(core, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = Vector3.new(core.Position.X, baseY + 2.5, core.Position.Z),
			})
			up:Play()
			up.Completed:Wait()
			local down = TweenService:Create(core, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = Vector3.new(core.Position.X, baseY, core.Position.Z),
			})
			down:Play()
			down.Completed:Wait()
		end
	end)
end

function PrismKeyGhostNpcService.buildNpc(parent: Instance, anchors: { { zoneIndex: number, cframe: CFrame } })
	for _, a in anchors do
		zoneAnchors[a.zoneIndex] = a.cframe
	end

	local model = Instance.new("Model")
	model.Name = "PrismKeyGhostTrader"
	model.Parent = parent

	local core = Instance.new("Part")
	core.Name = "GhostCore"
	core.Size = Vector3.new(3, 6, 3)
	core.Anchored = true
	core.CanCollide = false
	core.Transparency = 0.35
	core.Color = Color3.fromRGB(180, 140, 255)
	core.Material = Enum.Material.Neon
	core.Parent = model
	model.PrimaryPart = core

	local aura = Instance.new("Part")
	aura.Name = "Aura"
	aura.Size = Vector3.new(5, 1, 5)
	aura.Anchored = true
	aura.CanCollide = false
	aura.Transparency = 0.5
	aura.Color = Color3.fromRGB(100, 50, 160)
	aura.Material = Enum.Material.Neon
	aura.CFrame = core.CFrame * CFrame.new(0, -3.2, 0)
	aura.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GhostTradePrompt"
	prompt.ActionText = "Trade Keys"
	prompt.ObjectText = ghostConfig.DisplayName
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.Parent = core

	local nameGui = Instance.new("BillboardGui")
	nameGui.Size = UDim2.fromOffset(180, 36)
	nameGui.StudsOffset = Vector3.new(0, 4, 0)
	nameGui.Parent = core
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 1)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextColor3 = Color3.fromRGB(230, 210, 255)
	nameLbl.Text = ghostConfig.DisplayName
	nameLbl.Parent = nameGui

	npcModel = model
	moveNpcToZone(currentZoneIndex)
	startFloatTween(core)

	prompt.Triggered:Connect(function(player)
		if activeSession and activeSession.player ~= player then
			return
		end
		if activeSession then
			getRemotes():WaitForChild("TradeSessionStarted"):FireClient(player, {
				deadline = activeSession.deadline,
				zoneIndex = activeSession.zoneIndex,
			})
			return
		end
		activeSession = {
			player = player,
			deadline = os.clock() + ghostConfig.TradeTimeoutSeconds,
			zoneIndex = currentZoneIndex,
		}
		getRemotes():WaitForChild("TradeSessionStarted"):FireClient(player, {
			deadline = activeSession.deadline,
			zoneIndex = activeSession.zoneIndex,
			ownedKeys = PrismKeyService.getOwnedKeys(player),
			tradeCost = PrismKeyRandomPools.TradeCost,
		})
	end)
end

function PrismKeyGhostNpcService.completeTrade(player: Player): (boolean, string)
	if not activeSession or activeSession.player ~= player then
		return false, "No active trade session"
	end
	activeSession = nil
	getRemotes():WaitForChild("TradeSessionEnded"):FireClient(player, { reason = "complete" })
	return true, "Trade session closed"
end

function PrismKeyGhostNpcService.cancelSession(reason: string?)
	if activeSession then
		local p = activeSession.player
		activeSession = nil
		if p.Parent then
			getRemotes():WaitForChild("TradeSessionEnded"):FireClient(p, { reason = reason or "cancel" })
		end
	end
end

function PrismKeyGhostNpcService.getActiveSessionPlayer(): Player?
	return if activeSession then activeSession.player else nil
end

function PrismKeyGhostNpcService.isSessionExpired(): boolean
	return activeSession ~= nil and os.clock() >= activeSession.deadline
end

function PrismKeyGhostNpcService.startRotationLoop()
	task.spawn(function()
		while true do
			task.wait(ghostConfig.DwellSecondsPerZone)
			if activeSession and os.clock() >= activeSession.deadline then
				advanceZone("timeout")
			elseif not activeSession then
				advanceZone("rotate")
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		if activeSession and os.clock() >= activeSession.deadline then
			advanceZone("timeout")
		end
	end)
end

function PrismKeyGhostNpcService.start(parent: Instance?, anchors: { { zoneIndex: number, cframe: CFrame } }?)
	if parent and anchors then
		PrismKeyGhostNpcService.buildNpc(parent, anchors)
	end
	PrismKeyGhostNpcService.startRotationLoop()
	print("[PrismKey] Ghost trader online — zones 3–5 · 10m dwell · 1m trade window")
end

return PrismKeyGhostNpcService
