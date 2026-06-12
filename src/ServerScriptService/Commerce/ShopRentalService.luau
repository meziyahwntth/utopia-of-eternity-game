--!strict
--[[
	Player shop rental — Phase A: lease DataStore, Robux rent, sign sync.
]]
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local ShopRentalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopRentalConfig"))
local PrismCatalogAssets = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCatalogAssets"))
local RateLimiter = require(game:GetService("ServerScriptService"):WaitForChild("Security"):WaitForChild("RateLimiter"))

export type LeaseRecord = {
	ownerId: number,
	shopName: string,
	zone: string,
	rentedAt: number,
	expiresAt: number,
	tierIndex: number?,
	purchaseId: string?,
}

local ShopRentalService = {}

-- DataStore ใช้ไม่ได้บน local file (Studio ที่ยังไม่ publish) — ต้อง pcall เสมอ (convention: BanRegistry, DailyStreakStore)
local leaseStore: GlobalDataStore? = nil
local receiptStore: GlobalDataStore? = nil
local compensationStore: GlobalDataStore? = nil
pcall(function()
	leaseStore = DataStoreService:GetDataStore(ShopRentalConfig.DataStoreLease)
	receiptStore = DataStoreService:GetDataStore(ShopRentalConfig.DataStoreReceipts)
	compensationStore = DataStoreService:GetDataStore(ShopRentalConfig.DataStoreCompensation)
end)
if leaseStore == nil then
	warn("[SHOP] DataStore unavailable (local file?) — leases run in-memory only")
end

local leases: { [string]: LeaseRecord } = {}
local unitByRoomId: { [string]: Model } = {}
local pendingRent: { [number]: { roomId: string, tierIndex: number, nonce: string } } = {}

local leaseChanged: RemoteEvent? = nil

local RATE_DIRECTORY = { maxTokens = 8, refillPerSecond = 0.2 }
local RATE_RENT = { maxTokens = 4, refillPerSecond = 0.05 }
local RATE_NAME = { maxTokens = 3, refillPerSecond = 0.05 }

local function dataStoreUpdate(store: GlobalDataStore?, key: string, transform: (any?) -> any): (boolean, any)
	if store == nil then
		return false, nil
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:UpdateAsync(key, transform)
		end)
		if ok then
			return true, result
		end
		task.wait(0.5 * attempt)
	end
	return false, nil
end

local function findNameLabel(unit: Model): TextLabel?
	local sign = unit:FindFirstChild("NameSign")
	if sign and sign:IsA("BasePart") then
		local gui = sign:FindFirstChild("ShopName")
		if gui and gui:IsA("SurfaceGui") then
			local label = gui:FindFirstChild("ShopNameLabel")
			if label and label:IsA("TextLabel") then
				return label
			end
		end
	end
	return nil
end

function ShopRentalService.setLeaseChangedEvent(event: RemoteEvent)
	leaseChanged = event
end

function ShopRentalService.registerUnit(roomId: string, unit: Model)
	unitByRoomId[roomId] = unit
	ShopRentalService.syncUnitSign(roomId)
end

function ShopRentalService.syncUnitSign(roomId: string)
	local unit = unitByRoomId[roomId]
	if not unit then
		return
	end
	local label = findNameLabel(unit)
	if not label then
		return
	end
	local lease = leases[roomId]
	if lease and lease.expiresAt > os.time() then
		label.Text = if lease.shopName ~= "" then lease.shopName else "OPEN"
		unit:SetAttribute("ShopVacant", false)
		unit:SetAttribute("ShopOwnerId", lease.ownerId)
	else
		label.Text = "FOR RENT"
		unit:SetAttribute("ShopVacant", true)
		unit:SetAttribute("ShopOwnerId", nil)
	end
end

function ShopRentalService.syncAllSigns()
	for roomId in leases do
		ShopRentalService.syncUnitSign(roomId)
	end
	for roomId, unit in unitByRoomId do
		if leases[roomId] == nil then
			ShopRentalService.syncUnitSign(roomId)
		end
		unit:SetAttribute("ShopVacant", leases[roomId] == nil or leases[roomId].expiresAt <= os.time())
	end
end

function ShopRentalService.scanUnits(parent: Instance): number
	for _, inst in parent:GetDescendants() do
		if inst:IsA("Model") and inst:GetAttribute("ShopRoomId") then
			local roomId = inst:GetAttribute("ShopRoomId")
			if typeof(roomId) == "string" then
				ShopRentalService.registerUnit(roomId, inst)
			end
		end
	end
	local up = 0
	local et = 0
	for roomId in unitByRoomId do
		if string.sub(roomId, 1, 3) == "UP-" then
			up += 1
		elseif string.sub(roomId, 1, 3) == "ET-" then
			et += 1
		end
	end
	print(string.format("[SHOP] directory scan UP=%d ET=%d total=%d", up, et, up + et))
	return up + et
