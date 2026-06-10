--!strict
--[[
	Festival Phase 2 — Daily Quest Config
	8-quest pool, all tracked from existing systems only
]]
export type QuestType = "TouchZone" | "MountUse" | "PhotoVisit" | "DanceFloor" | "KeyPickup" | "DeathValleyVisit"

export type DailyQuest = {
	id: string,
	displayName: string,
	goal: number,
	questType: QuestType,
	zoneName: string?,
	icon: string,
}

local DailyQuestConfig = {}

DailyQuestConfig.QuestPool = {
	{
		id = "visit_marina",
		displayName = "Visit Marina Ring",
		goal = 1,
		questType = "TouchZone",
		zoneName = "MarinaRing",
		icon = "⚓",
	},
	{
		id = "visit_aurora_spire",
		displayName = "Visit Aurora Spire",
		goal = 1,
		questType = "TouchZone",
		zoneName = "AuroraSpire",
		icon = "🏙",
	},
	{
		id = "visit_twilight_overpass",
		displayName = "Visit Twilight Overpass",
		goal = 1,
		questType = "TouchZone",
		zoneName = "TwilightOverpass",
		icon = "🌉",
	},
	{
		id = "use_mount",
		displayName = "Use a Mount or Vehicle",
		goal = 1,
		questType = "MountUse",
		zoneName = nil,
		icon = "🏍",
	},
	{
		id = "photo_zone",
		displayName = "Visit a Photo Zone",
		goal = 1,
		questType = "PhotoVisit",
		zoneName = nil,
		icon = "📸",
	},
	{
		id = "dance_floor",
		displayName = "Dance at Festival Stage",
		goal = 1,
		questType = "DanceFloor",
		zoneName = nil,
		icon = "🎵",
	},
	{
		id = "collect_key",
		displayName = "Collect a Prism Key",
		goal = 1,
		questType = "KeyPickup",
		zoneName = nil,
		icon = "🔑",
	},
	{
		id = "enter_death_valley",
		displayName = "Enter Death Valley",
		goal = 1,
		questType = "DeathValleyVisit",
		zoneName = nil,
		icon = "💀",
	},
}

function DailyQuestConfig.getQuest(id: string): DailyQuest?
	for _, q in DailyQuestConfig.QuestPool do
		if q.id == id then
			return q
		end
	end
	return nil
end

return DailyQuestConfig