--!strict
--[[
	CombatService (P3-C+) — server-authoritative attack validation + damage.
	Sanity checks: distance, rate limit, line-of-sight raycast.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatConfig"))
local ItemTierConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemTierConfig"))
local NpcDropService = require(script.Parent:WaitForChild("NpcDropService"))

local CombatService = {}

export type AttackResult = {
	ok: boolean,
	reason: string?,
	npcId: number?,
	damage: number?,
	hp: number?,
	maxHp: number?,
}

local lastAttackAt: { [number]: number } = {}
local lastSkillAt: { [number]: { [string]: number } } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getPlayerRoot(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function findNpc(npcId: number): Model?
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("Model") and inst:GetAttribute(CombatConfig.NpcIdAttribute) == npcId then
			return inst
		end
	end
	return nil
end

local function getNpcRoot(npc: Model): BasePart?
	local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function weaponTypeFor(player: Player): CombatConfig.WeaponType
	local raw = player:GetAttribute("WeaponType")
	if typeof(raw) == "string" then
		if raw == "Bow" or raw == "Staff" or raw == "Sword" then
			return raw :: CombatConfig.WeaponType
		end
	end
	return CombatConfig.DefaultWeaponType :: CombatConfig.WeaponType
end

local function weaponTierFor(player: Player): CombatConfig.WeaponTier
	local raw = player:GetAttribute("WeaponTier")
	if typeof(raw) == "string" then
		if raw == "T1" or raw == "T2" or raw == "T3" or raw == "T4" or raw == "T5" then
			return raw :: CombatConfig.WeaponTier
		end
	end
	return CombatConfig.DefaultWeaponTier :: CombatConfig.WeaponTier
end

local function skillMultiplier(skillId: string): number
	local mult = CombatConfig.SkillMultiplier[skillId]
	return if typeof(mult) == "number" then mult else CombatConfig.SkillMultiplier.BasicAttack
end

local function hasLineOfSight(player: Player, npc: Model, origin: Vector3, targetPos: Vector3): boolean
	local char = player.Character
	if not char then
		return false
	end
	rayParams.FilterDescendantsInstances = { char, npc }
	local delta = targetPos - origin
	if delta.Magnitude < 0.05 then
		return true
	end
	local hit = Workspace:Raycast(origin, delta, rayParams)
	if not hit then
		return true
	end
	return hit.Instance:IsDescendantOf(npc)
end

local function checkRate(userId: number, attackSpeed: number): boolean
	local now = os.clock()
	local last = lastAttackAt[userId]
	if last and (now - last) < attackSpeed then
		return false
	end
	lastAttackAt[userId] = now
	return true
end

local function markLastAttacker(targetModel: Model, attackerUserId: number)
	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if targetHumanoid then
		targetHumanoid:SetAttribute("LastAttackerUserId", attackerUserId)
	end
end

local function applyDamage(targetModel: Model, attackerUserId: number, damage: number): Humanoid?
	local hum = targetModel:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	hum:TakeDamage(damage)
	markLastAttacker(targetModel, attackerUserId)
	return hum
end

local function getPlayerItemStore()
	return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerItemStore"))
end

local function weaponDamageFromEquipped(player: Player): number?
	local store = getPlayerItemStore()
	local equipped = store.getEquipped(player.UserId)
	for _, itemId in equipped do
		local def = ItemTierConfig.get(itemId)
		if def and def.weaponType ~= "None" and def.baseDamage then
			return def.baseDamage
		end
	end
	for itemId, _ in store.getInventory(player.UserId) do
		local def = ItemTierConfig.get(itemId)
		if def and def.weaponType ~= "None" and def.baseDamage then
			return def.baseDamage
		end
	end
	return nil
end

local function computeDamage(player: Player, skillId: string): number
	local weaponTier: CombatConfig.WeaponTier = weaponTierFor(player)
	local baseDamages: { [CombatConfig.WeaponTier]: number } = CombatConfig.BaseDamage
	local base = weaponDamageFromEquipped(player) or baseDamages[weaponTier]
	local rawDamage = base * skillMultiplier(skillId)
	local combatMod = player:GetAttribute("OverweightCombatMultiplier")
	if typeof(combatMod) == "number" and combatMod > 0 then
		rawDamage *= combatMod
	end
	return math.floor(rawDamage + 0.5)
end

local function resolveNpcId(npc: Model, fallbackId: number): number
	local attr = npc:GetAttribute(CombatConfig.NpcIdAttribute)
	if typeof(attr) == "number" then
		return math.floor(attr)
	end
	return fallbackId
end

local function grantKillRewards(player: Player, npcId: number)
	local okPls, pls = pcall(function()
		return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerLevelService"))
	end)
	if okPls and pls then
		local baseXP = NpcDropService.getBaseXP(npcId)
		local mult = (pls :: any).getExpGainMultiplier(player)
		local xpGain = math.floor(baseXP * mult + 0.5)
		;(pls :: any).addExp(player, xpGain)
	end

	NpcDropService.grantDrops(player, npcId)

	local killBindable = ReplicatedStorage:FindFirstChild("NpcKillEvent") :: BindableEvent?
	if killBindable then
		killBindable:Fire(player)
	end
end

function CombatService.findNpc(npcId: number): Model?
	return findNpc(npcId)
end

function CombatService.processAttack(player: Player, npcId: any, skillId: any): AttackResult
	if typeof(npcId) ~= "number" or typeof(skillId) ~= "string" then
		return { ok = false, reason = "invalid_payload" }
	end

	local npc = findNpc(npcId)
	if not npc then
		warn("[Combat] reject: npc missing", player.UserId, npcId)
		return { ok = false, reason = "npc_missing", npcId = npcId }
	end

	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return { ok = false, reason = "npc_dead", npcId = npcId }
	end

	local playerRoot = getPlayerRoot(player)
	local npcRoot = getNpcRoot(npc)
	if not playerRoot or not npcRoot then
		warn("[Combat] reject: missing root", player.UserId, npcId)
		return { ok = false, reason = "missing_root", npcId = npcId }
	end

	local maxRanges: { [CombatConfig.WeaponType]: number } = CombatConfig.MaxRange
	local attackSpeeds: { [CombatConfig.WeaponTier]: number } = CombatConfig.AttackSpeed

	local weaponType: CombatConfig.WeaponType = weaponTypeFor(player)
	local weaponTier: CombatConfig.WeaponTier = weaponTierFor(player)
	local maxRange = maxRanges[weaponType]
	local attackSpeed = attackSpeeds[weaponTier]

	local dist = (playerRoot.Position - npcRoot.Position).Magnitude
	if dist > maxRange then
		warn("[Combat] reject: out_of_range", player.UserId, npcId, dist, maxRange)
		return { ok = false, reason = "out_of_range", npcId = npcId }
	end

	if not checkRate(player.UserId, attackSpeed) then
		warn("[Combat] reject: rate_limit", player.UserId, npcId)
		return { ok = false, reason = "rate_limit", npcId = npcId }
	end

	-- server-authoritative per-skill cooldown (anti-exploit)
	local skillCooldowns: { [string]: number } = CombatConfig.SkillCooldown
	local skillCd = skillCooldowns[skillId]
	if typeof(skillCd) == "number" and skillCd > 0 then
		local userSkills = lastSkillAt[player.UserId]
		if not userSkills then
			userSkills = {}
			lastSkillAt[player.UserId] = userSkills
		end
		local lastSkill = userSkills[skillId]
		local nowSkill = os.clock()
		if lastSkill and (nowSkill - lastSkill) < skillCd then
			return { ok = false, reason = "skill_cooldown", npcId = npcId }
		end
		userSkills[skillId] = nowSkill
	end

	if not hasLineOfSight(player, npc, playerRoot.Position, npcRoot.Position) then
		warn("[Combat] reject: blocked_los", player.UserId, npcId)
		return { ok = false, reason = "blocked_los", npcId = npcId }
	end

	local damage = computeDamage(player, skillId)
	local humAfter = applyDamage(npc, player.UserId, damage)
	if humAfter and humAfter.Health <= 0 then
		grantKillRewards(player, resolveNpcId(npc, npcId))
	end

	return {
		ok = true,
		npcId = npcId,
		damage = damage,
		hp = if humAfter then humAfter.Health else 0,
		maxHp = if humAfter then humAfter.MaxHealth else hum.MaxHealth,
	}
end

function CombatService.processPlayerAttack(player: Player, targetUserId: any, skillId: any): AttackResult
	if typeof(targetUserId) ~= "number" or typeof(skillId) ~= "string" then
		return { ok = false, reason = "invalid_payload" }
	end
	if targetUserId == player.UserId then
		return { ok = false, reason = "self_target" }
	end

	-- TODO: PvP zone check (Eternal Colosseum only)

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer or not targetPlayer.Character then
		return { ok = false, reason = "target_missing" }
	end
	local targetModel = targetPlayer.Character
	local hum = targetModel:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return { ok = false, reason = "target_dead" }
	end

	local playerRoot = getPlayerRoot(player)
	local targetRoot = getPlayerRoot(targetModel)
	if not playerRoot or not targetRoot then
		return { ok = false, reason = "missing_root" }
	end

	local maxRanges: { [CombatConfig.WeaponType]: number } = CombatConfig.MaxRange
	local attackSpeeds: { [CombatConfig.WeaponTier]: number } = CombatConfig.AttackSpeed
	local weaponType: CombatConfig.WeaponType = weaponTypeFor(player)
	local weaponTier: CombatConfig.WeaponTier = weaponTierFor(player)
	local maxRange = maxRanges[weaponType]
	local attackSpeed = attackSpeeds[weaponTier]

	local dist = (playerRoot.Position - targetRoot.Position).Magnitude
	if dist > maxRange then
		return { ok = false, reason = "out_of_range" }
	end
	if not checkRate(player.UserId, attackSpeed) then
		return { ok = false, reason = "rate_limit" }
	end
	if not hasLineOfSight(player, targetModel, playerRoot.Position, targetRoot.Position) then
		return { ok = false, reason = "blocked_los" }
	end

	local damage = computeDamage(player, skillId)
	applyDamage(targetModel, player.UserId, damage)

	return {
		ok = true,
		damage = damage,
		hp = hum.Health,
		maxHp = hum.MaxHealth,
	}
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastAttackAt[player.UserId] = nil
	lastSkillAt[player.UserId] = nil
end)

return CombatService
