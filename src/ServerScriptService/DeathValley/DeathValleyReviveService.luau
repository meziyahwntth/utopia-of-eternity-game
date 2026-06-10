--!strict
--[[
	Downed state + Beacon revive — party ไม่ hard-fail ทั้งก้อน.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyBeaconService = require(script.Parent:WaitForChild("DeathValleyBeaconService"))
local SpawnService = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("SpawnService"))

local WorldPlaceGuard = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local DeathValleyReviveService = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local playerDownedEvent = remotes:WaitForChild("PlayerDowned") :: RemoteEvent

local pendingRevives: { [number]: { targetId: number, startedAt: number } } = {}

local function isDeathValleyPlace(): boolean
	return WorldPlaceGuard:GetCurrentPlaceKey() == "DeathValley"
end

local function setDowned(player: Player, downed: boolean)
	player:SetAttribute("DV_Downed", downed)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not root then
		return
	end
	if downed then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.AutoRotate = false
		root.Anchored = true
		hum.Health = 1
	else
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		hum.AutoRotate = true
		root.Anchored = false
		hum.Health = math.max(hum.Health, hum.MaxHealth * PrismDeathValleySurvivalConfig.Revive.ReviveHealthPercent)
	end
end

function DeathValleyReviveService.onHumanoidDied(player: Player)
	if not isDeathValleyPlace() then
		return
	end
	if player:GetAttribute("DV_Downed") == true then
		return
	end
	setDowned(player, true)
	playerDownedEvent:FireAllClients({
		userId = player.UserId,
		name = player.DisplayName,
		deadline = os.clock() + PrismDeathValleySurvivalConfig.Revive.DownedSeconds,
	})

		task.delay(PrismDeathValleySurvivalConfig.Revive.DownedSeconds, function()
		if player.Parent and player:GetAttribute("DV_Downed") == true then
			SpawnService.respawnPlayer(player)
		end
	end)

	task.spawn(function()
		local soloWait = PrismDeathValleySurvivalConfig.Revive.SoloAutoReviveSeconds
		task.wait(soloWait)
		if player.Parent and player:GetAttribute("DV_Downed") == true then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and DeathValleyBeaconService.isInsideSanctuary(root.Position) then
				DeathValleyReviveService.revivePlayer(player, player)
			end
		end
	end)
end

function DeathValleyReviveService.bindPlayer(player: Player)
	local function bindCharacter(char: Model)
		if not isDeathValleyPlace() then
			return
		end
		player:SetAttribute("DV_Downed", false)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.HealthChanged:Connect(function(health)
			if health <= 0 and player:GetAttribute("DV_Downed") ~= true then
				hum.Health = 1
				DeathValleyReviveService.onHumanoidDied(player)
			end
		end)
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end
end

function DeathValleyReviveService.startReviveChannel(reviver: Player, targetUserId: number): (boolean, string, number?)
	if typeof(targetUserId) ~= "number" then
		return false, "Invalid target", nil
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target:GetAttribute("DV_Downed") ~= true then
		return false, "Target not downed", nil
	end
	local reviverRoot = reviver.Character and reviver.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not reviverRoot or not DeathValleyBeaconService.isInsideSanctuary(reviverRoot.Position) then
		return false, "Stand at the Beacon to revive", nil
	end
	pendingRevives[reviver.UserId] = {
		targetId = targetUserId,
		startedAt = os.clock(),
	}
	return true, "Reviving...", PrismDeathValleySurvivalConfig.Revive.ChannelSeconds
end

function DeathValleyReviveService.completeReviveChannel(reviver: Player): (boolean, string)
	local pending = pendingRevives[reviver.UserId]
	if not pending then
		return false, "No revive in progress"
	end
	pendingRevives[reviver.UserId] = nil
	if os.clock() - pending.startedAt < PrismDeathValleySurvivalConfig.Revive.ChannelSeconds - 0.2 then
		return false, "Revive interrupted"
	end
	local target = Players:GetPlayerByUserId(pending.targetId)
	if not target then
		return false, "Target left"
	end
	return DeathValleyReviveService.revivePlayer(reviver, target)
end

function DeathValleyReviveService.revivePlayer(reviver: Player, target: Player): (boolean, string)
	if target:GetAttribute("DV_Downed") ~= true then
		return false, "Target not downed"
	end
	setDowned(target, false)
	target:SetAttribute("DV_Downed", false)
	return true, string.format("%s revived %s", reviver.DisplayName, target.DisplayName)
end

function DeathValleyReviveService.start()
	for _, player in Players:GetPlayers() do
		DeathValleyReviveService.bindPlayer(player)
	end
	Players.PlayerAdded:Connect(function(player)
		DeathValleyReviveService.bindPlayer(player)
	end)
end

return DeathValleyReviveService
