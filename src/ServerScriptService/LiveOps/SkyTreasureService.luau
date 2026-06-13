--!strict
--[[
	SkyTreasureService (P6) — cron sky treasure event: spawn chests, defend timer, claim rewards
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SkyTreasureConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SkyTreasureConfig"))
local CurrencyService = require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
local PlayerItemStore = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))

type SpawnPoint = SkyTreasureConfig.SpawnPoint
type RewardEntry = SkyTreasureConfig.RewardEntry

type ChestSession = {
	id: string,
	spawnPoint: SpawnPoint,
	reward: RewardEntry,
	startsAt: number,
	endsAt: number,
	claimedBy: number?,
	model: Model?,
}

export type AnnounceChest = {
	id: string,
	displayName: string,
	position: Vector3,
}

local activeChests: { [string]: ChestSession } = {}
local _remotes: Folder? = nil
local chestFolder: Folder? = nil

local SkyTreasureService = {}

local function remotesFolder(): Folder
	return ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
end

local function pickReward(): RewardEntry
	local pool = SkyTreasureConfig.Rewards
	local totalWeight = 0
	for _, r in pool do
		totalWeight += r.weight
	end
	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, r in pool do
		cumulative += r.weight
		if roll <= cumulative then
			return r
		end
	end
	return pool[1]
end

local function pickSpawnPoints(count: number): { SpawnPoint }
	local pool: { SpawnPoint } = table.clone(SkyTreasureConfig.SpawnPoints)
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local result: { SpawnPoint } = {}
	for i = 1, math.min(count, #pool) do
		table.insert(result, pool[i])
	end
	return result
end

local function getChestFolder(): Folder
	if chestFolder and chestFolder.Parent then
		return chestFolder
	end
	local existing = Workspace:FindFirstChild("SkyTreasureChests")
	if existing and existing:IsA("Folder") then
		chestFolder = existing
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "SkyTreasureChests"
	folder.Parent = Workspace
	chestFolder = folder
	return folder
end

local function spawnChestModel(position: Vector3, chestId: string): Model
	local model = Instance.new("Model")
	model.Name = "SkyTreasureChest_" .. chestId
	local part = Instance.new("Part")
	part.Size = Vector3.new(4, 4, 4)
	part.Position = position
	part.Anchored = true
	part.BrickColor = BrickColor.new("Bright yellow")
	part.Material = Enum.Material.SmoothPlastic
	part.Name = "ChestPart"
	part.Parent = model

	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Color = Color3.fromRGB(255, 220, 80)
	light.Range = 30
	light.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "ยึดกล่อง"
	prompt.ObjectText = "Sky Treasure"
	prompt.MaxActivationDistance = SkyTreasureConfig.ClaimRadius
	prompt.HoldDuration = 0
	prompt.Parent = part
	prompt.Triggered:Connect(function(playerWhoTriggered: Player)
		SkyTreasureService.claimChest(playerWhoTriggered, chestId)
	end)

	model:SetAttribute("ChestId", chestId)
	model.PrimaryPart = part
	model.Parent = getChestFolder()
	return model
end

local function fireAnnounce(chosen: { SpawnPoint }, endsAt: number)
	local announce = remotesFolder():FindFirstChild("SkyTreasureAnnounce")
	if not announce or not announce:IsA("RemoteEvent") then
		return
	end

	local zoneNames: { string } = {}
	local chests: { AnnounceChest } = {}
	for _, pt in chosen do
		table.insert(zoneNames, pt.displayName)
	end

	for chestId, session in activeChests do
		table.insert(chests, {
			id = chestId,
			displayName = session.spawnPoint.displayName,
			position = session.spawnPoint.position,
		})
	end

	(announce :: RemoteEvent):FireAllClients({
		zoneNames = zoneNames,
		endsAt = endsAt,
		chests = chests,
	})
end

function SkyTreasureService.startEvent()
	local now = os.time()
	local chosen = pickSpawnPoints(SkyTreasureConfig.ChestsPerEvent)
	local endsAt = now + SkyTreasureConfig.DefendSeconds

	for i, spawnPt in chosen do
		local reward = pickReward()
		local chestId = string.format("chest_%d_%d", now, i)
		local model = spawnChestModel(spawnPt.position, chestId)

		local session: ChestSession = {
			id = chestId,
			spawnPoint = spawnPt,
			reward = reward,
			startsAt = now,
			endsAt = endsAt,
			claimedBy = nil,
			model = model,
		}
		activeChests[chestId] = session

		task.delay(SkyTreasureConfig.DefendSeconds, function()
			local current = activeChests[chestId]
			if current and not current.claimedBy then
				if current.model and current.model.Parent then
					current.model:Destroy()
				end
				activeChests[chestId] = nil
				print(string.format("[SkyTreasure] %s expired unclaimed", chestId))
			end
		end)
	end

	fireAnnounce(chosen, endsAt)
	print(string.format("[SkyTreasure] event started — %d chests", #chosen))
end

function SkyTreasureService.claimChest(player: Player, chestId: string): (boolean, string)
	local session = activeChests[chestId]
	if not session then
		return false, "กล่องไม่มีอยู่"
	end
	if session.claimedBy then
		return false, "ถูกยึดไปแล้ว"
	end
	if os.time() > session.endsAt then
		return false, "หมดเวลา"
	end

	local char = player.Character
	if not char then
		return false, "ไม่พบตัวละคร"
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false, "ไม่พบ HumanoidRootPart"
	end

	local chestPart = if session.model then session.model:FindFirstChild("ChestPart") else nil
	if chestPart and chestPart:IsA("BasePart") then
		local dist = (root.Position - chestPart.Position).Magnitude
		if dist > SkyTreasureConfig.ClaimRadius then
			return false, string.format("ห่างเกิน %d studs", SkyTreasureConfig.ClaimRadius)
		end
	end

	session.claimedBy = player.UserId
	if session.model and session.model.Parent then
		session.model:Destroy()
	end
	activeChests[chestId] = nil

	local reward = session.reward
	if reward.type == "credits" and reward.amount then
		CurrencyService.addCredits(player.UserId, reward.amount)
	elseif reward.type == "item" and reward.itemId then
		PlayerItemStore.addItem(player.UserId, reward.itemId, 1)
	end

	local claimedEv = remotesFolder():FindFirstChild("SkyTreasureClaimed")
	if claimedEv and claimedEv:IsA("RemoteEvent") then
		(claimedEv :: RemoteEvent):FireAllClients(player.DisplayName, session.spawnPoint.displayName, reward.label)
	end

	return true, string.format("🎁 %s", reward.label)
end

function SkyTreasureService.init(remotesFolderArg: Folder?)
	_remotes = remotesFolderArg

	local function scheduleNext()
		task.delay(SkyTreasureConfig.IntervalSeconds, function()
			SkyTreasureService.startEvent()
			scheduleNext()
		end)
	end
	scheduleNext()
	print(string.format("[SkyTreasure] initialized — next event in %ds", SkyTreasureConfig.IntervalSeconds))
end

return SkyTreasureService
