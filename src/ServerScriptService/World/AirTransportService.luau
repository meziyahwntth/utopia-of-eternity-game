--!strict
--[[
	AirTransportService (V2 P2) — boarding + ค่าโดยสาร + เดินทาง
	  • wire ProximityPrompt บนแท่น "AirTransportDeparturePad" ในเมืองต้นทาง
	  • จ่ายด้วยกุญแจ (หักดอกสูงสุด) หรือ robux (PromptProductPurchase)
	  • เส้นทาง air = TeleportService ตรง; hyperspace จัดการโดย HellboundTerminalService (ไม่ผ่านที่นี่)

	server-authoritative: client แค่ trigger prompt, server ตัดสิน/หักค่าโดยสารทั้งหมด
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local AirTransportConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AirTransportConfig"))
local TravelTicketWallet = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("TravelTicketWallet"))
local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local AirTransportService = {}

local pendingRobux: { [number]: string } = {}

-- จ่ายด้วยตั๋วโดยสาร (TravelTicket — ไม่กระทบ progression/level)
function AirTransportService.payFareTickets(player: Player, routeId: string): (boolean, string)
	local route = AirTransportConfig.Routes[routeId]
	if not route then
		return false, "ไม่พบเส้นทาง"
	end
	if route.fareTickets <= 0 then
		return true, "ฟรี"
	end
	local have = TravelTicketWallet.get(player)
	if not TravelTicketWallet.trySpend(player, route.fareTickets) then
		return false, string.format("ต้องมีตั๋ว %d ใบ (มี %d) — หรือจ่าย robux", route.fareTickets, have)
	end
	return true, string.format("จ่ายค่าโดยสาร %d ตั๋ว", route.fareTickets)
end

-- ทำการเดินทาง (air เท่านั้น — hyperspace จัดการที่ HellboundTerminalService)
function AirTransportService.dispatch(player: Player, route: AirTransportConfig.Route): (boolean, string)
	local teleportData = {
		origin = "AirTransport",
		route = route.id,
		departedAt = os.time(),
	}
	local ok, err = PlaceTeleport:TeleportPlayerWithData(player, (route.toPlaceKey :: any), teleportData)
	if not ok then
		return false, err or "Teleport ล้มเหลว"
	end
	if route.fromPlaceKey == "NeonUtopia" and route.toPlaceKey == "EternityCity" then
		local okRouter, SpawnRouter = pcall(function()
			return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("SpawnRouter"))
		end)
		if okRouter then
			(SpawnRouter :: any).markNeonIntroComplete(player.UserId)
		end
	end
	return true, "ขึ้นเครื่อง \u{2192} " .. route.displayName
end

function AirTransportService.boardWithTickets(player: Player, routeId: string): (boolean, string)
	local route = AirTransportConfig.Routes[routeId]
	if not route then
		return false, "ไม่พบเส้นทาง"
	end
	local paid, payMsg = AirTransportService.payFareTickets(player, routeId)
	if not paid then
		return false, payMsg
	end
	local ok, msg = AirTransportService.dispatch(player, route)
	if not ok then
		-- คืนตั๋วถ้า teleport ล้มเหลวหลังหักแล้ว
		TravelTicketWallet.add(player, route.fareTickets)
		return false, msg
	end
	return true, msg
end

function AirTransportService.boardWithRobux(player: Player, routeId: string): (boolean, string)
	local route = AirTransportConfig.Routes[routeId]
	if not route then
		return false, "ไม่พบเส้นทาง"
	end
	if route.robuxProductId <= 0 then
		return false, "ค่าโดยสาร robux ยังไม่เปิด (รอสร้าง Developer Product)"
	end
	pendingRobux[player.UserId] = routeId
	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(player, route.robuxProductId)
	end)
	if not ok then
		pendingRobux[player.UserId] = nil
		return false, "เปิดหน้าซื้อ robux ไม่สำเร็จ"
	end
	return true, "กำลังเปิดหน้าซื้อ robux..."
end

