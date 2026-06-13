--!strict
--[[
	CombatService (P3-C+) — server-authoritative attack validation + damage.
	Sanity checks: distance, rate limit, line-of-sight raycast.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatConfig"))

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
	local baseDamages: { [CombatConfig.WeaponTier]: number } = CombatConfig.BaseDamage

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

	if not hasLineOfSight(player, npc, playerRoot.Position, npcRoot.Position) then
		warn("[Combat] reject: blocked_los", player.UserId, npcId)
		return { ok = false, reason = "blocked_los", npcId = npcId }
	end

	local base = baseDamages[weaponTier]
	local damage = math.floor(base * skillMultiplier(skillId) + 0.5)
	hum:TakeDamage(damage)

	return {
		ok = true,
		npcId = npcId,
		damage = damage,
		hp = hum.Health,
		maxHp = hum.MaxHealth,
	}
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastAttackAt[player.UserId] = nil
end)

return CombatService
