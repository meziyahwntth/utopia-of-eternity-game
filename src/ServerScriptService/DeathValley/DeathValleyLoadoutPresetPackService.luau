--!strict
--[[
	Phase P/R — Robux preset packs (Developer Products + inbox/cosmetic grants + UGC-linked).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyCreatorRevenueService = require(script.Parent:WaitForChild("DeathValleyCreatorRevenueService"))
local DeathValleyLoadoutPresetShareService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetShareService"))
local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))
local DeathValleyUgcCreatorPackService = require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
local PrismCatalogAssets = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCatalogAssets"))
local PrismDeathValleySeasonCosmetics = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySeasonCosmetics"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))

local DeathValleyLoadoutPresetPackService = {}

local DEV_GRANT_FREE = false -- PRODUCTION: grants require real purchase. Do NOT set true in production.
local UGC_GENERIC_PRODUCT_ID_KEY = "dv_pack_ugc_generic"
local pendingByUser: { [number]: string } = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local presetPackPurchased = remotes:WaitForChild("PresetPackPurchased") :: RemoteEvent

local function resolveCosmeticName(cosmeticId: string?): string?
	if not cosmeticId or cosmeticId == "" then
		return nil
	end
	local def = PrismDeathValleySeasonCosmetics.getDef(cosmeticId)
	return if def then def.displayName else cosmeticId
end

function DeathValleyLoadoutPresetPackService.resolvePack(packId: string): PrismPresetPackCatalog.PresetPackDef?
	return DeathValleyUgcCreatorPackService.resolvePack(packId)
end

function DeathValleyLoadoutPresetPackService.hasPurchased(userId: number, packId: string): boolean
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.purchasedPresetPacks then
		return false
	end
	for _, ownedId in data.purchasedPresetPacks do
		if ownedId == packId then
			return true
		end
	end
	return false
end

function DeathValleyLoadoutPresetPackService.getCatalogPayload(player: Player): { [string]: any }
	local items: { { [string]: any } } = {}
	for _, pack in PrismPresetPackCatalog.listAll() do
		table.insert(items, {
			id = pack.id,
			displayName = pack.displayName,
			description = pack.description,
			robux = pack.robux,
			cosmeticId = pack.cosmeticId,
			cosmeticName = resolveCosmeticName(pack.cosmeticId),
			titleText = pack.titleText,
			grantCosmetic = pack.grantCosmetic,
			featured = pack.featured == true,
			shopChannel = pack.shopChannel or "both",
			seasonTag = pack.seasonTag,
			creatorSharePercent = pack.creatorSharePercent,
			owned = DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, pack.id),
			developerProductId = PrismCatalogAssets.getProductId(pack.id),
			ugcLinked = false,
		})
	end
	for _, record in DeathValleyUgcCreatorPackService.listLinkedForAuthor(player.UserId) do
		table.insert(items, {
			id = record.packId,
			displayName = record.displayName,
			description = record.description,
			robux = record.robux,
			cosmeticId = record.cosmeticId,
			cosmeticName = resolveCosmeticName(record.cosmeticId),
			featured = true,
			shopChannel = "both",
			seasonTag = record.seasonTag,
			creatorSharePercent = 70,
			owned = DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, record.packId),
			developerProductId = PrismCatalogAssets.getProductId(UGC_GENERIC_PRODUCT_ID_KEY),
			ugcLinked = true,
			listingId = record.listingId,
		})
	end
	return {
		count = #items,
		items = items,
	}
end

