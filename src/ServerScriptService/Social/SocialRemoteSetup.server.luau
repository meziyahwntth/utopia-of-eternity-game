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

-- P3-C: Alliance Chat + Custom Chat System + Voice
ensure("RemoteFunction", "AllianceChatSend")      -- (message) -> ok,msg
ensure("RemoteEvent",   "AllianceChatReceived")   -- server->client: {allianceId,guildId,fromName,message}
ensure("RemoteEvent",   "AlliancePermSet")        -- server->client: confirm permission change
ensure("RemoteFunction", "AlliancePermSetReq")    -- (targetUserId, canSpeak) -> ok,msg  [leader only]
-- Custom Chat (P3-C) — server-authoritative route
ensure("RemoteFunction", "ChatSend")              -- (channel, message, targetName?) -> ok,msg
ensure("RemoteEvent",   "ChatReceive")            -- server->client: {channel,fromName,message,timestamp}
-- Admin (P3-C)
ensure("RemoteFunction", "AdminCmd")              -- (cmd, ...args) -> ok,msg  [admin only]
-- Voice (P3-C)
ensure("RemoteEvent",   "VoiceToggleMute")        -- client->server: toggle own mute
ensure("RemoteEvent",   "VoiceStateChanged")      -- server->client: {muted:bool}
ensure("RemoteFunction", "VoiceCallRequest")      -- (targetUserId) -> ok,msg

-- P3-C: Player Interaction Context Menu
ensure("RemoteFunction", "DuelSend")            -- client->server: (targetUserId) -> ok,msg
ensure("RemoteFunction", "DuelAccept")          -- client->server: (fromUserId) -> ok,msg
ensure("RemoteEvent",   "DuelReceived")         -- server->client: {fromUserId,fromName}
ensure("RemoteEvent",   "DuelStart")            -- server->client: {opponentUserId,opponentName}
ensure("RemoteFunction", "TradeSend")           -- client->server: (targetUserId) -> ok,msg
ensure("RemoteEvent",   "TradeReceived")        -- server->client: {fromUserId,fromName}
ensure("RemoteFunction", "CarryRequest")        -- client->server: (targetUserId) -> ok,msg
ensure("RemoteEvent",   "UncarryRequest")       -- client->server: uncarry self
ensure("RemoteEvent",   "CarryStarted")         -- server->client: {targetUserId or carrierUserId}
ensure("RemoteEvent",   "CarryEnded")           -- server->client: {}
ensure("RemoteFunction", "BlockPlayer")         -- (targetUserId) -> ok,msg
ensure("RemoteFunction", "UnblockPlayer")       -- (targetUserId) -> ok,msg
ensure("RemoteFunction", "InteractionPartyInvite") -- (targetName) -> ok,msg
ensure("RemoteFunction", "InteractionClanInvite")  -- (targetName) -> ok,msg

-- P5 Clan War
ensure("RemoteFunction", "WarRegister")
ensure("RemoteEvent", "WarStarted")
ensure("RemoteEvent", "WarResult")
ensure("RemoteEvent", "TerritoryUpdate")
ensure("RemoteFunction", "ClaimDividend")
ensure("RemoteFunction", "SetTaxRate")
ensure("RemoteFunction", "GetTerritoryStatus")

-- P5+ Mercenary & Bounty
ensure("RemoteFunction", "PostEscort")
ensure("RemoteFunction", "AcceptEscort")
ensure("RemoteFunction", "CompleteEscort")
ensure("RemoteFunction", "GetEscortJobs")
ensure("RemoteFunction", "PostBounty")
ensure("RemoteFunction", "GetBounties")
ensure("RemoteFunction", "GetBountyOn")

-- P6 Sky Treasure Live-Ops
ensure("RemoteEvent", "SkyTreasureAnnounce")
ensure("RemoteEvent", "SkyTreasureClaimed")
ensure("RemoteFunction", "ClaimChest")

-- P7 Visible Power (tier aura/glow)
ensure("RemoteEvent", "TierChanged")
ensure("RemoteEvent", "PlayerTierBroadcast")

-- P8 Emote + Event Calendar
ensure("RemoteFunction", "PlayEmote")
ensure("RemoteFunction", "StopEmote")
ensure("RemoteEvent", "EmotePlayed")
ensure("RemoteEvent", "EmoteStopped")
ensure("RemoteEvent", "ActiveEventsUpdate")

-- Backlog B: Pet/Companion
ensure("RemoteFunction", "EquipPet")
ensure("RemoteFunction", "UnequipPet")
ensure("RemoteFunction", "GetPetCollection")
ensure("RemoteEvent", "PetEquipped")
ensure("RemoteEvent", "PetUnequipped")
