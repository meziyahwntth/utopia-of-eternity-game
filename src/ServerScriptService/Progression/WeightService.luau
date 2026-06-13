--!strict
--[[
	WeightService (P4) — total carry weight + overweight penalties (walk + combat)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemTierConfig"))
local WeightConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeightConfig"))
local PlayerItemStore = require(script.Parent:WaitForChild("PlayerItemStore"))

local WeightService = {}

local baseWalkSpeed: { [number]: number } = {}

local function itemWeight(itemId: string, qty: number): number
	local def = ItemTierConfig.get(itemId)
	local unit = if def then def.weight else 1
	return unit * qty
end

function WeightService.totalWeight(userId: number): number
	local total = 0
	for itemId, qty in PlayerItemStore.getInventory(userId) do
		total += itemWeight(itemId, qty)
	end
	for _, itemId in PlayerItemStore.getEquipped(userId) do
		total += itemWeight(itemId, 1)
	end
	return total
end

function WeightService.isOverweight(userId: number): boolean
	return WeightService.totalWeight(userId) > WeightConfig.MaxCarryWeight
end

function WeightService.applyPenalty(player: Player)
	local userId = player.UserId
	local overweight = WeightService.isOverweight(userId)
	player:SetAttribute("Overweight", overweight)
	player:SetAttribute(
		"OverweightCombatMultiplier",
		if overweight then WeightConfig.OverweightCombatMultiplier else 1
	)

	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	if baseWalkSpeed[userId] == nil then
		baseWalkSpeed[userId] = hum.WalkSpeed
	end
	local base = baseWalkSpeed[userId]
	if overweight then
		hum.WalkSpeed = base * WeightConfig.OverweightWalkMultiplier
	else
		hum.WalkSpeed = base
	end
end

function WeightService.refreshPlayer(player: Player)
	WeightService.applyPenalty(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			WeightService.applyPenalty(player)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	baseWalkSpeed[player.UserId] = nil
end)

return WeightService
