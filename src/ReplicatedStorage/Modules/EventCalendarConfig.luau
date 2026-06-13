--!strict
--[[
	EventCalendarConfig (P8) — scheduled live-ops buff events
]]
export type BuffType = "DoubleExp" | "DoubleDrop" | "DoubleCurrency" | "None"

export type EventEntry = {
	id: string,
	nameTH: string,
	startMonth: number,
	startDay: number,
	endMonth: number,
	endDay: number,
	buffType: BuffType,
	buffValue: number,
	bannerColor: Color3,
}

local EventCalendarConfig = {}

EventCalendarConfig.Events = {
	{
		id = "songkran",
		nameTH = "สงกรานต์ 🎉",
		startMonth = 4,
		startDay = 13,
		endMonth = 4,
		endDay = 15,
		buffType = "DoubleExp",
		buffValue = 2,
		bannerColor = Color3.fromRGB(80, 200, 255),
	},
	{
		id = "loykrathong",
		nameTH = "ลอยกระทง 🪔",
		startMonth = 11,
		startDay = 15,
		endMonth = 11,
		endDay = 16,
		buffType = "DoubleDrop",
		buffValue = 2,
		bannerColor = Color3.fromRGB(255, 180, 50),
	},
	{
		id = "newyear",
		nameTH = "ปีใหม่ 🎆",
		startMonth = 12,
		startDay = 31,
		endMonth = 1,
		endDay = 2,
		buffType = "DoubleCurrency",
		buffValue = 2,
		bannerColor = Color3.fromRGB(200, 80, 255),
	},
	{
		id = "weekend",
		nameTH = "Weekend Boost ⚡",
		startMonth = 0,
		startDay = 0,
		endMonth = 0,
		endDay = 0,
		buffType = "DoubleExp",
		buffValue = 1.5,
		bannerColor = Color3.fromRGB(100, 255, 150),
	},
} :: { EventEntry }

return EventCalendarConfig
