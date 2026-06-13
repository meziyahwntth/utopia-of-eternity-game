--!strict
-- CombatRemoteSetup (P3-C+) — combat remotes (แยกจาก SocialRemotes)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("CombatRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "CombatRemotes"
	folder.Parent = ReplicatedStorage
end

local function ensure(className: string, name: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	local r = Instance.new(className)
	r.Name = name
	r.Parent = folder
	return r
end

ensure("RemoteEvent", "CombatAttackRequest")
ensure("RemoteEvent", "CombatResultClient")
ensure("RemoteFunction", "AutoBattleToggle")
