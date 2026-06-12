--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("CommerceRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "CommerceRemotes"
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

ensureRemote("RemoteFunction", "GetShopCatalog")
ensureRemote("RemoteFunction", "PurchaseItem")
ensureRemote("RemoteEvent", "ShopOpened")
ensureRemote("RemoteEvent", "PurchaseResult")
ensureRemote("RemoteFunction", "GetShopDirectory")
ensureRemote("RemoteFunction", "RentShop")
ensureRemote("RemoteFunction", "SetShopName")
ensureRemote("RemoteEvent", "ShopLeaseChanged")
ensureRemote("RemoteEvent", "OpenShopPromoterDialog")

print("[Commerce] Remotes ready")
