--!strict
--[[
	SecurityRemoteBootstrap — Wire RemoteGuard:Register + GriefingGuard hooks

	ทำงานหลัง SecurityCore (ซึ่งเรียก RemoteGuard:Init แล้ว) และหลัง WorldBootstrap
	(ซึ่ง EternityCityAccessGuard.start() เรียกแล้ว)

	ไฟล์นี้แก้ปัญหา 2 อย่าง:
	  [1] RemoteGuard:Register ไม่เคยถูกเรียก → ลงทะเบียน remotes ที่ต้องการ rate limit
	  [2] GriefingGuard ไม่ถูก wire → hook เข้า attribute + server-side events
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local securityFolder = ServerScriptService:WaitForChild("Security")

-- รอให้ SecurityCore:Init ทำงานเสร็จก่อน
local RemoteGuard = require(securityFolder:WaitForChild("RemoteGuard"))
local RateLimiter = require(securityFolder:WaitForChild("RateLimiter"))
local GriefingGuard = require(securityFolder:WaitForChild("GriefingGuard"))
local SuspicionTracker = require(securityFolder:WaitForChild("SuspicionTracker"))
local SentinelStrike = require(securityFolder:WaitForChild("SentinelStrike"))

-- ─── [1] RemoteGuard:Register ────────────────────────────────────────────────
-- ลงทะเบียน HealChannelComplete ผ่าน RemoteGuard (rate-limited + schema-validated)
-- Client fires เมื่อ heal channel เสร็จ → server apply heal
-- Separate จาก DungeonMegaZoneHandlers เพื่อ intercept flood ก่อนถึง handler

local DungeonZoneRuntime = require(ServerScriptService:WaitForChild("Dungeon"):WaitForChild("DungeonZoneRuntime"))

RemoteGuard:Register("HealChannelComplete_Guarded", {
	rateLimit = {
		maxTokens = 5,       -- heal ได้ไม่เกิน 5 ครั้งในหน้าต่าง
		refillPerSecond = 0.25, -- refill 1 token ทุก 4 วิ → ~15 heals/นาที
	},
	schema = {
		-- UserId ปัจจุบันทะลุหมื่นล้านแล้ว (เช่น 11,076,697,270) — เผื่อ headroom
		{ name = "targetUserId", type = "number", min = 1, max = 1e15 },
	},
	handler = function(player: Player, targetUserId: number)
		-- delegate ไปยัง DungeonZoneRuntime โดยตรง
		local zoneId = player:GetAttribute("DungeonZoneId")
		if typeof(zoneId) ~= "string" then
			warn("[HealHandler] SKIP: no DungeonZoneId attr on", player.Name)
			return
		end

		-- ตรวจ getRuntime ก่อนเรียก (ป้องกัน nil function ใน build เก่า)
		if typeof(DungeonZoneRuntime.getRuntime) ~= "function" then
			warn("[HealHandler] SKIP: DungeonZoneRuntime.getRuntime is not a function — rebuild required")
			return
		end

		local runtime = DungeonZoneRuntime.getRuntime(zoneId)
		if not runtime then
			warn("[HealHandler] SKIP: no runtime for zone", zoneId)
			return
		end

		local state = runtime.zonePlayers[player.UserId]
		if not state then
			warn("[HealHandler] SKIP: player not in zonePlayers, zoneId=", zoneId)
			return
		end

		local target = Players:GetPlayerByUserId(targetUserId)
		if not target or not runtime.zonePlayers[target.UserId] then
			warn("[HealHandler] SKIP: target invalid or not in zone, targetUserId=", targetUserId)
			return
		end

		state.healCount += 1
		DungeonZoneRuntime.syncContributionAttributes(player, state)
		local hum = target:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = math.min(hum.MaxHealth, hum.Health + 15)
		end
		print("[HealHandler] OK: healed", target.Name, "healCount now=", state.healCount)
	end,
})

-- ลงทะเบียน CoOpSabotageReport — client แจ้ง server เมื่อเพื่อนร่วมทีมทำ sabotage
-- (ใช้ rate limit เข้มเพราะ client-reported — server ยังต้อง validate เอง)
RemoteGuard:Register("CoOpSabotageReport", {
	rateLimit = {
		maxTokens = 3,
		refillPerSecond = 0.05, -- 1 report ทุก 20 วิ
	},
	schema = {
		{ name = "action", type = "string", maxLen = 64 },
	},
	handler = function(player: Player, action: string)
		-- server-side validation: ผู้เล่นต้องอยู่ใน dungeon zone จริง
		local zoneId = player:GetAttribute("DungeonZoneId")
		if typeof(zoneId) ~= "string" or zoneId == "" then
			-- ไม่อยู่ใน dungeon → อาจเป็น false report → เพิ่ม suspicion
			SuspicionTracker:Add(player, 10, "COOPSABOTAGE_REPORT_OUTSIDE_ZONE")
			return
		end
		GriefingGuard:RecordCoOpSabotage(player, action)
	end,
})

print("[Utopia] RemoteGuard: HealChannelComplete_Guarded + CoOpSabotageReport registered")

-- ─── [2] GriefingGuard Hooks ─────────────────────────────────────────────────

-- Hook A: Sanctuary violation (EternityCity)
-- EternityCityAccessGuard.enforceSanctuary() ตั้ง EternityPreviewBounce เมื่อ bounce
-- เราเฝ้า attribute นั้น → RecordSanctuaryViolation (server-only, ไม่ trust client)
local function bindGriefingHooks(player: Player)
	-- Sanctuary violation tracker
	player:GetAttributeChangedSignal("EternityPreviewBounce"):Connect(function()
		local bounceTime = player:GetAttribute("EternityPreviewBounce")
		-- ตรวจว่า attribute ถูกตั้งจริง (ไม่ใช่ clear)
		if typeof(bounceTime) == "number" and bounceTime > 0 then
			GriefingGuard:RecordSanctuaryViolation(player, "EternityCity")
		end
	end)

	-- PvP kill streak tracker — ฟัง Humanoid.Died บน character ที่ถูก kill
	-- แต่ server ไม่รู้ว่าใคร kill ใคร จาก Died event โดยตรง
	-- → ใช้ attribute DV_LastKillerUserId ที่ DeathValley survival system ตั้งไว้
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not hum then
			return
		end
		hum.Died:Connect(function()
			local killerId = player:GetAttribute("DV_LastKillerUserId")
			if typeof(killerId) ~= "number" or killerId <= 0 then
				return
			end
			local killer = Players:GetPlayerByUserId(killerId)
			if killer and killer ~= player then
				GriefingGuard:RecordPvPKill(killer, player.UserId)
			end
		end)
	end)
end

-- ลงทะเบียน hook กับ player ที่มีอยู่แล้ว + player ใหม่
for _, player in Players:GetPlayers() do
	task.spawn(bindGriefingHooks, player)
end
Players.PlayerAdded:Connect(bindGriefingHooks)

print("[Utopia] GriefingGuard: sanctuary + PvP hooks online")
