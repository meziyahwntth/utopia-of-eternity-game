--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("SupportDeskRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "SupportDeskRemotes"
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

ensureRemote("RemoteFunction", "SubmitFanReport")
ensureRemote("RemoteFunction", "SubmitBanAppeal")
ensureRemote("RemoteFunction", "GetSupportDeskInfo")

print("[SupportDesk] Remotes ready")
