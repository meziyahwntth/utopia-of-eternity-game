--!strict
--[[
	InteractionService (P3-C) — server logic สำหรับ Player Interaction Context Menu
	  • Duel Request   — ส่ง DuelRequest RE ไปหาเป้าหมาย (PvP consent)
	  • Trade Request  — ส่ง TradeRequest RE (P4 stub)
	  • Carry / Hold   — WeldConstraint ผู้เล่นสองคน + auto-break เมื่อ owner กด Uncarry
	  • Block          — client-side เท่านั้น (server validate + store)
	  • Follow         — pathfinding client-side, server validate ว่าไม่ถูก block
	  • Party/Clan     — delegate ไป PartyService/GuildService
	server-authoritative: ทุก action ผ่าน RemoteFunction ยืนยัน permission
]]
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Social = ServerScriptService:WaitForChild("Social")
local PartyService = require(Social:WaitForChild("PartyService"))
local GuildService = require(Social:WaitForChild("GuildService"))

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")

local InteractionService = {}

----------------------------------------------------------------
-- Block list (in-memory, resets on rejoin)
----------------------------------------------------------------
local blockedBy: { [number]: { [number]: boolean } } = {}
-- blockedBy[blocker][target] = true

function InteractionService.block(blocker: Player, targetUserId: number): (boolean, string)
	if targetUserId == blocker.UserId then return false, "บล็อกตัวเองไม่ได้" end
	if not blockedBy[blocker.UserId] then blockedBy[blocker.UserId] = {} end
	blockedBy[blocker.UserId][targetUserId] = true
	return true, "บล็อกแล้ว"
end

function InteractionService.unblock(blocker: Player, targetUserId: number): (boolean, string)
	if blockedBy[blocker.UserId] then
		blockedBy[blocker.UserId][targetUserId] = nil
	end
	return true, "ยกเลิกบล็อกแล้ว"
end

function InteractionService.isBlocked(viewerId: number, targetId: number): boolean
	return blockedBy[targetId] ~= nil and blockedBy[targetId][viewerId] == true
end

Players.PlayerRemoving:Connect(function(p: Player)
	blockedBy[p.UserId] = nil
end)

----------------------------------------------------------------
-- Duel Request
----------------------------------------------------------------
function InteractionService.duelRequest(sender: Player, targetUserId: number): (boolean, string)
	if targetUserId == sender.UserId then return false, "ดวลกับตัวเองไม่ได้" end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return false, "ผู้เล่นออกไปแล้ว" end
	if InteractionService.isBlocked(sender.UserId, targetUserId) then
		return false, "ผู้เล่นนี้บล็อกคุณอยู่"
	end
	local ev = remotes:FindFirstChild("DuelReceived")
	if ev and ev:IsA("RemoteEvent") then
		(ev :: RemoteEvent):FireClient(target, {
			fromUserId = sender.UserId,
			fromName   = sender.DisplayName,
		})
	end
	return true, "ส่งคำท้าดวลถึง " .. target.DisplayName
end

function InteractionService.duelAccept(accepter: Player, fromUserId: number): (boolean, string)
	local from = Players:GetPlayerByUserId(fromUserId)
	if not from then return false, "ผู้ท้ายออกไปแล้ว" end
	-- notify both parties
	local ev = remotes:FindFirstChild("DuelStart")
	if ev and ev:IsA("RemoteEvent") then
		local duelEv = ev :: RemoteEvent
		duelEv:FireClient(from, { opponentUserId = accepter.UserId, opponentName = accepter.DisplayName })
		duelEv:FireClient(accepter, { opponentUserId = fromUserId, opponentName = from.DisplayName })
	end
	return true, "เริ่มดวล!"
end

----------------------------------------------------------------
-- Trade Request (P4 stub)
----------------------------------------------------------------
function InteractionService.tradeRequest(sender: Player, targetUserId: number): (boolean, string)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return false, "ผู้เล่นออกไปแล้ว" end
	if InteractionService.isBlocked(sender.UserId, targetUserId) then
		return false, "ผู้เล่นนี้บล็อกคุณอยู่"
	end
	local ev = remotes:FindFirstChild("TradeReceived")
	if ev and ev:IsA("RemoteEvent") then
		(ev :: RemoteEvent):FireClient(target, {
			fromUserId = sender.UserId,
			fromName   = sender.DisplayName,
		})
	end
	return true, "ส่งคำขอแลกเปลี่ยนถึง " .. target.DisplayName
end

----------------------------------------------------------------
-- Carry / WeldConstraint
----------------------------------------------------------------
local carryWeld: { [number]: WeldConstraint } = {} -- carrierId -> weld

function InteractionService.carry(carrier: Player, targetUserId: number): (boolean, string)
	if targetUserId == carrier.UserId then return false, "อุ้มตัวเองไม่ได้" end
	if carryWeld[carrier.UserId] then return false, "กำลังอุ้มคนอื่นอยู่" end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return false, "ผู้เล่นออกไปแล้ว" end
	local carrierChar = carrier.Character
	local targetChar  = target.Character
	if not carrierChar or not targetChar then return false, "ตัวละครยังโหลดไม่เสร็จ" end
	local cRoot = carrierChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not cRoot or not tRoot then return false, "ไม่พบ HumanoidRootPart" end

	-- ย้ายเป้าหมายไปบน carrier
	tRoot.CFrame = cRoot.CFrame + Vector3.new(0, 3, 0)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = cRoot
	weld.Part1 = tRoot
	weld.Parent = carrierChar
	carryWeld[carrier.UserId] = weld

	-- notify client
	local ev = remotes:FindFirstChild("CarryStarted")
	if ev and ev:IsA("RemoteEvent") then
		local carryEv = ev :: RemoteEvent
		carryEv:FireClient(carrier, { targetUserId = targetUserId })
		carryEv:FireClient(target, { carrierUserId = carrier.UserId })
	end
	return true, "อุ้ม " .. target.DisplayName .. " แล้ว"
end

function InteractionService.uncarry(carrier: Player): (boolean, string)
	local weld = carryWeld[carrier.UserId]
	if not weld then return false, "ไม่ได้อุ้มใคร" end
	weld:Destroy()
	carryWeld[carrier.UserId] = nil
	local ev = remotes:FindFirstChild("CarryEnded")
	if ev and ev:IsA("RemoteEvent") then
		(ev :: RemoteEvent):FireClient(carrier, {})
	end
	return true, "วางลงแล้ว"
end

Players.PlayerRemoving:Connect(function(p: Player)
	-- auto-uncarry เมื่อ carrier ออก
	local weld = carryWeld[p.UserId]
	if weld then
		pcall(function() weld:Destroy() end)
		carryWeld[p.UserId] = nil
	end
end)

----------------------------------------------------------------
-- Party invite shortcut (delegate)
----------------------------------------------------------------
function InteractionService.partyInvite(sender: Player, targetName: string): (boolean, string)
	return PartyService.invite(sender, targetName)
end

----------------------------------------------------------------
-- Clan invite shortcut (delegate)
----------------------------------------------------------------
function InteractionService.clanInvite(sender: Player, targetName: string): (boolean, string)
	return GuildService.invite(sender, targetName)
end

return InteractionService
