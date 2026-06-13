--!strict
--[[
	CurrencyService (P6) — player credits balance (DataStore + memory fallback)
]]
local DataStoreService = game:GetService("DataStoreService")

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaCredits_v1")
end)

local memory: { [number]: number } = {}

local CurrencyService = {}

function CurrencyService.getBalance(userId: number): number
	if memory[userId] ~= nil then
		return memory[userId]
	end
	if not ds then
		return 0
	end
	local ok, result = pcall(function()
		return (ds :: GlobalDataStore):GetAsync("credits_" .. tostring(userId))
	end)
	if ok and typeof(result) == "number" then
		memory[userId] = result
		return result
	end
	return 0
end

function CurrencyService.addCredits(userId: number, amount: number): boolean
	if amount <= 0 then
		return false
	end
	if not ds then
		memory[userId] = CurrencyService.getBalance(userId) + amount
		return true
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):UpdateAsync("credits_" .. tostring(userId), function(current)
			return (if typeof(current) == "number" then current else 0) + amount
		end)
	end)
	if not ok then
		warn("[CurrencyService] addCredits failed:", err)
	end
	return ok
end

function CurrencyService.deductCredits(userId: number, amount: number): (boolean, string)
	if amount <= 0 then
		return false, "invalid amount"
	end
	if not ds then
		local balance = CurrencyService.getBalance(userId)
		if balance < amount then
			return false, string.format("ยอดไม่พอ (มี %d, ต้อง %d)", balance, amount)
		end
		memory[userId] = balance - amount
		return true, ""
	end

	local success = false
	local msg = ""
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):UpdateAsync("credits_" .. tostring(userId), function(current)
			local balance = if typeof(current) == "number" then current else 0
			if balance < amount then
				msg = string.format("ยอดไม่พอ (มี %d, ต้อง %d)", balance, amount)
				return nil
			end
			success = true
			return balance - amount
		end)
	end)
	if not ok then
		return false, tostring(err)
	end
	if not success then
		return false, if msg ~= "" then msg else "deduct failed"
	end
	return true, ""
end

return CurrencyService
