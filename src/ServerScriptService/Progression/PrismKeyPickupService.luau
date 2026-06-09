--!strict
--[[
	World pickups for fixed Prism Keys (Hub fountain #1, future POIs).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismKeyService = require(script.Parent:WaitForChild("PrismKeyService"))

local PrismKeyPickupService = {}

local PICKUP_ID_ATTR = "PrismKeyPickupId"
local PICKUP_NUMBER_ATTR = "PrismKeyNumber"
local wired: { [Instance]: boolean } = {}

local function pickupSource(pickupId: string): string
	return "pickup_" .. pickupId
end

local function onPickupTriggered(player: Player, part: BasePart)
	local pickupId = part:GetAttribute(PICKUP_ID_ATTR)
	local keyNumber = part:GetAttribute(PICKUP_NUMBER_ATTR)
	if typeof(pickupId) ~= "string" or pickupId == "" then
		return
	end
	if typeof(keyNumber) ~= "number" then
		return
	end
	if PrismKeyService.hasPickupClaimed(player, pickupId) then
		return
	end
	if PrismKeyService.hasKeyNumber(player, keyNumber) then
		PrismKeyService.markPickupClaimed(player, pickupId)
		return
	end

	local ok, msg = PrismKeyService.grantKeyNumber(player, keyNumber, pickupSource(pickupId))
	if ok then
		PrismKeyService.markPickupClaimed(player, pickupId)
		player:SetAttribute("PrismKeyPickupToast", msg)
	end
end

function PrismKeyPickupService.wirePart(part: BasePart)
	if wired[part] then
		return
	end
	if typeof(part:GetAttribute(PICKUP_ID_ATTR)) ~= "string" then
		return
	end
	wired[part] = true

	local existing = part:FindFirstChildOfClass("ProximityPrompt")
	local prompt = if existing then existing else Instance.new("ProximityPrompt")
	prompt.ObjectText = "Prism Key"
	prompt.ActionText = "Collect"
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0.4
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(player)
		onPickupTriggered(player, part)
	end)
end

function PrismKeyPickupService.wireDescendants(root: Instance)
	for _, inst in root:GetDescendants() do
		if inst:IsA("BasePart") and typeof(inst:GetAttribute(PICKUP_ID_ATTR)) == "string" then
			PrismKeyPickupService.wirePart(inst)
		end
	end
	root.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") and typeof(inst:GetAttribute(PICKUP_ID_ATTR)) == "string" then
			PrismKeyPickupService.wirePart(inst)
		end
	end)
end

function PrismKeyPickupService.ensureHubCentralFountain(parent: Instance)
	local existing = parent:FindFirstChild("CentralFountain", true)
	if existing then
		return existing
	end

	local fountain = Instance.new("Model")
	fountain.Name = "CentralFountain"
	fountain.Parent = parent

	local pool = Instance.new("Part")
	pool.Name = "FountainPool"
	pool.Shape = Enum.PartType.Cylinder
	pool.Size = Vector3.new(1.2, 16, 16)
	pool.CFrame = CFrame.new(0, 0.6, 14) * CFrame.Angles(0, 0, math.rad(90))
	pool.Anchored = true
	pool.Color = Color3.fromRGB(40, 120, 180)
	pool.Material = Enum.Material.Glass
	pool.Transparency = 0.25
	pool.Parent = fountain

	local ring = Instance.new("Part")
	ring.Name = "PrismKeyPickup"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.8, 6, 6)
	ring.CFrame = CFrame.new(0, 1.2, 14) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.Color = Color3.fromRGB(0, 229, 255)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.15
	ring:SetAttribute(PICKUP_ID_ATTR, "hub_fountain_key_1")
	ring:SetAttribute(PICKUP_NUMBER_ATTR, 1)
	ring:SetAttribute("GateZoneId", "CentralFountain")
	ring.Parent = fountain

	local pedestal = Instance.new("Part")
	pedestal.Name = "FountainPedestal"
	pedestal.Size = Vector3.new(10, 1, 10)
	pedestal.CFrame = CFrame.new(0, 0.5, 14)
	pedestal.Anchored = true
	pedestal.Color = Color3.fromRGB(55, 65, 85)
	pedestal.Material = Enum.Material.Slate
	pedestal.Parent = fountain

	PrismKeyPickupService.wirePart(ring)
	return fountain
end

function PrismKeyPickupService.start()
	local hubWorld = workspace:FindFirstChild("UtopiaHubWorld")
	if hubWorld then
		PrismKeyPickupService.ensureHubCentralFountain(hubWorld)
	end
	PrismKeyPickupService.wireDescendants(workspace)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			PrismKeyService.hydratePlayer(player)
		end)
	end
end

return PrismKeyPickupService
