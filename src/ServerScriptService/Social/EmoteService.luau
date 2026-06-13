--!strict
--[[
	EmoteService (P8) — server validate + broadcast emote animations
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EmoteConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EmoteConfig"))

local function questEmoteProgress(player: Player)
	pcall(function()
		require(ServerScriptService:WaitForChild("Progression"):WaitForChild("QuestService")).recordProgress(
			player,
			"use_emote",
			1
		)
	end)
end

local EmoteService = {}

local lastEmote: { [number]: number } = {}
local COOLDOWN = 2

local function findEmote(id: string): EmoteConfig.EmoteEntry?
	for _, entry in EmoteConfig.Emotes do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

function EmoteService.playEmote(player: Player, emoteId: string): (boolean, string)
	local now = os.time()
	local last = lastEmote[player.UserId] or 0
	if now - last < COOLDOWN then
		return false, string.format("รอ %d วินาที", COOLDOWN - (now - last))
	end

	local emote = findEmote(emoteId)
	if not emote then
		return false, "ไม่พบ emote"
	end

	lastEmote[player.UserId] = now

	local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
	if remotes then
		local ev = remotes:FindFirstChild("EmotePlayed") :: RemoteEvent?
		if ev then
			ev:FireAllClients(player.UserId, emoteId, emote.animationId, emote.looped, emote.durationSecs)
		end
	end
	questEmoteProgress(player)
	return true, emote.nameTH
end

function EmoteService.stopEmote(player: Player)
	local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
	if remotes then
		local ev = remotes:FindFirstChild("EmoteStopped") :: RemoteEvent?
		if ev then
			ev:FireAllClients(player.UserId)
		end
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastEmote[player.UserId] = nil
end)

return EmoteService
