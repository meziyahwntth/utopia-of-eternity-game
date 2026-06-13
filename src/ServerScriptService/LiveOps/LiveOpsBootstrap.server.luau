--!strict
--[[
	LiveOpsBootstrap (P8) — wire Event Calendar, Season, Emote on server start
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EventCalendarService = require(script.Parent:WaitForChild("EventCalendarService"))
local SeasonService = require(script.Parent:WaitForChild("SeasonService"))
local EmoteService = require(ServerScriptService:WaitForChild("Social"):WaitForChild("EmoteService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

EventCalendarService.init(remotes)

local playEmoteRF = remotes:WaitForChild("PlayEmote") :: RemoteFunction
local stopEmoteRF = remotes:WaitForChild("StopEmote") :: RemoteFunction

playEmoteRF.OnServerInvoke = function(player: Player, emoteId: any)
	if typeof(emoteId) ~= "string" then
		return false, "invalid"
	end
	return EmoteService.playEmote(player, emoteId)
end

stopEmoteRF.OnServerInvoke = function(player: Player)
	EmoteService.stopEmote(player)
	return true, "stopped"
end

local season = SeasonService.getCurrentSeason()
print(string.format("[LiveOps] Season: %s", if season then season.nameTH else "none"))
print("[LiveOps] P8 bootstrap online (EventCalendar + Emote + Season)")
