--!strict
-- SocialHandlers (P3-A) — wire ระบบสังคม (whisper) ทุก place
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WhisperService = require(script.Parent:WaitForChild("WhisperService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local whisperSend = remotes:WaitForChild("WhisperSend") :: RemoteFunction

whisperSend.OnServerInvoke = function(player: Player, targetName: any, message: any)
	return WhisperService.send(player, targetName, message)
end

WhisperService.init()

print("[Social] handlers online — whisper")
