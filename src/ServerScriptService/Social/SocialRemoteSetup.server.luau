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
-- Audio Settings
ensure("RemoteFunction", "AudioGet")
ensure("RemoteEvent", "AudioSet")
-- Party
ensure("RemoteFunction", "PartyInviteSend") -- (targetName) -> ok,msg
ensure("RemoteFunction", "PartyAccept") -- () -> ok,msg
ensure("RemoteEvent", "PartyDecline") -- ()
ensure("RemoteEvent", "PartyLeave") -- ()
ensure("RemoteFunction", "PartyChatSend") -- (message) -> ok,msg
ensure("RemoteEvent", "PartyInviteReceived") -- server->client
ensure("RemoteEvent", "PartyStateChanged") -- server->client
ensure("RemoteEvent", "PartyChatReceived") -- server->client
-- Guild / Clan
ensure("RemoteFunction", "GuildCreate") -- (name) -> ok,msg
ensure("RemoteEvent", "GuildDisband") -- ()
ensure("RemoteFunction", "GuildInviteSend") -- (targetName) -> ok,msg
ensure("RemoteFunction", "GuildAccept") -- () -> ok,msg
ensure("RemoteEvent", "GuildDecline") -- ()
ensure("RemoteEvent", "GuildLeave") -- ()
ensure("RemoteEvent", "GuildKick") -- (targetUserId)
ensure("RemoteFunction", "GuildSetRank") -- (targetUserId, rank) -> ok,msg
ensure("RemoteFunction", "GuildGet") -- () -> publicState?
ensure("RemoteEvent", "GuildInviteReceived") -- server->client
ensure("RemoteEvent", "GuildStateChanged") -- server->client
-- Guild chunk2: Clan Chat
ensure("RemoteFunction", "GuildChatSend")       -- (message) -> ok,msg
ensure("RemoteEvent",   "GuildChatReceived")     -- server->client: {guildId,guildName,fromName,message}
ensure("RemoteEvent",   "GuildMemberJoined")     -- server->client: {displayName,userId}  (online notify)
-- Guild chunk2: Alliance
ensure("RemoteFunction", "AllianceCreate")       -- (targetClanName) -> ok,msg  (ส่ง invite)
ensure("RemoteFunction", "AllianceAccept")       -- () -> ok,msg
ensure("RemoteEvent",   "AllianceDecline")       -- ()
ensure("RemoteEvent",   "AllianceLeave")         -- ()
ensure("RemoteEvent",   "AllianceInviteReceived") -- server->client: {fromClanName,fromLeaderName}
ensure("RemoteEvent",   "AllianceStateChanged")  -- server->client: {allianceId,guildIds[]}
