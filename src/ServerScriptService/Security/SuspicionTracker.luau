--!strict
local SuspicionTracker = {}

export type AddReason = string

local scores: { [number]: number } = {}
local reasons: { [number]: { string } } = {}

function SuspicionTracker:GetScore(userId: number): number
	return scores[userId] or 0
end

function SuspicionTracker:Add(player: Player, amount: number, reason: AddReason): number
	local userId = player.UserId
	local nextScore = (scores[userId] or 0) + amount
	scores[userId] = nextScore
	local bucket = reasons[userId]
	if not bucket then
		bucket = {}
		reasons[userId] = bucket
	end
	table.insert(bucket, reason)
	return nextScore
end

function SuspicionTracker:GetReasons(userId: number): { string }
	return reasons[userId] or {}
end

function SuspicionTracker:Clear(userId: number)
	scores[userId] = nil
	reasons[userId] = nil
end

function SuspicionTracker:ClearPlayer(player: Player)
	self:Clear(player.UserId)
end

return SuspicionTracker
