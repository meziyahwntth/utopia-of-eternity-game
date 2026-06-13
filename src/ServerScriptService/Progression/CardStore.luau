--!strict
--[[
	CardStore — DataStore for equipped card sockets
]]
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("UtopiaCard_v1")

export type CardData = {
	equippedCards: { string },
}

local CardStore = {}

local DEFAULT: CardData = { equippedCards = {} }

function CardStore.load(userId: number): CardData
	local ok, data = pcall(function()
		return store:GetAsync("card_" .. userId)
	end)
	if ok and data then
		return data :: CardData
	end
	return table.clone(DEFAULT)
end

function CardStore.save(userId: number, data: CardData)
	local ok, err = pcall(function()
		store:SetAsync("card_" .. userId, data)
	end)
	if not ok then
		warn("[CardStore] save failed:", err)
	end
end

return CardStore