end

function ShopRentalService.loadLeases()
	if leaseStore == nil then
		return
	end
	local ok, data = pcall(function()
		return leaseStore:GetAsync("all_leases")
	end)
	if ok and typeof(data) == "table" then
		leases = data :: { [string]: LeaseRecord }
	end
	ShopRentalService.expireLeases(false)
end

function ShopRentalService.getLeases(): { [string]: LeaseRecord }
	return leases
end

function ShopRentalService.isVacant(roomId: string): boolean
	local lease = leases[roomId]
	if not lease then
		return true
	end
	return lease.expiresAt <= os.time()
end

function ShopRentalService.countPlayerLeasesInBuilding(userId: number, building: ShopRentalConfig.BuildingCode): number
	local count = 0
	for roomId, lease in leases do
		if lease.ownerId == userId and lease.expiresAt > os.time() then
			local b = ShopRentalConfig.getBuildingFromRoomId(roomId)
			if b == building then
				count += 1
			end
		end
	end
	return count
end

function ShopRentalService.buildDirectoryEntry(roomId: string): { [string]: any }
	local lease = leases[roomId]
	local vacant = ShopRentalService.isVacant(roomId)
	local building = ShopRentalConfig.getBuildingFromRoomId(roomId) or "UP"
	local floor = tonumber(string.match(roomId, "%-(%d+)%-")) or 0
	return {
		roomId = roomId,
		building = building,
		floor = floor,
		zone = ShopRentalConfig.getZone(building :: ShopRentalConfig.BuildingCode, floor),
		vacant = vacant,
		shopName = if vacant then "FOR RENT" else (lease and lease.shopName or "OPEN"),
		ownerId = if vacant then nil else (lease and lease.ownerId),
		expiresAt = if vacant then nil else (lease and lease.expiresAt),
	}
end

function ShopRentalService.getDirectory(): { any }
	local out: { any } = {}
	for _, roomId in ShopRentalConfig.listAllRoomIds() do
		table.insert(out, ShopRentalService.buildDirectoryEntry(roomId))
	end
	return out
end

function ShopRentalService.findNearestVacant(fromPosition: Vector3): string?
	local bestId: string? = nil
	local bestDist = math.huge
	for roomId in unitByRoomId do
		if ShopRentalService.isVacant(roomId) then
			local unit = unitByRoomId[roomId]
			local primary = unit.PrimaryPart or unit:FindFirstChildWhichIsA("BasePart")
			if primary then
				local dist = (primary.Position - fromPosition).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestId = roomId
				end
			end
		end
	end
	return bestId
end

function ShopRentalService.expireLeases(fireEvent: boolean)
	local now = os.time()
	local changed = false
	for roomId, lease in leases do
		if lease.expiresAt <= now then
			leases[roomId] = nil
			ShopRentalService.syncUnitSign(roomId)
			changed = true
			-- TODO Phase B: return listed inventory to owner
		end
	end
	if changed and fireEvent and leaseChanged then
		leaseChanged:FireAllClients({ type = "expire" })
	end
end

local function saveLeases()
	dataStoreUpdate(leaseStore, "all_leases", function(_old)
		return leases
	end)
end

local function recordReceiptId(purchaseId: string): boolean
	local ok, already = dataStoreUpdate(receiptStore, purchaseId, function(old)
		if old then
			return old
		end
		return { at = os.time() }
	end)
	return ok and already ~= nil
end

local function wasReceiptProcessed(purchaseId: string): boolean
	if receiptStore == nil then
		return false
	end
	local ok, data = pcall(function()
		return receiptStore:GetAsync(purchaseId)
	end)
	return ok and data ~= nil
end

local function grantCompensationCredit(userId: number, amount: number, reason: string)
	dataStoreUpdate(compensationStore, tostring(userId), function(old)
		local row = if typeof(old) == "table" then old else { total = 0, entries = {} }
		row.total = (row.total or 0) + amount
		table.insert(row.entries, { amount = amount, reason = reason, at = os.time() })
		return row
	end)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		player:SetAttribute("ShopRentCompensation", amount)
	end
end

