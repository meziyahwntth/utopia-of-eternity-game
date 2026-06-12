--!strict
-- SocialHandlers (P3-A) — wire ระบบสังคม (whisper) ทุก place
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WhisperService = require(script.Parent:WaitForChild("WhisperService"))
local AudioSettingsService = require(script.Parent:WaitForChild("AudioSettingsService"))
local PartyService = require(script.Parent:WaitForChild("PartyService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local whisperSend = remotes:WaitForChild("WhisperSend") :: RemoteFunction
local audioGet = remotes:WaitForChild("AudioGet") :: RemoteFunction
local audioSet = remotes:WaitForChild("AudioSet") :: RemoteEvent
local partyInviteSend = remotes:WaitForChild("PartyInviteSend") :: RemoteFunction
local partyAccept = remotes:WaitForChild("PartyAccept") :: RemoteFunction
local partyDecline = remotes:WaitForChild("PartyDecline") :: RemoteEvent
local partyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent
local partyChatSend = remotes:WaitForChild("PartyChatSend") :: RemoteFunction

whisperSend.OnServerInvoke = function(player: Player, targetName: any, message: any)
	return WhisperService.send(player, targetName, message)
end

audioGet.OnServerInvoke = function(player: Player)
	return AudioSettingsService.get(player)
end

audioSet.OnServerEvent:Connect(function(player: Player, prefs: any)
	AudioSettingsService.set(player, prefs)
end)

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

WhisperService.init()
PartyService.init()

print("[Social] handlers online — whisper + audio + party")
