--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismCommerceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCommerceConfig"))
local PrismCatalogAssets = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCatalogAssets"))
local PrismPresetPackCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismPresetPackCatalog"))
local GreyboxAccessoryFactory = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GreyboxAccessoryFactory"))
local PrismFashionCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismFashionCatalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local getCatalog = remotes:WaitForChild("GetShopCatalog") :: RemoteFunction
local purchaseItem = remotes:WaitForChild("PurchaseItem") :: RemoteFunction
local purchaseResult = remotes:WaitForChild("PurchaseResult") :: RemoteEvent

local DEV_GRANT_FREE = false -- PRODUCTION: grants require real purchase. Do NOT set true in production.

type CatalogItem = {
	id: string,
	displayName: string,
	kind: "set" | "piece" | "service",
	robux: number,
	baseRobux: number?,
	slot: string?,
	developerProductId: number?,
	owned: boolean?,
	locked: boolean?,
	lockReason: string?,
	source: string?,
}

local function colorToTable(color: Color3): { r: number, g: number, b: number }
	return { r = color.R, g = color.G, b = color.B }
end

local function getSeasonThemePayload(seasonName: string): { [string]: any }?
	local themes = GameConfig.SeasonThemes
	if typeof(themes) ~= "table" then
		return nil
	end
	local theme = themes[seasonName]
	if typeof(theme) ~= "table" then
		return nil
	end
	local accent = theme.accent
	local signColor = theme.signColor
	return {
		seasonName = seasonName,
		badge = theme.badge or seasonName,
		accent = if typeof(accent) == "Color3" then colorToTable(accent) else nil,
		signColor = if typeof(signColor) == "Color3" then colorToTable(signColor) else nil,
	}
end

local function getPlayerKeyCount(player: Player): number
	local count = player:GetAttribute("PrismKeyCount")
	if typeof(count) == "number" then
		return count
	end
	return 0
end

local function applyShopPricing(item: CatalogItem, shop: PrismCommerceConfig.ShopEntry, player: Player)
	local keys = getPlayerKeyCount(player)
	local canBuy = PrismCommerceConfig.playerCanPurchase(keys, shop)
	item.baseRobux = item.robux
	item.robux = PrismCommerceConfig.applyPrice(item.robux, shop)
	item.locked = not canBuy
	if not canBuy then
		item.lockReason = string.format("Requires Prism Key progress (%d/%d)", keys, shop.minPrismKeys)
	end
end

local function playerOwns(player: Player, itemId: string): boolean
	local inv = player:GetAttribute("OwnedCosmetics")
	if typeof(inv) ~= "string" or inv == "" then
		return false
	end
	return string.find(inv, itemId .. ",", 1, true) ~= nil
end

local function findItemSlot(itemId: string): string?
	for _, set in PrismFashionCatalog.getAllSets() do
		for _, piece in set.pieces do
			if piece.id == itemId then
				return piece.slot
			end
		end
	end
	return nil
end

local function grantOwned(player: Player, itemId: string)
	local inv = player:GetAttribute("OwnedCosmetics")
	if typeof(inv) ~= "string" then
		inv = ""
	end
	if not playerOwns(player, itemId) then
		player:SetAttribute("OwnedCosmetics", inv .. itemId .. ",")
	end
	local char = player.Character
	local slot = findItemSlot(itemId)
	if char and slot then
		GreyboxAccessoryFactory:EquipPreview(char, itemId, slot)
	end
end

local function setToCatalogItem(set: any, owned: boolean): CatalogItem
	return {
		id = set.id,
		displayName = set.displayName,
		kind = "set",
		robux = set.bundleRobux,
		developerProductId = PrismCatalogAssets.getProductId(set.id),
		owned = owned,
	}
end

local function piecesToItems(set: any): { CatalogItem }
	local items: { CatalogItem } = {}
	for _, piece in set.pieces do
		table.insert(items, {
			id = piece.id,
			displayName = piece.displayName,
			kind = "piece",
			robux = piece.robux,
			slot = piece.slot,
			developerProductId = PrismCatalogAssets.getProductId(piece.id),
		})
	end
	return items
