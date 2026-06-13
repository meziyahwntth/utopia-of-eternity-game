--!strict
--[[
	PlayerLevelService (P7 stub) — level attribute + tier broadcast via VisiblePowerService
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlayerTierConfig"))
local VisiblePowerService = require(script.Parent:WaitForChild("VisiblePowerService"))

local PlayerLevelService = {}

local LEVEL_ATTR = "PlayerLevel"
local levels: { [number]: number } = {}

local function readLevel(player: Player): number
	local attr = player:GetAttribute(LEVEL_ATTR)
	if typeof(attr) == "number" and attr >= 1 then
		return math.floor(attr)
	end
	return 1
end

local function applyLevel(player: Player, newLevel: number)
	levels[player.UserId] = newLevel
	player:SetAttribute(LEVEL_ATTR, newLevel)
	local tier = PlayerTierConfig.getTierForLevel(newLevel)
	player:SetAttribute("PlayerTier", tier.tier)
	VisiblePowerService.onLevelChanged(player, newLevel)
end

function PlayerLevelService.getLevel(player: Player): number
	return levels[player.UserId] or readLevel(player)
end

function PlayerLevelService.setLevel(player: Player, newLevel: number)
	applyLevel(player, math.max(1, math.floor(newLevel)))
end

function PlayerLevelService.addLevel(player: Player, delta: number)
	PlayerLevelService.setLevel(player, PlayerLevelService.getLevel(player) + delta)
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

function PlayerLevelService.init(remotesFolder: Folder)
	VisiblePowerService.init(remotesFolder)
end

function PlayerLevelService.onPlayerReady(player: Player)
	local level = readLevel(player)
	levels[player.UserId] = level
	applyLevel(player, level)
end

Players.PlayerAdded:Connect(function(player)
	PlayerLevelService.onPlayerReady(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		VisiblePowerService.onLevelChanged(player, PlayerLevelService.getLevel(player))
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	levels[player.UserId] = nil
end)

return PlayerLevelService
