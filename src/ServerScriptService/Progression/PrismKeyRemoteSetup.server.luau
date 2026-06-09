--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("PrismKeyRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "PrismKeyRemotes"
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

ensureRemote("RemoteFunction", "GetOwnedKeys")
ensureRemote("RemoteFunction", "ExecuteKeyTrade")
ensureRemote("RemoteEvent", "TradeSessionStarted")
ensureRemote("RemoteEvent", "TradeSessionEnded")
ensureRemote("RemoteEvent", "GhostMoved")
ensureRemote("RemoteEvent", "GhostComplaint")

print("[PrismKey] Remotes ready")
