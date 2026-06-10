--!strict
--[[
	Phase K — Cross-place loadout remotes (Hub + Death Valley + all places).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local DeathValleyCosmeticService = require(script.Parent:WaitForChild("DeathValleyCosmeticService"))
local DeathValleyLoadoutService = require(script.Parent:WaitForChild("DeathValleyLoadoutService"))
local DeathValleyLoadoutPresetService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetService"))
local DeathValleyLoadoutPresetShareService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetShareService"))
local DeathValleyLoadoutPresetMarketService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetMarketService"))
local DeathValleyLoadoutMirrorService = require(script.Parent:WaitForChild("DeathValleyLoadoutMirrorService"))
local DeathValleyTitleService = require(script.Parent:WaitForChild("DeathValleyTitleService"))

local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getCosmeticInventory = remotes:WaitForChild("GetCosmeticInventory") :: RemoteFunction
local equipSeasonCosmetic = remotes:WaitForChild("EquipSeasonCosmetic") :: RemoteFunction
local unequipSeasonCosmetic = remotes:WaitForChild("UnequipSeasonCosmetic") :: RemoteFunction
local getTitleInventory = remotes:WaitForChild("GetTitleInventory") :: RemoteFunction
local equipSeasonTitle = remotes:WaitForChild("EquipSeasonTitle") :: RemoteFunction
local unequipSeasonTitle = remotes:WaitForChild("UnequipSeasonTitle") :: RemoteFunction
local getLoadoutSummary = remotes:WaitForChild("GetLoadoutSummary") :: RemoteFunction
local getLoadoutFull = remotes:WaitForChild("GetLoadoutFull") :: RemoteFunction
local saveLoadoutPreset = remotes:WaitForChild("SaveLoadoutPreset") :: RemoteFunction
local applyLoadoutPreset = remotes:WaitForChild("ApplyLoadoutPreset") :: RemoteFunction
local clearLoadoutPreset = remotes:WaitForChild("ClearLoadoutPreset") :: RemoteFunction
local shareLoadoutPreset = remotes:WaitForChild("ShareLoadoutPreset") :: RemoteFunction
local getSharedPresets = remotes:WaitForChild("GetSharedPresets") :: RemoteFunction
local applySharedPreset = remotes:WaitForChild("ApplySharedPreset") :: RemoteFunction
local dismissSharedPreset = remotes:WaitForChild("DismissSharedPreset") :: RemoteFunction
local generatePresetShareCode = remotes:WaitForChild("GeneratePresetShareCode") :: RemoteFunction
local redeemPresetShareCode = remotes:WaitForChild("RedeemPresetShareCode") :: RemoteFunction
local getActivePresetShareCodes = remotes:WaitForChild("GetActivePresetShareCodes") :: RemoteFunction
local browsePresetMarket = remotes:WaitForChild("BrowsePresetMarket") :: RemoteFunction
local publishPresetMarket = remotes:WaitForChild("PublishPresetMarket") :: RemoteFunction
local acquirePresetMarket = remotes:WaitForChild("AcquirePresetMarket") :: RemoteFunction
local likePresetMarket = remotes:WaitForChild("LikePresetMarket") :: RemoteFunction
local getPresetMarket = remotes:WaitForChild("GetPresetMarket") :: RemoteFunction
local getFeaturedCarousel = remotes:WaitForChild("GetFeaturedCarousel") :: RemoteFunction
local getPresetPackCatalog = remotes:WaitForChild("GetPresetPackCatalog") :: RemoteFunction
local purchasePresetPack = remotes:WaitForChild("PurchasePresetPack") :: RemoteFunction
local adminFeatureMarketListing = remotes:WaitForChild("AdminFeatureMarketListing") :: RemoteFunction
local getCreatorRevenueSummary = remotes:WaitForChild("GetCreatorRevenueSummary") :: RemoteFunction
local getSeasonalFeaturedRotation = remotes:WaitForChild("GetSeasonalFeaturedRotation") :: RemoteFunction
local requestCreatorPayout = remotes:WaitForChild("RequestCreatorPayout") :: RemoteFunction
local createUgcCreatorPack = remotes:WaitForChild("CreateUgcCreatorPack") :: RemoteFunction
local getMyUgcCreatorPacks = remotes:WaitForChild("GetMyUgcCreatorPacks") :: RemoteFunction
local getSeasonalPopUpShop = remotes:WaitForChild("GetSeasonalPopUpShop") :: RemoteFunction

local DeathValleyLoadoutFeaturedService = require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedService"))
local DeathValleyLoadoutFeaturedRotationService =
	require(script.Parent:WaitForChild("DeathValleyLoadoutFeaturedRotationService"))
local DeathValleyCreatorRevenueService = require(script.Parent:WaitForChild("DeathValleyCreatorRevenueService"))
local DeathValleyCreatorPayoutSyncBridge = require(script.Parent:WaitForChild("DeathValleyCreatorPayoutSyncBridge"))
local DeathValleyUgcCreatorPackService = require(script.Parent:WaitForChild("DeathValleyUgcCreatorPackService"))
local DeathValleySeasonalPopUpShopService =
	require(script.Parent:WaitForChild("DeathValleySeasonalPopUpShopService"))
local DeathValleyLoadoutPresetPackService = require(script.Parent:WaitForChild("DeathValleyLoadoutPresetPackService"))

local LOADOUT_WORLDS = {
	"UtopiaHubWorld",
	"UtopiaHubGreybox",
	"UtopiaDeathValley",
	"UtopiaEternityCity",
	"UtopiaSolhaven",
	"UtopiaNocturne",
}

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

getCosmeticInventory.OnServerInvoke = function(player: Player)
	return DeathValleyCosmeticService.getInventoryPayload(player)
end

equipSeasonCosmetic.OnServerInvoke = function(player: Player, cosmeticId: string)
	if not allow(player, "EquipSeasonCosmetic", 8, 30) then
		return false, "Rate limited"
	end
	if typeof(cosmeticId) ~= "string" then
		return false, "Invalid cosmetic"
	end
	return DeathValleyCosmeticService.equipCosmetic(player, cosmeticId)
end

unequipSeasonCosmetic.OnServerInvoke = function(player: Player)
	if not allow(player, "UnequipSeasonCosmetic", 8, 30) then
		return false, "Rate limited"
	end
	return DeathValleyCosmeticService.unequipCosmetic(player)
end

getTitleInventory.OnServerInvoke = function(player: Player)
	return DeathValleyTitleService.getInventoryPayload(player)
end

equipSeasonTitle.OnServerInvoke = function(player: Player, seasonId: string)
	if not allow(player, "EquipSeasonTitle", 8, 30) then
		return false, "Rate limited"
	end
	if typeof(seasonId) ~= "string" then
		return false, "Invalid season"
	end
	return DeathValleyTitleService.equipTitle(player, seasonId)
end

unequipSeasonTitle.OnServerInvoke = function(player: Player)
	if not allow(player, "UnequipSeasonTitle", 8, 30) then
		return false, "Rate limited"
	end
	return DeathValleyTitleService.unequipTitle(player)
end

getLoadoutSummary.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutService.getSummaryPayload(player)
end

getLoadoutFull.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutService.getFullPayload(player)
end

saveLoadoutPreset.OnServerInvoke = function(player: Player, slotIndex: number, useCurrent: boolean?)
	if not allow(player, "SaveLoadoutPreset", 6, 30) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" then
		return false, "Invalid slot"
	end
	if useCurrent == true then
		return DeathValleyLoadoutPresetService.saveCurrentLoadout(player, slotIndex)
	end
	return false, "Use save current from UI"
end

applyLoadoutPreset.OnServerInvoke = function(player: Player, slotIndex: number)
	if not allow(player, "ApplyLoadoutPreset", 6, 30) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" then
		return false, "Invalid slot"
	end
	return DeathValleyLoadoutPresetService.applyPreset(player, slotIndex)
end

clearLoadoutPreset.OnServerInvoke = function(player: Player, slotIndex: number)
	if not allow(player, "ClearLoadoutPreset", 6, 30) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" then
		return false, "Invalid slot"
	end
	return DeathValleyLoadoutPresetService.clearPreset(player, slotIndex)
end

getSharedPresets.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutPresetShareService.getSharedPresetsPayload(player)
end

shareLoadoutPreset.OnServerInvoke = function(player: Player, slotIndex: number, targetUserId: number)
	if not allow(player, "ShareLoadoutPreset", 4, 60) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" or typeof(targetUserId) ~= "number" then
		return false, "Invalid share request"
	end
	return DeathValleyLoadoutPresetShareService.sharePresetWithFriend(player, slotIndex, targetUserId)
end

applySharedPreset.OnServerInvoke = function(player: Player, shareId: string)
	if not allow(player, "ApplySharedPreset", 6, 30) then
		return false, "Rate limited"
	end
	if typeof(shareId) ~= "string" then
		return false, "Invalid share"
	end
	return DeathValleyLoadoutPresetShareService.applySharedPreset(player, shareId)
end

dismissSharedPreset.OnServerInvoke = function(player: Player, shareId: string)
	if not allow(player, "DismissSharedPreset", 6, 30) then
		return false, "Rate limited"
	end
	if typeof(shareId) ~= "string" then
		return false, "Invalid share"
	end
	return DeathValleyLoadoutPresetShareService.dismissSharedPreset(player, shareId)
end

generatePresetShareCode.OnServerInvoke = function(player: Player, slotIndex: number)
	if not allow(player, "GeneratePresetShareCode", 3, 120) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" then
		return false, "Invalid slot"
	end
	return DeathValleyLoadoutPresetShareService.generateShareCode(player, slotIndex)
end

redeemPresetShareCode.OnServerInvoke = function(player: Player, code: string)
	if not allow(player, "RedeemPresetShareCode", 6, 60) then
		return false, "Rate limited"
	end
	if typeof(code) ~= "string" then
		return false, "Invalid code"
	end
	return DeathValleyLoadoutPresetShareService.redeemShareCode(player, code)
end

getActivePresetShareCodes.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutPresetShareService.getActiveShareCodesPayload(player)
end

browsePresetMarket.OnServerInvoke = function(player: Player, pageIndex: number?)
	return DeathValleyLoadoutPresetMarketService.browseMarket(player, pageIndex)
end

publishPresetMarket.OnServerInvoke = function(player: Player, slotIndex: number, tags: { string }?)
	if not allow(player, "PublishPresetMarket", 2, 120) then
		return false, "Rate limited"
	end
	if typeof(slotIndex) ~= "number" then
		return false, "Invalid slot"
	end
	return DeathValleyLoadoutPresetMarketService.publishToMarket(player, slotIndex, tags)
end

acquirePresetMarket.OnServerInvoke = function(player: Player, listingId: string)
	if not allow(player, "AcquirePresetMarket", 8, 60) then
		return false, "Rate limited"
	end
	if typeof(listingId) ~= "string" then
		return false, "Invalid listing"
	end
	return DeathValleyLoadoutPresetMarketService.acquireFromMarket(player, listingId)
end

likePresetMarket.OnServerInvoke = function(player: Player, listingId: string)
	if not allow(player, "LikePresetMarket", 10, 60) then
		return false, "Rate limited"
	end
	if typeof(listingId) ~= "string" then
		return false, "Invalid listing"
	end
	return DeathValleyLoadoutPresetMarketService.likeListing(player, listingId)
end

getPresetMarket.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutPresetMarketService.getMarketPayload(player)
end

getFeaturedCarousel.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutFeaturedService.getCarouselPayload(player)
end

getPresetPackCatalog.OnServerInvoke = function(player: Player)
	return DeathValleyLoadoutPresetPackService.getCatalogPayload(player)
end

purchasePresetPack.OnServerInvoke = function(player: Player, packId: string)
	if not allow(player, "PurchasePresetPack", 3, 60) then
		return false, "Rate limited"
	end
	if typeof(packId) ~= "string" then
		return false, "Invalid pack"
	end
	return DeathValleyLoadoutPresetPackService.promptPurchase(player, packId)
end

adminFeatureMarketListing.OnServerInvoke = function(player: Player, listingId: string)
	if not allow(player, "AdminFeatureMarketListing", 4, 60) then
		return false, "Rate limited"
	end
	return DeathValleyLoadoutFeaturedService.adminFeatureListing(player, listingId)
end

getCreatorRevenueSummary.OnServerInvoke = function(player: Player)
	return DeathValleyCreatorRevenueService.getSummary(player.UserId)
end

getSeasonalFeaturedRotation.OnServerInvoke = function(_player: Player)
	return DeathValleyLoadoutFeaturedRotationService.getRotationPayload()
end

requestCreatorPayout.OnServerInvoke = function(player: Player)
	if not allow(player, "RequestCreatorPayout", 2, 300) then
		return false, "Rate limited"
	end
	return DeathValleyCreatorRevenueService.requestPayout(player)
end

createUgcCreatorPack.OnServerInvoke = function(player: Player, listingId: string, robux: number?)
	if not allow(player, "CreateUgcCreatorPack", 3, 120) then
		return false, "Rate limited"
	end
	if typeof(listingId) ~= "string" then
		return false, "Invalid listing"
	end
	return DeathValleyUgcCreatorPackService.createFromListing(player, listingId, robux)
end

getMyUgcCreatorPacks.OnServerInvoke = function(player: Player)
	local records = DeathValleyUgcCreatorPackService.listLinkedForAuthor(player.UserId)
	local items: { { [string]: any } } = {}
	for _, record in records do
		table.insert(items, {
			packId = record.packId,
			listingId = record.listingId,
			displayName = record.displayName,
			robux = record.robux,
			seasonTag = record.seasonTag,
		})
	end
	return { count = #items, items = items }
end

getSeasonalPopUpShop.OnServerInvoke = function(player: Player)
	return DeathValleySeasonalPopUpShopService.getPayload(player)
end

local function wireLoadoutTerminal(part: BasePart)
	if part:GetAttribute("ValleyLoadoutTerminal") ~= true then
		return
	end
	if part:GetAttribute("WiredLoadoutTerminal") == true then
		return
	end
	part:SetAttribute("WiredLoadoutTerminal", true)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Valley Loadout"
		prompt.ActionText = "Open Wardrobe"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.3
		prompt.Parent = part
	end
	prompt.Triggered:Connect(function(player: Player)
		local mode = part:GetAttribute("LoadoutPickerMode")
		if typeof(mode) ~= "string" or mode == "" then
			mode = "loadout"
		end
		if mode == "cosmetic" or mode == "cosmetics" then
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "cosmetics")
		elseif mode == "title" or mode == "titles" then
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "titles")
		elseif mode == "shared" or mode == "share" then
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "shared")
		elseif mode == "market" or mode == "bazaar" then
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "market")
		elseif mode == "loadout" or mode == "presets" or mode == "wardrobe" then
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "presets")
		else
			player:SetAttribute("DV_OpenUnifiedLoadoutTab", "titles")
		end
	end)
