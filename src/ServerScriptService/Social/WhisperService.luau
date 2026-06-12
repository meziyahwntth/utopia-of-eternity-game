--!strict
--[[
	WhisperService (P3-A) — กระซิบส่วนตัว `/w <ชื่อ> <ข้อความ>` ข้ามเซิร์ฟเวอร์
	- หาผู้รับใน server นี้ก่อน → ถ้าไม่เจอใช้ MessagingService หาทุก server
	- server-authoritative + rate-limit กันสแปม
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local SocialConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SocialConfig"))

local WhisperService = {}

local TOPIC = "UtopiaSocial_Whisper_v1"
local rate: { [number]: { count: number, resetAt: number } } = {}
local subscribed = false

local function findLocalByName(name: string): Player?
	local n = string.lower(name)
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == n or string.lower(p.DisplayName) == n then
			return p
		end
	end
	return nil
end

local function checkRate(userId: number): boolean
	local now = os.time()
	local b = rate[userId]
	if not b or now >= b.resetAt then
		rate[userId] = { count = 1, resetAt = now + 60 }
		return true
	end
	if b.count >= SocialConfig.Whisper.RateLimitPerMinute then
		return false
	end
	b.count += 1
	return true
end

local function deliver(target: Player, fromUserId: number, fromName: string, message: string)
	local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes")
	local ev = remotes and remotes:FindFirstChild("WhisperReceive")
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(target, { fromUserId = fromUserId, fromName = fromName, message = message })
	end
end

function WhisperService.send(fromPlayer: Player, targetName: any, message: any): (boolean, string)
	if typeof(targetName) ~= "string" or typeof(message) ~= "string" then
		return false, "ข้อมูลไม่ถูกต้อง"
	end
	targetName = string.gsub(targetName, "^%s+", "")
	targetName = string.gsub(targetName, "%s+$", "")
	if targetName == "" then
		return false, "ระบุชื่อผู้รับ"
	end
	if #message == 0 then
		return false, "ข้อความว่าง"
	end
	if #message > SocialConfig.Whisper.MaxLength then
		message = string.sub(message, 1, SocialConfig.Whisper.MaxLength)
	end
	if not checkRate(fromPlayer.UserId) then
		return false, "ส่งถี่เกินไป รอสักครู่"
	end

	local target = findLocalByName(targetName)
	if target then
		if target == fromPlayer then
			return false, "กระซิบหาตัวเองไม่ได้"
		end
		deliver(target, fromPlayer.UserId, fromPlayer.DisplayName, message)
		return true, "ส่งถึง " .. target.DisplayName
	end

	-- ข้ามเซิร์ฟเวอร์
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(TOPIC, {
				jobId = game.JobId,
				fromUserId = fromPlayer.UserId,
				fromName = fromPlayer.DisplayName,
				targetName = targetName,
				message = message,
			})
		end)
	end)
	return true, "กำลังส่งถึง " .. targetName .. " (ข้ามเมือง)..."
end

function WhisperService.init()
	if subscribed then
		return
	end
	subscribed = true
	task.spawn(function()
		local ok = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(msg)
				local data = msg.Data
				if typeof(data) ~= "table" or data.jobId == game.JobId then
					return
				end
				local target = findLocalByName(tostring(data.targetName))
				if target then
					deliver(target, data.fromUserId, tostring(data.fromName), tostring(data.message))
				end
			end)
		end)
		if not ok then
			warn("[Social] Whisper MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

return WhisperService
