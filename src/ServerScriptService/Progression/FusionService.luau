--!strict
--[[
	FusionService — fuse 2 duplicate items + credit cost
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FusionConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FusionConfig"))
local PlayerItemStore = require(script.Parent:WaitForChild("PlayerItemStore"))

local function getCurrency()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
end

local FusionService = {}

export type FuseResult = {
	ok: boolean,
	reason: string,
	output: string?,
}

local function findRecipe(inputItem: string): FusionConfig.FusionRecipe?
	for _, r in FusionConfig.Recipes do
		if r.inputItem == inputItem then
			return r
		end
	end
	return nil
end

function FusionService.canFuse(player: Player, inputItem: string): (boolean, string)
	local recipe = findRecipe(inputItem)
	if not recipe then
		return false, "ไม่พบ recipe สำหรับ " .. inputItem
	end

	local uid = player.UserId
	if PlayerItemStore.getQty(uid, inputItem) < 2 then
		return false, string.format("ต้องมี %s อย่างน้อย 2 ชิ้น", inputItem)
	end
	local balance = getCurrency().getBalance(uid)
	if balance < recipe.creditCost then
		return false, string.format("credits ไม่พอ (มี %d/%d)", balance, recipe.creditCost)
	end
	return true, "ok"
end

function FusionService.fuse(player: Player, inputItem: string): FuseResult
	local ok, reason = FusionService.canFuse(player, inputItem)
	if not ok then
		return { ok = false, reason = reason, output = nil }
	end

	local recipe = findRecipe(inputItem) :: FusionConfig.FusionRecipe
	local uid = player.UserId

	if not PlayerItemStore.removeItem(uid, inputItem, 2) then
		return { ok = false, reason = "ตัดไอเทมล้มเหลว", output = nil }
	end

	local deducted, errMsg = getCurrency().deductCredits(uid, recipe.creditCost)
	if not deducted then
		PlayerItemStore.addItem(uid, inputItem, 2)
		return { ok = false, reason = "ตัด credits ล้มเหลว: " .. tostring(errMsg), output = nil }
	end

	PlayerItemStore.addItem(uid, recipe.outputItem, 1)
	return { ok = true, reason = "สำเร็จ", output = recipe.outputItem }
end

function FusionService.getAllRecipes(): { FusionConfig.FusionRecipe }
	return FusionConfig.Recipes
end

return FusionService
