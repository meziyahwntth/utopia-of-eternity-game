--!strict
local DataStoreService = game:GetService("DataStoreService")

local BanRegistry = {}

local STORE_NAME = "UtopiaBanRegistry_v1"
local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local cache: { [number]: boolean } = {}

export type BanRecord = {
	userId: number,
	reason: string,
	bannedAt: number,
	expiresAt: number?,
	by: string,
}

function BanRegistry:IsBanned(userId: number): boolean
	if cache[userId] then
		return true
	end
	if not store then
		return false
	end
	local ok, record = pcall(function()
		return store:GetAsync(tostring(userId))
	end)
	if ok and record then
		local typed = record :: BanRecord
		if typed.expiresAt and typed.expiresAt <= os.time() then
			self:Unban(userId)
			return false
		end
		cache[userId] = true
		return true
	end
	return false
end

function BanRegistry:GetRecord(userId: number): BanRecord?
	if not store then
		return nil
	end
	local ok, record = pcall(function()
		return store:GetAsync(tostring(userId))
	end)
	if ok then
		return record :: BanRecord?
	end
	return nil
end

function BanRegistry:Ban(userId: number, reason: string, durationSeconds: number?, by: string)
	local record: BanRecord = {
		userId = userId,
		reason = reason,
		bannedAt = os.time(),
		expiresAt = if durationSeconds then os.time() + durationSeconds else nil,
		by = by,
	}
	cache[userId] = true
	if store then
		pcall(function()
			store:SetAsync(tostring(userId), record)
		end)
	end
	return record
end

function BanRegistry:Unban(userId: number)
	cache[userId] = nil
	if store then
		pcall(function()
			store:RemoveAsync(tostring(userId))
		end)
	end
end

function BanRegistry:ClearCache(userId: number)
	cache[userId] = nil
end

return BanRegistry
