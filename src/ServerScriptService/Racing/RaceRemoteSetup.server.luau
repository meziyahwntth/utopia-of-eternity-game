--!strict
-- RaceRemoteSetup — สร้าง remotes สำหรับ Racing system
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("RacingRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "RacingRemotes"
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

ensure("RemoteFunction", "StartRace") -- client→server: เริ่มแข่ง
ensure("RemoteEvent", "CheckpointPing") -- client→server: แตะ checkpoint
ensure("RemoteEvent", "RaceState") -- server→client: started/checkpoint/finished/cancelled
ensure("RemoteFunction", "GetBest") -- client→server: best time ของ track
