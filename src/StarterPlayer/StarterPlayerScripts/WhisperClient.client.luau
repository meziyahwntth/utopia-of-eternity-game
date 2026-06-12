--!strict
--[[
	WhisperClient (P3-A) — slash command /w + แสดงกระซิบในแชท
	ใช้ TextChatService (default chat) — TextChatCommand + DisplaySystemMessage
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local whisperSend = remotes:WaitForChild("WhisperSend") :: RemoteFunction
local whisperReceive = remotes:WaitForChild("WhisperReceive") :: RemoteEvent

local function systemMsg(text: string)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(text)
		end
	end)
end

-- slash command /w  /whisper
local cmd = Instance.new("TextChatCommand")
cmd.Name = "WhisperCommand"
cmd.PrimaryAlias = "/w"
cmd.SecondaryAlias = "/whisper"
cmd.Parent = TextChatService

cmd.Triggered:Connect(function(_origin, unfilteredText)
	-- unfilteredText = "/w <ชื่อ> <ข้อความ>"
	local rest = string.gsub(unfilteredText, "^/%S+%s*", "")
	local name, message = string.match(rest, "^(%S+)%s+(.+)$")
	if not name or not message then
		systemMsg("[ระบบ] ใช้: /w <ชื่อ> <ข้อความ>")
		return
	end
	local ok, msg = whisperSend:InvokeServer(name, message)
	if ok then
		systemMsg(string.format("[กระซิบ → %s] %s", name, message))
	else
		systemMsg("[ระบบ] " .. tostring(msg))
	end
end)

whisperReceive.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end
	systemMsg(string.format("[กระซิบ จาก %s] %s", tostring(data.fromName), tostring(data.message)))
end)
