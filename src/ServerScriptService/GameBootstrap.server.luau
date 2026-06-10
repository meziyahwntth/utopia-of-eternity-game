--!strict
--[[
	Game bootstrap — boot order ตาม Blueprint §6 (docs/MAP-CHARACTER-REBUILD-BLUEPRINT.md)

	  1. defer spawn ทันที (ก่อนผู้เล่นคนแรก join)
	  2. BridgeBootstrap — โหลด PlaceSecrets เข้า GameConfig
	  3. VoidRecovery.start() — FallenParts + void watch เปิดก่อน ปลอดภัยสุด
	  4. BuildOrchestrator:Run() — pcall builder → markReady / markFailed เสมอ
	  5. SpawnService.start() — รอ ready แล้วค่อยปล่อย character
	     (failed/timeout → emergency floor → ปล่อย — ไม่มีทางตกเหว/ค้าง)

	ทุกขั้น always-on ทั้ง Studio และ cloud — ไม่ gate ด้วย IsStudio() อีก
]]
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ขั้น 1: กัน default spawn ก่อนโลกพร้อม — ต้องทำก่อน yield ใดๆ
Players.CharacterAutoLoads = false

require(ServerScriptService:WaitForChild("BridgeBootstrap")):Apply()

local World = ServerScriptService:WaitForChild("World")
local VoidRecovery = require(World:WaitForChild("VoidRecovery"))
local BuildOrchestrator = require(World:WaitForChild("BuildOrchestrator"))
local SpawnService = require(World:WaitForChild("SpawnService"))
local WorldPlaceGuard = require(World:WaitForChild("WorldPlaceGuard"))

print("[Utopia] GameBootstrap — PlaceId=", game.PlaceId, "placeKey=", WorldPlaceGuard:GetCurrentPlaceKey())

VoidRecovery.start()
BuildOrchestrator:Run()
SpawnService.start({ deferUntilReady = true })
