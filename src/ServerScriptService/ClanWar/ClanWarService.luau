--!strict
--[[
	ClanWarService (P5) — war scheduling, zone capture, territory management
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TerritoryStore = require(script.Parent:WaitForChild("TerritoryStore"))
local DefensiveFatigueService = require(script.Parent:WaitForChild("DefensiveFatigueService"))
local TaxDistributionService = require(script.Parent:WaitForChild("TaxDistributionService"))
local ClanWarConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClanWarConfig"))
local GuildService = require(ServerScriptService:WaitForChild("Social"):WaitForChild("GuildService"))

type WarSession = {
	zoneId: string,
	startedAt: number,
	endsAt: number,
	attackers: { [string]: number },
	defender: string,
	active: boolean,
}

export type TerritoryStatus = {
	zoneId: string,
	displayName: string,
	ownerClanId: string,
	ownerName: string,
	taxRate: number,
	fortHp: number,
	serverBuffActive: boolean,
}

local activeSessions: { [string]: WarSession } = {}
local _remotes: Folder? = nil
local lastWarDayKey = ""

local ClanWarService = {}

local function remotesFolder(): Folder
	return ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
end

local function ownerName(clanId: string): string
	if clanId == "" then
		return "—"
	end
	local guild = GuildService.getById(clanId)
	return if guild then guild.name else clanId
end

local function broadcastTerritory(zoneId: string)
	local territory = TerritoryStore.get(zoneId)
	local ev = remotesFolder():FindFirstChild("TerritoryUpdate")
	if ev and ev:IsA("RemoteEvent") then
		(ev :: RemoteEvent):FireAllClients(zoneId, ownerName(territory.ownerClanId), territory.taxRate, territory.fortHp)
	end
end

local function endWar(zoneId: string)
	local session = activeSessions[zoneId]
	if not session then
		return
	end
	session.active = false

	local winnerId = session.defender
	local topScore = 0
	for clanId, score in session.attackers do
		if score > topScore then
			topScore = score
			winnerId = clanId
		end
	end

	local territory = TerritoryStore.get(zoneId)
	if winnerId ~= "" and winnerId ~= territory.ownerClanId then
		territory.ownerClanId = winnerId
		territory.fortHp = ClanWarConfig.FortHpMax
		territory.weeksClaimed = 0
	end
	territory.lastWarCycleId = tostring(os.time())
	TerritoryStore.save(zoneId, territory)

	local warResult = remotesFolder():FindFirstChild("WarResult")
	if warResult and warResult:IsA("RemoteEvent") then
		(warResult :: RemoteEvent):FireAllClients(zoneId, winnerId)
	end
	broadcastTerritory(zoneId)

	activeSessions[zoneId] = nil
	print(string.format("[ClanWar] %s ended — winner: %s", zoneId, winnerId))
end

function ClanWarService.startWar(zoneId: string)
	if activeSessions[zoneId] then
		return
	end
	local territory = TerritoryStore.get(zoneId)
	local session: WarSession = {
		zoneId = zoneId,
		startedAt = os.time(),
		endsAt = os.time() + ClanWarConfig.WarDurationSecs,
		attackers = {},
		defender = territory.ownerClanId,
		active = true,
	}
	activeSessions[zoneId] = session

	local warStarted = remotesFolder():FindFirstChild("WarStarted")
	if warStarted and warStarted:IsA("RemoteEvent") then
		(warStarted :: RemoteEvent):FireAllClients(zoneId, session.endsAt)
	end

	task.delay(ClanWarConfig.WarDurationSecs, function()
		endWar(zoneId)
	end)
end

function ClanWarService.registerClan(player: Player, zoneId: string): (boolean, string)
	local guild = GuildService.getByPlayer(player)
	if not guild then
		return false, "ไม่ได้อยู่ในแคลน"
	end
	if guild.level < ClanWarConfig.MinClanLevelForWar then
		return false,
			string.format("แคลนต้องระดับ %d+ (ปัจจุบัน %d)", ClanWarConfig.MinClanLevelForWar, guild.level)
	end
	local session = activeSessions[zoneId]
	if not session or not session.active then
		return false, "สงครามยังไม่เริ่ม"
	end
	session.attackers[guild.id] = session.attackers[guild.id] or 0
	return true, "ลงทะเบียนสำเร็จ"
end

function ClanWarService.addScore(clanId: string, zoneId: string, points: number)
	local session = activeSessions[zoneId]
	if not session or not session.active then
		return
	end
	session.attackers[clanId] = (session.attackers[clanId] or 0) + points
end

function ClanWarService.getTerritoryStatus(): { TerritoryStatus }
	local out: { TerritoryStatus } = {}
	for _, zone in ClanWarConfig.Zones do
		local territory = TerritoryStore.get(zone.id)
		table.insert(out, {
			zoneId = zone.id,
			displayName = zone.displayName,
			ownerClanId = territory.ownerClanId,
			ownerName = ownerName(territory.ownerClanId),
			taxRate = territory.taxRate,
			fortHp = territory.fortHp,
			serverBuffActive = territory.serverBuffActive,
		})
	end
	return out
end

function ClanWarService.setTaxRate(player: Player, zoneId: string, rate: number): (boolean, string)
	if rate < 1 or rate > 5 or math.floor(rate) ~= rate then
		return false, "อัตราภาษีต้อง 1-5"
	end
	local guild = GuildService.getByPlayer(player)
	if not guild then
		return false, "ไม่ได้อยู่ในแคลน"
	end
	if guild.leaderId ~= player.UserId then
		return false, "เฉพาะหัวหน้าแคลนตั้งภาษีได้"
	end
	local territory = TerritoryStore.get(zoneId)
	if territory.ownerClanId ~= guild.id then
		return false, "แคลนคุณไม่ได้ครองเขตนี้"
	end
	local mult = ClanWarConfig.MaintenanceMultiplier[rate] or 1
	territory.taxRate = rate
	territory.maintenanceCost = math.floor(ClanWarConfig.BaseMaintenanceCost * mult)
	TerritoryStore.save(zoneId, territory)
	broadcastTerritory(zoneId)
	return true, "ตั้งภาษี " .. tostring(rate) .. "% แล้ว"
end

function ClanWarService.claimDividend(player: Player, zoneId: string): (boolean, string, number)
	local amount = TaxDistributionService.claimDividend(player, zoneId)
	if amount <= 0 then
		return false, "ไม่มีเงินปันผลค้าง", 0
	end
	return true, "รับปันผล " .. tostring(amount) .. " credits", amount
end

local function maybeStartScheduledWars()
	local utc = os.date("!*t")
	local dayKey = string.format("%04d-%02d-%02d", utc.year, utc.yday, utc.hour)
	if utc.wday - 1 ~= ClanWarConfig.WarDayOfWeek then
		return
	end
	if utc.hour ~= ClanWarConfig.WarStartHourUTC then
		return
	end
	if lastWarDayKey == dayKey then
		return
	end
	lastWarDayKey = dayKey
	for _, zone in ClanWarConfig.Zones do
		ClanWarService.startWar(zone.id)
	end
	print("[ClanWar] scheduled wars started for all zones")
end

local function scheduleWarTicker()
	task.spawn(function()
		while true do
			maybeStartScheduledWars()
			task.wait(60)
		end
	end)
end

function ClanWarService.init(_remotesFolder: Folder?)
	_remotes = _remotesFolder
	DefensiveFatigueService.init()
	scheduleWarTicker()
	for _, zone in ClanWarConfig.Zones do
		broadcastTerritory(zone.id)
	end
end

return ClanWarService
