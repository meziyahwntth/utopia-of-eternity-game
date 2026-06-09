--!strict
--[[
	Prism Key progression — numbered keys 1–99, DataStore-backed (UtopiaPrismKeys_v1).
	ดอก 1–5: หมายเลข 1,2,3,4,5 · ดอก 6+: สุ่มตาม PrismKeyRandomPools
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismKeyProgression = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyProgression"))
local PrismKeyRandomPools = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyRandomPools"))
local PrismKeyPlayerStore = require(script.Parent:WaitForChild("PrismKeyPlayerStore"))
local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local PrismKeyService = {}

local OWNED_ATTR = "PrismKeysOwned"
local PICKUP_PREFIX = "PrismKeyPickup_"

local persistScheduled: { [number]: boolean } = {}
local hydrating: { [number]: boolean } = {}

local function zoneClaimAttribute(zoneId: string): string
	return "DungeonKey_" .. zoneId
end

local function pickupClaimAttribute(pickupId: string): string
	return PICKUP_PREFIX .. pickupId
end

local function collectZoneClaims(player: Player): { [string]: boolean }
	local claims: { [string]: boolean } = {}
	for name, value in player:GetAttributes() do
		if typeof(name) == "string" and string.sub(name, 1, 11) == "DungeonKey_" and value == true then
			claims[string.sub(name, 12)] = true
		end
	end
	return claims
end

local function collectMilestones(player: Player): { [string]: boolean }
	local claimed: { [string]: boolean } = {}
	for name, value in player:GetAttributes() do
		if typeof(name) == "string" and string.sub(name, 1, 26) == "PrismKeyMilestoneClaimed_" and value == true then
			claimed[string.sub(name, 27)] = true
		end
	end
	return claimed
end

local function collectPickups(player: Player): { [string]: boolean }
	local pickups: { [string]: boolean } = {}
	for name, value in player:GetAttributes() do
		if typeof(name) == "string" and string.sub(name, 1, #PICKUP_PREFIX) == PICKUP_PREFIX and value == true then
			pickups[string.sub(name, #PICKUP_PREFIX + 1)] = true
		end
	end
	return pickups
end

function PrismKeyService.schedulePersist(player: Player)
	if hydrating[player.UserId] then
		return
	end
	if persistScheduled[player.UserId] then
		return
	end
	persistScheduled[player.UserId] = true
	task.delay(1, function()
		persistScheduled[player.UserId] = nil
		if player.Parent then
			PrismKeyService.persistPlayer(player)
		end
	end)
end

function PrismKeyService.persistPlayer(player: Player): boolean
	local pending = player:GetAttribute("PrismKeyMilestonePending")
	local payload = {
		ownedKeys = PrismKeyService.getOwnedKeys(player),
		zoneClaims = collectZoneClaims(player),
		milestonesClaimed = collectMilestones(player),
		pickupsClaimed = collectPickups(player),
		liveMirrorUnlocked = player:GetAttribute("PrismLiveMirrorUnlocked") == true,
		milestonePending = if typeof(pending) == "number" then pending else nil,
		version = 1,
	}
	return PrismKeyPlayerStore.save(player.UserId, payload)
end

function PrismKeyService.hydratePlayer(player: Player)
	local data = PrismKeyPlayerStore.load(player.UserId)
	if not data then
		return
	end

	hydrating[player.UserId] = true
	if data.ownedKeys then
		writeOwned(player, data.ownedKeys)
	end
	if data.zoneClaims then
		for zoneId, claimed in data.zoneClaims do
			if claimed then
				player:SetAttribute(zoneClaimAttribute(zoneId), true)
			end
		end
	end
	if data.milestonesClaimed then
		for keyIndex, claimed in data.milestonesClaimed do
			if claimed then
				player:SetAttribute("PrismKeyMilestoneClaimed_" .. keyIndex, true)
			end
		end
	end
	if data.pickupsClaimed then
		for pickupId, claimed in data.pickupsClaimed do
			if claimed then
				player:SetAttribute(pickupClaimAttribute(pickupId), true)
			end
		end
	end
	if data.liveMirrorUnlocked then
		player:SetAttribute("PrismLiveMirrorUnlocked", true)
	end
	if typeof(data.milestonePending) == "number" then
		player:SetAttribute("PrismKeyMilestonePending", data.milestonePending)
	end
	hydrating[player.UserId] = nil
end

function PrismKeyService.hasPickupClaimed(player: Player, pickupId: string): boolean
	return player:GetAttribute(pickupClaimAttribute(pickupId)) == true
end

function PrismKeyService.markPickupClaimed(player: Player, pickupId: string)
	player:SetAttribute(pickupClaimAttribute(pickupId), true)
	PrismKeyService.schedulePersist(player)
end

local function parseOwned(raw: any): { number }
	local list: { number } = {}
	if typeof(raw) ~= "string" or raw == "" then
		return list
	end
	for token in string.gmatch(raw, "[^,]+") do
		local n = tonumber(token)
		if n and PrismKeyRandomPools.isValidKeyNumber(n) then
			table.insert(list, n)
		end
	end
	table.sort(list)
	return list
end

local function ownedSetFromList(list: { number }): { [number]: boolean }
	local set: { [number]: boolean } = {}
	for _, n in list do
		set[n] = true
	end
	return set
end

local function writeOwned(player: Player, list: { number })
	table.sort(list)
	player:SetAttribute(OWNED_ATTR, table.concat(list, ","))
	player:SetAttribute("PrismKeyCount", #list)
	PrismKeyService.schedulePersist(player)
end

function PrismKeyService.getOwnedKeys(player: Player): { number }
	return parseOwned(player:GetAttribute(OWNED_ATTR))
end

function PrismKeyService.hasKeyNumber(player: Player, keyNumber: number): boolean
	for _, n in PrismKeyService.getOwnedKeys(player) do
		if n == keyNumber then
			return true
		end
	end
	return false
end

function PrismKeyService.getKeyCount(player: Player): number
	local attr = player:GetAttribute("PrismKeyCount")
	if typeof(attr) == "number" then
		return attr
	end
	return #PrismKeyService.getOwnedKeys(player)
end

function PrismKeyService.hasClaimedZoneKey(player: Player, zoneId: string): boolean
	return player:GetAttribute(zoneClaimAttribute(zoneId)) == true
end

local function applyMilestones(player: Player, grantedKeyNumber: number)
	if PrismKeyProgression.hasReward(grantedKeyNumber) then
		local claimed = player:GetAttribute("PrismKeyMilestoneClaimed_" .. tostring(grantedKeyNumber))
		if claimed ~= true then
			player:SetAttribute("PrismKeyMilestonePending", grantedKeyNumber)
		end
	end

	if grantedKeyNumber >= GameConfig.PrismKeys.LIVE_MIRROR_UNLOCK_KEY then
		player:SetAttribute("PrismLiveMirrorUnlocked", true)
	end
end

function PrismKeyService.grantKeyNumber(player: Player, keyNumber: number, source: string): (boolean, string)
	if not PrismKeyRandomPools.isValidKeyNumber(keyNumber) then
		return false, "Invalid key number"
	end
	local placeKey = WorldPlaceGuard:GetCurrentPlaceKey()
	if not PrismKeyProgression.canGrantKeyInPlace(keyNumber, placeKey) then
		if placeKey == "EternityCity" then
			return false, "Only gate keys #11, #15, and #20 can be earned in Eternity City"
		end
		return false, string.format("Prism Key #%d must be collected in Eternity City", keyNumber)
	end
	if PrismKeyService.hasKeyNumber(player, keyNumber) then
		return false, string.format("Already own Prism Key #%d", keyNumber)
	end

	local owned = PrismKeyService.getOwnedKeys(player)
	table.insert(owned, keyNumber)
	writeOwned(player, owned)

	player:SetAttribute("PrismKeyLastGrantedNumber", keyNumber)
	player:SetAttribute("PrismKeyLastSource", source)
	player:SetAttribute("PrismKeyLastGrantAt", os.time())

	applyMilestones(player, keyNumber)

	local display = GameConfig.PrismKeys.DISPLAY_COUNT
	local msg = if display == "??"
		then string.format("Prism Key #%d earned!", keyNumber)
		else string.format("Prism Key #%d (+1 total %d)", keyNumber, #owned)

	return true, msg
end

function PrismKeyService.removeKeyNumbers(player: Player, keyNumbers: { number }): (boolean, string)
	local owned = PrismKeyService.getOwnedKeys(player)
	local removeSet: { [number]: boolean } = {}
	for _, n in keyNumbers do
		removeSet[n] = true
	end

	local nextList: { number } = {}
	local removed = 0
	for _, n in owned do
		if removeSet[n] then
			removed += 1
		else
			table.insert(nextList, n)
		end
	end

	if removed ~= #keyNumbers then
		return false, "You do not own all selected keys"
	end

	writeOwned(player, nextList)
	return true, "Keys removed for trade"
end

function PrismKeyService.rollNextKeyNumber(player: Player): (number?, string?)
	local owned = ownedSetFromList(PrismKeyService.getOwnedKeys(player))
	local earnOrder = PrismKeyService.getKeyCount(player) + 1

	local fixed = PrismKeyRandomPools.getFixedKeyNumberForEarnOrder(earnOrder)
	if fixed then
		if owned[fixed] then
			return nil, string.format("Key #%d already owned", fixed)
		end
		return fixed, nil
	end

	return PrismKeyRandomPools.rollRandomKeyNumber(owned)
end

function PrismKeyService.grantZoneKey(player: Player, zoneId: string, zoneIndex: number): (boolean, string)
	if PrismKeyService.hasClaimedZoneKey(player, zoneId) then
		return false, "Already claimed key for this zone"
	end

	local keyNumber, rollErr = PrismKeyService.rollNextKeyNumber(player)
	if not keyNumber then
		return false, rollErr or "Could not roll key"
	end

	player:SetAttribute(zoneClaimAttribute(zoneId), true)
	player:SetAttribute("PrismKeyLastZoneId", zoneId)

	local ok, msg = PrismKeyService.grantKeyNumber(
		player,
		keyNumber,
		string.format("death_valley_z%d_%s", zoneIndex, zoneId)
	)
	if not ok then
		player:SetAttribute(zoneClaimAttribute(zoneId), nil)
		return false, msg
	end

	PrismKeyService.schedulePersist(player)
	return true, msg
end

function PrismKeyService.tradeKeysForNumber(
	player: Player,
	sacrificeKeys: { number },
	targetKeyNumber: number
): (boolean, string)
	if #sacrificeKeys ~= PrismKeyRandomPools.TradeCost then
		return false, string.format("Trade requires exactly %d keys", PrismKeyRandomPools.TradeCost)
	end
	if not PrismKeyRandomPools.isValidKeyNumber(targetKeyNumber) then
		return false, "Invalid target key number"
	end
	if PrismKeyService.hasKeyNumber(player, targetKeyNumber) then
		return false, string.format("Already own key #%d", targetKeyNumber)
	end

	local seen: { [number]: boolean } = {}
	for _, n in sacrificeKeys do
		if seen[n] then
			return false, "Duplicate sacrifice keys"
		end
		if not PrismKeyService.hasKeyNumber(player, n) then
			return false, string.format("You do not own key #%d", n)
		end
		seen[n] = true
	end

	local removed, removeErr = PrismKeyService.removeKeyNumbers(player, sacrificeKeys)
	if not removed then
		return false, removeErr
	end

	local ok, msg = PrismKeyService.grantKeyNumber(
		player,
		targetKeyNumber,
		string.format("ghost_trade_z%d", targetKeyNumber)
	)
	if not ok then
		return false, msg
	end

	return true, string.format("Traded 3 keys for Prism Key #%d", targetKeyNumber)
end

return PrismKeyService
