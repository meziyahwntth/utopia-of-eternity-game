--!strict
--[[
	Batch security + economy logs for offline AI review (Bridge API / cron analyzer).
	Fails silently if Bridge URL unset — local warn only.
]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local LogExportBridge = {}

local queue: { { kind: string, payload: any, at: number } } = {}

function LogExportBridge:Enqueue(kind: string, payload: any)
	table.insert(queue, { kind = kind, payload = payload, at = os.time() })
	local maxQ = GameConfig.Security.LOG_EXPORT_QUEUE_MAX
	while #queue > maxQ do
		table.remove(queue, 1)
	end
end

function LogExportBridge:GetBatch(limit: number?): { { kind: string, payload: any, at: number } }
	local n = limit or 50
	local batch = {}
	for i = 1, math.min(n, #queue) do
		table.insert(batch, queue[i])
	end
	return batch
end

function LogExportBridge:Flush(): boolean
	local url = GameConfig.Bridge.LOG_ANALYZER_URL
	if url == "" or not HttpService.HttpEnabled then
		return false
	end
	if #queue == 0 then
		return true
	end
	local batch = self:GetBatch(GameConfig.Security.LOG_EXPORT_BATCH_SIZE)
	local body = HttpService:JSONEncode({
		game = GameConfig.GAME_NAME,
		version = GameConfig.VERSION,
		events = batch,
	})
	local headers = {
		["X-Utopia-Security"] = "Phase0.5",
	}
	if GameConfig.Bridge.BRIDGE_KEY ~= "" then
		headers["X-Utopia-Bridge-Key"] = GameConfig.Bridge.BRIDGE_KEY
	end
	local ok = pcall(function()
		HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	if ok then
		for _ = 1, #batch do
			table.remove(queue, 1)
		end
	end
	return ok
end

function LogExportBridge:StartAutoFlush()
	task.spawn(function()
		while true do
			task.wait(GameConfig.Security.LOG_EXPORT_INTERVAL_SECONDS)
			self:Flush()
		end
	end)
end

return LogExportBridge
