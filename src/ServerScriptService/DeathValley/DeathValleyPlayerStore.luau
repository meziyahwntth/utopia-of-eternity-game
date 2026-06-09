--!strict
--[[
	Phase C — DataStore persistence for Death Valley checkpoint + weekly boss flags.
]]

local DataStoreService = game:GetService("DataStoreService")

export type CheckpointSave = {
	nightsSurvived: number,
	currentNight: number,
	beaconLevel: number,
	beaconFuel: number,
	savedAt: number,
}

export type PlayerSaveData = {
	checkpoint: CheckpointSave?,
	weeklyBossWeekId: string?,
	weeklyBossClears: number?,
	seasonBests: { [string]: number }?,
	seasonalClaims: { [string]: boolean }?,
	seasonRewardClaims: { [string]: boolean }?,
	earnedTitles: { [string]: string }?,
	ownedCosmetics: { string }?,
	equippedCosmeticId: string?,
	equippedTitleSeasonId: string?,
	loadoutPresets: { { titleSeasonId: string?, cosmeticId: string?, savedAt: number? } }?,
	presetInbox: { {
		shareId: string,
		fromUserId: number,
		fromDisplayName: string,
		titleSeasonId: string?,
		cosmeticId: string?,
		titleText: string?,
		cosmeticName: string?,
		sharedAt: number?,
	} }?,
	activeShareCodes: { {
		code: string,
		slotIndex: number,
		createdAt: number,
		expiresAt: number,
	} }?,
	socialNotifyQueue: { {
		id: string,
		type: string,
		title: string,
		body: string,
		createdAt: number,
		data: { [string]: any }?,
	} }?,
	notifyPrefs: {
		presetShare: boolean?,
		friendOnline: boolean?,
		marketFeatured: boolean?,
		pushOptIn: boolean?,
	}?,
	publishedMarketListings: { {
		listingId: string,
		slotIndex: number,
		shareCode: string?,
		createdAt: number,
		expiresAt: number,
	} }?,
	marketLikes: { string }?,
	purchasedPresetPacks: { string }?,
	creatorBalance: number?,
	creatorSalesLedger: { {
		buyerUserId: number,
		grossRobux: number,
		creatorShare: number,
		source: string,
		packId: string?,
		listingId: string?,
		createdAt: number,
	} }?,
	creatorPayoutRequests: { {
		requestId: string,
		amount: number,
		status: string,
		createdAt: number,
		exportedAt: number?,
		paidAt: number?,
	} }?,
	linkedUgcPackIds: { string }?,
	version: number,
}

local DeathValleyPlayerStore = {}

local STORE_NAME = "UtopiaDeathValley_v1"
local SAVE_VERSION = 1

local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
local memoryCache: { [number]: PlayerSaveData } = {}

local function keyFor(userId: number): string
	return "player:" .. tostring(userId)
end

function DeathValleyPlayerStore.load(userId: number): PlayerSaveData?
	if memoryCache[userId] then
		return memoryCache[userId]
	end

	if not store then
		return nil
	end

	local ok, data = pcall(function()
		return store:GetAsync(keyFor(userId))
	end)

	if ok and typeof(data) == "table" then
		memoryCache[userId] = data :: PlayerSaveData
		return data :: PlayerSaveData
	end

	return nil
end

function DeathValleyPlayerStore.save(userId: number, payload: PlayerSaveData): boolean
	payload.version = SAVE_VERSION
	memoryCache[userId] = payload

	if not store then
		return true
	end

	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), payload)
	end)

	if not ok then
		warn("[DeathValley] DataStore save failed:", err)
		return false
	end
	return true
end

