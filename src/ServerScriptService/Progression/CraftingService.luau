--!strict
--[[
	CraftingService — Grandeur Upgrade (material + credits sink)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemCraftingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemCraftingConfig"))
local PlayerItemStore = require(script.Parent:WaitForChild("PlayerItemStore"))

local function getCurrency()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
end

local CraftingService = {}

export type CraftResult = {
	ok: boolean,
	reason: string,
	output: string?,
}

local function findRecipe(outputItem: string): ItemCraftingConfig.GrandeurRecipe?
	return ItemCraftingConfig.Grandeur[outputItem]
end

function CraftingService.canCraft(player: Player, outputItem: string): (boolean, string)
	local recipe = findRecipe(outputItem)
	if not recipe then
		return false, "ไม่พบ recipe"
	end

	local uid = player.UserId

	if PlayerItemStore.getQty(uid, recipe.baseItem) < 1 then
		return false, "ต้องมี " .. recipe.baseItem
	end

	for _, mat in recipe.materials do
		local have = PlayerItemStore.getQty(uid, mat.id)
		if have < mat.qty then
			return false, string.format("ขาด %s (มี %d/%d)", mat.id, have, mat.qty)
		end
	end

	local balance = getCurrency().getBalance(uid)
	if balance < recipe.creditCost then
		return false, string.format("credits ไม่พอ (มี %d/%d)", balance, recipe.creditCost)
	end

	return true, "ok"
end

function CraftingService.craft(player: Player, outputItem: string): CraftResult
	local ok, reason = CraftingService.canCraft(player, outputItem)
	if not ok then
		return { ok = false, reason = reason, output = nil }
	end

	local recipe = findRecipe(outputItem) :: ItemCraftingConfig.GrandeurRecipe
	local uid = player.UserId

	if not PlayerItemStore.removeItem(uid, recipe.baseItem, 1) then
		return { ok = false, reason = "ตัด base item ล้มเหลว", output = nil }
	end

	for _, mat in recipe.materials do
		if not PlayerItemStore.removeItem(uid, mat.id, mat.qty) then
			PlayerItemStore.addItem(uid, recipe.baseItem, 1)
			return { ok = false, reason = "ตัด " .. mat.id .. " ล้มเหลว", output = nil }
		end
	end

	local deducted, errMsg = getCurrency().deductCredits(uid, recipe.creditCost)
	if not deducted then
		PlayerItemStore.addItem(uid, recipe.baseItem, 1)
		for _, mat in recipe.materials do
			PlayerItemStore.addItem(uid, mat.id, mat.qty)
		end
		return { ok = false, reason = "ตัด credits ล้มเหลว: " .. tostring(errMsg), output = nil }
	end

	PlayerItemStore.addItem(uid, recipe.outputItem, 1)

	return { ok = true, reason = "สำเร็จ!", output = recipe.outputItem }
end

function CraftingService.getAllRecipes(): { [string]: ItemCraftingConfig.GrandeurRecipe }
	return ItemCraftingConfig.Grandeur
end

function CraftingService.getAvailableRecipes(player: Player): { string }
	local available: { string } = {}
	for outputItem, _ in ItemCraftingConfig.Grandeur do
		local canDo, _ = CraftingService.canCraft(player, outputItem)
		if canDo then
			table.insert(available, outputItem)
		end
	end
	return available
end

return CraftingService
