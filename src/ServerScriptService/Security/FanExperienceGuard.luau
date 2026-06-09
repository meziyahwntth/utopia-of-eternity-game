--!strict
--[[
	Eternity Forge — fan experience compliance scoring.
	Bridge cron feeds candidate experiences; in-game handles reports.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local FanExperienceGuard = {}

export type FanCandidate = {
	experienceId: number,
	title: string,
	description: string?,
	creatorId: number?,
	visits: number?,
	ccu: number?,
	hasMonetization: boolean?,
	policyFlags: { string }?,
}

export type FanVerdict = "UNLICENSED_OK" | "REVIEW" | "VIOLATION" | "PARTNER_ELIGIBLE"

local LogExportBridge

function FanExperienceGuard:Init(deps: { LogExportBridge: any? })
	LogExportBridge = deps.LogExportBridge
end

local function normalize(text: string): string
	return string.lower(text)
end

function FanExperienceGuard:MatchesIpKeywords(text: string): boolean
	local lowered = normalize(text)
	for _, keyword in GameConfig.FanLicense.IpKeywords do
		if string.find(lowered, normalize(keyword), 1, true) then
			return true
		end
	end
	return false
end

function FanExperienceGuard:HasPolicyViolation(flags: { string }?): boolean
	if not flags then
		return false
	end
	local red = GameConfig.FanLicense.PolicyRedFlags
	for _, flag in flags do
		for _, banned in red do
			if flag == banned then
				return true
			end
		end
	end
	return false
end

function FanExperienceGuard:ScoreCandidate(candidate: FanCandidate): (number, FanVerdict, { string })
	local reasons: { string } = {}
	local score = 0
	local combined = candidate.title .. " " .. (candidate.description or "")

	if self:MatchesIpKeywords(combined) then
		score += 30
		table.insert(reasons, "IP_KEYWORD_MATCH")
	end

	local cfg = GameConfig.Security
	if candidate.ccu and candidate.ccu >= cfg.FAN_REVIEW_CCU_THRESHOLD then
		score += 25
		table.insert(reasons, "HIGH_CCU")
	end
	if candidate.visits and candidate.visits >= cfg.FAN_REVIEW_VISITS_THRESHOLD then
		score += 20
		table.insert(reasons, "HIGH_VISITS")
	end
	if candidate.hasMonetization then
		score += 25
		table.insert(reasons, "MONETIZED")
	end
	if self:HasPolicyViolation(candidate.policyFlags) then
		score += 50
		table.insert(reasons, "POLICY_VIOLATION")
	end

	local verdict: FanVerdict
	if self:HasPolicyViolation(candidate.policyFlags) and score >= cfg.FAN_VIOLATION_SCORE then
		verdict = "VIOLATION"
	elseif score >= cfg.FAN_VIOLATION_SCORE then
		verdict = "REVIEW"
	elseif score >= cfg.FAN_PARTNER_ELIGIBLE_SCORE and candidate.hasMonetization then
		verdict = "PARTNER_ELIGIBLE"
	else
		verdict = "UNLICENSED_OK"
	end

	return score, verdict, reasons
end

function FanExperienceGuard:GetTierForCcu(ccu: number): string?
	for tierName, tier in GameConfig.FanLicense.Tiers do
		local maxCcu = tier.maxCcu
		if ccu >= tier.minCcu and (maxCcu == nil or ccu <= maxCcu) then
			return tierName
		end
	end
	return nil
end

function FanExperienceGuard:LogCandidate(candidate: FanCandidate, score: number, verdict: FanVerdict, reasons: { string })
	if not LogExportBridge then
		return
	end
	LogExportBridge:Enqueue("FAN_EXPERIENCE", {
		experienceId = candidate.experienceId,
		title = candidate.title,
		score = score,
		verdict = verdict,
		reasons = reasons,
	})
end

function FanExperienceGuard:Evaluate(candidate: FanCandidate): (FanVerdict, number)
	local score, verdict, reasons = self:ScoreCandidate(candidate)
	self:LogCandidate(candidate, score, verdict, reasons)
	return verdict, score
end

return FanExperienceGuard