function ShopRentalService.beginRent(player: Player, roomId: string, tierIndex: number): (boolean, string)
	if not RateLimiter:TryConsume(player, "RentShop", RATE_RENT) then
		return false, "กรุณารอสักครู่แล้วลองใหม่"
	end
	if typeof(roomId) ~= "string" or unitByRoomId[roomId] == nil then
		return false, "ไม่พบห้องร้านนี้"
	end
	local tier = ShopRentalConfig.RentTiers[tierIndex]
	if not tier then
		return false, "แพ็กเกจเช่าไม่ถูกต้อง"
	end
	if not ShopRentalService.isVacant(roomId) then
		return false, "ห้องนี้มีผู้เช่าแล้ว"
	end
	local building = ShopRentalConfig.getBuildingFromRoomId(roomId)
	if building and ShopRentalService.countPlayerLeasesInBuilding(player.UserId, building) >= ShopRentalConfig.MaxLeasesPerBuilding then
		return false, "คุณเช่าร้านในอาคารนี้ครบแล้ว (1 ร้าน/อาคาร)"
	end

	local productId = PrismCatalogAssets.getProductId(tier.productKey)
	if productId <= 0 then
		return false, "product ยังไม่ตั้งค่า — สร้าง Developer Product บน dashboard แล้วกรอกใน CatalogSecrets"
	end

	pendingRent[player.UserId] = {
		roomId = roomId,
		tierIndex = tierIndex,
		nonce = tostring(os.clock()),
	}
	MarketplaceService:PromptProductPurchase(player, productId)
	return true, "เปิดหน้าชำระ Robux"
end

function ShopRentalService.tryProcessReceipt(receipt: any): Enum.ProductPurchaseDecision?
	local tierIndex: number? = nil
	for i, tier in ShopRentalConfig.RentTiers do
		if PrismCatalogAssets.getProductId(tier.productKey) == receipt.ProductId then
			tierIndex = i
			break
		end
	end
	if not tierIndex then
		return nil
	end

	if wasReceiptProcessed(receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local pending = pendingRent[receipt.PlayerId]
	if not pending or pending.tierIndex ~= tierIndex then
		warn(string.format("[SHOP] ProcessReceipt: no pending rent userId=%d product=%d", receipt.PlayerId, receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local roomId = pending.roomId
	local tier = ShopRentalConfig.RentTiers[tierIndex]

	if not ShopRentalService.isVacant(roomId) then
		grantCompensationCredit(receipt.PlayerId, tier.robuxHint, "room_taken:" .. roomId)
		pendingRent[receipt.PlayerId] = nil
		recordReceiptId(receipt.PurchaseId)
		player:SetAttribute("ShopRentMessage", "ห้องถูกเช่าไปแล้ว — ได้รับเครดิตชดเชยในเกม")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local now = os.time()
	local zone = ShopRentalConfig.getZone(ShopRentalConfig.getBuildingFromRoomId(roomId) :: ShopRentalConfig.BuildingCode, tonumber(string.match(roomId, "%-(%d+)%-")) or 1)
	leases[roomId] = {
		ownerId = receipt.PlayerId,
		shopName = "",
		zone = zone,
		rentedAt = now,
		expiresAt = now + tier.days * 86400,
		tierIndex = tierIndex,
		purchaseId = receipt.PurchaseId,
	}
	saveLeases()
	recordReceiptId(receipt.PurchaseId)
	pendingRent[receipt.PlayerId] = nil
	ShopRentalService.syncUnitSign(roomId)
	if leaseChanged then
		leaseChanged:FireClient(player, { type = "rented", roomId = roomId })
	end
	player:SetAttribute("ShopRentMessage", "เช่าร้าน " .. roomId .. " สำเร็จ!")
	print(string.format("[SHOP] lease granted %s owner=%d tier=%d", roomId, receipt.PlayerId, tierIndex))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopRentalService.setShopName(player: Player, roomId: string, rawName: string): (boolean, string)
	if not RateLimiter:TryConsume(player, "SetShopName", RATE_NAME) then
		return false, "กรุณารอสักครู่แล้วลองใหม่"
	end
	local lease = leases[roomId]
	if not lease or lease.ownerId ~= player.UserId or lease.expiresAt <= os.time() then
		return false, "คุณไม่ใช่เจ้าของร้านนี้"
	end
	if typeof(rawName) ~= "string" or #rawName == 0 or #rawName > 40 then
		return false, "ชื่อร้านไม่ถูกต้อง"
	end
	local filtered: string
	local ok, err = pcall(function()
		local result = TextService:FilterStringAsync(rawName, player.UserId)
		filtered = result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return false, "กรองชื่อไม่สำเร็จ"
	end
	lease.shopName = filtered
	saveLeases()
	ShopRentalService.syncUnitSign(roomId)
	if leaseChanged then
		leaseChanged:FireClient(player, { type = "rename", roomId = roomId, shopName = filtered })
	end
	return true, filtered
end

function ShopRentalService.handleGetDirectory(player: Player): { ok: boolean, rooms: { any }?, message: string? }
	if not RateLimiter:TryConsume(player, "GetShopDirectory", RATE_DIRECTORY) then
		return { ok = false, message = "กรุณารอสักครู่" }
	end
	return { ok = true, rooms = ShopRentalService.getDirectory() }
end

function ShopRentalService.startMaintenanceLoop()
	task.spawn(function()
		while true do
			task.wait(600)
			ShopRentalService.expireLeases(true)
			saveLeases()
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	pendingRent[player.UserId] = nil
	RateLimiter:ClearPlayer(player)
end)

return ShopRentalService
