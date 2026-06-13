--!strict
-- QuestHandlers — wire remotes + progress hooks via BindableEvents
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local QuestService = require(script.Parent:WaitForChild("QuestService"))
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ZoneConfig"))

local function ensureBindable(name: string): BindableEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("BindableEvent") then
		return existing
	end
	local bindable = Instance.new("BindableEvent")
	bindable.Name = name
	bindable.Parent = ReplicatedStorage
	return bindable
end

ensureBindable("NpcKillEvent")
ensureBindable("TradeCompleteEvent")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
QuestService.init(remotes)

local getQuestsRF = remotes:WaitForChild("GetDailyQuests") :: RemoteFunction
local claimRewardRF = remotes:WaitForChild("ClaimQuestReward") :: RemoteFunction

getQuestsRF.OnServerInvoke = function(player: Player)
	return QuestService.getQuests(player)
end

claimRewardRF.OnServerInvoke = function(player: Player, questId: any)
	if typeof(questId) ~= "string" then
		return false, "invalid"
	end
	return QuestService.claimReward(player, questId)
end

local npcKillBindable = ReplicatedStorage:WaitForChild("NpcKillEvent") :: BindableEvent
npcKillBindable.Event:Connect(function(player: Player)
	if player and player:IsA("Player") then
		QuestService.recordProgress(player, "kill_npc", 1)
	end
end)

local tradeComplete = ReplicatedStorage:WaitForChild("TradeCompleteEvent") :: BindableEvent
tradeComplete.Event:Connect(function(player: Player)
	if player and player:IsA("Player") then
		QuestService.recordProgress(player, "trade_complete", 1)
	end
end)

for _, player in Players:GetPlayers() do
	QuestService.onPlayerReady(player)
end

local zoneVisitedEv = remotes:WaitForChild("ZoneVisited") :: RemoteEvent

zoneVisitedEv.OnServerEvent:Connect(function(player: Player, zoneId: any)
	if typeof(zoneId) ~= "string" then
		return
	end

	local valid = false
	for _, zone in ZoneConfig.Zones do
		if zone.id == zoneId then
			valid = true
			break
		end
	end
	if not valid then
		return
	end

	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local playerPos = hrp.Position

	local inZone = false
	for _, zone in ZoneConfig.Zones do
		if zone.id == zoneId then
			local dx = playerPos.X - zone.center.X
			local dz = playerPos.Z - zone.center.Z
			if math.sqrt(dx * dx + dz * dz) <= zone.radius + 20 then
				inZone = true
			end
			break
		end
	end
	if not inZone then
		warn("[ZoneDetector] player", player.Name, "claimed zone", zoneId, "but is out of range")
		return
	end

	QuestService.recordProgress(player, "visit_zone", 1, zoneId)
end)

print("[Progression] QuestHandlers online (Daily Quest)")
