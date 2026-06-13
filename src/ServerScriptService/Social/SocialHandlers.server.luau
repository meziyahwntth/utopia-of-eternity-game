--!strict
-- SocialHandlers (P3-A/P3-B) — wire ระบบสังคม ทุก place: whisper + audio + party + guild/clan
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WhisperService = require(script.Parent:WaitForChild("WhisperService"))
local AudioSettingsService = require(script.Parent:WaitForChild("AudioSettingsService"))
local PartyService = require(script.Parent:WaitForChild("PartyService"))
local GuildService = require(script.Parent:WaitForChild("GuildService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")

-- Whisper
local whisperSend = remotes:WaitForChild("WhisperSend") :: RemoteFunction
-- Audio
local audioGet = remotes:WaitForChild("AudioGet") :: RemoteFunction
local audioSet = remotes:WaitForChild("AudioSet") :: RemoteEvent
-- Party
local partyInviteSend = remotes:WaitForChild("PartyInviteSend") :: RemoteFunction
local partyAccept = remotes:WaitForChild("PartyAccept") :: RemoteFunction
local partyDecline = remotes:WaitForChild("PartyDecline") :: RemoteEvent
local partyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent
local partyChatSend = remotes:WaitForChild("PartyChatSend") :: RemoteFunction
-- Guild / Clan (P3-B)
local guildCreate = remotes:WaitForChild("GuildCreate") :: RemoteFunction
local guildDisband = remotes:WaitForChild("GuildDisband") :: RemoteEvent
local guildInviteSend = remotes:WaitForChild("GuildInviteSend") :: RemoteFunction
local guildAccept = remotes:WaitForChild("GuildAccept") :: RemoteFunction
local guildDecline = remotes:WaitForChild("GuildDecline") :: RemoteEvent
local guildLeave = remotes:WaitForChild("GuildLeave") :: RemoteEvent
local guildKick = remotes:WaitForChild("GuildKick") :: RemoteEvent
local guildSetRank = remotes:WaitForChild("GuildSetRank") :: RemoteFunction
local guildGet = remotes:WaitForChild("GuildGet") :: RemoteFunction

----------------------------------------------------------------
-- Whisper
----------------------------------------------------------------
whisperSend.OnServerInvoke = function(player: Player, targetName: any, message: any)
	return WhisperService.send(player, targetName, message)
end

----------------------------------------------------------------
-- Audio
----------------------------------------------------------------
audioGet.OnServerInvoke = function(player: Player)
	return AudioSettingsService.get(player)
end

audioSet.OnServerEvent:Connect(function(player: Player, prefs: any)
	AudioSettingsService.set(player, prefs)
end)

----------------------------------------------------------------
-- Party
----------------------------------------------------------------
partyInviteSend.OnServerInvoke = function(player: Player, targetName: any)
	return PartyService.invite(player, targetName)
end
partyAccept.OnServerInvoke = function(player: Player)
	return PartyService.accept(player)
end
partyDecline.OnServerEvent:Connect(function(player: Player)
	PartyService.decline(player)
end)
partyLeave.OnServerEvent:Connect(function(player: Player)
	PartyService.leave(player)
end)
partyChatSend.OnServerInvoke = function(player: Player, message: any)
	return PartyService.chat(player, message)
end

----------------------------------------------------------------
-- Guild / Clan (P3-B)
----------------------------------------------------------------
guildCreate.OnServerInvoke = function(player: Player, name: any)
	return GuildService.create(player, name)
end

guildDisband.OnServerEvent:Connect(function(player: Player)
	local ok, msg = GuildService.disband(player)
	if not ok then
		-- ส่ง state เพื่อแสดงข้อผิดพลาด (ผ่าน GuildStateChanged ที่ client ฟังอยู่)
		local ev = remotes:FindFirstChild("GuildStateChanged")
		if ev and ev:IsA("RemoteEvent") then
			ev:FireClient(player, { error = msg })
		end
	end
end)

guildInviteSend.OnServerInvoke = function(player: Player, targetName: any)
	return GuildService.invite(player, targetName)
end

guildAccept.OnServerInvoke = function(player: Player)
	return GuildService.accept(player)
end

guildDecline.OnServerEvent:Connect(function(player: Player)
	GuildService.decline(player)
end)

guildLeave.OnServerEvent:Connect(function(player: Player)
	GuildService.leave(player)
end)

guildKick.OnServerEvent:Connect(function(player: Player, targetUserId: any)
	GuildService.kick(player, targetUserId)
end)

guildSetRank.OnServerInvoke = function(player: Player, targetUserId: any, rank: any)
	return GuildService.setRank(player, targetUserId, rank)
end

guildGet.OnServerInvoke = function(player: Player)
	local g = GuildService.getPlayerGuild(player)
	if not g then
		return nil
	end
	-- reuse publicState via GuildService (return field-subset ที่ client ต้องการ)
	return {
		id = g.id,
		name = g.name,
		leaderId = g.leaderId,
		level = g.level,
		reputation = g.reputation,
		members = g.members,
		allianceId = g.allianceId,
	}
end

----------------------------------------------------------------
-- Guild chunk2: Clan Chat + Alliance
----------------------------------------------------------------
local guildChatSend   = remotes:WaitForChild("GuildChatSend")    :: RemoteFunction
local allianceCreate  = remotes:WaitForChild("AllianceCreate")   :: RemoteFunction
local allianceAccept  = remotes:WaitForChild("AllianceAccept")   :: RemoteFunction
local allianceDecline = remotes:WaitForChild("AllianceDecline")  :: RemoteEvent
local allianceLeave   = remotes:WaitForChild("AllianceLeave")    :: RemoteEvent

guildChatSend.OnServerInvoke = function(player: Player, message: any)
	return GuildService.chat(player, message)
end

allianceCreate.OnServerInvoke = function(player: Player, targetClanName: any)
	return GuildService.allianceInvite(player, targetClanName)
end

allianceAccept.OnServerInvoke = function(player: Player)
	return GuildService.allianceAccept(player)
end

allianceDecline.OnServerEvent:Connect(function(player: Player)
	GuildService.allianceDecline(player)
end)

allianceLeave.OnServerEvent:Connect(function(player: Player)
	GuildService.allianceLeave(player)
end)

----------------------------------------------------------------
-- Init all services
----------------------------------------------------------------
WhisperService.init()
PartyService.init()
GuildService.init()

print("[Social] handlers online — whisper + audio + party + guild/clan + alliance (P3-B)")
