--!strict
--[[
	TaxDistributionService (P5) — 50/30/20 tax split on territory commerce
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuildService = require(ServerScriptService:WaitForChild("Social"):WaitForChild("GuildService"))
local TerritoryStore = require(script.Parent:WaitForChild("TerritoryStore"))
local ClanVaultStore = require(script.Parent:WaitForChild("ClanVaultStore"))
local ClanWarConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClanWarConfig"))

local TaxDistributionService = {}

function TaxDistributionService.onTaxCollected(zoneId: string, amount: number)
	if amount <= 0 then
		return
	end
	local territory = TerritoryStore.get(zoneId)
	if territory.ownerClanId == "" then
		return
	end

	local split = ClanWarConfig.TaxSplit
	local vaultAmt = math.floor(amount * split.ClanVault)
	local memberAmt = amount * split.MemberShare

	ClanVaultStore.deposit(territory.ownerClanId, vaultAmt)

	local guild = GuildService.getById(territory.ownerClanId)
	if guild then
		local eligibleMembers: { string } = {}
		for uidStr, rank in guild.members do
			if rank == "Leader" or rank == "Officer" or rank == "Veteran" then
				table.insert(eligibleMembers, uidStr)
			end
		end
		if #eligibleMembers > 0 then
			local share = math.floor(memberAmt / #eligibleMembers)
			for _, uidStr in eligibleMembers do
				territory.memberDividends[uidStr] = (territory.memberDividends[uidStr] or 0) + share
			end
		end
	end

	territory.serverBuffActive = true
	territory.lastDistributedAt = os.time()
	TerritoryStore.save(zoneId, territory)
end

function TaxDistributionService.claimDividend(player: Player, zoneId: string): number
	local territory = TerritoryStore.get(zoneId)
	local uid = tostring(player.UserId)
	local amount = territory.memberDividends[uid] or 0
	if amount > 0 then
		territory.memberDividends[uid] = 0
		TerritoryStore.save(zoneId, territory)
	end
	return amount
end

return TaxDistributionService
