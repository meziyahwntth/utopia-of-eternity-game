--!strict
-- CombatHandlers (P3-C+) — wire combat remotes → services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatService = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatService"))
local AutoBattleService = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("AutoBattleService"))

local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local attackRequest = remotes:WaitForChild("CombatAttackRequest") :: RemoteEvent
local resultClient = remotes:WaitForChild("CombatResultClient") :: RemoteEvent
local autoToggle = remotes:WaitForChild("AutoBattleToggle") :: RemoteFunction

attackRequest.OnServerEvent:Connect(function(player: Player, npcId: any, skillId: any)
	local skill = if typeof(skillId) == "string" then skillId else AutoBattleService.defaultSkill()
	local result = CombatService.processAttack(player, npcId, skill)
	if result.ok then
		resultClient:FireClient(player, {
			ok = true,
			npcId = result.npcId,
			damage = result.damage,
			hp = result.hp,
			maxHp = result.maxHp,
			skillId = skill,
		})
	end
end)

autoToggle.OnServerInvoke = function(player: Player, enabled: any, targetId: any?)
	return AutoBattleService.setAutoMode(player, enabled, targetId)
end

print("[Combat] handlers online (P3-C+)")
