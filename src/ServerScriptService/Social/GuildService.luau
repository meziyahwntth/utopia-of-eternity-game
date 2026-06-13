--!strict
--[[
	GuildService (P3-B) — แคลน/กิลด์ (ถาวร DataStore)
	  • create (ต้องเลเวลถึง + ไม่อยู่แคลนอื่น) · disband
	  • invite by ชื่อ (Leader/Officer) → accept/decline (cross-server MessagingService) — ไม่ teleport (แคลนถาวร)
	  • leave · kick (Officer+) · promote/demote (Leader)
	  • reputation → level (1-10) → member cap 20-65 (SocialConfig)
	  • alliance / clan-chat / member-online-notify = chunk ถัดไป (task #33)
	server-authoritative ทั้งหมด
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")

local SocialConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SocialConfig"))
local GuildStore = require(script.Parent:WaitForChild("GuildStore"))
local PrismKeyService =
	require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PrismKeyService"))

type GuildData = GuildStore.GuildData

local GuildService = {}

local TOPIC = "UtopiaSocial_Guild_v1"
local cache: { [string]: GuildData } = {}
local pendingInvite: { [number]: { guildId: string, fromName: string, expiresAt: number } } = {}
local subscribed = false

local REP_PER_LEVEL = 1000

local function remotesFolder(): Instance
	return ReplicatedStorage:WaitForChild("SocialRemotes")
end

local function fireTo(userId: number, remoteName: string, payload: any)
	local target = Players:GetPlayerByUserId(userId)
	if not target then
		return
	end
	local ev = remotesFolder():FindFirstChild(remoteName)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(target, payload)
	end
end

local function newId(): string
	return "g_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
end

local function levelForReputation(rep: number): number
	local lvl = 1
	for n = 2, SocialConfig.Clan.MaxLevel do
		if rep >= (n - 1) * REP_PER_LEVEL then
			lvl = n
		else
			break
		end
	end
	return lvl
end

local function memberCount(g: GuildData): number
	local c = 0
	for _ in g.members do
		c += 1
	end
	return c
end

local function loadGuild(guildId: string): GuildData?
	if cache[guildId] then
		return cache[guildId]
	end
	local g = GuildStore.loadGuild(guildId)
	if g then
		cache[guildId] = g
	end
	return g
end

local function persist(g: GuildData)
	cache[g.id] = g
	task.spawn(function()
		GuildStore.saveGuild(g)
	end)
end

local function publicState(g: GuildData): { [string]: any }
	return {
		id = g.id,
		name = g.name,
		leaderId = g.leaderId,
		level = g.level,
		reputation = g.reputation,
		memberCap = SocialConfig.clanMemberCap(g.level),
		members = g.members,
		allianceId = g.allianceId,
	}
end

local function pushState(g: GuildData)
	for uidStr in g.members do
		local uid = tonumber(uidStr)
		if uid then
			fireTo(uid, "GuildStateChanged", publicState(g))
		end
	end
end

function GuildService.getPlayerGuild(player: Player): GuildData?
	local gid = GuildStore.getPlayerGuildId(player.UserId)
	if not gid then
		return nil
	end
	return loadGuild(gid)
end

local function rankOf(g: GuildData, userId: number): string?
	return g.members[tostring(userId)]
end

local function isOfficerOrLeader(g: GuildData, userId: number): boolean
	local r = rankOf(g, userId)
	return r == "Leader" or r == "Officer"
end

function GuildService.create(player: Player, name: any): (boolean, string)
	if typeof(name) ~= "string" then
		return false, "ชื่อไม่ถูกต้อง"
	end
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if #name < 2 or #name > SocialConfig.Clan.NameMaxLength then
		return false, string.format("ชื่อแคลนต้อง 2-%d ตัวอักษร", SocialConfig.Clan.NameMaxLength)
	end
	if GuildStore.getPlayerGuildId(player.UserId) then
		return false, "คุณอยู่ในแคลนอยู่แล้ว"
	end
	if PrismKeyService.getKeyCount(player) < SocialConfig.Clan.MinPlayerLevelToCreate then
		return false, string.format("ต้องถึงเลเวล %d ก่อนสร้างแคลน", SocialConfig.Clan.MinPlayerLevelToCreate)
	end
	local g: GuildData = {
		id = newId(),
		name = name,
		leaderId = player.UserId,
		members = { [tostring(player.UserId)] = "Leader" },
		level = 1,
		reputation = 0,
		allianceId = nil,
		createdAt = os.time(),
	}
	GuildStore.setPlayerGuildId(player.UserId, g.id)
	persist(g)
	pushState(g)
	return true, "สร้างแคลน " .. name .. " สำเร็จ"
end

function GuildService.disband(player: Player): (boolean, string)
	local g = GuildService.getPlayerGuild(player)
	if not g then
		return false, "คุณไม่อยู่ในแคลน"
	end
	if g.leaderId ~= player.UserId then
		return false, "เฉพาะหัวหน้าแคลนยุบได้"
	end
	for uidStr in g.members do
		local uid = tonumber(uidStr)
		if uid then
			GuildStore.setPlayerGuildId(uid, nil)
			fireTo(uid, "GuildStateChanged", { id = "" })
		end
	end
	cache[g.id] = nil
	GuildStore.deleteGuild(g.id)
	return true, "ยุบแคลนแล้ว"
end

function GuildService.invite(inviter: Player, targetName: any): (boolean, string)
	if typeof(targetName) ~= "string" or targetName == "" then
		return false, "ระบุชื่อผู้เล่น"
	end
	local g = GuildService.getPlayerGuild(inviter)
	if not g then
		return false, "คุณยังไม่มีแคลน — /clancreate <ชื่อ>"
	end
	if not isOfficerOrLeader(g, inviter.UserId) then
		return false, "เฉพาะหัวหน้า/Officer เชิญได้"
	end
	if memberCount(g) >= SocialConfig.clanMemberCap(g.level) then
		return false, "แคลนเต็ม (cap " .. SocialConfig.clanMemberCap(g.level) .. ")"
	end

	local targetUserId: number? = nil
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == string.lower(targetName) or string.lower(p.DisplayName) == string.lower(targetName) then
			targetUserId = p.UserId
			break
		end
	end
	if not targetUserId then
		local ok, uid = pcall(function()
			return Players:GetUserIdFromNameAsync(targetName)
		end)
		if ok and typeof(uid) == "number" then
			targetUserId = uid
		end
	end
	if not targetUserId then
		return false, "ไม่พบผู้เล่นชื่อ " .. targetName
	end
	if GuildStore.getPlayerGuildId(targetUserId) then
		return false, "ผู้เล่นนี้อยู่ในแคลนอื่นแล้ว"
	end

	local invite = { guildId = g.id, fromName = g.name, expiresAt = os.time() + 120 }
	pendingInvite[targetUserId] = invite
	if Players:GetPlayerByUserId(targetUserId) then
		fireTo(targetUserId, "GuildInviteReceived", { guildName = g.name, fromPlayer = inviter.DisplayName })
	else
		task.spawn(function()
			pcall(function()
				MessagingService:PublishAsync(TOPIC, {
					jobId = game.JobId,
					action = "invite",
					targetUserId = targetUserId,
					guildId = g.id,
					guildName = g.name,
					fromPlayer = inviter.DisplayName,
				})
			end)
		end)
	end
	return true, "ส่งคำเชิญแคลนถึง " .. targetName
end

function GuildService.accept(player: Player): (boolean, string)
	local invite = pendingInvite[player.UserId]
	if not invite or os.time() > invite.expiresAt then
		pendingInvite[player.UserId] = nil
		return false, "คำเชิญหมดอายุ"
	end
	pendingInvite[player.UserId] = nil
	if GuildStore.getPlayerGuildId(player.UserId) then
		return false, "คุณอยู่ในแคลนอื่นแล้ว"
	end
	local g = loadGuild(invite.guildId)
	if not g then
		return false, "แคลนไม่มีแล้ว"
	end
	if memberCount(g) >= SocialConfig.clanMemberCap(g.level) then
		return false, "แคลนเต็ม"
	end
	g.members[tostring(player.UserId)] = "Member"
	GuildStore.setPlayerGuildId(player.UserId, g.id)
	persist(g)
	pushState(g)
	return true, "เข้าแคลน " .. g.name .. " แล้ว"
end

function GuildService.decline(player: Player)
	pendingInvite[player.UserId] = nil
end

function GuildService.leave(player: Player): (boolean, string)
	local g = GuildService.getPlayerGuild(player)
	if not g then
		return false, "คุณไม่อยู่ในแคลน"
	end
	if g.leaderId == player.UserId then
		return false, "หัวหน้าต้องโอนตำแหน่งหรือยุบแคลนก่อน"
	end
	g.members[tostring(player.UserId)] = nil
	GuildStore.setPlayerGuildId(player.UserId, nil)
	persist(g)
	fireTo(player.UserId, "GuildStateChanged", { id = "" })
	pushState(g)
	return true, "ออกจากแคลนแล้ว"
end

function GuildService.kick(officer: Player, targetUserId: any): (boolean, string)
	if typeof(targetUserId) ~= "number" then
		return false, "เป้าหมายไม่ถูกต้อง"
	end
	local g = GuildService.getPlayerGuild(officer)
	if not g or not isOfficerOrLeader(g, officer.UserId) then
		return false, "ไม่มีสิทธิ์"
	end
	if targetUserId == g.leaderId then
		return false, "เตะหัวหน้าไม่ได้"
	end
	if not g.members[tostring(targetUserId)] then
		return false, "ไม่ใช่สมาชิกแคลน"
	end
	g.members[tostring(targetUserId)] = nil
	GuildStore.setPlayerGuildId(targetUserId, nil)
	persist(g)
	fireTo(targetUserId, "GuildStateChanged", { id = "" })
	pushState(g)
	return true, "เตะออกแล้ว"
end

function GuildService.setRank(leader: Player, targetUserId: any, rank: any): (boolean, string)
	if typeof(targetUserId) ~= "number" or typeof(rank) ~= "string" then
		return false, "ข้อมูลไม่ถูกต้อง"
	end
	if rank ~= "Officer" and rank ~= "Veteran" and rank ~= "Member" then
		return false, "ยศไม่ถูกต้อง"
	end
	local g = GuildService.getPlayerGuild(leader)
	if not g or g.leaderId ~= leader.UserId then
		return false, "เฉพาะหัวหน้าตั้งยศได้"
	end
	if not g.members[tostring(targetUserId)] then
		return false, "ไม่ใช่สมาชิก"
	end
	if rank == "Officer" then
		local officers = 0
		for _, r in g.members do
			if r == "Officer" then
				officers += 1
			end
		end
		if officers >= SocialConfig.Clan.MaxOfficers then
			return false, "Officer เต็ม (สูงสุด " .. SocialConfig.Clan.MaxOfficers .. ")"
		end
	end
	g.members[tostring(targetUserId)] = rank
	persist(g)
	pushState(g)
	return true, "ตั้งยศแล้ว"
end

function GuildService.addReputation(g: GuildData, amount: number)
	g.reputation = math.max(0, g.reputation + amount)
	local newLevel = levelForReputation(g.reputation)
	if newLevel ~= g.level then
		g.level = newLevel
	end
	persist(g)
	pushState(g)
end

function GuildService.init()
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
				if data.action == "invite" and typeof(data.targetUserId) == "number" then
					local target = Players:GetPlayerByUserId(data.targetUserId)
					if target then
						pendingInvite[data.targetUserId] = {
							guildId = tostring(data.guildId),
							fromName = tostring(data.guildName),
							expiresAt = os.time() + 120,
						}
						fireTo(data.targetUserId, "GuildInviteReceived", {
							guildName = tostring(data.guildName),
							fromPlayer = tostring(data.fromPlayer),
						})
					end
				end
			end)
		end)
		if not ok then
			warn("[Social] Guild MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

return GuildService
