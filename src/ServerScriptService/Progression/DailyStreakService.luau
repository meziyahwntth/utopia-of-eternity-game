--!strict
--[[
	Festival Phase 2 — Daily Login Streak Service
	- Tracks UTC day-of-year streak via DailyStreakStore (DataStore)
	- 7-day reward cycle: Days 1-6 = Luminite, Day 7 = title + Luminite
	- Grant via DV_LuminiteShards attribute (existing economy pattern)
	- Server-only validation prevents double-claim on same day
]]
local Players = game:GetService("Players")

local DailyStreakStore = require(script.Parent:WaitForChild("DailyStreakStore"))
local DeathValleyTitleService = require(script.Parent.Parent:WaitForChild("DeathValley"):WaitForChild("DeathValleyTitleService"))

local DailyStreakService = {}

export type StreakReward = {
	shards: number,
	title: string?,
}

local STREAK_REWARDS: { StreakReward } = {
	{ shards = 5, title = nil },
	{ shards = 8, title = nil },
	{ shards = 12, title = nil },
	{ shards = 15, title = nil },
	{ shards = 20, title = nil },
	{ shards = 25, title = nil },
	{ shards = 30, title = "Festival Streak" },
}

local function todayUtcDay(): number
	local date = os.date("!*t")
	return date.yday
end

function DailyStreakService.loadStreak(userId: number): StreakData
	local data = DailyStreakStore.load(userId)
	if not data then
		data = DailyStreakStore.createDefault(userId)
	end
	local today = todayUtcDay()

	if data.lastLoginDay == 0 then
		data.lastLoginDay = today
		data.streak = 1
	elseif data.lastLoginDay == today then
		-- same day, keep streak
	elseif data.lastLoginDay == today - 1 or (data.lastLoginDay == 365 and today == 1) then
		data.streak = math.min(data.streak + 1, 7)
		data.lastLoginDay = today
		data.claimedDays = {}
	else
		data.streak = 1
		data.lastLoginDay = today
		data.claimedDays = {}
	end

	DailyStreakStore.save(userId, data)
	return data
end

function DailyStreakService.canClaim(player: Player): (boolean, string?)
	local data = DailyStreakStore.load(player.UserId)
	if not data then
		return false, "No streak data"
	end
	if data.claimedDays[data.streak] then
		return false, "Already claimed today"
	end
	if data.streak < 1 or data.streak > 7 then
		return false, "Invalid streak day"
	end
	return true, nil
end

function DailyStreakService.claimReward(player: Player): (boolean, string)
	local ok, err = DailyStreakService.canClaim(player)
	if not ok then
		return false, err or "Cannot claim"
	end

	local data = DailyStreakStore.load(player.UserId) or DailyStreakStore.createDefault(player.UserId)
	local reward = STREAK_REWARDS[data.streak]
	if not reward then
		return false, "No reward for day " .. tostring(data.streak)
	end

	local currentShards = player:GetAttribute("DV_LuminiteShards")
	if typeof(currentShards) ~= "number" then
		currentShards = 0
	end
	player:SetAttribute("DV_LuminiteShards", currentShards + reward.shards)

	if reward.title then
		DeathValleyTitleService.grantTitle(player, "SummerFestival", reward.title)
	end

	data.claimedDays[data.streak] = true
	DailyStreakStore.save(player.UserId, data)
	player:SetAttribute("DailyStreakDay", data.streak)

	local msg = string.format(
		"Day %d streak: +%d Luminite%s",
		data.streak,
		reward.shards,
		if reward.title then (" + " .. reward.title .. " title") else ""
	)
	return true, msg
end

function DailyStreakService.onPlayerAdded(player: Player)
	local data = DailyStreakService.loadStreak(player.UserId)
	player:SetAttribute("DailyStreakDay", data.streak)
end

function DailyStreakService.onPlayerRemoving(player: Player)
	DailyStreakStore.clearMemory(player.UserId)
end

return DailyStreakService