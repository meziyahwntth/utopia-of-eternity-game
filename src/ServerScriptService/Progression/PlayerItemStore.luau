--!strict
--[[
	PlayerItemStore (P4) — in-memory item quantities per player (stub until DataStore inventory)
]]
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerItemStore = {}

export type Inventory = { [string]: number }

local inventories: { [number]: Inventory } = {}
local equipped: { [number]: { string } } = {}

local STARTER: Inventory = {
	StoneFragment = 100,
	IronOre = 25,
	MagicCrystal = 5,
	StarSword2 = 1,
}

local function ensure(userId: number): Inventory
	local inv = inventories[userId]
	if not inv then
		inv = table.clone(STARTER)
		inventories[userId] = inv
	end
	return inv
end

function PlayerItemStore.getInventory(userId: number): Inventory
	return table.clone(ensure(userId))
end

function PlayerItemStore.getEquipped(userId: number): { string }
	local list = equipped[userId]
	if not list then
		list = {}
		equipped[userId] = list
	end
	return table.clone(list)
end

function PlayerItemStore.setEquipped(userId: number, itemIds: { string })
	equipped[userId] = table.clone(itemIds)
end

function PlayerItemStore.getQty(userId: number, itemId: string): number
	return ensure(userId)[itemId] or 0
end

function PlayerItemStore.addItem(userId: number, itemId: string, qty: number): boolean
	if qty <= 0 then
		return false
	end
	local ok, svc = pcall(function()
		return require(ServerScriptService:WaitForChild("LiveOps"):WaitForChild("EventCalendarService"))
	end)
	if ok then
		qty = math.max(1, math.floor(qty * (svc :: any).getMultiplier("DoubleDrop")))
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local luckBonus = player:GetAttribute("PetLuckBonus")
		if typeof(luckBonus) == "number" and luckBonus > 0 then
			qty = math.max(1, math.floor(qty * (1 + luckBonus)))
		end
	end
	local inv = ensure(userId)
	inv[itemId] = (inv[itemId] or 0) + qty
	return true
end

function PlayerItemStore.removeItem(userId: number, itemId: string, qty: number): boolean
	if qty <= 0 then
		return false
	end
	local inv = ensure(userId)
	local have = inv[itemId] or 0
	if have < qty then
		return false
	end
	local nextQty = have - qty
	if nextQty <= 0 then
		inv[itemId] = nil
	else
		inv[itemId] = nextQty
	end
	return true
end

function PlayerItemStore.transfer(
	fromUserId: number,
	toUserId: number,
	itemId: string,
	qty: number
): boolean
	if not PlayerItemStore.removeItem(fromUserId, itemId, qty) then
		return false
	end
	PlayerItemStore.addItem(toUserId, itemId, qty)
	return true
end

Players.PlayerRemoving:Connect(function(player: Player)
	inventories[player.UserId] = nil
	equipped[player.UserId] = nil
end)

return PlayerItemStore
