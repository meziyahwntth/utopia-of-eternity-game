--!strict
-- SocialRemoteSetup (P3-A) — สร้างโฟลเดอร์ remote กลางของระบบสังคม (ทุก place)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("SocialRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "SocialRemotes"
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

-- Whisper
ensure("RemoteFunction", "WhisperSend")
ensure("RemoteEvent", "WhisperReceive")
-- (Party/Clan remotes — เพิ่มภายหลัง)
