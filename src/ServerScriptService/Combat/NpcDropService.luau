--!strict
--[[
	NpcDropService — roll/grant NPC material drops into PlayerItemStore
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NpcDropConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NpcDropConfig"))

local NpcDropService = {}

export type DropResult = {
	dropType: "item" | "pet",
	itemId: string,
	qty: number,
	petId: string?,
}

local function getItemStore()
	return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))
end

local function getPetService()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("PetService"))
end

local function getProfile(npcId: number): NpcDropConfig.NpcDropProfile
	local profile = NpcDropConfig.Profiles[npcId]
	if profile then
		return profile
	end
	return NpcDropConfig.DefaultProfile
end

function NpcDropService.rollDrops(npcId: number): { DropResult }
	local profile = getProfile(npcId)
	local results: { DropResult } = {}

	for _, entry in profile.dropTable do
		if math.random() <= entry.chance then
			local entryType = entry.dropType or "item"
			if entryType == "pet" then
				table.insert(results, {
					dropType = "pet",
					itemId = entry.petId or entry.itemId,
					qty = 1,
					petId = entry.petId,
				})
			else
				local qty = math.random(entry.minQty, entry.maxQty)
				table.insert(results, {
					dropType = "item",
					itemId = entry.itemId,
					qty = qty,
					petId = nil,
				})
			end
		end
	end

	return results
end

function NpcDropService.grantDrops(player: Player, npcId: number): { DropResult }
	local drops = NpcDropService.rollDrops(npcId)
	if #drops == 0 then
		return drops
	end

	local itemStore = getItemStore()
	local petService = getPetService()

	for _, drop in drops do
		if drop.dropType == "pet" and drop.petId then
			local ok, msg = petService.grantPet(player, drop.petId)
			if not ok and msg ~= "มี pet นี้แล้ว" then
				warn("[NpcDropService] grantPet failed:", msg)
			end
		else
			itemStore.addItem(player.UserId, drop.itemId, drop.qty)
		end
	end

	local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
	if remotes then
		local ev = remotes:FindFirstChild("ItemDropped") :: RemoteEvent?
		if ev then
			ev:FireClient(player, drops)
		end
	end

	return drops
end

function NpcDropService.getBaseXP(npcId: number): number
	return getProfile(npcId).baseXP
end

return NpcDropService
