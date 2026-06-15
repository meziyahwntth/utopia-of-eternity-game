--!strict
--[[
	ClassService (Class/Job system) — server-authoritative
	- เก็บคลาสผู้เล่นใน DataStore (pcall ครบ) + cache per session
	- requestChange: validate ผ่าน ClassConfig.canChange + PlayerLevelService level + debounce
	- apply: ตั้ง attribute PlayerClass/WeaponType + ปรับ MaxHealth ตาม statMods.hp + fire ClassChanged
	- ใช้โดย CombatService: getClassDef / getAtkMult / getCdMult / allowsSkill
	- ไม่มีคลาส = default (ไม่พังเกมเดิม)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClassConfig"))

local ClassService = {}

local BASE_MAX_HEALTH = 100
local CHANGE_DEBOUNCE = 2 -- วินาที กัน spam

local classByUser: { [number]: string } = {}
local lastChangeAt: { [number]: number } = {}

local ds: GlobalDataStore? = nil
pcall(function()
	ds = DataStoreService:GetDataStore("UtopiaPlayerClass_v1")
end)

local function dsKey(userId: number): string
	return "class_" .. userId
end

local function loadClass(userId: number): string?
	if classByUser[userId] ~= nil then
		return classByUser[userId]
	end
	if not ds then
		return nil
	end
	local ok, value = pcall(function()
		return (ds :: GlobalDataStore):GetAsync(dsKey(userId))
	end)
	if ok and typeof(value) == "string" and ClassConfig.get(value) then
		classByUser[userId] = value
		return value
	end
	return nil
end

local function saveClass(userId: number, classId: string)
	classByUser[userId] = classId
	if not ds then
		return
	end
	task.spawn(function()
		pcall(function()
			(ds :: GlobalDataStore):SetAsync(dsKey(userId), classId)
		end)
	end)
end

local function getLevel(player: Player): number
	local attr = player:GetAttribute("PlayerLevel")
	if typeof(attr) == "number" then
		return attr
	end
	local ok, pls = pcall(function()
		return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerLevelService"))
	end)
	if ok and pls and typeof((pls :: any).getLevel) == "function" then
		return (pls :: any).getLevel(player)
	end
	return 1
end

-- race hp multiplier (lazy require RaceService; default 1 ถ้าไม่มีเผ่า/ยังไม่โหลด)
local function raceHpMult(player: Player): number
	local ok, rs = pcall(function()
		return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("RaceService"))
	end)
	if ok and rs and typeof(rs.getHpMult) == "function" then
		return rs.getHpMult(player)
	end
	return 1
end

local function fireClassChanged(player: Player, def: ClassConfig.ClassDef?)
	local remotes = ReplicatedStorage:FindFirstChild("ClassRemotes")
	local ev = remotes and remotes:FindFirstChild("ClassChanged")
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(player, if def then def.id else nil, if def then def.skills else nil)
	end
end

-- ใส่ค่าคลาสเข้าตัวละคร (attribute + HP) — เรียกตอน spawn/เปลี่ยนคลาส
function ClassService.applyToCharacter(player: Player)
	local classId = classByUser[player.UserId]
	local def = ClassConfig.get(classId)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if def then
		player:SetAttribute("PlayerClass", def.id)
		player:SetAttribute("WeaponType", def.weaponType)
	end
	if hum then
		-- MaxHealth = base × class.hp × race.hp (stack; default 1 ถ้าไม่มี)
		local classHp = if def then def.statMods.hp else 1
		local newMax = math.floor(BASE_MAX_HEALTH * classHp * raceHpMult(player) + 0.5)
		local keep = hum.Health
		hum.MaxHealth = newMax
		hum.Health = if keep > 0 then math.min(keep, newMax) else newMax
	end
end

function ClassService.getClass(player: Player): string?
	return loadClass(player.UserId)
end

function ClassService.getClassDef(player: Player): ClassConfig.ClassDef?
	return ClassConfig.get(loadClass(player.UserId))
end

function ClassService.getAtkMult(player: Player): number
	local def = ClassService.getClassDef(player)
	return if def then def.statMods.atk else 1
end

function ClassService.getCdMult(player: Player): number
	local def = ClassService.getClassDef(player)
	return if def then def.statMods.cdMult else 1
end

-- true = อนุญาตยิงสกิลนี้ (ไม่มีคลาส = อนุญาต default; มีคลาส = ต้องอยู่ในชุดสกิลคลาส)
function ClassService.allowsSkill(player: Player, skillId: string): boolean
	local classId = loadClass(player.UserId)
	if not classId then
		return true
	end
	return ClassConfig.allowsSkill(classId, skillId)
end

-- เปลี่ยน/เลือกคลาส (server-authoritative)
function ClassService.requestChange(player: Player, targetClassId: any): (boolean, string)
	if typeof(targetClassId) ~= "string" then
		return false, "invalid"
	end
	local now = os.clock()
	local last = lastChangeAt[player.UserId]
	if last and (now - last) < CHANGE_DEBOUNCE then
		return false, "เปลี่ยนเร็วเกินไป"
	end
	local current = loadClass(player.UserId)
	local ok, msg = ClassConfig.canChange(current, targetClassId, getLevel(player))
	if not ok then
		return false, msg
	end
	lastChangeAt[player.UserId] = now
	saveClass(player.UserId, targetClassId)
	ClassService.applyToCharacter(player)
	local def = ClassConfig.get(targetClassId)
	fireClassChanged(player, def)
	return true, "ok"
end

local initialized = false
function ClassService.init()
	if initialized then
		return
	end
	initialized = true

	local function onPlayer(player: Player)
		loadClass(player.UserId)
		player.CharacterAdded:Connect(function()
			task.wait(0.2) -- ให้ Humanoid พร้อม
			ClassService.applyToCharacter(player)
			fireClassChanged(player, ClassService.getClassDef(player))
		end)
		if player.Character then
			ClassService.applyToCharacter(player)
		end
	end

	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		classByUser[player.UserId] = nil
		lastChangeAt[player.UserId] = nil
	end)
end

return ClassService
