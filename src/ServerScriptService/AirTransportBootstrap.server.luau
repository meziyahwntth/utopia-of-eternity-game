--!strict
-- AirTransportBootstrap (V2 P2) — เริ่มระบบขนส่งทางอากาศ (wire boarding pads)
local ServerScriptService = game:GetService("ServerScriptService")

local AirTransportService = require(ServerScriptService:WaitForChild("World"):WaitForChild("AirTransportService"))
local TravelTicketWallet = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("TravelTicketWallet"))

TravelTicketWallet.init()

task.defer(function()
	AirTransportService.init()
end)
