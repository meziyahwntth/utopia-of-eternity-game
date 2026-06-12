--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ShopRentalService = require(script.Parent.ShopRentalService)
local ShopRentalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopRentalConfig"))

local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local getDirectory = remotes:WaitForChild("GetShopDirectory") :: RemoteFunction
local rentShop = remotes:WaitForChild("RentShop") :: RemoteFunction
local setShopName = remotes:WaitForChild("SetShopName") :: RemoteFunction
local leaseChanged = remotes:WaitForChild("ShopLeaseChanged") :: RemoteEvent
local openPromoter = remotes:WaitForChild("OpenShopPromoterDialog") :: RemoteEvent

ShopRentalService.setLeaseChangedEvent(leaseChanged)

local function waitForCity(): Instance?
	local deadline = os.clock() + 30
	while os.clock() < deadline do
		local city = workspace:FindFirstChild("UtopiaEternityCity")
		if city then
			return city
		end
		task.wait(0.25)
	end
	return nil
end

task.defer(function()
	ShopRentalService.loadLeases()
	local city = waitForCity()
	if city then
		-- shop units ถูกสร้างหลัง city model โผล่ใน workspace — retry จนครบหรือหมดเวลา 30 วิ
		local expected = #ShopRentalConfig.listAllRoomIds()
		local deadline = os.clock() + 30
		while ShopRentalService.scanUnits(city) < expected and os.clock() < deadline do
			task.wait(1)
		end
		ShopRentalService.syncAllSigns()
	end
	ShopRentalService.startMaintenanceLoop()
	print("[SHOP] ShopRentalService online")
end)

getDirectory.OnServerInvoke = function(player: Player)
	return ShopRentalService.handleGetDirectory(player)
end

rentShop.OnServerInvoke = function(player: Player, roomId: any, tierIndex: any)
	if typeof(roomId) ~= "string" then
		return { ok = false, message = "ห้องไม่ถูกต้อง" }
	end
	if typeof(tierIndex) ~= "number" then
		return { ok = false, message = "แพ็กเกจไม่ถูกต้อง" }
	end
	local ok, message = ShopRentalService.beginRent(player, roomId, tierIndex)
	return { ok = ok, message = message }
end

setShopName.OnServerInvoke = function(player: Player, roomId: any, name: any)
	if typeof(roomId) ~= "string" or typeof(name) ~= "string" then
		return { ok = false, message = "ข้อมูลไม่ถูกต้อง" }
	end
	local ok, message = ShopRentalService.setShopName(player, roomId, name)
	return { ok = ok, message = message }
end

openPromoter.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local nearest = if hrp and hrp:IsA("BasePart") then ShopRentalService.findNearestVacant(hrp.Position) else nil
	player:SetAttribute("ShopPromoterNearestVacant", nearest or "")
end)
