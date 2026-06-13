--!strict
--[[
	CardService — equip cards in sockets, apply stat bonuses via Attributes
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CardConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CardConfig"))
local CardStore = require(script.Parent:WaitForChild("CardStore"))

local CardService = {}

local cache: { [number]: CardStore.CardData } = {}

local function getData(userId: number): CardStore.CardData
	if not cache[userId] then
		cache[userId] = CardStore.load(userId)
	end
	return cache[userId]
end

function CardService.init(player: Player)
	cache[player.UserId] = CardStore.load(player.UserId)
	CardService.applyBonuses(player)
end

function CardService.getEquipped(player: Player): { string }
	return table.clone(getData(player.UserId).equippedCards)
end

function CardService.equipCard(player: Player, cardId: string, slot: number): (boolean, string)
	if not CardConfig.Cards[cardId] then
		return false, "ไม่พบ card: " .. cardId
	end
	if slot < 1 or slot > CardConfig.MAX_SOCKETS then
		return false, "slot ไม่ถูกต้อง"
	end

	local data = getData(player.UserId)
	while #data.equippedCards < slot do
		table.insert(data.equippedCards, "")
	end
	data.equippedCards[slot] = cardId
	task.spawn(function()
		CardStore.save(player.UserId, data)
	end)
	CardService.applyBonuses(player)
	return true, "equipped"
end

function CardService.unequipCard(player: Player, slot: number): (boolean, string)
	local data = getData(player.UserId)
	if slot < 1 or slot > #data.equippedCards then
		return false, "slot ว่างอยู่แล้ว"
	end
	data.equippedCards[slot] = ""
	task.spawn(function()
		CardStore.save(player.UserId, data)
	end)
	CardService.applyBonuses(player)
	return true, "unequipped"
end

function CardService.applyBonuses(player: Player)
	local data = getData(player.UserId)
	local totalAtk, totalDef, totalLuck, totalExp = 0, 0, 0, 0

	for _, cardId in data.equippedCards do
		local def = CardConfig.Cards[cardId]
		if def then
			totalAtk += def.bonus.atkBonus or 0
			totalDef += def.bonus.defBonus or 0
			totalLuck += def.bonus.luckBonus or 0
			totalExp += def.bonus.expBonus or 0
		end
	end

	player:SetAttribute("CardAtkBonus", totalAtk)
	player:SetAttribute("CardDefBonus", totalDef)
	player:SetAttribute("CardLuckBonus", totalLuck)
	player:SetAttribute("CardExpBonus", totalExp)
end

Players.PlayerRemoving:Connect(function(p)
	cache[p.UserId] = nil
end)

return CardService
