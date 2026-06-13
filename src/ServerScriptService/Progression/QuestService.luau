--!strict
--[[
	QuestService — daily quest roll, progress tracking, reward claim
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local QuestConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestConfig"))
local QuestStore = require(script.Parent:WaitForChild("QuestStore"))

local function getLevelService()
	return require(script.Parent:WaitForChild("PlayerLevelService"))
end

local function getCurrencyService()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
end

local function getItemStore()
	return require(script.Parent:WaitForChild("PlayerItemStore"))
end

local QuestService = {}

local cache: { [number]: QuestStore.PlayerQuestData } = {}
local remotes: Folder? = nil

local function getDateKeyUTC7(): string
	local utc7Offset = 7 * 3600
	local now = os.time() + utc7Offset
	local t = os.date("!*t", now) :: { year: number, month: number, day: number }
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

local function pickDailyQuests(): { QuestStore.QuestProgress }
	local pool: { QuestConfig.QuestTemplate } = {}
	for _, tmpl in QuestConfig.Templates do
		table.insert(pool, tmpl)
	end
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local result: { QuestStore.QuestProgress } = {}
	for i = 1, math.min(QuestConfig.DAILY_QUEST_COUNT, #pool) do
		table.insert(result, {
			questId = pool[i].id,
			progress = 0,
			completed = false,
			claimed = false,
		})
	end
	return result
end

local function ensureDailyQuests(userId: number): QuestStore.PlayerQuestData
	local data = cache[userId] or QuestStore.get(userId)
	local today = getDateKeyUTC7()
	if data.dateKey ~= today then
		data = { dateKey = today, quests = pickDailyQuests() }
		QuestStore.save(userId, data)
	end
	cache[userId] = data
	return data
end

local function findTemplate(questId: string): QuestConfig.QuestTemplate?
	for _, tmpl in QuestConfig.Templates do
		if tmpl.id == questId then
			return tmpl
		end
	end
	return nil
end

local function fireUpdate(player: Player)
	if not remotes then
		return
	end
	local data = cache[player.UserId]
	if not data then
		return
	end
	local ev = remotes:FindFirstChild("QuestUpdate") :: RemoteEvent?
	if ev then
		ev:FireClient(player, data.quests)
	end
end

local function saveAsync(userId: number)
	local data = cache[userId]
	if data then
		task.spawn(function()
			QuestStore.save(userId, data)
		end)
	end
end

function QuestService.recordProgress(player: Player, objective: QuestConfig.QuestObjective, count: number?)
	local amount = count or 1
	ensureDailyQuests(player.UserId)
	local data = cache[player.UserId]
	if not data then
		return
	end

	local changed = false
	for _, q in data.quests do
		if q.completed then
			continue
		end
		local tmpl = findTemplate(q.questId)
		if not tmpl or tmpl.objective ~= objective then
			continue
		end

		q.progress = math.min(q.progress + amount, tmpl.targetCount)
		if q.progress >= tmpl.targetCount then
			q.completed = true
			if remotes then
				local ev = remotes:FindFirstChild("QuestCompleted") :: RemoteEvent?
				if ev then
					ev:FireClient(player, q.questId)
				end
			end
		end
		changed = true
	end

	if changed then
		saveAsync(player.UserId)
		fireUpdate(player)
	end
end

function QuestService.claimReward(player: Player, questId: string): (boolean, string)
	ensureDailyQuests(player.UserId)
	local data = cache[player.UserId]
	if not data then
		return false, "ไม่มีข้อมูล"
	end

	for _, q in data.quests do
		if q.questId ~= questId then
			continue
		end
		if not q.completed then
			return false, "ยังไม่เสร็จ"
		end
		if q.claimed then
			return false, "รับแล้ว"
		end

		local tmpl = findTemplate(questId)
		if not tmpl then
			return false, "ไม่พบ quest"
		end

		q.claimed = true
		local rw = tmpl.reward

		if rw.rewardType == "xp" then
			getLevelService().addExp(player, rw.amount)
		elseif rw.rewardType == "credits" then
			getCurrencyService().addCredits(player.UserId, rw.amount)
		elseif rw.rewardType == "item" and rw.itemId then
			getItemStore().addItem(player.UserId, rw.itemId, rw.itemQty or 1)
		end

		saveAsync(player.UserId)
		fireUpdate(player)
		return true, "รับรางวัลแล้ว!"
	end

	return false, "ไม่พบ quest นี้"
end

function QuestService.getQuests(player: Player): { QuestStore.QuestProgress }
	return ensureDailyQuests(player.UserId).quests
end

function QuestService.onPlayerReady(player: Player)
	ensureDailyQuests(player.UserId)
	task.delay(2, function()
		if player.Parent then
			fireUpdate(player)
		end
	end)
end

function QuestService.init(remotesFolder: Folder)
	remotes = remotesFolder

	Players.PlayerAdded:Connect(function(player)
		QuestService.onPlayerReady(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local data = cache[player.UserId]
		if data then
			QuestStore.save(player.UserId, data)
		end
		cache[player.UserId] = nil
	end)
end

return QuestService