end

local function getShopDef(shopId: string): PrismCommerceConfig.ShopEntry?
	for _, shop in PrismCommerceConfig.Shops do
		if shop.id == shopId then
			return shop
		end
	end
	return nil
end

local function appendAllFashionSets(items: { CatalogItem }, player: Player, shop: PrismCommerceConfig.ShopEntry)
	for _, set in PrismFashionCatalog.getAllSets() do
		local catalogItem = setToCatalogItem(set, playerOwns(player, set.id))
		applyShopPricing(catalogItem, shop, player)
		table.insert(items, catalogItem)
		for _, piece in piecesToItems(set) do
			piece.owned = playerOwns(player, piece.id)
			applyShopPricing(piece, shop, player)
			table.insert(items, piece)
		end
	end
end

local function buildCatalogForShop(shopId: string, player: Player): { CatalogItem }
	local shop = getShopDef(shopId)
	if not shop then
		return {}
	end

	local items: { CatalogItem } = {}
	local shopType = shop.shopType

	if shopType == "LuxuryGalleria" then
		appendAllFashionSets(items, player, shop)
		for _, w in PrismCatalogAssets.Weapons do
			local entry: CatalogItem = {
				id = w.id,
				displayName = w.displayName,
				kind = "piece",
				robux = w.robux,
				slot = "Back",
				developerProductId = PrismCatalogAssets.getProductId(w.id),
				owned = playerOwns(player, w.id),
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
		for _, v in PrismCatalogAssets.Vehicles do
			local entry: CatalogItem = {
				id = v.id,
				displayName = v.displayName,
				kind = "service",
				robux = v.robux,
				developerProductId = PrismCatalogAssets.getProductId(v.id),
				owned = playerOwns(player, v.id),
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
	elseif shopType == "PrismWardrobe" then
		local wardrobeSets: { any } = {}
		for _, set in PrismFashionCatalog.SignatureSets do
			table.insert(wardrobeSets, set)
		end
		for _, set in PrismFashionCatalog.TeenTrendSets do
			table.insert(wardrobeSets, set)
		end
		for _, set in wardrobeSets do
			local catalogItem = setToCatalogItem(set, playerOwns(player, set.id))
			applyShopPricing(catalogItem, shop, player)
			table.insert(items, catalogItem)
			for _, piece in piecesToItems(set) do
				piece.owned = playerOwns(player, piece.id)
				applyShopPricing(piece, shop, player)
				table.insert(items, piece)
			end
		end
	elseif shopType == "WorldCulturePavilion" then
		for _, set in PrismFashionCatalog.NationalSets do
			local catalogItem = setToCatalogItem(set, playerOwns(player, set.id))
			applyShopPricing(catalogItem, shop, player)
			table.insert(items, catalogItem)
			for _, piece in piecesToItems(set) do
				piece.owned = playerOwns(player, piece.id)
				applyShopPricing(piece, shop, player)
				table.insert(items, piece)
			end
		end
	elseif shopType == "SeasonalPopUp" then
		local ServerScriptService = game:GetService("ServerScriptService")
		local DeathValleyLoadoutFeaturedRotationService = require(
			ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleyLoadoutFeaturedRotationService")
		)
		local DeathValleySeasonalPopUpShopService = require(
			ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleySeasonalPopUpShopService")
		)
		local seasonName = DeathValleyLoadoutFeaturedRotationService.getSeasonName()
		for _, set in PrismFashionCatalog.getSetsForSeason(seasonName) do
			local catalogItem = setToCatalogItem(set, playerOwns(player, set.id))
			catalogItem.source = "fashion"
			applyShopPricing(catalogItem, shop, player)
			table.insert(items, catalogItem)
		end
		for _, popUpItem in DeathValleySeasonalPopUpShopService.getPresetPackItems(player) do
			local itemSource = if popUpItem.source == "ugc_creator" then "ugc_creator" else "season_rotation"
			local entry: CatalogItem = {
				id = popUpItem.id,
				displayName = popUpItem.displayName,
				kind = "service",
				robux = popUpItem.robux,
				developerProductId = PrismCatalogAssets.getProductId(
					if PrismPresetPackCatalog.isUgcPackId(popUpItem.id) then "dv_pack_ugc_generic" else popUpItem.id
				),
				owned = popUpItem.owned,
				source = itemSource,
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
	elseif shopType == "PrismWeaponGallery" then
		for _, w in PrismCatalogAssets.Weapons do
			local entry: CatalogItem = {
				id = w.id,
				displayName = w.displayName,
				kind = "piece",
				robux = w.robux,
				slot = "Back",
				developerProductId = PrismCatalogAssets.getProductId(w.id),
				owned = playerOwns(player, w.id),
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
	elseif shopType == "PrismMotors" or shopType == "MountEmporium" then
		for _, v in PrismCatalogAssets.Vehicles do
			if shopType == "MountEmporium" and v.category ~= "mount" then
				continue
			end
			if shopType == "PrismMotors" and v.category == "mount" then
				continue
			end
			local entry: CatalogItem = {
				id = v.id,
				displayName = v.displayName,
				kind = "service",
				robux = v.robux,
				developerProductId = PrismCatalogAssets.getProductId(v.id),
				owned = playerOwns(player, v.id),
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
	elseif shopType == "PrismServiceCenter" or shopType == "NeonAlleyTune" then
		local tier = if shopType == "PrismServiceCenter" then "premium" else "budget"
		for _, paint in PrismCatalogAssets.VehiclePaints do
			if paint.tier == tier then
				local entry: CatalogItem = {
					id = paint.id,
					displayName = paint.displayName,
					kind = "service",
					robux = paint.robux,
					developerProductId = PrismCatalogAssets.getProductId(paint.id),
				}
				applyShopPricing(entry, shop, player)
				table.insert(items, entry)
			end
		end
	elseif shopType == "StellarSalon" or shopType == "PrismBeauty" or shopType == "EternityAesthetics" then
		for _, s in PrismCatalogAssets.BeautyServices do
			if s.shopType == shopType then
				local entry: CatalogItem = {
					id = s.id,
					displayName = s.displayName,
					kind = "service",
					robux = s.robux,
					developerProductId = PrismCatalogAssets.getProductId(s.id),
				}
				applyShopPricing(entry, shop, player)
				table.insert(items, entry)
			end
		end
	elseif shopType == "HellboundTerminal" then
		table.insert(items, {
			id = "hellbound_public_airplane",
			displayName = "Hellbound Public Airplane Ticket",
			kind = "service",
			robux = 0,
		})
		table.insert(items, {
			id = "hellbound_private_jet",
			displayName = "Hellbound Private Jet (Hyperdrive)",
			kind = "service",
			robux = 499,
		})
	elseif shopType == "PresetBazaar" then
		local ServerScriptService = game:GetService("ServerScriptService")
		local DeathValleyLoadoutPresetPackService =
			require(ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleyLoadoutPresetPackService"))
		for _, pack in PrismPresetPackCatalog.listForChannel("commerce") do
			local entry: CatalogItem = {
				id = pack.id,
				displayName = pack.displayName,
				kind = "service",
				robux = pack.robux,
				developerProductId = PrismCatalogAssets.getProductId(pack.id),
				owned = DeathValleyLoadoutPresetPackService.hasPurchased(player.UserId, pack.id),
			}
			applyShopPricing(entry, shop, player)
			table.insert(items, entry)
		end
	else
		table.insert(items, {
			id = shopId .. "_coming_soon",
			displayName = shop.displayName .. " — Coming Soon",
			kind = "service",
			robux = 0,
		})
	end

	return items
end

getCatalog.OnServerInvoke = function(player: Player, shopId: string)
	if typeof(shopId) ~= "string" then
		return { shopId = "", shopName = "", items = {} }
	end
	local shop = getShopDef(shopId)
	local response: { [string]: any } = {
		shopId = shopId,
		shopName = if shop then shop.displayName else "Shop",
		peaceZone = true,
		commerceTier = if shop then shop.commerceTier else "street",
		priceMultiplier = if shop then shop.priceMultiplier else 1,
		minPrismKeys = if shop then shop.minPrismKeys else 0,
		playerKeyCount = getPlayerKeyCount(player),
		items = buildCatalogForShop(shopId, player),
	}
	if shop and shop.shopType == "SeasonalPopUp" then
		local ServerScriptService = game:GetService("ServerScriptService")
		local DeathValleySeasonalPopUpShopService = require(
			ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleySeasonalPopUpShopService")
		)
		local popUp = DeathValleySeasonalPopUpShopService.getPayload(player)
		response.seasonPopUpLabel = popUp.label
		response.seasonName = popUp.seasonName
		response.seasonId = popUp.seasonId
		response.seasonTheme = getSeasonThemePayload(popUp.seasonName)
	end
	return response
end

local pendingPurchases: { [number]: string } = {}

local function tryHellboundDepart(player: Player, itemId: string): (boolean?, string?)
	if itemId ~= "hellbound_public_airplane" and itemId ~= "hellbound_private_jet" then
		return nil
	end
	local ServerScriptService = game:GetService("ServerScriptService")
	local HellboundTerminalService = require(ServerScriptService:WaitForChild("Hellbound"):WaitForChild("HellboundTerminalService"))
	local mode = if itemId == "hellbound_private_jet" then "PrivateJet" else "PublicAirplane"
	return HellboundTerminalService.depart(player, mode)
end

local function processPurchase(player: Player, itemId: string): (boolean, string)
	local hellboundResult = tryHellboundDepart(player, itemId)
	if hellboundResult then
		return hellboundResult
	end

	local ServerScriptService = game:GetService("ServerScriptService")
	local DeathValleyLoadoutPresetPackService = require(
		ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleyLoadoutPresetPackService")
	)
	if DeathValleyLoadoutPresetPackService.resolvePack(itemId) then
		return DeathValleyLoadoutPresetPackService.promptPurchase(player, itemId)
	end

	if playerOwns(player, itemId) then
		return true, "Already owned"
	end

	local productId = PrismCatalogAssets.getProductId(itemId)
	if productId > 0 then
		pendingPurchases[player.UserId] = itemId
		MarketplaceService:PromptProductPurchase(player, productId)
		return true, "Prompt opened"
	end

	if DEV_GRANT_FREE then
		grantOwned(player, itemId)
		return true, "Granted (dev)"
	end

	return false, "Product not configured"
end

purchaseItem.OnServerInvoke = function(player: Player, shopId: string, itemId: string)
	if typeof(itemId) ~= "string" or itemId == "" then
		return { ok = false, message = "Invalid item" }
	end
	local shop = if typeof(shopId) == "string" then getShopDef(shopId) else nil
	if shop and not PrismCommerceConfig.playerCanPurchase(getPlayerKeyCount(player), shop) then
		return {
			ok = false,
			message = string.format("Street shop locked — need %d Prism Keys (you have %d)", shop.minPrismKeys, getPlayerKeyCount(player)),
		}
	end
	local ok, message = processPurchase(player, itemId)
	return { ok = ok, message = message }
end

MarketplaceService.ProcessReceipt = function(receipt)
	local ServerScriptService = game:GetService("ServerScriptService")

	-- Try preset pack handler first
	local packOk, packDecision = pcall(function()
		local DeathValleyLoadoutPresetPackService =
			require(ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleyLoadoutPresetPackService"))
		return DeathValleyLoadoutPresetPackService.tryProcessReceipt(receipt)
	end)
	if packOk and packDecision then
		return packDecision
	end

	-- Player must be online to grant
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- Retry later — do NOT grant to an offline player
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local itemId = pendingPurchases[receipt.PlayerId]
	if not itemId then
		-- Unknown product for this player — log and acknowledge to stop retry loop
		warn(string.format("[Commerce] ProcessReceipt: unknown productId=%d for userId=%d — no pending purchase recorded", receipt.ProductId, receipt.PlayerId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	grantOwned(player, itemId)
	pendingPurchases[receipt.PlayerId] = nil
	purchaseResult:FireClient(player, { ok = true, itemId = itemId })
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerRemoving:Connect(function(player)
	pendingPurchases[player.UserId] = nil
end)

print("[Commerce] Shop service online")
