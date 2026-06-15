--!strict
-- RaceRemoteSetup — สร้าง remotes สำหรับ Race system
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("RaceRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "RaceRemotes"
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

ensure("RemoteFunction", "RequestRaceSelect") -- client→server: เลือกเผ่า
ensure("RemoteFunction", "GetMyRace") -- client→server: ดึงเผ่าปัจจุบัน
ensure("RemoteEvent", "RaceChanged") -- server→client: เผ่าเปลี่ยน
