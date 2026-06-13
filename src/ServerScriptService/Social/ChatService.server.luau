--!strict
--[[
	ChatService (P3-C) — server-authoritative custom chat router
	  • รับ ChatSend (RF) จาก client → validate → filter → route ตาม channel
	  • channels: General (broadcast), Party, Clan (/g), Alliance (/a), Whisper (/w targetName)
	  • TextService:FilterStringAsync สำหรับทุก message (Roblox ToS)
	  • rate-limit per player (RateLimitPerMinute จาก ChatConfig)
	  • slash-command (&& admin :cmd) parse บน server — client ส่งมาเป็น plain text
	  • Admin commands: fly/noclip/speed/kick/tp/heal/god — validate UserId ใน ChatConfig.AdminIds
]]
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService       = game:GetService("TextService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local ChatConfig  = require(Modules:WaitForChild("ChatConfig"))

-- lazy-require social services (อยู่ใน server same script service tree)
local ServerScriptService = game:GetService("ServerScriptService")
local Social = ServerScriptService:WaitForChild("Social")
local PartyService = require(Social:WaitForChild("PartyService"))
local GuildService = require(Social:WaitForChild("GuildService"))
local WhisperService = require(Social:WaitForChild("WhisperService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local chatSend    = remotes:WaitForChild("ChatSend")    :: RemoteFunction
local chatReceive = remotes:WaitForChild("ChatReceive") :: RemoteEvent
local adminCmd    = remotes:WaitForChild("AdminCmd")    :: RemoteFunction

----------------------------------------------------------------
-- Rate-limit
----------------------------------------------------------------
local rateCount: { [number]: number } = {}
local rateReset: { [number]: number } = {}

local function checkRate(userId: number): boolean
	local now = os.time()
	if not rateReset[userId] or now >= rateReset[userId] then
		rateCount[userId] = 0
		rateReset[userId] = now + 60
	end
	rateCount[userId] = (rateCount[userId] or 0) + 1
	return rateCount[userId] <= ChatConfig.RateLimitPerMinute
end

Players.PlayerRemoving:Connect(function(p: Player)
	rateCount[p.UserId] = nil
	rateReset[p.UserId] = nil
end)

----------------------------------------------------------------
-- TextService filter helper
----------------------------------------------------------------
local function filterText(text: string, senderId: number): string
	local filtered = text
	local ok = pcall(function()
		local obj = TextService:FilterStringAsync(text, senderId, Enum.TextFilterContext.PublicChat)
		local s, r = pcall(function()
			return obj:GetNonChatStringForBroadcastAsync()
		end)
		if s then
			filtered = r
		end
	end)
	if not ok then
		-- filter failed → replace with safe fallback
		filtered = string.rep("#", math.min(#text, 20))
	end
	return filtered
end

----------------------------------------------------------------
-- Broadcast helpers
----------------------------------------------------------------
local function broadcastTo(playerList: { Player }, channel: string, fromName: string, message: string, timestamp: number)
	local payload = { channel = channel, fromName = fromName, message = message, timestamp = timestamp }
	for _, p in playerList do
		chatReceive:FireClient(p, payload)
	end
end

local function allPlayers(): { Player }
	return Players:GetPlayers()
end

local function questChatProgress(player: Player)
	pcall(function()
		require(ServerScriptService:WaitForChild("Progression"):WaitForChild("QuestService")).recordProgress(
			player,
			"send_chat",
			1
		)
	end)
end

local function partyMembers(player: Player): { Player }
	return PartyService.getPartyMembers(player)
end

local function _clanMembers(player: Player): { Player }
	local g = GuildService.getPlayerGuild(player)
	if not g then return {} end
	local result: { Player } = {}
	for uidStr in g.members do
		local uid = tonumber(uidStr)
		if uid then
			local p = Players:GetPlayerByUserId(uid)
			if p then table.insert(result, p) end
		end
	end
	return result
end

local function _allianceMembers(player: Player): { Player }
	local g = GuildService.getPlayerGuild(player)
	if not g or not g.allianceId or g.allianceId == "" then return {} end
	local aid = g.allianceId
	local result: { Player } = {}
	for _, pl in Players:GetPlayers() do
		local pg = GuildService.getPlayerGuild(pl)
		if pg and pg.allianceId == aid then
			table.insert(result, pl)
		end
	end
	return result
end

----------------------------------------------------------------
-- Admin command executor
----------------------------------------------------------------
local adminSet: { [number]: boolean } = {}
for _, uid in ChatConfig.AdminIds do
	adminSet[uid] = true
end

local function execAdminCmd(player: Player, cmd: string, args: { string }): (boolean, string)
	if not adminSet[player.UserId] then
		return false, "ไม่มีสิทธิ์ admin"
	end
	local c = string.lower(cmd)
	if c == "kick" then
		local targetName = args[1] or ""
		for _, p in Players:GetPlayers() do
			if string.lower(p.Name) == string.lower(targetName) then
				p:Kick("Kicked by admin")
				return true, "เตะ " .. p.Name .. " แล้ว"
			end
		end
		return false, "ไม่พบผู้เล่น " .. targetName
	elseif c == "heal" then
		local targetName = args[1] or player.Name
		for _, p in Players:GetPlayers() do
			if string.lower(p.Name) == string.lower(targetName) then
				local char = p.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then hum.Health = hum.MaxHealth end
				end
				return true, "heal " .. p.Name
			end
		end
		return false, "ไม่พบผู้เล่น"
	elseif c == "tp" then
		-- :tp targetName  OR  :tp fromName toName
		if #args >= 2 then
			local from = args[1]
			local to = args[2]
			local fromP: Player? = nil
			local toP: Player? = nil
			for _, p in Players:GetPlayers() do
				if string.lower(p.Name) == string.lower(from) then fromP = p end
				if string.lower(p.Name) == string.lower(to) then toP = p end
			end
			if fromP and toP and fromP.Character and toP.Character then
				local root = toP.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local fr = fromP.Character:FindFirstChild("HumanoidRootPart")
					if fr then
						(fr :: BasePart).CFrame = (root :: BasePart).CFrame + Vector3.new(2, 0, 0)
					end
				end
				return true, "tp " .. from .. " → " .. to
			end
			return false, "ไม่พบผู้เล่น"
		elseif #args == 1 then
			-- tp player to admin
			local targetName = args[1]
			for _, p in Players:GetPlayers() do
				if string.lower(p.Name) == string.lower(targetName) then
					local char = p.Character
					local adminChar = player.Character
					if char and adminChar then
						local root = adminChar:FindFirstChild("HumanoidRootPart")
						if root then
							local fr = char:FindFirstChild("HumanoidRootPart")
							if fr then
								(fr :: BasePart).CFrame = (root :: BasePart).CFrame + Vector3.new(2, 0, 0)
							end
						end
					end
					return true, "tp " .. p.Name .. " มาหาคุณ"
				end
			end
			return false, "ไม่พบผู้เล่น"
		end
		return false, "ใช้: :tp <target> หรือ :tp <from> <to>"
	elseif c == "speed" then
		local targetName = args[1] or player.Name
		local val = tonumber(args[2] or args[1]) or 16
		-- if first arg is a number, apply to self
		if tonumber(args[1]) then
			targetName = player.Name
			val = tonumber(args[1]) :: number
		end
		for _, p in Players:GetPlayers() do
			if string.lower(p.Name) == string.lower(targetName) then
				local char = p.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed = math.clamp(val, 4, 100) end
				end
				return true, "speed " .. p.Name .. " = " .. val
			end
		end
		return false, "ไม่พบผู้เล่น"
	elseif c == "fly" or c == "noclip" or c == "god" then
		-- these require client-side handling — server fires back confirmation
		-- client ChatClient will handle UI notification
		return true, "[admin] " .. c .. " ต้องทำที่ client (stub)"
	end
	return false, "คำสั่งไม่รู้จัก: " .. cmd
end

----------------------------------------------------------------
-- ChatSend handler
----------------------------------------------------------------
chatSend.OnServerInvoke = function(player: Player, channelRaw: any, messageRaw: any, extra: any): (boolean, string)
	if typeof(channelRaw) ~= "string" or typeof(messageRaw) ~= "string" then
		return false, "ข้อมูลไม่ถูกต้อง"
	end
	local channel = channelRaw :: ChatConfig.Channel
	local message = string.sub(messageRaw, 1, ChatConfig.MaxMessageLength)
	message = string.gsub(message, "^%s+", "")
	message = string.gsub(message, "%s+$", "")
	if message == "" then return false, "ข้อความว่าง" end

	if not checkRate(player.UserId) then
		return false, "พูดเร็วเกินไป (rate limit)"
	end

	local filtered = filterText(message, player.UserId)
	local now = os.time()

	if channel == "General" then
		broadcastTo(allPlayers(), "General", player.DisplayName, filtered, now)
		questChatProgress(player)
		return true, ""

	elseif channel == "Party" then
		local members = partyMembers(player)
		if #members == 0 then return false, "คุณไม่ได้อยู่ใน party" end
		broadcastTo(members, "Party", player.DisplayName, filtered, now)
		questChatProgress(player)
		return true, ""

	elseif channel == "Clan" then
		local ok, msg = GuildService.chat(player, filtered)
		if ok then
			questChatProgress(player)
		end
		return ok, msg

	elseif channel == "Alliance" then
		local ok, msg = GuildService.allianceChat(player, filtered)
		if ok then
			questChatProgress(player)
		end
		return ok, msg

	elseif channel == "Whisper" then
		local targetName = if typeof(extra) == "string" then extra else ""
		if targetName == "" then return false, "ระบุชื่อผู้เล่นที่จะกระซิบ" end
		local ok, msg = WhisperService.send(player, targetName, filtered)
		if ok then
			questChatProgress(player)
		end
		return ok, msg
	end

	return false, "channel ไม่รู้จัก: " .. channel
end

----------------------------------------------------------------
-- AdminCmd handler
----------------------------------------------------------------
adminCmd.OnServerInvoke = function(player: Player, cmd: any, ...: any): (boolean, string)
	if typeof(cmd) ~= "string" then return false, "invalid" end
	local args: { string } = {}
	for _, v in { ... } do
		if typeof(v) == "string" then table.insert(args, v) end
	end
	return execAdminCmd(player, cmd, args)
end

----------------------------------------------------------------
-- AlliancePermSetReq handler
----------------------------------------------------------------
local alliancePermSetReq = remotes:WaitForChild("AlliancePermSetReq") :: RemoteFunction
alliancePermSetReq.OnServerInvoke = function(player: Player, targetUserId: any, canSpeak: any): (boolean, string)
	return GuildService.setAlliancePermission(player, targetUserId, canSpeak)
end

print("[Social] ChatService online — General/Party/Clan/Alliance/Whisper + Admin (P3-C)")
