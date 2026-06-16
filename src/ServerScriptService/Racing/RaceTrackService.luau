--!strict
--[[
	RaceTrackService (Racing — NeonUtopia) — server-authoritative
	- startRun → ติดตาม checkpoint เรียงลำดับ (validate proximity) → finish คิดเวลา server-side
	- anti-cheat: เช็ก checkpoint เรียงลำดับ + อยู่ในรัศมี + เวลา ≥ minPlausibleTime
	- reward: credits (no-P2W) · best time → RaceLeaderboardStore
	- solo time-trial (v1) · ghost/wave race/garage = follow-up
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RacingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RacingConfig"))
local RaceLeaderboardStore = require(script.Parent:WaitForChild("RaceLeaderboardStore"))

local RaceTrackService = {}

type RunState = { trackId: string, startClock: number, nextCp: number }
local runs: { [number]: RunState } = {}

local function getRoot(player: Player): BasePart?
	local char = player.Character
	local r = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	return if r and r:IsA("BasePart") then r else nil
end

-- ตำแหน่งจริงของ checkpoint part (กันปัญหา offset/SkyCityLift เช่นชั้นใต้ดิน Utopia ที่ถูกยกขึ้น)
-- fallback = nil ให้ caller ใช้ config position
local function checkpointPartPos(trackId: string, index: number): Vector3?
	local cpAttr = RacingConfig.CheckpointAttribute
	local trAttr = RacingConfig.TrackIdAttribute
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute(cpAttr) == index and inst:GetAttribute(trAttr) == trackId then
			return inst.Position
		end
	end
	return nil
end

local function fireState(player: Player, payload: { [string]: any })
	local remotes = ReplicatedStorage:FindFirstChild("RacingRemotes")
	local ev = remotes and remotes:FindFirstChild("RaceState")
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(player, payload)
	end
end

local function creditReward(userId: number, amount: number)
	local ok, cur = pcall(function()
		return require(ServerScriptService:WaitForChild("Commerce"):WaitForChild("CurrencyService"))
	end)
	if ok and cur and typeof(cur.addCredits) == "function" then
		cur.addCredits(userId, amount)
	end
end

function RaceTrackService.startRun(player: Player, trackId: any): (boolean, string)
	local track = RacingConfig.get(if typeof(trackId) == "string" then trackId else nil)
	if not track then
		return false, "ไม่พบสนาม"
	end
	runs[player.UserId] = { trackId = track.id, startClock = os.clock(), nextCp = 1 }
	fireState(player, {
		phase = "started",
		trackId = track.id,
		totalCp = #track.checkpoints,
		cpIndex = 0,
		maxRunTime = track.maxRunTime,
	})
	return true, "go"
end

-- client แตะ checkpoint → ping (trackId, index). server validate.
function RaceTrackService.checkpointReached(player: Player, trackId: any, index: any)
	local state = runs[player.UserId]
	if not state then
		return
	end
	if typeof(trackId) ~= "string" or trackId ~= state.trackId then
		return
	end
	if typeof(index) ~= "number" or index ~= state.nextCp then
		return -- ข้ามลำดับ = ปฏิเสธ (anti-skip)
	end
	local track = RacingConfig.get(state.trackId)
	if not track then
		return
	end
	local cp = track.checkpoints[index]
	local root = getRoot(player)
	if not cp or not root then
		return
	end
	-- proximity check (anti-teleport/exploit) — ใช้ตำแหน่ง part จริงถ้ามี (กัน SkyCityLift/offset)
	local cpPos = checkpointPartPos(track.id, index) or cp.position
	if (root.Position - cpPos).Magnitude > cp.radius + 8 then
		return
	end

	-- timeout
	if (os.clock() - state.startClock) > track.maxRunTime then
		runs[player.UserId] = nil
		fireState(player, { phase = "cancelled", trackId = track.id, msg = "หมดเวลา" })
		return
	end

	if index >= #track.checkpoints then
		-- FINISH
		local timeSec = os.clock() - state.startClock
		runs[player.UserId] = nil
		if timeSec < track.minPlausibleTime then
			fireState(player, { phase = "cancelled", trackId = track.id, msg = "เวลาผิดปกติ (reject)" })
			return
		end
		local isBest = RaceLeaderboardStore.saveBest(player.UserId, track.id, timeSec)
		creditReward(player.UserId, track.rewardCredits)
		fireState(player, {
			phase = "finished",
			trackId = track.id,
			time = timeSec,
			best = RaceLeaderboardStore.getBest(player.UserId, track.id),
			isBest = isBest,
			reward = track.rewardCredits,
		})
	else
		state.nextCp = index + 1
		fireState(player, {
			phase = "checkpoint",
			trackId = track.id,
			cpIndex = index,
			totalCp = #track.checkpoints,
		})
	end
end

function RaceTrackService.getBest(player: Player, trackId: any): number?
	if typeof(trackId) ~= "string" then
		return nil
	end
	return RaceLeaderboardStore.getBest(player.UserId, trackId)
end

local initialized = false
function RaceTrackService.init()
	if initialized then
		return
	end
	initialized = true
	Players.PlayerRemoving:Connect(function(player: Player)
		runs[player.UserId] = nil
		RaceLeaderboardStore.clearUser(player.UserId)
	end)
end

return RaceTrackService
