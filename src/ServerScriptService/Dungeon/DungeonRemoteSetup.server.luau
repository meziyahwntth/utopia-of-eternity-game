--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("DungeonRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "DungeonRemotes"
	folder.Parent = ReplicatedStorage
end

local function ensureRemote(className: string, name: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = folder
	return inst
end

ensureRemote("RemoteFunction", "GetLoadoutCatalog")
ensureRemote("RemoteFunction", "SaveLoadout")
ensureRemote("RemoteFunction", "EnterZone")
ensureRemote("RemoteFunction", "StartBoss")
ensureRemote("RemoteFunction", "HealAlly")
ensureRemote("RemoteFunction", "RecordAssist")
ensureRemote("RemoteEvent", "ZoneStateChanged")
ensureRemote("RemoteEvent", "HealChannelComplete")

print("[Dungeon] Remotes ready")
