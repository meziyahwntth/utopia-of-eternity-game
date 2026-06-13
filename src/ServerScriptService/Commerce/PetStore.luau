--!strict
--[[
	PetStore (Backlog B) — DataStore owned pets + active pet per player
]]
local DataStoreService = game:GetService("DataStoreService")

export type PlayerPetData = {
	ownedPets: { string },
	activePetId: string?,
}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaPet_v1")
end)

local memory: { [number]: PlayerPetData } = {}

local function defaultData(): PlayerPetData
	return { ownedPets = {}, activePetId = nil }
end

local function cloneData(data: PlayerPetData): PlayerPetData
	return {
		ownedPets = table.clone(data.ownedPets),
		activePetId = data.activePetId,
	}
end

local PetStore = {}

function PetStore.get(userId: number): PlayerPetData
	if memory[userId] then
		return cloneData(memory[userId])
	end
	if not ds then
		return defaultData()
	end
	local ok, result = pcall(function()
		return (ds :: GlobalDataStore):GetAsync("pet_" .. tostring(userId))
	end)
	if ok and typeof(result) == "table" then
		local data = result :: PlayerPetData
		memory[userId] = cloneData(data)
		return cloneData(data)
	end
	return defaultData()
end

function PetStore.save(userId: number, data: PlayerPetData)
	memory[userId] = cloneData(data)
	if not ds then
		return
	end
	local ok, err = pcall(function()
		(ds :: GlobalDataStore):SetAsync("pet_" .. tostring(userId), cloneData(data))
	end)
	if not ok then
		warn("[PetStore] save failed:", err)
	end
end

function PetStore.addPet(userId: number, petId: string): boolean
	local data = PetStore.get(userId)
	for _, id in data.ownedPets do
		if id == petId then
			return false
		end
	end
	table.insert(data.ownedPets, petId)
	PetStore.save(userId, data)
	return true
end

function PetStore.setActive(userId: number, petId: string?): boolean
	local data = PetStore.get(userId)
	if petId then
		local owned = false
		for _, id in data.ownedPets do
			if id == petId then
				owned = true
				break
			end
		end
		if not owned then
			return false
		end
	end
	data.activePetId = petId
	PetStore.save(userId, data)
	return true
end

return PetStore
