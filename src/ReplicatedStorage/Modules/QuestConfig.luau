--!strict
--[[
	QuestConfig — daily mission templates (3 random per UTC+7 day)
]]
export type RewardType = "xp" | "credits" | "item"

export type QuestReward = {
	rewardType: RewardType,
	amount: number,
	itemId: string?,
	itemQty: number?,
}

export type QuestObjective = "kill_npc" | "use_emote" | "visit_zone" | "send_chat" | "equip_pet" | "trade_complete"

export type QuestTemplate = {
	id: string,
	nameTH: string,
	descTH: string,
	objective: QuestObjective,
	targetCount: number,
	targetZoneId: string?,
	reward: QuestReward,
}

local QuestConfig = {}

QuestConfig.Templates = {
	{
		id = "kill10",
		nameTH = "นักล่าเริ่มต้น",
		descTH = "สังหาร NPC 10 ตัว",
		objective = "kill_npc",
		targetCount = 10,
		reward = { rewardType = "xp", amount = 500 },
	},
	{
		id = "kill30",
		nameTH = "นักล่าชั้นสอง",
		descTH = "สังหาร NPC 30 ตัว",
		objective = "kill_npc",
		targetCount = 30,
		reward = { rewardType = "xp", amount = 1500 },
	},
	{
		id = "emote3",
		nameTH = "จิตวิญญาณสังคม",
		descTH = "ใช้ Emote 3 ครั้ง",
		objective = "use_emote",
		targetCount = 3,
		reward = { rewardType = "credits", amount = 100 },
	},
	{
		id = "chat10",
		nameTH = "นักพูด",
		descTH = "ส่งข้อความแชท 10 ข้อความ",
		objective = "send_chat",
		targetCount = 10,
		reward = { rewardType = "credits", amount = 80 },
	},
	{
		id = "visit_marina",
		nameTH = "นักท่องเที่ยว",
		descTH = "ไปที่ Marina District",
		objective = "visit_zone",
		targetCount = 1,
		targetZoneId = "marina",
		reward = { rewardType = "xp", amount = 200 },
	},
	{
		id = "equip_pet",
		nameTH = "เจ้าของสัตว์เลี้ยง",
		descTH = "สวม Pet 1 ตัว",
		objective = "equip_pet",
		targetCount = 1,
		reward = { rewardType = "credits", amount = 50 },
	},
	{
		id = "trade1",
		nameTH = "พ่อค้า",
		descTH = "ทำการซื้อขาย 1 ครั้ง",
		objective = "trade_complete",
		targetCount = 1,
		reward = { rewardType = "xp", amount = 300 },
	},
	{
		id = "kill50",
		nameTH = "นักสังหาร",
		descTH = "สังหาร NPC 50 ตัว",
		objective = "kill_npc",
		targetCount = 50,
		reward = { rewardType = "item", amount = 0, itemId = "StoneFragment", itemQty = 30 },
	},
} :: { QuestTemplate }

QuestConfig.DAILY_QUEST_COUNT = 3
QuestConfig.RESET_HOUR_UTC = 17

return QuestConfig
