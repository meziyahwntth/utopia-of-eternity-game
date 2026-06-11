--!strict
--[[
	Combat loop — ผู้เล่นกด strike (F) → server หา wraith ใกล้สุดในระยะ → apply damage
	ฆ่าได้ → Luminite shards + DV_WraithKills + WraithKilled event (HUD toast)
	no-P2W: ดาเมจคงที่จาก config ไม่ขึ้นกับไอเทมซื้อ · server-authoritative ทั้งหมด
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyWraithFactory = require(script.Parent:WaitForChild("DeathValleyWraithFactory"))

local DeathValleyCombatService = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local wraithKilledEvent = remotes:WaitForChild("WraithKilled") :: RemoteEvent

local lastAttackAt: { [number]: number } = {}

local function getCombatConfig()
	return PrismDeathValleySurvivalConfig.Combat
end

local function onWraithKilled(attacker: Player?, kind: string, position: Vector3)
	local combat = getCombatConfig()
	local reward = combat.ShardRewards[kind] or 0

	if attacker then
		local shards = attacker:GetAttribute("DV_LuminiteShards")
		if typeof(shards) ~= "number" then
			shards = 0
		end
		attacker:SetAttribute("DV_LuminiteShards", shards + reward)

		local kills = attacker:GetAttribute("DV_WraithKills")
		if typeof(kills) ~= "number" then
			kills = 0
		end
		attacker:SetAttribute("DV_WraithKills", kills + 1)
	end

	wraithKilledEvent:FireAllClients({
		kind = kind,
		position = position,
		killerUserId = if attacker then attacker.UserId else nil,
		killerName = if attacker then attacker.Name else nil,
		shardReward = reward,
		activeWraiths = DeathValleyWraithFactory.getActiveCount(),
	})
end

function DeathValleyCombatService.attack(player: Player): (boolean, string)
	local combat = getCombatConfig()

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return false, "You are down"
	end
	if player:GetAttribute("DV_Downed") then
		return false, "You are downed — wait for revive"
	end

	local now = os.clock()
	local last = lastAttackAt[player.UserId]
	if last and now - last < combat.AttackCooldownSeconds then
		return false, ""
	end
	lastAttackAt[player.UserId] = now

	local target = DeathValleyWraithFactory.findNearestActive(root.Position, combat.AttackRangeStuds)
	if not target then
		return false, "No wraith in range"
	end

	local kind = tostring(target:GetAttribute("WraithKind"))
	local died, remaining = DeathValleyWraithFactory.applyDamage(target, combat.BaseDamage, player)
	if died then
		local reward = combat.ShardRewards[kind] or 0
		return true, string.format("Wraith destroyed! +%d shards", reward)
	end
	return true, string.format("Hit — %d HP left", math.floor(remaining + 0.5))
end

function DeathValleyCombatService.start()
	DeathValleyWraithFactory.setOnKilled(onWraithKilled)
	Players.PlayerRemoving:Connect(function(player)
		lastAttackAt[player.UserId] = nil
	end)
	print("[DeathValley] Combat service online — strike loop ready")
end

return DeathValleyCombatService