end

local function wireWorld(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("ValleyLoadoutTerminal") == true then
			wireLoadoutTerminal(desc)
		end
	end
end

local function onPlayerReady(player: Player)
	task.defer(function()
		DeathValleyLoadoutService.syncFromStore(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerReady)
for _, player in Players:GetPlayers() do
	onPlayerReady(player)
end

for _, modelName in LOADOUT_WORLDS do
	local world = Workspace:FindFirstChild(modelName)
	if world and world:IsA("Model") then
		wireWorld(world)
		DeathValleyLoadoutMirrorService.wireWorld(world)
	end
end

Workspace.ChildAdded:Connect(function(child)
	if not child:IsA("Model") then
		return
	end
	for _, modelName in LOADOUT_WORLDS do
		if child.Name == modelName then
			task.defer(function()
				wireWorld(child)
				DeathValleyLoadoutMirrorService.wireWorld(child)
			end)
			break
		end
	end
end)

DeathValleyLoadoutMirrorService.start()
DeathValleyCreatorPayoutSyncBridge:StartPolling()

if RunService:IsStudio() then
	local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
	local studioDev = (GameConfig :: any).StudioDev
	if typeof(studioDev) == "table" and studioDev.SeedCreatorTestCredits == true then
		local DeathValleyPlayerStore = require(script.Parent:WaitForChild("DeathValleyPlayerStore"))
		local minPayout = (GameConfig.DeathValley :: any).CreatorPayout.minCredits or 100
		local seedAmount = math.max(minPayout + 50, 150)
		local function seedCreatorCredits(player: Player)
			task.defer(function()
				local data = DeathValleyPlayerStore.load(player.UserId)
				if not data then
					warn("[DeathValley] Studio: PlayerStore.load returned nil for", player.Name, "— skipping seed")
					return
				end
				local balance = if typeof(data.creatorBalance) == "number" then data.creatorBalance else 0
				if balance < minPayout then
					data.creatorBalance = seedAmount
					DeathValleyPlayerStore.save(player.UserId, data)
					print("[DeathValley] Studio: seeded creator test credits for", player.Name, seedAmount)
				end
			end)
		end
		Players.PlayerAdded:Connect(seedCreatorCredits)
		for _, player in Players:GetPlayers() do
			seedCreatorCredits(player)
		end
	end
end

print("[DeathValley] Cross-place loadout handlers online")
