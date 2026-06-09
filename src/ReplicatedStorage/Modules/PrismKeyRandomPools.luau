--!strict
--[[
	Prism Key random tiers — ดอกที่ 6+ สุ่มหมายเลขตามช่วง
	ปลด tier ถัดไปเมื่อ "รับ" กุญแจ milestone 25 / 40 / 60 / 80
]]

export type RandomTier = {
	id: string,
	minKey: number,
	maxKey: number,
	unlockAfterOwning: number?, -- ต้องมีกุญแจหมายเลขนี้ก่อนเข้า pool นี้
}

local PrismKeyRandomPools = {}

PrismKeyRandomPools.FIXED_KEY_COUNT = 5 -- ดอก 1–5 ได้หมายเลข 1,2,3,4,5 ตามลำดับ

PrismKeyRandomPools.Tiers = {
	{ id = "bloom_6_25", minKey = 6, maxKey = 25, unlockAfterOwning = nil },
	{ id = "bloom_26_40", minKey = 26, maxKey = 40, unlockAfterOwning = 25 },
	{ id = "bloom_41_60", minKey = 41, maxKey = 60, unlockAfterOwning = 40 },
	{ id = "bloom_61_80", minKey = 61, maxKey = 80, unlockAfterOwning = 60 },
	{ id = "bloom_81_99", minKey = 81, maxKey = 99, unlockAfterOwning = 80 },
}

PrismKeyRandomPools.TradeCost = 3 -- แลก 3 ดอก → 1 หมายเลขที่เลือก

PrismKeyRandomPools.GhostNpc = {
	ZoneIndices = { 3, 4, 5 },
	DwellSecondsPerZone = 600, -- 10 นาที
	TradeTimeoutSeconds = 60, -- 1 นาที ต้องแลกให้เสร็จ
	ComplaintText = "คนอะไร ทำอะไรก็เชื่องช้างุ่มง่าม น่ารำคาญ",
	DisplayName = "วิญญาณแลกกุญแจ",
}

function PrismKeyRandomPools.getFixedKeyNumberForEarnOrder(earnOrder: number): number?
	if earnOrder >= 1 and earnOrder <= PrismKeyRandomPools.FIXED_KEY_COUNT then
		return earnOrder
	end
	return nil
end

function PrismKeyRandomPools.getActiveTier(owned: { [number]: boolean }): RandomTier
	if not owned[25] then
		return PrismKeyRandomPools.Tiers[1]
	end
	if not owned[40] then
		return PrismKeyRandomPools.Tiers[2]
	end
	if not owned[60] then
		return PrismKeyRandomPools.Tiers[3]
	end
	if not owned[80] then
		return PrismKeyRandomPools.Tiers[4]
	end
	return PrismKeyRandomPools.Tiers[5]
end

function PrismKeyRandomPools.buildPoolCandidates(tier: RandomTier, owned: { [number]: boolean }): { number }
	local list: { number } = {}
	for n = tier.minKey, tier.maxKey do
		if not owned[n] then
			table.insert(list, n)
		end
	end
	return list
end

function PrismKeyRandomPools.rollRandomKeyNumber(ownedSet: { [number]: boolean }, rng: Random?): (number?, string?)
	local tier = PrismKeyRandomPools.getActiveTier(ownedSet)
	if not tier then
		return nil, "No active tier"
	end

	local candidates = PrismKeyRandomPools.buildPoolCandidates(tier, ownedSet)
	if #candidates == 0 then
		for _, nextTier in PrismKeyRandomPools.Tiers do
			if nextTier.minKey > tier.maxKey then
				candidates = PrismKeyRandomPools.buildPoolCandidates(nextTier, ownedSet)
				if #candidates > 0 then
					tier = nextTier
					break
				end
			end
		end
	end

	if #candidates == 0 then
		return nil, "All keys in range collected"
	end

	local randomGen = rng or Random.new()
	local idx = randomGen:NextInteger(1, #candidates)
	return candidates[idx], nil
end

function PrismKeyRandomPools.isValidKeyNumber(n: number): boolean
	return n >= 1 and n <= 99
end

return PrismKeyRandomPools
