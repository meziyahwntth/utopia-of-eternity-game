--!strict
--[[
	PartyService (P3-A) — ปาร์ตี้สังคม global
	  • /invite <ชื่อ>  → resolve username→userId → ส่งคำเชิญ (same-server + cross-server MessagingService)
	  • รับเชิญ → ถ้าคนละ server: teleport-to-join (cooldown 30 นาที/คน) มา server หัวหน้า
	  • party chat (/p) · ออก/ยุบปาร์ตี้
	  • server-authoritative · สูงสุด SocialConfig.Party.MaxMembers (12)

	reuse: FriendPresence (หา jobId หัวหน้าเพื่อ teleport-to-join)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")

local SocialConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SocialConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local FriendPresence =
	require(ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleyFriendPresenceService"))

type Party = { id: string, leaderId: number, members: { number } }
type Invite = { partyId: string, fromUserId: number, fromName: string, targetUserId: number, expiresAt: number }

local PartyService = {}

local TOPIC = "UtopiaSocial_Party_v1"
local parties: { [string]: Party } = {}
local playerParty: { [number]: string } = {} -- userId -> partyId
local pendingInvite: { [number]: Invite } = {} -- targetUserId -> invite
local lastTeleportJoin: { [number]: number } = {} -- userId -> os.time
local subscribed = false

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
	return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

local function getParty(userId: number): Party?
	local pid = playerParty[userId]
	return if pid then parties[pid] else nil
end

local function broadcastState(party: Party)
	local names: { [number]: string } = {}
	for _, uid in party.members do
		local p = Players:GetPlayerByUserId(uid)
		names[uid] = if p then p.DisplayName else tostring(uid)
	end
	for _, uid in party.members do
		fireTo(uid, "PartyStateChanged", {
			id = party.id,
			leaderId = party.leaderId,
			members = party.members,
			names = names,
		})
	end
end

local function ensureParty(leader: Player): Party
	local existing = getParty(leader.UserId)
	if existing then
		return existing
	end
	local party: Party = { id = newId(), leaderId = leader.UserId, members = { leader.UserId } }
	parties[party.id] = party
	playerParty[leader.UserId] = party.id
	return party
end

-- เพิ่มสมาชิกเข้าปาร์ตี้ (server เดียวกันแล้ว)
function PartyService.addMember(party: Party, userId: number)
	if #party.members >= SocialConfig.Party.MaxMembers then
		return
	end
	if playerParty[userId] then
		return
	end
	table.insert(party.members, userId)
	playerParty[userId] = party.id
	broadcastState(party)
end

-- ส่งคำเชิญ (resolve ชื่อ → userId)
function PartyService.invite(sender: Player, targetName: any): (boolean, string)
	if typeof(targetName) ~= "string" or targetName == "" then
		return false, "ระบุชื่อเพื่อน"
	end
	local party = ensureParty(sender)
	if party.leaderId ~= sender.UserId then
		return false, "เฉพาะหัวหน้าปาร์ตี้เชิญได้"
	end
	if #party.members >= SocialConfig.Party.MaxMembers then
		return false, "ปาร์ตี้เต็ม"
	end

	-- resolve ชื่อ → userId (username)
	local targetUserId: number? = nil
	local localTarget: Player? = nil
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == string.lower(targetName) or string.lower(p.DisplayName) == string.lower(targetName) then
			localTarget = p
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
	if targetUserId == sender.UserId then
		return false, "เชิญตัวเองไม่ได้"
	end
	if playerParty[targetUserId] then
		return false, "ผู้เล่นนี้อยู่ในปาร์ตี้อื่นแล้ว"
	end

	local invite: Invite = {
		partyId = party.id,
		fromUserId = sender.UserId,
		fromName = sender.DisplayName,
		targetUserId = targetUserId,
		expiresAt = os.time() + SocialConfig.Party.InviteTimeoutSeconds,
	}
	pendingInvite[targetUserId] = invite

	if localTarget then
		fireTo(targetUserId, "PartyInviteReceived", invite)
	else
		task.spawn(function()
			pcall(function()
				MessagingService:PublishAsync(TOPIC, { jobId = game.JobId, action = "invite", invite = invite })
			end)
		end)
	end
	return true, "ส่งคำเชิญถึง " .. targetName
end

-- teleport-to-join: ย้ายผู้รับมา server หัวหน้า (ถ้าคนละ server)
local function teleportToLeader(target: Player, leaderId: number, partyId: string): (boolean, string)
	local now = os.time()
	local last = lastTeleportJoin[target.UserId]
	if last and (now - last) < SocialConfig.Party.TeleportToJoinCooldownSeconds then
		local remain = math.ceil((SocialConfig.Party.TeleportToJoinCooldownSeconds - (now - last)) / 60)
		return false, string.format("ต้องรออีก %d นาที หรือใช้เครื่องบิน", remain)
	end
	local presence = FriendPresence.getPresence(leaderId)
	if not presence then
		return false, "หาหัวหน้าปาร์ตี้ไม่เจอ (อาจออฟไลน์)"
	end
	local placeId = PlaceTeleport:GetPlaceId((presence.placeKey :: any))
	if not placeId or placeId <= 0 then
		return false, "ปลายทางยังไม่พร้อม (place ยังไม่ publish)"
	end
	lastTeleportJoin[target.UserId] = now
	local ok, err = pcall(function()
		local options = Instance.new("TeleportOptions")
		options.ServerInstanceId = presence.jobId
		options:SetTeleportData({ socialParty = { partyId = partyId, leaderId = leaderId } })
		TeleportService:TeleportAsync(placeId, { target }, options)
	end)
	if not ok then
		lastTeleportJoin[target.UserId] = last -- คืน cooldown ถ้า fail
		return false, "teleport ล้มเหลว: " .. tostring(err)
	end
	return true, "กำลังย้ายไปหาปาร์ตี้..."
end

function PartyService.accept(target: Player): (boolean, string)
	local invite = pendingInvite[target.UserId]
	if not invite or os.time() > invite.expiresAt then
		pendingInvite[target.UserId] = nil
		return false, "คำเชิญหมดอายุ"
	end
	pendingInvite[target.UserId] = nil
	local leaderId = invite.fromUserId -- ผู้เชิญ = หัวหน้าปาร์ตี้
	local leaderHere = Players:GetPlayerByUserId(leaderId)
	if leaderHere then
		local party = getParty(leaderId)
		if not party then
			return false, "ปาร์ตี้ไม่มีแล้ว"
		end
		if #party.members >= SocialConfig.Party.MaxMembers then
			return false, "ปาร์ตี้เต็ม"
		end
		PartyService.addMember(party, target.UserId)
		return true, "เข้าปาร์ตี้แล้ว"
	end
	-- หัวหน้าอยู่ server อื่น → teleport-to-join (พา partyId/leaderId ไปด้วย)
	return teleportToLeader(target, leaderId, invite.partyId)
end

function PartyService.decline(target: Player)
	pendingInvite[target.UserId] = nil
end

function PartyService.leave(player: Player)
	local party = getParty(player.UserId)
	if not party then
		return
	end
	playerParty[player.UserId] = nil
	local nm: { number } = {}
	for _, uid in party.members do
		if uid ~= player.UserId then
			table.insert(nm, uid)
		end
	end
	party.members = nm
	fireTo(player.UserId, "PartyStateChanged", { id = "", leaderId = 0, members = {}, names = {} })
	if #party.members == 0 then
		parties[party.id] = nil
		return
	end
	if party.leaderId == player.UserId then
		party.leaderId = party.members[1] -- โอนหัวหน้า
	end
	broadcastState(party)
end

function PartyService.chat(player: Player, message: any): (boolean, string)
	if typeof(message) ~= "string" or message == "" then
		return false, "ข้อความว่าง"
	end
	local party = getParty(player.UserId)
	if not party then
		return false, "ยังไม่อยู่ในปาร์ตี้"
	end
	if #message > 200 then
		message = string.sub(message, 1, 200)
	end
	for _, uid in party.members do
		fireTo(uid, "PartyChatReceived", { fromName = player.DisplayName, message = message })
	end
	return true, ""
end

-- เมื่อผู้เล่นที่ถูก teleport-to-join มาถึง server หัวหน้า → เพิ่มเข้าปาร์ตี้
function PartyService.onArrival(player: Player)
	local joinData = player:GetJoinData()
	local td = joinData.TeleportData
	if typeof(td) ~= "table" then
		return
	end
	local sp = td.socialParty
	if typeof(sp) ~= "table" or typeof(sp.leaderId) ~= "number" then
		return
	end
	local leaderHere = Players:GetPlayerByUserId(sp.leaderId)
	if not leaderHere then
		return
	end
	local party = getParty(sp.leaderId)
	if party then
		PartyService.addMember(party, player.UserId)
	end
end

function PartyService.onRemoving(player: Player)
	PartyService.leave(player)
	pendingInvite[player.UserId] = nil
end

function PartyService.init()
	Players.PlayerRemoving:Connect(PartyService.onRemoving)
	Players.PlayerAdded:Connect(function(p)
		task.defer(PartyService.onArrival, p)
	end)
	for _, p in Players:GetPlayers() do
		task.defer(PartyService.onArrival, p)
	end
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
				if data.action == "invite" and typeof(data.invite) == "table" then
					local invite = data.invite :: Invite
					local target = Players:GetPlayerByUserId(invite.targetUserId)
					if target then
						pendingInvite[invite.targetUserId] = invite
						fireTo(invite.targetUserId, "PartyInviteReceived", invite)
					end
				end
			end)
		end)
		if not ok then
			warn("[Social] Party MessagingService subscribe failed (Studio API off?)")
			subscribed = false
		end
	end)
end

return PartyService
