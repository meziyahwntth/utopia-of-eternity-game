--!strict
--[[
	PlayerLevelService (Full) — DataStore XP + Level + Tier broadcast
	XP required to level: expNeeded(lv) = lv * 100 + lv^2 * 5
	Max level: 149 (Hero tier cap in PlayerTierConfig)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlayerTierConfig"))
local VisiblePowerService = require(script.Parent:WaitForChild("VisiblePowerService"))
local LevelStore = require(script.Parent:WaitForChild("LevelStore"))

local PlayerLevelService = {}

local cache: { [number]: LevelStore.LevelData } = {}
local remotesFolder: Folder? = nil

local MAX_LEVEL = 149

local function expNeeded(lv: number): number
	return lv * 100 + lv * lv * 5
end

local function applyData(player: Player, data: LevelStore.LevelData)
	cache[player.UserId] = data
	player:SetAttribute("PlayerLevel", data.level)
	player:SetAttribute("PlayerXP", data.xp)
	player:SetAttribute("PlayerXPMax", expNeeded(data.level))
	local tier = PlayerTierConfig.getTierForLevel(data.level)
	player:SetAttribute("PlayerTier", tier.tier)
	VisiblePowerService.onLevelChanged(player, data.level)
end

function PlayerLevelService.getLevel(player: Player): number
	local data = cache[player.UserId]
	return if data then data.level else 1
end

function PlayerLevelService.getXP(player: Player): number
	local data = cache[player.UserId]
	return if data then data.xp else 0
end

function PlayerLevelService.addExp(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	local data = cache[player.UserId]
	if not data then
		return
	end

	data.xp += amount
	local leveledUp = false

	while data.level < MAX_LEVEL do
		local needed = expNeeded(data.level)
		if data.xp >= needed then
			data.xp -= needed
			data.level += 1
			leveledUp = true
		else
			break
		end
	end

	if data.level >= MAX_LEVEL then
		data.xp = 0
	end

	applyData(player, data)

	if leveledUp and remotesFolder then
		local ev = remotesFolder:FindFirstChild("LevelUp") :: RemoteEvent?
		if ev then
			ev:FireClient(player, data.level)
		end
	end

	task.spawn(function()
		LevelStore.save(player.UserId, data)
	end)
end

function PlayerLevelService.addLevel(player: Player, delta: number)
	local data = cache[player.UserId]
	if not data then
		return
	end
	local newLevel = math.clamp(data.level + math.floor(delta), 1, MAX_LEVEL)
	data.level = newLevel
	data.xp = 0
	applyData(player, data)
	task.spawn(function()
		LevelStore.save(player.UserId, data)
	end)
end

function PlayerLevelService.setLevel(player: Player, newLevel: number)
	PlayerLevelService.addLevel(player, newLevel - PlayerLevelService.getLevel(player))
end

function PlayerLevelService.getExpGainMultiplier(player: Player): number
	local mult = 1.0

	local petBonus = player:GetAttribute("PetExpBonus")
	if typeof(petBonus) == "number" and petBonus > 0 then
		mult += petBonus
	end

	local ok, ecs = pcall(function()
		return require(ServerScriptService:WaitForChild("LiveOps"):WaitForChild("EventCalendarService"))
	end)
	if ok then
		mult *= (ecs :: any).getMultiplier("DoubleExp")
	end

	return mult
end

function PlayerLevelService.init(folder: Folder)
	remotesFolder = folder
	VisiblePowerService.init(folder)
end

function PlayerLevelService.onPlayerReady(player: Player)
	local data = LevelStore.get(player.UserId)
	applyData(player, data)
end

Players.PlayerAdded:Connect(function(player)
	PlayerLevelService.onPlayerReady(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		local data = cache[player.UserId]
		if data then
			VisiblePowerService.onLevelChanged(player, data.level)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = cache[player.UserId]
	if data then
		LevelStore.save(player.UserId, data)
	end
	cache[player.UserId] = nil
end)

return PlayerLevelService
