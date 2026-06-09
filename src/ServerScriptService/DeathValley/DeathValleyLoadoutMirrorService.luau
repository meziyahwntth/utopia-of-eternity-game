--!strict
--[[
	Phase L/M — Hub + cross-plaza mirror showcase with optional auto-rotate.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DeathValleyLoadoutVisuals = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DeathValleyLoadoutVisuals"))

local DeathValleyLoadoutMirrorService = {}

local activeByPlayer: { [Player]: BasePart } = {}
local displayByPlayer: { [Player]: Model } = {}
local spinByPlayer: { [Player]: number } = {}
local mirrorRootByPlayer: { [Player]: Model } = {}

local WIRED_WORLDS = {
	"UtopiaHubWorld",
	"UtopiaHubGreybox",
	"UtopiaEternityCity",
	"UtopiaSolhaven",
	"UtopiaNocturne",
}

local function getEquippedTitle(player: Player): string
	local title = player:GetAttribute("DV_EquippedTitle")
	if typeof(title) == "string" then
		return title
	end
	return ""
end

local function getEquippedCosmetic(player: Player): string
	local cosmetic = player:GetAttribute("DV_EquippedSeasonCosmetic")
	if typeof(cosmetic) == "string" then
		return cosmetic
	end
	return ""
end

local function clearDisplay(player: Player)
	local existing = displayByPlayer[player]
	if existing then
		existing:Destroy()
		displayByPlayer[player] = nil
	end
	activeByPlayer[player] = nil
	spinByPlayer[player] = nil
	mirrorRootByPlayer[player] = nil
	player:SetAttribute("DV_MirrorShowcase", false)
end

local function findPedestal(mirrorRoot: Model, player: Player): BasePart?
	local assigned = activeByPlayer[player]
	if assigned and assigned.Parent then
		return assigned
	end
	for _, child in mirrorRoot:GetChildren() do
		if child:IsA("BasePart") and string.match(child.Name, "^MirrorPedestal") then
			local occupied = false
			for otherPlayer, pedestal in activeByPlayer do
				if pedestal == child and otherPlayer ~= player then
					occupied = true
					break
				end
			end
			if not occupied then
				return child
			end
		end
	end
	return mirrorRoot:FindFirstChild("MirrorPedestal_1") :: BasePart?
end

local function pedestalPivot(pedestal: BasePart): CFrame
	local offset = pedestal:GetAttribute("MirrorOffset")
	if typeof(offset) == "Vector3" then
		return pedestal.CFrame * CFrame.new(offset)
	end
	return pedestal.CFrame
end

function DeathValleyLoadoutMirrorService.refreshDisplay(player: Player)
	local pedestal = activeByPlayer[player]
	if not pedestal then
		return
	end
	DeathValleyLoadoutMirrorService.showOnPedestal(player, pedestal, mirrorRootByPlayer[player])
end

function DeathValleyLoadoutMirrorService.showOnPedestal(player: Player, pedestal: BasePart, mirrorRoot: Model?)
	local savedRoot = mirrorRoot or mirrorRootByPlayer[player]
	local savedSpin = spinByPlayer[player] or 0
	clearDisplay(player)
	local character = player.Character
	if not character then
		return
	end

	local clone = character:Clone()
	clone.Name = "MirrorDisplay_" .. tostring(player.UserId)
	DeathValleyLoadoutVisuals.applyLoadoutToCharacter(clone, getEquippedTitle(player), getEquippedCosmetic(player))
	DeathValleyLoadoutVisuals.addMirrorNameTag(clone, player.DisplayName)

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
	end

	clone:PivotTo(pedestalPivot(pedestal))
	clone.Parent = pedestal
	displayByPlayer[player] = clone
	activeByPlayer[player] = pedestal
	spinByPlayer[player] = savedSpin
	if savedRoot then
		mirrorRootByPlayer[player] = savedRoot
	end
	player:SetAttribute("DV_MirrorShowcase", true)
end

function DeathValleyLoadoutMirrorService.toggleMirrorShowcase(player: Player, mirrorRoot: Model)
	if activeByPlayer[player] then
		clearDisplay(player)
		return true, "Mirror showcase hidden"
	end
	local pedestal = findPedestal(mirrorRoot, player)
	if not pedestal then
		return false, "Mirror pedestals unavailable"
	end
	DeathValleyLoadoutMirrorService.showOnPedestal(player, pedestal, mirrorRoot)
	return true, "Loadout on display — other players can view your mirror clone"
end

local function bindPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		if activeByPlayer[player] then
			task.defer(function()
				DeathValleyLoadoutMirrorService.refreshDisplay(player)
			end)
		end
	end)
	player:GetAttributeChangedSignal("DV_EquippedTitle"):Connect(function()
		if activeByPlayer[player] then
			DeathValleyLoadoutMirrorService.refreshDisplay(player)
		end
	end)
	player:GetAttributeChangedSignal("DV_EquippedSeasonCosmetic"):Connect(function()
		if activeByPlayer[player] then
			DeathValleyLoadoutMirrorService.refreshDisplay(player)
		end
	end)
end

local function wireMirrorRoot(mirrorRoot: Model)
	if mirrorRoot:GetAttribute("WiredLoadoutMirror") == true then
		return
	end
	mirrorRoot:SetAttribute("WiredLoadoutMirror", true)

	local trigger = mirrorRoot:FindFirstChild("MirrorTrigger") :: BasePart?
	if not trigger then
		trigger = mirrorRoot:FindFirstChildWhichIsA("BasePart")
	end
	if not trigger then
		return
	end

	local prompt = trigger:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Valley Mirror"
		prompt.ActionText = "Showcase Loadout"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0.4
		prompt.Parent = trigger
	end

	prompt.Triggered:Connect(function(player: Player)
		local ok, msg = DeathValleyLoadoutMirrorService.toggleMirrorShowcase(player, mirrorRoot)
		player:SetAttribute("DV_MirrorMessage", msg)
		if not ok then
			warn("[DeathValley] Mirror:", msg)
		end
	end)
end

function DeathValleyLoadoutMirrorService.wireWorld(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("Model") and desc:GetAttribute("ValleyLoadoutMirror") == true then
			wireMirrorRoot(desc)
		end
	end
	if model:GetAttribute("ValleyLoadoutMirror") == true then
		wireMirrorRoot(model)
	end
end

local function startAutoRotate()
	RunService.Heartbeat:Connect(function(dt)
		for player, model in displayByPlayer do
			local pedestal = activeByPlayer[player]
			local mirrorRoot = mirrorRootByPlayer[player]
			if not pedestal or not model or not model.Parent then
				continue
			end
			local autoRotate = true
			if mirrorRoot then
				autoRotate = mirrorRoot:GetAttribute("MirrorAutoRotate") ~= false
			end
			if not autoRotate then
				continue
			end
			local speed = 0.35
			if mirrorRoot then
				local configured = mirrorRoot:GetAttribute("MirrorRotateSpeed")
				if typeof(configured) == "number" then
					speed = configured
				end
			end
			spinByPlayer[player] = (spinByPlayer[player] or 0) + speed * dt
			model:PivotTo(pedestalPivot(pedestal) * CFrame.Angles(0, spinByPlayer[player], 0))
		end
	end)
end

function DeathValleyLoadoutMirrorService.start()
	startAutoRotate()

	Players.PlayerRemoving:Connect(function(player)
		clearDisplay(player)
	end)
	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end
	Players.PlayerAdded:Connect(bindPlayer)

	for _, modelName in WIRED_WORLDS do
		local world = Workspace:FindFirstChild(modelName)
		if world and world:IsA("Model") then
			DeathValleyLoadoutMirrorService.wireWorld(world)
		end
	end

	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			for _, modelName in WIRED_WORLDS do
				if child.Name == modelName then
					task.defer(function()
						DeathValleyLoadoutMirrorService.wireWorld(child)
					end)
					break
				end
			end
		end
	end)
end

return DeathValleyLoadoutMirrorService
