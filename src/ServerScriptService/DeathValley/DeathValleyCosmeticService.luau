--!strict
--[[
	Phase J — Season cosmetic inventory, equip, and DataStore persistence.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))

local DeathValleyCosmeticService = {}

local function syncOwnedAttribute(player: Player, owned: { string })
	local parts: { string } = {}
	for _, cosmeticId in owned do
		table.insert(parts, cosmeticId .. ",")
	end
	player:SetAttribute("OwnedCosmetics", table.concat(parts))
end

function DeathValleyCosmeticService.syncFromStore(player: Player)
	local owned = DeathValleyPlayerStore.listOwnedCosmetics(player.UserId)
	syncOwnedAttribute(player, owned)

	local equipped = DeathValleyPlayerStore.getEquippedCosmetic(player.UserId)
	if equipped and equipped ~= "" then
		player:SetAttribute("DV_EquippedSeasonCosmetic", equipped)
	else
		player:SetAttribute("DV_EquippedSeasonCosmetic", "")
	end
end

function DeathValleyCosmeticService.grantCosmetic(player: Player, cosmeticId: string?)
	if not cosmeticId or cosmeticId == "" then
		return
	end
	if not PrismDeathValleySeasonCosmetics.getDef(cosmeticId) then
		return
	end

	DeathValleyPlayerStore.addOwnedCosmetic(player.UserId, cosmeticId)
	local owned = DeathValleyPlayerStore.listOwnedCosmetics(player.UserId)
	syncOwnedAttribute(player, owned)
	DeathValleyCosmeticService.equipCosmetic(player, cosmeticId)
end

function DeathValleyCosmeticService.equipCosmetic(player: Player, cosmeticId: string): (boolean, string)
	if cosmeticId == "" then
		return DeathValleyCosmeticService.unequipCosmetic(player)
	end
	if not PrismDeathValleySeasonCosmetics.getDef(cosmeticId) then
		return false, "Unknown cosmetic"
	end
	if not DeathValleyPlayerStore.hasOwnedCosmetic(player.UserId, cosmeticId) then
		return false, "You do not own this cosmetic"
	end

	player:SetAttribute("DV_EquippedSeasonCosmetic", cosmeticId)
	DeathValleyPlayerStore.setEquippedCosmetic(player.UserId, cosmeticId)
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	local label = if def then def.displayName else cosmeticId
	return true, "Equipped " .. label
end

function DeathValleyCosmeticService.unequipCosmetic(player: Player): (boolean, string)
	player:SetAttribute("DV_EquippedSeasonCosmetic", "")
	DeathValleyPlayerStore.setEquippedCosmetic(player.UserId, nil)
	return true, "Cosmetic unequipped"
end

function DeathValleyCosmeticService.getInventoryPayload(player: Player): { [string]: any }
	local owned = DeathValleyPlayerStore.listOwnedCosmetics(player.UserId)
	local equipped = player:GetAttribute("DV_EquippedSeasonCosmetic")
	if typeof(equipped) ~= "string" then
		equipped = DeathValleyPlayerStore.getEquippedCosmetic(player.UserId) or ""
	end

	local items: { { [string]: any } } = {}
	for _, cosmeticId in owned do
		local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
		table.insert(items, {
			id = cosmeticId,
			displayName = if def then def.displayName else cosmeticId,
			style = if def then def.style else "badge",
			equipped = cosmeticId == equipped,
		})
	end

	table.sort(items, function(a, b)
		return tostring(a.displayName) < tostring(b.displayName)
	end)

	return {
		equippedCosmeticId = if equipped ~= "" then equipped else nil,
		items = items,
		count = #items,
	}
end

return DeathValleyCosmeticService
