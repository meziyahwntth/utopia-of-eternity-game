--!strict
--[[
	WorldBuildState — Singleton สถานะการ build โลก
	ใช้แทน poll-loop ใน spawn guard เดิม เพื่อป้องกัน:
	  - waitForWorldReady block 60s เมื่อ build fail กลางทาง
	  - VoidGuard spawn stabilizeCharacter ซ้อนกัน (re-entrancy)

	การใช้งาน:
	  Builder เรียก markReady() หรือ markFailed() หลัง build เสร็จ/ล้มเหลว
	  SpawnGuard เรียก waitReady(timeoutSeconds) แทน poll loop
]]

local WorldBuildState = {}

export type BuildStatus = "pending" | "ready" | "failed"

local _status: BuildStatus = "pending"
local _readyBindable = Instance.new("BindableEvent")

-- อ่านสถานะปัจจุบัน
function WorldBuildState.getStatus(): BuildStatus
	return _status
end

-- Builder เรียกเมื่อ build สำเร็จ
function WorldBuildState.markReady()
	if _status == "ready" then
		return
	end
	_status = "ready"
	_readyBindable:Fire(true)
end

-- Builder เรียกเมื่อ build ล้มเหลว (เช่น pcall catch error)
function WorldBuildState.markFailed(reason: string?)
	if _status == "failed" then
		return
	end
	_status = "failed"
	warn(string.format("[WorldBuildState] Build failed: %s", reason or "unknown"))
	_readyBindable:Fire(false) -- unblock waiters — they handle false ด้วย emergency floor
end

-- SpawnGuard เรียกแทน poll loop
-- returns true ถ้า ready, false ถ้า failed หรือ timeout
function WorldBuildState.waitReady(timeoutSeconds: number?): boolean
	local timeout = timeoutSeconds or 60

	-- ถ้า build เสร็จแล้วก่อนเรียก — return ทันที
	if _status == "ready" then
		return true
	end
	if _status == "failed" then
		return false
	end

	-- รอ event (ไม่ poll)
	local result = false
	local connection: RBXScriptConnection
	local thread = coroutine.running()

	connection = _readyBindable.Event:Connect(function(ok: boolean)
		result = ok
		connection:Disconnect()
		task.spawn(thread)
	end)

	-- timeout guard
	task.delay(timeout, function()
		if connection.Connected then
			connection:Disconnect()
			task.spawn(thread)
		end
	end)

	coroutine.yield()
	return result
end

-- Reset สำหรับ test หรือ hot-reload (Studio เท่านั้น)
function WorldBuildState.reset()
	_status = "pending"
	_readyBindable = Instance.new("BindableEvent")
end

return WorldBuildState