function DeathValleyLoadoutPresetPackService.grantPack(player: Player, packId: string): (boolean, string)
	local pack = DeathValleyLoadoutPresetPackService.resolvePack(packId)
	if not pack then
		return false, "Unknown pack"
	end
	if DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, packId) then
		return true, "Already owned"
	end

	local existing = DeathValleyPlayerStore.load(player.UserId) or { version = 1 }
	if not existing.purchasedPresetPacks then
		existing.purchasedPresetPacks = {}
	end
	table.insert(existing.purchasedPresetPacks, packId)

	local isUgc = DeathValleyUgcCreatorPackService.isUgcPackId(packId)
	if isUgc then
		local shareCode = DeathValleyUgcCreatorPackService.getShareCode(packId)
		if shareCode and shareCode ~= "" then
			DeathValleyLoadoutPresetShareService.redeemShareCode(player, shareCode)
		end
	else
		if pack.grantCosmetic and pack.cosmeticId and pack.cosmeticId ~= "" then
			DeathValleyPlayerStore.addOwnedCosmetic(player.UserId, pack.cosmeticId)
		end
		if pack.titleSeasonId and pack.titleSeasonId ~= "" and pack.titleText then
			DeathValleyPlayerStore.saveEarnedTitle(player.UserId, pack.titleSeasonId, pack.titleText)
		end

		if not existing.presetInbox then
			existing.presetInbox = {}
		end
		table.insert(existing.presetInbox, 1, {
			shareId = packId .. "_pack",
			fromUserId = 0,
			fromDisplayName = "Preset Bazaar Pack",
			titleSeasonId = pack.titleSeasonId,
			cosmeticId = pack.cosmeticId,
			titleText = pack.titleText,
			cosmeticName = resolveCosmeticName(pack.cosmeticId),
			sharedAt = os.time(),
		})
		while #existing.presetInbox > 12 do
			table.remove(existing.presetInbox)
		end
	end

	DeathValleyPlayerStore.save(player.UserId, existing)

	local creatorUserId = pack.creatorUserId or 0
	if creatorUserId > 0 then
		DeathValleyCreatorRevenueService.recordPackSale(
			creatorUserId,
			player.UserId,
			pack.robux,
			packId,
			pack.creatorSharePercent
		)
	end

	if not isUgc then
		if pack.cosmeticId and pack.cosmeticId ~= "" and pack.grantCosmetic then
			DeathValleyCosmeticService.equipCosmetic(player, pack.cosmeticId)
		end
		if pack.titleSeasonId and pack.titleSeasonId ~= "" then
			DeathValleyTitleService.equipTitle(player, pack.titleSeasonId)
		end
	end

	presetPackPurchased:FireClient(player, { ok = true, packId = packId })
	return true, string.format("Unlocked %s — check Shared inbox", pack.displayName)
end

function DeathValleyLoadoutPresetPackService.promptPurchase(player: Player, packId: string): (boolean, string)
	local pack = DeathValleyLoadoutPresetPackService.resolvePack(packId)
	if not pack then
		return false, "Unknown pack"
	end
	if DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, packId) then
		return false, "Already owned"
	end

	local productKey = if DeathValleyUgcCreatorPackService.isUgcPackId(packId)
		then UGC_GENERIC_PRODUCT_ID_KEY
		else packId
	local productId = PrismCatalogAssets.getProductId(productKey)
	if productId > 0 then
		pendingByUser[player.UserId] = packId
		MarketplaceService:PromptProductPurchase(player, productId)
		return true, "Purchase prompt opened"
	end

	if DEV_GRANT_FREE then
		return DeathValleyLoadoutPresetPackService.grantPack(player, packId)
	end

	return false, "Developer Product not configured for " .. packId
end

function DeathValleyLoadoutPresetPackService.tryProcessReceipt(receipt: any): Enum.ProductPurchaseDecision?
	local packId = pendingByUser[receipt.PlayerId]
	if not packId then
		for _, pack in PrismPresetPackCatalog.listAll() do
			if PrismCatalogAssets.getProductId(pack.id) == receipt.ProductId then
				packId = pack.id
				break
			end
		end
	end
	if not packId then
		return nil -- Not our product
	end

	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- Player offline — Roblox will retry. Do NOT grant to absent player.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DeathValleyLoadoutPresetPackService.grantPack(player, packId)
	pendingByUser[receipt.PlayerId] = nil
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerRemoving:Connect(function(player)
	pendingByUser[player.UserId] = nil
end)

return DeathValleyLoadoutPresetPackService
