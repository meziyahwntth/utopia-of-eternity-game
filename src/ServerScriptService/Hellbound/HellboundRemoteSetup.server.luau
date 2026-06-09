--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("HellboundRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "HellboundRemotes"
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

ensureRemote("RemoteFunction", "BeginHellboundTravel")
ensureRemote("RemoteFunction", "GetHellboundTravelState")
ensureRemote("RemoteEvent", "TravelStateChanged")
ensureRemote("RemoteEvent", "HellboundJumpSpectator")

print("[Hellbound] Remotes ready")
