--!strict
--[[
	NpcDropService — roll/grant NPC material drops into PlayerItemStore
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NpcDropConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NpcDropConfig"))

local NpcDropService = {}

export type DropResult = {
	itemId: string,
	qty: number,
}

local function getItemStore()
	return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))
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
			local qty = math.random(entry.minQty, entry.maxQty)
			table.insert(results, { itemId = entry.itemId, qty = qty })
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
	for _, drop in drops do
		itemStore.addItem(player.UserId, drop.itemId, drop.qty)
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
