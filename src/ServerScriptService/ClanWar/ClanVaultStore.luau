--!strict
--[[
	ClanVaultStore (P5) — DataStore wrapper for clan vault balances
]]
local DataStoreService = game:GetService("DataStoreService")

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaVault_v1")
end)

export type ClanVaultData = {
	balance: number,
	npcGuardSlots: number,
	barrierLevel: number,
	lastWithdrawnBy: string,
	lastUpdatedAt: number,
}

local memory: { [string]: ClanVaultData } = {}

local function defaultVault(): ClanVaultData
	return {
		balance = 0,
		npcGuardSlots = 0,
		barrierLevel = 1,
		lastWithdrawnBy = "",
		lastUpdatedAt = os.time(),
	}
end

local ClanVaultStore = {}

function ClanVaultStore.get(clanId: string): ClanVaultData
	if memory[clanId] then
		return memory[clanId]
	end
	if ds then
		local ok, result = pcall(function()
			return (ds :: GlobalDataStore):GetAsync("vault_" .. clanId)
		end)
		if ok and typeof(result) == "table" then
			local data = result :: ClanVaultData
			memory[clanId] = data
			return data
		end
	end
	local data = defaultVault()
	memory[clanId] = data
	return data
end

function ClanVaultStore.save(clanId: string, data: ClanVaultData)
	memory[clanId] = data
	if not ds then
		return
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):SetAsync("vault_" .. clanId, data)
	end)
	if not ok then
		warn("[ClanVaultStore] save failed:", err)
	end
end

function ClanVaultStore.deposit(clanId: string, amount: number)
	local vault = ClanVaultStore.get(clanId)
	vault.balance += amount
	vault.lastUpdatedAt = os.time()
	ClanVaultStore.save(clanId, vault)
end

return ClanVaultStore
