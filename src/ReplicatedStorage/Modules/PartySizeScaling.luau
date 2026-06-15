--!strict
--[[
	PartySizeScaling — centralized party-size formula for solo + group play.

	Principles (see docs/PARTY-SIZE-SCALING-BLUEPRINT.md):
	- Solo-viable: count=1 → hpMult=1.00, rewardMult=1.00 (full baseline reward; slower but completable).
	- Party speed, not gate: HP scales up with headcount so combined DPS keeps time similar; more hands clear faster.
	- Per-capita fair: solo keeps full base reward; party gets a small per-player bonus (RewardPerExtra), not a penalty for playing alone.
	- Enemy damage stays flat by default (DamagePerExtra=0) so solo is not overwhelmed — fewer spawns handle the rest.

	Replace ad-hoc `baseHp + hpPerPlayer * n` with scaleHp / scaleReward everywhere.
]]

local Players = game:GetService("Players")

-- Config — tune in one place
local MaxPartySize = 8
local HpPerExtra = 0.6 -- 1p=1.00, 2p=1.60, 3p=2.20, 4p=2.80 …
local RewardPerExtra = 0.10 -- 1p=1.00, 2p=1.10, 3p=1.20 … (light social bonus, per-capita fair)
local DamagePerExtra = 0.0 -- default: do not scale enemy damage (solo safety)

export type ScaleResult = {
	hpMult: number,
	rewardMult: number,
	count: number,
}

local PartySizeScaling = {}

local function clampCount(raw: number): number
	if raw ~= raw or raw < 1 then
		return 1
	end
	return math.clamp(math.floor(raw), 1, MaxPartySize)
end

--[[
	Returns multipliers for a party of `count` (clamped 1..MaxPartySize).
	hpMult / rewardMult use linear per-extra-player curves from config above.
]]
function PartySizeScaling.compute(count: number): ScaleResult
	local clamped = clampCount(count)
	local extras = clamped - 1
	return {
		hpMult = 1 + extras * HpPerExtra,
		rewardMult = 1 + extras * RewardPerExtra,
		count = clamped,
	}
end

function PartySizeScaling.scaleHp(baseHp: number, count: number): number
	local scaled = PartySizeScaling.compute(count)
	return math.floor(baseHp * scaled.hpMult)
end

function PartySizeScaling.scaleReward(baseReward: number, count: number): number
	local scaled = PartySizeScaling.compute(count)
	return math.floor(baseReward * scaled.rewardMult)
end

--[[
	Death Valley and other dedicated places: everyone in the server is in-zone.
]]
function PartySizeScaling.countInPlace(): number
	return clampCount(#Players:GetPlayers())
end

--[[
	Dungeon instances: pass the participant set for that instance only.
]]
function PartySizeScaling.countInSet(set: { [number]: boolean }): number
	local n = 0
	for _, inSet in set do
		if inSet then
			n += 1
		end
	end
	return clampCount(n)
end

return PartySizeScaling
