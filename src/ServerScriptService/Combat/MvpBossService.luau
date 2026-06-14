--!strict
--[[
	MvpBossService — Eternity City world boss spawn, damage board, MVP rewards
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local MvpBossConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MvpBossConfig"))

local MvpBossService = {}

local bossActive = false
local currentBoss: MvpBossConfig.MvpBossDef? = nil
local bossHp = 0
local bossMaxHp = 0
local bossModel: Model? = nil
local damageBoard: { [number]: number } = {}

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function getLevelService()
	return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerLevelService"))
end

local function getCurrency()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
end

local function getItemStore()
	return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))
end

local function getPetService()
	return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("PetService"))
end

local function getBossDefByTime(): MvpBossConfig.MvpBossDef
	local bosses = MvpBossConfig.Bosses
	local idx = math.floor(os.time() / MvpBossConfig.SPAWN_INTERVAL_SECONDS) % #bosses + 1
	return bosses[idx]
end

local function buildPublicState(): { [string]: any }
	local boss = currentBoss or getBossDefByTime()
	local nextSpawn = MvpBossConfig.SPAWN_INTERVAL_SECONDS - (os.time() % MvpBossConfig.SPAWN_INTERVAL_SECONDS)
	return {
		bossActive = bossActive,
		bossId = boss.id,
		bossName = boss.nameTH,
		bossEmoji = boss.emoji,
		bossHp = bossHp,
		bossMaxHp = bossMaxHp,
		nextSpawnSec = nextSpawn,
	}
end

local function broadcast()
	local ev = remotes:FindFirstChild("MvpBossStateChanged") :: RemoteEvent?
	if ev then
		ev:FireAllClients(buildPublicState())
	end
end

local function spawnBossModel(boss: MvpBossConfig.MvpBossDef)
	if bossModel then
		bossModel:Destroy()
	end

	local m = Instance.new("Model")
	m.Name = "MvpBoss_" .. boss.id

	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(8, 12, 8)
	body.Position = boss.spawnPos
	body.Anchored = true
	body.BrickColor = BrickColor.new("Crimson")
	body.Material = Enum.Material.Neon
	body.Parent = m

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 50)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = boss.emoji .. " " .. boss.nameTH
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = bb

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HpLabel"
	hpLabel.Size = UDim2.new(1, 0, 0.4, 0)
	hpLabel.Position = UDim2.fromScale(0, 0.6)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = string.format("HP: %d / %d", bossHp, bossMaxHp)
	hpLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextScaled = true
	hpLabel.Parent = bb

	m.PrimaryPart = body
	m.Parent = Workspace
	bossModel = m
end

local function updateBossHpLabel()
	if not bossModel then
		return
	end
	local hrp = bossModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local bb = hrp:FindFirstChild("BillboardGui") :: BillboardGui?
	if not bb then
		return
	end
	local lbl = bb:FindFirstChild("HpLabel") :: TextLabel?
	if lbl then
		lbl.Text = string.format("HP: %d / %d", bossHp, bossMaxHp)
	end
end

local function grantRewards(boss: MvpBossConfig.MvpBossDef)
	type Entry = { userId: number, dmg: number }
	local sorted: { Entry } = {}
	for uid, dmg in damageBoard do
		table.insert(sorted, { userId = uid, dmg = dmg })
	end
	table.sort(sorted, function(a, b)
		return a.dmg > b.dmg
	end)

	local lvSvc = getLevelService()
	local curSvc = getCurrency()
	local itmSvc = getItemStore()
	local reward = boss.reward

	for rank, entry in sorted do
		local player = Players:GetPlayerByUserId(entry.userId)
		if not player then
			continue
		end

		lvSvc.addExp(player, reward.xp)
		curSvc.addCredits(entry.userId, reward.credits)
		if reward.itemId then
			itmSvc.addItem(entry.userId, reward.itemId, 1)
		end

		if rank == 1 and reward.mvpItemId then
			itmSvc.addItem(entry.userId, reward.mvpItemId, 1)
			local mvpEv = remotes:FindFirstChild("MvpAnnounce") :: RemoteEvent?
			if mvpEv then
				mvpEv:FireClient(player, boss.nameTH, reward.mvpItemId)
			end
		end

		-- MVP (rank 1) pet drop — e.g. void_imp from the world boss
		local mvpPetId = reward.mvpPetId
		if rank == 1 and mvpPetId then
			if math.random() < (reward.mvpPetChance or 1) then
				local ok = pcall(function()
					getPetService().grantPet(player, mvpPetId)
				end)
				if ok then
					local petEv = remotes:FindFirstChild("MvpAnnounce") :: RemoteEvent?
					if petEv then
						petEv:FireClient(player, boss.nameTH, mvpPetId)
					end
				end
			end
		end
	end
end

function MvpBossService.getPublicState(): { [string]: any }
	return buildPublicState()
end

function MvpBossService.attack(player: Player): (boolean, string)
	if not bossActive or not currentBoss then
		return false, "ไม่มี boss active อยู่ตอนนี้"
	end

	local boss = currentBoss
	local dmg = boss.damagePerHit
	bossHp = math.max(0, bossHp - dmg)

	local uid = player.UserId
	damageBoard[uid] = (damageBoard[uid] or 0) + dmg

	updateBossHpLabel()
	broadcast()

	if bossHp <= 0 then
		bossActive = false
		local defeatedBoss = currentBoss
		currentBoss = nil
		if bossModel then
			bossModel:Destroy()
			bossModel = nil
		end

		if defeatedBoss then
			grantRewards(defeatedBoss)
			local defEv = remotes:FindFirstChild("MvpBossDefeated") :: RemoteEvent?
			if defEv then
				defEv:FireAllClients(defeatedBoss.nameTH)
			end
		end
		broadcast()
		return true, "Boss พ่ายแล้ว!"
	end

	return true, string.format("%s — %d HP เหลือ", boss.nameTH, bossHp)
end

local function trySpawn()
	if bossActive then
		return
	end

	local boss = getBossDefByTime()
	local playerCount = math.max(1, #Players:GetPlayers())
	bossMaxHp = boss.baseHp + boss.hpPerPlayer * playerCount
	bossHp = bossMaxHp
	bossActive = true
	currentBoss = boss
	table.clear(damageBoard)

	spawnBossModel(boss)
	broadcast()

	local spawnEv = remotes:FindFirstChild("MvpBossSpawned") :: RemoteEvent?
	if spawnEv then
		spawnEv:FireAllClients(boss.nameTH, boss.emoji)
	end
	print(string.format("[MvpBoss] %s spawned — HP %d", boss.nameTH, bossMaxHp))
end

task.spawn(function()
	task.wait(10)
	while true do
		local sec = os.time() % MvpBossConfig.SPAWN_INTERVAL_SECONDS
		if sec < 60 and not bossActive then
			trySpawn()
		end
		task.wait(60)
	end
end)

return MvpBossService
