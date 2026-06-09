--!strict
local RateLimiter = {}

export type BucketConfig = {
	maxTokens: number,
	refillPerSecond: number,
}

local buckets: { [number]: { [string]: { tokens: number, lastRefill: number } } } = {}

local function getBucket(userId: number, remoteName: string, config: BucketConfig)
	local playerBuckets = buckets[userId]
	if not playerBuckets then
		playerBuckets = {}
		buckets[userId] = playerBuckets
	end
	local bucket = playerBuckets[remoteName]
	if not bucket then
		bucket = {
			tokens = config.maxTokens,
			lastRefill = os.clock(),
		}
		playerBuckets[remoteName] = bucket
	end
	return bucket
end

function RateLimiter:TryConsume(player: Player, remoteName: string, config: BucketConfig): boolean
	local bucket = getBucket(player.UserId, remoteName, config)
	local now = os.clock()
	local elapsed = now - bucket.lastRefill
	if elapsed > 0 then
		bucket.tokens = math.min(config.maxTokens, bucket.tokens + elapsed * config.refillPerSecond)
		bucket.lastRefill = now
	end
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter:ClearPlayer(player: Player)
	buckets[player.UserId] = nil
end

return RateLimiter
