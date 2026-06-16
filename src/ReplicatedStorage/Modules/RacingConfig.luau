--!strict
--[[
	RacingConfig (Racing system — NeonUtopia) — data-driven
	อิง RACING-SYSTEM-BLUEPRINT.md · benchmark Velocity Outlast
	- track loop รอบเมือง NeonUtopia (center origin, ตึก radius 70 → loop radius 95)
	- checkpoints เรียงลำดับ; server validate order + proximity + min time (anti-cheat)
	- reward = credits/keys (no-P2W: รางวัลเล่นได้ ไม่ขายความเร็ว) · solo time-trial
]]

local RacingConfig = {}

export type Checkpoint = { index: number, position: Vector3, radius: number }
export type TrackDef = {
	id: string,
	name: string,
	placeKey: string,
	startPosition: Vector3,
	startLookAt: Vector3,
	checkpoints: { Checkpoint },
	rewardCredits: number,
	rewardKeyChance: number, -- 0..1 โอกาสได้กุญแจสุ่มเมื่อจบ
	minPlausibleTime: number, -- วินาที — ต่ำกว่านี้ = โกง (reject)
	maxRunTime: number, -- วินาที — เกินนี้ = หมดเวลา (auto-cancel)
	checkpointRadius: number,
}

-- สร้าง loop รัศมี R รอบ origin (y=3) จำนวน n จุด
local function ringCheckpoints(n: number, R: number, y: number, radius: number): { Checkpoint }
	local out: { Checkpoint } = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2
		table.insert(out, {
			index = i,
			position = Vector3.new(math.cos(a) * R, y, math.sin(a) * R),
			radius = radius,
		})
	end
	return out
end

local R = 95
local CP_RADIUS = 16

local tracks: { TrackDef } = {
	{
		id = "neon_grand_prix",
		name = "Neon Grand Prix",
		placeKey = "NeonUtopia",
		startPosition = Vector3.new(R, 3, 0),
		startLookAt = Vector3.new(R, 3, 20), -- หันตามเส้นทาง (tangent)
		checkpoints = ringCheckpoints(6, R, 3, CP_RADIUS),
		rewardCredits = 150,
		rewardKeyChance = 0.15,
		minPlausibleTime = 8,
		maxRunTime = 180,
		checkpointRadius = CP_RADIUS,
	},
	{
		-- Utopia (capital) underground arena — built by UtopiaUndergroundRaceBuilder.
		-- ตำแหน่งใน config = relative ของ model EternityCity (Y ใต้ดิน -55) ก่อน SkyCityLift;
		-- RaceTrackService validate ด้วยตำแหน่ง part จริง (เลี่ยงปัญหา lift) — config = hint สำหรับ builder
		id = "utopia_underground_gp",
		name = "Utopia Underground GP",
		placeKey = "EternityCity",
		startPosition = Vector3.new(80, -55, 0),
		startLookAt = Vector3.new(80, -55, 20),
		checkpoints = ringCheckpoints(6, 80, -55, CP_RADIUS),
		rewardCredits = 180,
		rewardKeyChance = 0.15,
		minPlausibleTime = 8,
		maxRunTime = 180,
		checkpointRadius = CP_RADIUS,
	},
}

local byId: { [string]: TrackDef } = {}
for _, t in tracks do
	byId[t.id] = t
end

RacingConfig.CheckpointAttribute = "RaceCheckpointIndex"
RacingConfig.TrackIdAttribute = "RaceTrackId"

function RacingConfig.all(): { TrackDef }
	return tracks
end

function RacingConfig.get(id: string?): TrackDef?
	if typeof(id) ~= "string" then
		return nil
	end
	return byId[id]
end

return RacingConfig
