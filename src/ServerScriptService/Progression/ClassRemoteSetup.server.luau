--!strict
-- ClassRemoteSetup — สร้าง remotes สำหรับ Class/Job system
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("ClassRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "ClassRemotes"
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

ensure("RemoteFunction", "RequestClassChange") -- client→server: เลือก/เปลี่ยนคลาส
ensure("RemoteFunction", "GetMyClass") -- client→server: ดึงคลาสปัจจุบัน (+skills)
ensure("RemoteEvent", "ClassChanged") -- server→client: คลาสเปลี่ยน → SkillBar refresh
