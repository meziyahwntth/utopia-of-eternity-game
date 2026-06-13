--!strict
--[[
	EventCalendarService (P8) — date check → activate buffs → broadcast
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventCalendarConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventCalendarConfig"))

export type ActiveBuff = {
	buffType: EventCalendarConfig.BuffType,
	value: number,
	eventName: string,
}

local EventCalendarService = {}

local currentBuffs: { ActiveBuff } = {}
local remotes: Folder? = nil

local function isDateInRange(month: number, day: number, sm: number, sd: number, em: number, ed: number): boolean
	if sm == 0 then
		return false
	end
	local startN = sm * 100 + sd
	local endN = em * 100 + ed
	local nowN = month * 100 + day
	if startN <= endN then
		return nowN >= startN and nowN <= endN
	end
	return nowN >= startN or nowN <= endN
end

local function isWeekend(): boolean
	local wday = tonumber(os.date("%w")) or 0
	return wday == 0 or wday == 6
end

function EventCalendarService.getActiveBuffs(): { ActiveBuff }
	return currentBuffs
end

function EventCalendarService.checkAndApply()
	local month = tonumber(os.date("%m")) or 0
	local day = tonumber(os.date("%d")) or 0
	currentBuffs = {}

	for _, event in EventCalendarConfig.Events do
		local active = false
		if event.id == "weekend" then
			active = isWeekend()
		else
			active = isDateInRange(
				month,
				day,
				event.startMonth,
				event.startDay,
				event.endMonth,
				event.endDay
			)
		end

		if active and event.buffType ~= "None" then
			table.insert(currentBuffs, {
				buffType = event.buffType,
				value = event.buffValue,
				eventName = event.nameTH,
			})
		end
	end

	if remotes then
		local ev = remotes:FindFirstChild("ActiveEventsUpdate") :: RemoteEvent?
		if ev then
			ev:FireAllClients(currentBuffs)
		end
	end

	print(string.format("[EventCalendar] %d active buffs", #currentBuffs))
end

function EventCalendarService.getMultiplier(buffType: EventCalendarConfig.BuffType | string): number
	local mult = 1.0
	for _, b in currentBuffs do
		if b.buffType == buffType then
			mult *= b.value
		end
	end
	return mult
end

function EventCalendarService.init(remotesFolder: Folder)
	remotes = remotesFolder

	EventCalendarService.checkAndApply()

	local function scheduleNext()
		task.delay(3600, function()
			EventCalendarService.checkAndApply()
			scheduleNext()
		end)
	end
	scheduleNext()
end

return EventCalendarService
