--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("MountRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "MountRemotes"
	folder.Parent = ReplicatedStorage
end

local function ensureRemote(className: string, name: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

ensureRemote("RemoteFunction", "GetRewardCatalog")
ensureRemote("RemoteFunction", "ClaimMountReward")
ensureRemote("RemoteFunction", "GetEternityShopCatalog")
ensureRemote("RemoteFunction", "DevGrantEternityItem")
ensureRemote("RemoteEvent", "MountRewardResult")
ensureRemote("RemoteEvent", "OpenEternityShop")

print("[Mount] Remotes ready")
