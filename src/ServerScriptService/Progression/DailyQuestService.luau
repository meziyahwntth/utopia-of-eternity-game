--!strict
--[[
	Festival Phase 2 — Daily Quest Service
	- Assigns 3 random quests per player per UTC day from DailyQuestConfig pool
	- Tracks progress via server-side event hooks (Touched, Mount, Key, etc.)
	- Progress attributes on player: QuestProgress_<id>, QuestClaimed_<id>
	- Bonus for completing all 3: +15 Luminite
	- Anti-cheat: all progress server-side (no client-input progress)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DailyQuestConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DailyQuestConfig"))
local DailyQuestStore = require(script.Parent:WaitForChild("DailyQuestStore"))

local DailyQuestService = {}

-- ──────────────────────────────────────────────
-- UTC day helper
-- ──────────────────────────────────────────────

local function todayUtcDay(): number
	return os.date("!*t").yday
end

-- ──────────────────────────────────────────────
-- Quest assignment
-- ──────────────────────────────────────────────

local function shufflePool(): { string }
	local pool = {}
	for _, q in DailyQuestConfig.QuestPool do
		table.insert(pool, q.id)
	end
	-- Fisher-Yates shuffle
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	return pool
end

local function assignDailyQuests(userId: number, forceNew: boolean): { QuestProgress }
	local existing = DailyQuestStore.load(userId)
	local today = todayUtcDay()

	if not forceNew and existing and existing.dateDay == today then
		return existing.assignedQuests
	end

	local shuffled = shufflePool()
	local quests: { QuestProgress } = {}
	for i = 1, 3 do
		if i > #shuffled then break end
		local questDef = DailyQuestConfig.getQuest(shuffled[i])
		if questDef then
			table.insert(quests, {
				id = questDef.id,
				progress = 0,
				goal = questDef.goal,
				claimed = false,
			})
		end
	end

	local payload: QuestSaveData = {
		dateDay = today,
		assignedQuests = quests,
		completedAll = false,
		version = 1,
	}
	DailyQuestStore.save(userId, payload)
	return quests
end

-- ──────────────────────────────────────────────
-- Progress tracking
-- ──────────────────────────────────────────────

local function getActiveQuests(userId: number): { QuestProgress }
	local data = DailyQuestStore.load(userId)
	if not data then
		return assignDailyQuests(userId, false)
	end
	if data.dateDay ~= todayUtcDay() then
		return assignDailyQuests(userId, true)
	end
	return data.assignedQuests
end

local function updateProgress(player: Player, questType: string, zoneName: string?, amount: number?)
	local inc = amount or 1
	local userId = player.UserId
	local quests = getActiveQuests(userId)
	local changed = false

	for i, q in quests do
		if q.claimed then continue end
		if q.progress >= q.goal then continue end

		local def = DailyQuestConfig.getQuest(q.id)
		if not def then continue end

		local matches = def.questType == questType
		if def.zoneName and zoneName then
			matches = matches and def.zoneName == zoneName
		end

		if matches then
			q.progress = math.min(q.progress + inc, q.goal)
			changed = true
		end
	end

	if changed then
		local data = DailyQuestStore.load(userId)
		if data then
			data.assignedQuests = quests
			DailyQuestStore.save(userId, data)
		end
	end
end

-- ──────────────────────────────────────────────
-- Server-side event hooks
-- ──────────────────────────────────────────────

local function bindTouchZones(player: Player)
	local model = workspace:FindFirstChild("UtopiaEternityCity")
	if not model then return end

	local function onDescendantAdded(inst: Instance)
		if not inst:IsA("Folder") then return end
		local districtName = inst:GetAttribute("VisualBibleDistrict")
		if typeof(districtName) ~= "string" then return end

		-- Map district names to quest zone names
		local zoneMap = {
			MarinaRing = "MarinaRing",
			AuroraSpire = "AuroraSpire",
			TwilightOverpass = "TwilightOverpass",
		}
		local zoneName = zoneMap[districtName]
		if not zoneName then return end

		-- Watch for player Touched on any part in this district
		for _, part in inst:GetDescendants() do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(other)
					local hitChar = other.Parent
					if hitChar and hitChar:IsA("Model") then
						local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
						if hitPlayer == player then
							updateProgress(player, "TouchZone", zoneName)
						end
					end
				end)
			end
		end
	end

	for _, child in model:GetChildren() do
		onDescendantAdded(child)
	end
	model.ChildAdded:Connect(onDescendantAdded)
	model.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") then
			local folder = inst:FindFirstAncestorOfClass("Folder")
			if folder and folder:GetAttribute("VisualBibleDistrict") then
				-- Watch specific parts
			end
		end
	end)
end