function DeathValleyPlayerStore.updateCheckpoint(
	userId: number,
	checkpoint: CheckpointSave
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	existing.checkpoint = checkpoint
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.markWeeklyBossClear(userId: number, weekId: string): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if existing.weeklyBossWeekId == weekId then
		return true
	end
	existing.weeklyBossWeekId = weekId
	existing.weeklyBossClears = (existing.weeklyBossClears or 0) + 1
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.hasWeeklyBossClear(userId: number, weekId: string): boolean
	local data = DeathValleyPlayerStore.load(userId)
	return data ~= nil and data.weeklyBossWeekId == weekId
end

function DeathValleyPlayerStore.updateBestNights(userId: number, seasonId: string, nights: number): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.seasonBests then
		existing.seasonBests = {}
	end
	local current = existing.seasonBests[seasonId] or 0
	if nights <= current then
		return true
	end
	existing.seasonBests[seasonId] = nights
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.markSeasonalClaim(userId: number, seasonId: string): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.seasonalClaims then
		existing.seasonalClaims = {}
	end
	existing.seasonalClaims[seasonId] = true
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.hasSeasonalClaim(userId: number, seasonId: string): boolean
	local data = DeathValleyPlayerStore.load(userId)
	return data ~= nil and data.seasonalClaims ~= nil and data.seasonalClaims[seasonId] == true
end

function DeathValleyPlayerStore.markSeasonRewardClaim(userId: number, seasonId: string): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.seasonRewardClaims then
		existing.seasonRewardClaims = {}
	end
	existing.seasonRewardClaims[seasonId] = true
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.hasSeasonRewardClaim(userId: number, seasonId: string): boolean
	local data = DeathValleyPlayerStore.load(userId)
	return data ~= nil and data.seasonRewardClaims ~= nil and data.seasonRewardClaims[seasonId] == true
end

function DeathValleyPlayerStore.saveEarnedTitle(userId: number, seasonId: string, title: string): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.earnedTitles then
		existing.earnedTitles = {}
	end
	existing.earnedTitles[seasonId] = title
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.listOwnedCosmetics(userId: number): { string }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.ownedCosmetics then
		return {}
	end
	return data.ownedCosmetics
end

function DeathValleyPlayerStore.hasOwnedCosmetic(userId: number, cosmeticId: string): boolean
	for _, ownedId in DeathValleyPlayerStore.listOwnedCosmetics(userId) do
		if ownedId == cosmeticId then
			return true
		end
	end
	return false
end

function DeathValleyPlayerStore.addOwnedCosmetic(userId: number, cosmeticId: string): boolean
	if cosmeticId == "" then
		return true
	end
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.ownedCosmetics then
		existing.ownedCosmetics = {}
	end
	for _, ownedId in existing.ownedCosmetics do
		if ownedId == cosmeticId then
			return true
		end
	end
	table.insert(existing.ownedCosmetics, cosmeticId)
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.getEquippedCosmetic(userId: number): string?
	local data = DeathValleyPlayerStore.load(userId)
	if data and typeof(data.equippedCosmeticId) == "string" and data.equippedCosmeticId ~= "" then
		return data.equippedCosmeticId
	end
	return nil
end

function DeathValleyPlayerStore.setEquippedCosmetic(userId: number, cosmeticId: string?): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if cosmeticId and cosmeticId ~= "" then
		existing.equippedCosmeticId = cosmeticId
	else
		existing.equippedCosmeticId = nil
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.getEquippedTitleSeasonId(userId: number): string?
	local data = DeathValleyPlayerStore.load(userId)
	if data and typeof(data.equippedTitleSeasonId) == "string" and data.equippedTitleSeasonId ~= "" then
		return data.equippedTitleSeasonId
	end
	return nil
end

function DeathValleyPlayerStore.setEquippedTitleSeasonId(userId: number, seasonId: string?): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if seasonId and seasonId ~= "" then
		existing.equippedTitleSeasonId = seasonId
	else
		existing.equippedTitleSeasonId = nil
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

local PRESET_SLOTS = 3

function DeathValleyPlayerStore.getLoadoutPresets(userId: number): { [number]: { titleSeasonId: string?, cosmeticId: string?, savedAt: number? } }
	local data = DeathValleyPlayerStore.load(userId)
	local result: { [number]: { titleSeasonId: string?, cosmeticId: string?, savedAt: number? } } = {}
	if not data or not data.loadoutPresets then
		return result
	end
	for slotIndex, entry in data.loadoutPresets do
		if typeof(entry) == "table" then
			result[slotIndex] = entry
		end
	end
	return result
end

function DeathValleyPlayerStore.saveLoadoutPreset(
	userId: number,
	slotIndex: number,
	titleSeasonId: string?,
	cosmeticId: string?
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.loadoutPresets then
		existing.loadoutPresets = {}
	end
	existing.loadoutPresets[slotIndex] = {
		titleSeasonId = if titleSeasonId and titleSeasonId ~= "" then titleSeasonId else nil,
		cosmeticId = if cosmeticId and cosmeticId ~= "" then cosmeticId else nil,
		savedAt = os.time(),
	}
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.clearLoadoutPreset(userId: number, slotIndex: number): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if existing.loadoutPresets then
		existing.loadoutPresets[slotIndex] = nil
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.listPresetInbox(userId: number): { any }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.presetInbox then
		return {}
	end
	return data.presetInbox
end

function DeathValleyPlayerStore.getPresetInboxEntry(userId: number, shareId: string): any
	for _, entry in DeathValleyPlayerStore.listPresetInbox(userId) do
		if entry.shareId == shareId then
			return entry
		end
	end
	return nil
end

function DeathValleyPlayerStore.addPresetInbox(
	userId: number,
	entry: {
		shareId: string,
		fromUserId: number,
		fromDisplayName: string,
		titleSeasonId: string?,
		cosmeticId: string?,
		titleText: string?,
		cosmeticName: string?,
		sharedAt: number?,
	},
	maxEntries: number
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.presetInbox then
		existing.presetInbox = {}
	end
	table.insert(existing.presetInbox, 1, entry)
	while #existing.presetInbox > maxEntries do
		table.remove(existing.presetInbox)
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.removePresetInbox(userId: number, shareId: string): boolean
	local existing = DeathValleyPlayerStore.load(userId)
	if not existing or not existing.presetInbox then
		return false
	end
	for index, entry in existing.presetInbox do
		if entry.shareId == shareId then
			table.remove(existing.presetInbox, index)
			return DeathValleyPlayerStore.save(userId, existing)
		end
	end
	return false
end

function DeathValleyPlayerStore.listActiveShareCodes(userId: number): { any }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.activeShareCodes then
		return {}
	end
	return data.activeShareCodes
end

function DeathValleyPlayerStore.addActiveShareCode(
	userId: number,
	entry: { code: string, slotIndex: number, createdAt: number, expiresAt: number },
	maxEntries: number
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.activeShareCodes then
		existing.activeShareCodes = {}
	end
	table.insert(existing.activeShareCodes, 1, entry)
	while #existing.activeShareCodes > maxEntries do
		table.remove(existing.activeShareCodes)
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.removeActiveShareCode(userId: number, code: string): boolean
	local existing = DeathValleyPlayerStore.load(userId)
	if not existing or not existing.activeShareCodes then
		return false
	end
	for index, entry in existing.activeShareCodes do
		if entry.code == code then
			table.remove(existing.activeShareCodes, index)
			return DeathValleyPlayerStore.save(userId, existing)
		end
	end
	return false
end

function DeathValleyPlayerStore.listPublishedMarketListings(userId: number): { any }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.publishedMarketListings then
		return {}
	end
	return data.publishedMarketListings
end

function DeathValleyPlayerStore.addPublishedMarketListing(
	userId: number,
	entry: { listingId: string, slotIndex: number, shareCode: string?, createdAt: number, expiresAt: number },
	maxEntries: number
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.publishedMarketListings then
		existing.publishedMarketListings = {}
	end
	table.insert(existing.publishedMarketListings, 1, entry)
	while #existing.publishedMarketListings > maxEntries do
		table.remove(existing.publishedMarketListings)
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.hasMarketLike(userId: number, listingId: string): boolean
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.marketLikes then
		return false
	end
	for _, likedId in data.marketLikes do
		if likedId == listingId then
			return true
		end
	end
	return false
end

function DeathValleyPlayerStore.addMarketLike(userId: number, listingId: string): boolean
	if DeathValleyPlayerStore.hasMarketLike(userId, listingId) then
		return true
	end
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.marketLikes then
		existing.marketLikes = {}
	end
	table.insert(existing.marketLikes, listingId)
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.migrateOwnedFromAttribute(userId: number, attributeValue: string): boolean
	if attributeValue == "" then
		return true
	end
	local changed = false
	for token in string.gmatch(attributeValue, "([^,]+)") do
		if token ~= "" and not DeathValleyPlayerStore.hasOwnedCosmetic(userId, token) then
			DeathValleyPlayerStore.addOwnedCosmetic(userId, token)
			changed = true
		end
	end
	return changed
end

function DeathValleyPlayerStore.clearMemory(userId: number)
	memoryCache[userId] = nil
end

function DeathValleyPlayerStore.listCreatorPayoutRequests(userId: number): { any }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.creatorPayoutRequests then
		return {}
	end
	return data.creatorPayoutRequests
end

function DeathValleyPlayerStore.addCreatorPayoutRequest(
	userId: number,
	entry: { requestId: string, amount: number, status: string, createdAt: number, exportedAt: number? },
	maxEntries: number
): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.creatorPayoutRequests then
		existing.creatorPayoutRequests = {}
	end
	table.insert(existing.creatorPayoutRequests, 1, entry)
	while #existing.creatorPayoutRequests > maxEntries do
		table.remove(existing.creatorPayoutRequests)
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.patchCreatorPayoutRequest(
	userId: number,
	requestId: string,
	patch: { [string]: any }
): boolean
	if requestId == "" or typeof(patch) ~= "table" then
		return false
	end
	local existing = DeathValleyPlayerStore.load(userId)
	if not existing or not existing.creatorPayoutRequests then
		return false
	end
	local changed = false
	for _, entry in existing.creatorPayoutRequests do
		if entry.requestId == requestId then
			for key, value in patch do
				if entry[key] ~= value then
					entry[key] = value
					changed = true
				end
			end
			break
		end
	end
	if not changed then
		return false
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

function DeathValleyPlayerStore.listLinkedUgcPackIds(userId: number): { string }
	local data = DeathValleyPlayerStore.load(userId)
	if not data or not data.linkedUgcPackIds then
		return {}
	end
	return data.linkedUgcPackIds
end

function DeathValleyPlayerStore.addLinkedUgcPackId(userId: number, packId: string, maxEntries: number): boolean
	local existing = DeathValleyPlayerStore.load(userId) or { version = SAVE_VERSION }
	if not existing.linkedUgcPackIds then
		existing.linkedUgcPackIds = {}
	end
	for _, linkedId in existing.linkedUgcPackIds do
		if linkedId == packId then
			return true
		end
	end
	table.insert(existing.linkedUgcPackIds, 1, packId)
	while #existing.linkedUgcPackIds > maxEntries do
		table.remove(existing.linkedUgcPackIds)
	end
	return DeathValleyPlayerStore.save(userId, existing)
end

return DeathValleyPlayerStore
