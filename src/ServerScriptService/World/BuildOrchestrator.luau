--!strict
--[[
	BuildOrchestrator — จุด "เดียว" ที่ห่อ pcall และ set WorldBuildState
	(Blueprint §4.2 — docs/MAP-CHARACTER-REBUILD-BLUEPRINT.md)

	แก้ root cause A+B: ทุก place ได้ contract ready/failed เท่ากันอัตโนมัติ
	ไม่ว่า builder จะสำเร็จ, skip, หรือ throw กลางทาง — ไม่มีทางที่
	WorldBuildState ค้าง "pending" จน waiter block เต็ม timeout อีก

	Migration (Blueprint §7):
	  - ขั้น 1: ไฟล์นี้ additive — ยังไม่ถูกเรียกจาก GameBootstrap
	  - ขั้น 3: GameBootstrap เรียก BuildOrchestrator:Run() แทน WorldBootstrap:BuildCurrent()
	  - รองรับ legacy builder (คืน nil) ระหว่างแปลงทีละตัว — ดู normalize()
]]

local World = script.Parent
local WorldBuilderTypes = require(World:WaitForChild("WorldBuilderTypes"))
local WorldBuildState = require(World:WaitForChild("WorldBuildState"))
local WorldPlaceGuard = require(World:WaitForChild("WorldPlaceGuard"))
local WorldBootstrap = require(World:WaitForChild("WorldBootstrap"))

type BuildResult = WorldBuilderTypes.BuildResult
type BuildContext = WorldBuilderTypes.BuildContext

local BuildOrchestrator = {}

local _hasRun = false

local function makeContext(placeKey: string): BuildContext
	return { placeKey = placeKey }
end

-- Normalize ผลจาก builder:
--   - BuildResult table → ใช้ตรงๆ
--   - nil (legacy builder ที่ยังไม่ถูกแปลงตาม Blueprint §4.1) → ถือว่าสำเร็จ
--     เพราะไม่มี error หลุดจาก pcall (พฤติกรรมเดิมของ builder ที่คืน void)
local function normalize(raw: any, placeKey: string): BuildResult
	if typeof(raw) == "table" and typeof((raw :: any).ok) == "boolean" then
		return raw :: BuildResult
	end
	warn(string.format(
		"[BuildOrchestrator] %s builder returned no BuildResult (legacy) — treating as success",
		placeKey
	))
	return WorldBuilderTypes.success(nil)
end

function BuildOrchestrator:Run(): BuildResult
	if _hasRun then
		warn("[BuildOrchestrator] Run() called twice — ignored (idempotent)")
		return WorldBuilderTypes.skip("already ran")
	end
	_hasRun = true

	local placeKey = WorldPlaceGuard:GetCurrentPlaceKey()
	local builder = (WorldBootstrap.BUILDERS :: any)[placeKey]
	if not builder then
		local reason = "no builder for placeKey: " .. tostring(placeKey)
		WorldBuildState.markFailed(reason)
		return WorldBuilderTypes.fail(reason)
	end

	local pcallOk, rawResult = pcall(function()
		return builder:Build(makeContext(placeKey))
	end)

	if not pcallOk then
		local reason = tostring(rawResult)
		warn(string.format("[BuildOrchestrator] %s build FAILED: %s", placeKey, reason))
		WorldBuildState.markFailed(reason)
		return WorldBuilderTypes.fail(reason)
	end

	local result = normalize(rawResult, placeKey)

	-- Legacy builder อาจ set state เองไปแล้ว (เช่น EternityCity เดิมเรียก
	-- markReady/markFailed ใน :Build()) — เคารพสถานะนั้น ไม่ทับ
	if WorldBuildState.getStatus() ~= "pending" then
		return result
	end

	if result.ok then
		-- สำเร็จ หรือ skipped (ไม่มีอะไรต้องสร้าง = พร้อม)
		print(string.format(
			"[BuildOrchestrator] %s → ready (skipped=%s)",
			placeKey,
			tostring(result.skipped)
		))
		WorldBuildState.markReady()
	else
		warn(string.format(
			"[BuildOrchestrator] %s → failed: %s",
			placeKey,
			result.reason or "unknown"
		))
		WorldBuildState.markFailed(result.reason)
	end

	return result
end

-- สำหรับ test/hot-reload คู่กับ WorldBuildState.reset() (Studio เท่านั้น)
function BuildOrchestrator:ResetForTest()
	_hasRun = false
end

return BuildOrchestrator