local function bindMountUse(player: Player)
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("VehicleSeat") or child:IsA("Seat") then
				updateProgress(player, "MountUse", nil)
			end
		end)
	end)
end

local function bindPhotoVisit(player: Player)
	local model = workspace:FindFirstChild("UtopiaEternityCity")
	if not model then return end
	model.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") and inst:GetAttribute("PhotoZone") then
			inst.Touched:Connect(function(other)
				local hitChar = other.Parent
				if hitChar and hitChar:IsA("Model") then
					local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
					if hitPlayer == player then
						updateProgress(player, "PhotoVisit", nil)
					end
				end
			end)
		end
	end)
end

local function bindDanceFloor(player: Player)
	local model = workspace:FindFirstChild("UtopiaEternityCity")
	if not model then return end
	model.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") and inst.Name:find("^DanceTile_") then
			inst.Touched:Connect(function(other)
				local hitChar = other.Parent
				if hitChar and hitChar:IsA("Model") then
					local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
					if hitPlayer == player then
						updateProgress(player, "DanceFloor", nil)
					end
				end
			end)
		end
	end)
	-- Also check existing
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name:find("^DanceTile_") then
			inst.Touched:Connect(function(other)
				local hitChar = other.Parent
				if hitChar and hitChar:IsA("Model") then
					local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
					if hitPlayer == player then
						updateProgress(player, "DanceFloor", nil)
					end
				end
			end)
		end
	end
end

local function bindKeyPickup(player: Player)
	player:GetAttributeChangedSignal("PrismKeyCount"):Connect(function()
		local count = player:GetAttribute("PrismKeyCount")
		if typeof(count) == "number" then
			updateProgress(player, "KeyPickup", nil)
		end
	end)
end

-- ──────────────────────────────────────────────
-- Claiming
-- ──────────────────────────────────────────────

function DailyQuestService.getQuestInfo(player: Player): { any }
	local userId = player.UserId
	local quests = getActiveQuests(userId)
	local result: { any } = {}
	for _, q in quests do
		local def = DailyQuestConfig.getQuest(q.id)
		table.insert(result, {
			id = q.id,
			displayName = def and def.displayName or q.id,
			icon = def and def.icon or "",
			progress = q.progress,
			goal = q.goal,
			claimed = q.claimed,
		})
	end

	-- Check bonus status
	local data = DailyQuestStore.load(userId)
	local allDone = true
	for _, q in quests do
		if q.progress < q.goal then
			allDone = false
			break
		end
	end

	return {
		quests = result,
		allComplete = allDone and not (data and data.completedAll),
		bonusClaimed = data ~= nil and data.completedAll == true,
	}
end

function DailyQuestService.claimQuest(player: Player, questId: string): (boolean, string)
	local userId = player.UserId
	local data = DailyQuestStore.load(userId)
	if not data then
		return false, "No active quests"
	end

	for _, q in data.assignedQuests do
		if q.id == questId then
			if q.claimed then
				return false, "Already claimed"
			end
			if q.progress < q.goal then
				return false, "Quest not complete"
			end
			q.claimed = true
			DailyQuestStore.save(userId, data)

			local shards = player:GetAttribute("DV_LuminiteShards")
			if typeof(shards) ~= "number" then shards = 0 end
			player:SetAttribute("DV_LuminiteShards", (shards :: number) + 5)
			return true, "Quest complete! +5 Luminite"
		end
	end

	return false, "Quest not found"
end

function DailyQuestService.claimBonus(player: Player): (boolean, string)
	local userId = player.UserId
	local data = DailyQuestStore.load(userId)
	if not data then
		return false, "No active quests"
	end
	if data.completedAll then
		return false, "Bonus already claimed"
	end

	for _, q in data.assignedQuests do
		if q.progress < q.goal then
			return false, "Complete all 3 quests first"
		end
	end

	data.completedAll = true
	DailyQuestStore.save(userId, data)

	local shards = player:GetAttribute("DV_LuminiteShards")
	if typeof(shards) ~= "number" then shards = 0 end
	player:SetAttribute("DV_LuminiteShards", (shards :: number) + 15)
	return true, "All quests complete! +15 Luminite bonus"
end

-- ──────────────────────────────────────────────
-- Player join/leave
-- ──────────────────────────────────────────────

function DailyQuestService.onPlayerAdded(player: Player)
	assignDailyQuests(player.UserId, false)
	task.spawn(bindTouchZones, player)
	task.spawn(bindMountUse, player)
	task.spawn(bindPhotoVisit, player)
	task.spawn(bindDanceFloor, player)
	task.spawn(bindKeyPickup, player)
end

function DailyQuestService.onPlayerRemoving(player: Player)
	DailyQuestStore.clearMemory(player.UserId)
end

return DailyQuestService