-- ProcessReceipt hook (เรียกจาก CommerceShopService router)
function AirTransportService.tryProcessReceipt(receipt: any): Enum.ProductPurchaseDecision?
	for _, route in AirTransportConfig.Routes do
		if route.robuxProductId > 0 and receipt.ProductId == route.robuxProductId then
			local player = Players:GetPlayerByUserId(receipt.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			AirTransportService.dispatch(player, route)
			pendingRobux[receipt.PlayerId] = nil
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return nil
end

function AirTransportService.init()
	local placeKey = WorldPlaceGuard:GetCurrentPlaceKey()
	local activeRoute: AirTransportConfig.Route? = nil
	for _, route in AirTransportConfig.Routes do
		if route.fromPlaceKey == placeKey and route.kind == "air" then
			activeRoute = route
			break
		end
	end
	if not activeRoute then
		return
	end
	local routeRef = activeRoute :: AirTransportConfig.Route

	local function wirePad(pad: BasePart)
		if pad:FindFirstChildOfClass("ProximityPrompt") then
			return
		end
		local ticketPrompt = Instance.new("ProximityPrompt")
		ticketPrompt.ActionText = string.format("ขึ้นเครื่อง (%d ตั๋ว)", routeRef.fareTickets)
		ticketPrompt.ObjectText = routeRef.displayName
		ticketPrompt.HoldDuration = 0.6
		ticketPrompt.RequiresLineOfSight = false
		ticketPrompt.MaxActivationDistance = 16
		ticketPrompt.KeyboardKeyCode = Enum.KeyCode.E
		ticketPrompt.Parent = pad
		ticketPrompt.Triggered:Connect(function(player)
			local _, msg = AirTransportService.boardWithTickets(player, routeRef.id)
			player:SetAttribute("AirTransportMsg", msg)
		end)

		local robuxPrompt = Instance.new("ProximityPrompt")
		robuxPrompt.ActionText = string.format("ขึ้นเครื่อง (%d Robux)", routeRef.fareRobux)
		robuxPrompt.ObjectText = routeRef.displayName
		robuxPrompt.HoldDuration = 0.4
		robuxPrompt.RequiresLineOfSight = false
		robuxPrompt.MaxActivationDistance = 16
		robuxPrompt.KeyboardKeyCode = Enum.KeyCode.F
		robuxPrompt.Parent = pad
		robuxPrompt.Triggered:Connect(function(player)
			local _, msg = AirTransportService.boardWithRobux(player, routeRef.id)
			player:SetAttribute("AirTransportMsg", msg)
		end)
	end

	local function scan()
		for _, d in Workspace:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "AirTransportDeparturePad" then
				wirePad(d)
			end
		end
	end

	task.delay(2, scan)
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and d.Name == "AirTransportDeparturePad" then
			task.defer(function()
				wirePad(d)
			end)
		end
	end)

	print("[AirTransport] online — route " .. routeRef.id .. " @ " .. placeKey)
end

function AirTransportService.isNearDeparturePad(player: Player): boolean
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return false
	end

	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "AirTransportDeparturePad" then
			if (hrp.Position - d.Position).Magnitude < 60 then
				return true
			end
		end
	end
	return false
end

function AirTransportService.grantStarterTickets(player: Player, count: number?)
	local amount = count or 5
	TravelTicketWallet.ensureStarter(player)
	if TravelTicketWallet.get(player) < amount then
		player:SetAttribute("TravelTickets", amount)
	end
	print(string.format("[AirTransport] starter tickets (%d) for %s", amount, player.Name))
end

function AirTransportService.boardTransport(player: Player): (boolean, string)
	if not AirTransportService.isNearDeparturePad(player) then
		return false, "ต้องไปที่แท่นออกเดินทางก่อน"
	end
	local placeKey = WorldPlaceGuard:GetCurrentPlaceKey()
	local routeId = "NeonToUtopia"
	for _, route in AirTransportConfig.Routes do
		if route.fromPlaceKey == placeKey and route.kind == "air" then
			routeId = route.id
			break
		end
	end
	return AirTransportService.boardWithTickets(player, routeId)
end

return AirTransportService
