--!strict
--[[
	Eternity City zone gates — Preview Tour <10 keys, district unlock 11/15/20.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismKeyProgression = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyProgression"))
local PrismKeyService = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("PrismKeyService"))

local EternityCityAccessGuard = {}

local accessConfig = PrismKeyProgression.EternityCityAccess
local sanctuaryRadius = GameConfig.Sanctuary.EternityCityRadiusStuds

local function getKeyCount(player: Player): number
	return PrismKeyService.getKeyCount(player)
end

local function playerMeetsKeyRequirement(player: Player, minKeys: number): boolean
	if minKeys == 11 or minKeys == 15 or minKeys == 20 then
		return PrismKeyService.hasKeyNumber(player, minKeys)
	end
	return getKeyCount(player) >= minKeys
end

function EternityCityAccessGuard.getAccessTier(keyCount: number): string
	return PrismKeyProgression.getZoneForKeyCount(keyCount)
end

function EternityCityAccessGuard.isPreviewTour(keyCount: number): boolean
	return keyCount <= accessConfig.PreviewTourMaxKeys
end

function EternityCityAccessGuard.canAccessDistrict(keyCount: number, zoneId: string): boolean
	local gates = accessConfig.ZoneGateKeys
	for gateKey, gateZone in gates do
		if gateZone == zoneId and keyCount < gateKey then
			return false
		end
	end
	if zoneId == "FullCity" or zoneId == "AuroraMegaMall" then
		return keyCount >= 20
	end
	if zoneId == "SkyRailPlaza" or zoneId == "PremiumShop" then
		return keyCount >= 15
	end
	if zoneId == "CanalPromenade" or zoneId == "HoverShowroom" or zoneId == "MarinaRing" then
		return keyCount >= 11
	end
	return keyCount >= accessConfig.FreeRoamMinKeys
end

local function applyDistrictLocks(cityModel: Model, player: Player)
	local keyCount = getKeyCount(player)
	local tier = EternityCityAccessGuard.getAccessTier(keyCount)
	player:SetAttribute("EternityAccessTier", tier)
	player:SetAttribute("EternityPreviewTour", EternityCityAccessGuard.isPreviewTour(keyCount))

	for _, inst in cityModel:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("DistrictGate") == true then
			local minKeys = inst:GetAttribute("MinPrismKeys") or 0
			local locked = not playerMeetsKeyRequirement(player, minKeys)
			inst.CanCollide = locked
			inst.Transparency = if locked then 0.35 else 0.85
		end
	end
end

local function enforceSanctuary(player: Player)
	if not EternityCityAccessGuard.isPreviewTour(getKeyCount(player)) then
		return
	end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end
	local pos = char.HumanoidRootPart.Position
	local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.zero).Magnitude
	if dist > sanctuaryRadius then
		char.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
		player:SetAttribute("EternityPreviewBounce", os.clock())
	end
end

function EternityCityAccessGuard.tagDistrict(district: Instance, minKeys: number, zoneId: string)
	district:SetAttribute("MinPrismKeys", minKeys)
	district:SetAttribute("ZoneId", zoneId)

	local gate = Instance.new("Part")
	gate.Name = "ZoneGate_" .. zoneId
	gate.Size = Vector3.new(6, 14, 2)
	gate.Anchored = true
	gate.CanCollide = true
	gate.Transparency = 0.35
	gate.Color = Color3.fromRGB(212, 175, 55)
	gate.Material = Enum.Material.Neon
	gate:SetAttribute("DistrictGate", true)
	gate:SetAttribute("MinPrismKeys", minKeys)
	gate:SetAttribute("ZoneId", zoneId)
	gate.Parent = district

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 48)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.Parent = gate
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = string.format("%s · Keys %d+", zoneId, minKeys)
	lbl.Parent = billboard
end

function EternityCityAccessGuard.start(cityModel: Model?)
	local function onPlayer(player: Player)
		task.defer(function()
			if cityModel then
				applyDistrictLocks(cityModel, player)
			end
		end)
		player:GetAttributeChangedSignal("PrismKeyCount"):Connect(function()
			if cityModel then
				applyDistrictLocks(cityModel, player)
			end
		end)
	end

	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)

	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("EternityPreviewTour") == true then
				enforceSanctuary(player)
			end
		end
	end)

	print("[Eternity] Access guard online — Preview Tour <10 · gates 11/15/20")
end

return EternityCityAccessGuard
