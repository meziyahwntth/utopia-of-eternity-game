--!strict
--[[
	BountyService (P5+) — post/claim/expire player bounties (session in-memory)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MercenaryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MercenaryConfig"))
local CurrencyService = require(script.Parent.Parent:WaitForChild("Commerce"):WaitForChild("CurrencyService"))

export type Bounty = {
	bountyId: string,
	posterId: number,
	targetId: number,
	amount: number,
	postedAt: number,
	expiresAt: number,
	claimed: boolean,
	claimedBy: number?,
}

export type PublicBounty = {
	bountyId: string,
	targetId: number,
	amount: number,
	postedAt: number,
	expiresAt: number,
}

local bounties: { [string]: Bounty } = {}
local bountyCounter = 0

local BountyService = {}

local function makeBountyId(): string
	bountyCounter += 1
	return string.format("bounty_%d_%d", os.time(), bountyCounter)
end

local function getRoot(char: Model): BasePart?
	local root = char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function BountyService.post(poster: Player, targetId: number, amount: number): (boolean, string)
	if poster.UserId == targetId then
		return false, "ไม่สามารถโพสต์ bounty บนตัวเองได้"
	end
	if amount < MercenaryConfig.BountyMinAmount or amount > MercenaryConfig.BountyMaxAmount then
		return false,
			string.format("จำนวน bounty ต้อง %d–%d", MercenaryConfig.BountyMinAmount, MercenaryConfig.BountyMaxAmount)
	end

	local count = 0
	for _, b in bounties do
		if b.targetId == targetId and not b.claimed then
			count += 1
		end
	end
	if count >= MercenaryConfig.MaxBountiesPerPlayer then
		return false, "มี bounty บนผู้เล่นคนนี้เต็มแล้ว"
	end

	local balance = CurrencyService.getBalance(poster.UserId)
	if balance < amount then
		return false, string.format("credits ไม่พอ (มี %d, ต้องการ %d)", balance, amount)
	end

	local deducted, deductErr = CurrencyService.deductCredits(poster.UserId, amount)
	if not deducted then
		return false, "ตัด credits ล้มเหลว: " .. tostring(deductErr)
	end

	local id = makeBountyId()
	local expirySecs = MercenaryConfig.BountyExpiryDays * 86400
	bounties[id] = {
		bountyId = id,
		posterId = poster.UserId,
		targetId = targetId,
		amount = amount,
		postedAt = os.time(),
		expiresAt = os.time() + expirySecs,
		claimed = false,
		claimedBy = nil,
	}

	task.delay(expirySecs, function()
		local bounty = bounties[id]
		if bounty and not bounty.claimed then
			bounties[id] = nil
			local refunded = CurrencyService.addCredits(bounty.posterId, bounty.amount)
			if not refunded then
				warn("[BountyService] refund failed for poster", bounty.posterId)
			end
		end
	end)

	return true, id
end

function BountyService.onTargetKilled(killerId: number, targetId: number)
	local killer = Players:GetPlayerByUserId(killerId)
	local target = Players:GetPlayerByUserId(targetId)
	if not killer or not target then
		return
	end

	local killerChar = killer.Character
	local targetChar = target.Character
	if killerChar and targetChar then
		local killerRoot = getRoot(killerChar)
		local targetRoot = getRoot(targetChar)
		if killerRoot and targetRoot then
			local dist = (killerRoot.Position - targetRoot.Position).Magnitude
			if dist > MercenaryConfig.BountyKillProximity then
				return
			end
		end
	end

	local now = os.time()
	local totalReward = 0
	for id, bounty in bounties do
		if bounty.targetId == targetId and not bounty.claimed and now < bounty.expiresAt then
			bounty.claimed = true
			bounty.claimedBy = killerId
			totalReward += bounty.amount
			bounties[id] = bounty
		end
	end

	if totalReward > 0 then
		CurrencyService.addCredits(killerId, totalReward)
		print(string.format("[Bounty] %s claimed %d credits on target %d", killer.Name, totalReward, targetId))
	end
end

function BountyService.getActiveBounties(): { PublicBounty }
	local result: { PublicBounty } = {}
	local now = os.time()
	for _, b in bounties do
		if not b.claimed and now < b.expiresAt then
			table.insert(result, {
				bountyId = b.bountyId,
				targetId = b.targetId,
				amount = b.amount,
				postedAt = b.postedAt,
				expiresAt = b.expiresAt,
			})
		end
	end
	return result
end

function BountyService.getBountiesOnTarget(targetId: number): number
	local total = 0
	local now = os.time()
	for _, b in bounties do
		if b.targetId == targetId and not b.claimed and now < b.expiresAt then
			total += b.amount
		end
	end
	return total
end

return BountyService
