--!strict
-- MvpBossHandlers — wire SocialRemotes → MvpBossService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MvpBossService = require(script.Parent:WaitForChild("MvpBossService"))
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

ensure("RemoteEvent", "MvpBossStateChanged")
ensure("RemoteEvent", "MvpBossSpawned")
ensure("RemoteEvent", "MvpBossDefeated")
ensure("RemoteEvent", "MvpAnnounce")

local GetMvpStateRF = ensure("RemoteFunction", "GetMvpBossState") :: RemoteFunction
local AttackMvpRF = ensure("RemoteFunction", "AttackMvpBoss") :: RemoteFunction

GetMvpStateRF.OnServerInvoke = function(_player: Player)
	return MvpBossService.getPublicState()
end

local lastAttack: { [number]: number } = {}

AttackMvpRF.OnServerInvoke = function(player: Player)
	local now = os.clock()
	local last = lastAttack[player.UserId] or 0
	if now - last < 0.5 then
		return false, "ช้าลงหน่อย"
	end
	lastAttack[player.UserId] = now
	return MvpBossService.attack(player)
end

print("[Combat] MvpBossHandlers online")
