--!strict
--[[
	RaceService (Race system) — server-authoritative
	- เก็บเผ่าผู้เล่นใน DataStore (pcall) + cache; เลือกตอนสร้างตัว (re-select free+debounce v1)
	- apply: attribute PlayerRace + WalkSpeed; HP recompute ให้ ClassService (race hp × class hp)
	- ใช้โดย CombatService/ClassService: getHpMult / getAtkMult / getStatMods
	- ไม่มีเผ่า = default (ไม่พังเกมเดิม) · เผ่าฟรี ไม่ขายเพื่อพลัง (no-P2W)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RaceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RaceConfig"))

local RaceService = {}

local BASE_WALKSPEED = 16
local SELECT_DEBOUNCE = 2

local raceByUser: { [number]: string } = {}
local lastSelectAt: { [number]: number } = {}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaPlayerRace_v1")
end)

local function dsKey(userId: number): string
	return "race_" .. userId
end

local function loadRace(userId: number): string?
	if raceByUser[userId] ~= nil then
		return raceByUser[userId]
	end
	if not ds then
		return nil
	end
	local ok, value = pcall(function()
		return (ds :: GlobalDataStore):GetAsync(dsKey(userId))
	end)
	if ok and typeof(value) == "string" and RaceConfig.get(value) then
		raceByUser[userId] = value
		return value
	end
	return nil
end

local function saveRace(userId: number, raceId: string)
	raceByUser[userId] = raceId
	if not ds then
		return
	end
	task.spawn(function()
		pcall(function()
			(ds :: GlobalDataStore):SetAsync(dsKey(userId), raceId)
		end)
	end)
end

function RaceService.getRace(player: Player): string?
	return loadRace(player.UserId)
end

function RaceService.getDef(player: Player): RaceConfig.RaceDef?
	return RaceConfig.get(loadRace(player.UserId))
end

function RaceService.getHpMult(player: Player): number
	local d = RaceService.getDef(player)
	return if d then d.statMods.hp else 1
end

function RaceService.getAtkMult(player: Player): number
	local d = RaceService.getDef(player)
	return if d then d.statMods.atk else 1
end

local function fireRaceChanged(player: Player, def: RaceConfig.RaceDef?)
	local remotes = ReplicatedStorage:FindFirstChild("RaceRemotes")
	local ev = remotes and remotes:FindFirstChild("RaceChanged")
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(player, if def then def.id else nil)
	end
end

-- คืน ClassService (lazy) สำหรับ recompute HP เมื่อเผ่าเปลี่ยน
local function classService(): any
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("ClassService"))
	end)
	return if ok then mod else nil
end

-- apply: WalkSpeed (race) + trigger HP recompute (ClassService รวม race×class hp)
function RaceService.applyToCharacter(player: Player)
	local def = RaceService.getDef(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if def then
		player:SetAttribute("PlayerRace", def.id)
		if hum then
			hum.WalkSpeed = BASE_WALKSPEED * def.statMods.walkSpeed
		end
	end
	local cs = classService()
	if cs and typeof(cs.applyToCharacter) == "function" then
		cs.applyToCharacter(player) -- recompute MaxHealth = class.hp × race.hp
	end
end

function RaceService.requestSelect(player: Player, raceId: any): (boolean, string)
	if typeof(raceId) ~= "string" or not RaceConfig.isPlayable(raceId) then
		return false, "เผ่าไม่ถูกต้อง"
	end
	local now = os.clock()
	local last = lastSelectAt[player.UserId]
	if last and (now - last) < SELECT_DEBOUNCE then
		return false, "เปลี่ยนเร็วเกินไป"
	end
	lastSelectAt[player.UserId] = now
	saveRace(player.UserId, raceId)
	RaceService.applyToCharacter(player)
	fireRaceChanged(player, RaceConfig.get(raceId))
	return true, "ok"
end

local initialized = false
function RaceService.init()
	if initialized then
		return
	end
	initialized = true

	local function onPlayer(player: Player)
		loadRace(player.UserId)
		player.CharacterAdded:Connect(function()
			task.wait(0.25)
			RaceService.applyToCharacter(player)
		end)
		if player.Character then
			RaceService.applyToCharacter(player)
		end
	end

	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		raceByUser[player.UserId] = nil
		lastSelectAt[player.UserId] = nil
	end)
end

return RaceService
