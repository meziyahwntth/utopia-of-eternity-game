--!strict
-- UtopiaUndergroundRaceBuilder — ชั้นใต้ดินสนามแข่งรถใต้เมืองหลวง Utopia (EternityCity place)
-- เรียกหลัง SkyCityLift (ใช้ตำแหน่ง absolute จาก WorldGround จริง) · idempotent
-- ฟุตบาทเหนือสนาม = พื้นโปร่งใส SmoothPlastic (ไม่ใช้ Glass — กัน Glass culling ของ transparent ด้านล่าง)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RacingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RacingConfig"))

local UtopiaUndergroundRaceBuilder = {}

local HOLE_HALF = 110 -- รูกลางพื้น 220x220 (วิวลงสนาม)
local CHAMBER_DEPTH = 60 -- ลึกจากพื้นลงไป
local TRACK_Y_OFFSET = -55 -- ระดับสนามแข่งใต้พื้น
local TRACK_RADIUS = 80

local function frameStrip(parent: Instance, name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function labelGui(parent: Instance, text: string, yOff: number, w: number)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(w, 30)
	g.StudsOffset = Vector3.new(0, yOff, 0)
	g.AlwaysOnTop = true
	g.Parent = parent
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextStrokeTransparency = 0.4
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Text = text
	l.Parent = g
end

local function makeCheckpoint(parent: Instance, trackId: string, index: number, pos: Vector3, radius: number, isFinish: boolean)
	local name = "RaceCheckpoint_"
	local color = Color3.fromRGB(64, 196, 224)
	local text = "CP " .. tostring(index)
	if isFinish then
		name = "RaceFinish_"
		color = Color3.fromRGB(90, 230, 120)
		text = "FINISH"
	end
	local part = Instance.new("Part")
	part.Name = name .. tostring(index)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.Size = Vector3.new(radius * 2, 14, 2)
	part.CFrame = CFrame.lookAt(pos, Vector3.new(pos.X * 0.5, pos.Y, pos.Z * 0.5))
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.5
	part:SetAttribute(RacingConfig.CheckpointAttribute, index)
	part:SetAttribute(RacingConfig.TrackIdAttribute, trackId)
	part.Parent = parent
	labelGui(part, text, 9, 70)
end

function UtopiaUndergroundRaceBuilder.build(cityModel: Instance?)
	if not cityModel then
		return
	end
	if cityModel:FindFirstChild("UtopiaUnderground") then
		return -- idempotent
	end
	local ground = cityModel:FindFirstChild("WorldGround")
	if not ground or not ground:IsA("BasePart") then
		warn("[UtopiaUnderground] no WorldGround — skip")
		return
	end
	local track = RacingConfig.get("utopia_underground_gp")
	if not track then
		return
	end

	local gy = ground.Position.Y
	local center = Vector3.new(ground.Position.X, gy, ground.Position.Z)
	local S = ground.Size.X
	local color = ground.Color
	local mat = ground.Material

	local model = Instance.new("Model")
	model.Name = "UtopiaUnderground"
	model.Parent = cityModel

	-- (1) เจาะรูพื้น: แทน WorldGround ด้วยกรอบ 4 แถบ เหลือรูกลาง 220x220
	-- (ตั้งชื่อแถบหนึ่งเป็น WorldGround ให้ VoidRecovery ยังเจอ)
	local half = S / 2
	local outer = (half + HOLE_HALF) / 2
	local stripLong = half - HOLE_HALF
	if stripLong < 4 then
		stripLong = 4
	end
	ground:Destroy()
	-- North/South (เต็มความกว้าง x)
	frameStrip(model, "WorldGround", Vector3.new(S, 1, stripLong), center + Vector3.new(0, 0, outer), color, mat)
	frameStrip(model, "GroundFrameS", Vector3.new(S, 1, stripLong), center + Vector3.new(0, 0, -outer), color, mat)
	-- East/West (เฉพาะช่วงรู)
	frameStrip(model, "GroundFrameE", Vector3.new(stripLong, 1, HOLE_HALF * 2), center + Vector3.new(outer, 0, 0), color, mat)
	frameStrip(model, "GroundFrameW", Vector3.new(stripLong, 1, HOLE_HALF * 2), center + Vector3.new(-outer, 0, 0), color, mat)

	-- (2) ฟุตบาทโปร่งใสเหนือรู (เดินได้ + มองทะลุลงสนาม) — SmoothPlastic ไม่ใช่ Glass
	local viewFloor = Instance.new("Part")
	viewFloor.Name = "UndergroundViewFloor"
	viewFloor.Anchored = true
	viewFloor.CanCollide = true
	viewFloor.Size = Vector3.new(HOLE_HALF * 2, 1, HOLE_HALF * 2)
	viewFloor.Position = center
	viewFloor.Material = Enum.Material.SmoothPlastic
	viewFloor.Color = Color3.fromRGB(180, 220, 255)
	viewFloor.Transparency = 0.55 -- เกือบโปร่งใส
	viewFloor.Reflectance = 0.05
	viewFloor.Parent = model

	-- (3) ห้องใต้ดิน: พื้นสนาม + ผนัง 4 ด้าน + ไฟ neon
	local chamberHalf = HOLE_HALF + 12
	local arenaFloor = Instance.new("Part")
	arenaFloor.Name = "ArenaFloor"
	arenaFloor.Anchored = true
	arenaFloor.Size = Vector3.new(chamberHalf * 2, 2, chamberHalf * 2)
	arenaFloor.Position = center + Vector3.new(0, -CHAMBER_DEPTH, 0)
	arenaFloor.Material = Enum.Material.Concrete
	arenaFloor.Color = Color3.fromRGB(38, 40, 52)
	arenaFloor.Parent = model
	for _, sx in { -1, 1 } do
		frameStrip(model, "ArenaWallX", Vector3.new(2, CHAMBER_DEPTH, chamberHalf * 2), center + Vector3.new(sx * chamberHalf, -CHAMBER_DEPTH / 2, 0), Color3.fromRGB(28, 30, 40), Enum.Material.Slate)
		frameStrip(model, "ArenaWallZ", Vector3.new(chamberHalf * 2, CHAMBER_DEPTH, 2), center + Vector3.new(0, -CHAMBER_DEPTH / 2, sx * chamberHalf), Color3.fromRGB(28, 30, 40), Enum.Material.Slate)
	end
	-- neon accent strips
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2
		local strip = Instance.new("Part")
		strip.Name = "ArenaNeon_" .. i
		strip.Anchored = true
		strip.CanCollide = false
		strip.Size = Vector3.new(3, 3, chamberHalf * 1.6)
		strip.CFrame = CFrame.new(center + Vector3.new(0, -4, 0)) * CFrame.Angles(0, a, 0)
		strip.Material = Enum.Material.Neon
		strip.Color = Color3.fromRGB(90, 200, 255)
		strip.Parent = model
	end

	-- (4) start gate + checkpoints (ring รอบ center ที่ระดับสนาม)
	local trackY = gy + TRACK_Y_OFFSET
	local startPos = center + Vector3.new(TRACK_RADIUS, TRACK_Y_OFFSET, 0)
	local gate = Instance.new("Part")
	gate.Name = "RaceStartGate"
	gate.Anchored = true
	gate.CanCollide = false
	gate.CanTouch = false
	gate.Size = Vector3.new(track.checkpointRadius * 2, 16, 2)
	gate.CFrame = CFrame.lookAt(startPos, startPos + Vector3.new(0, 0, 20))
	gate.Material = Enum.Material.Neon
	gate.Color = Color3.fromRGB(240, 210, 90)
	gate.Transparency = 0.4
	gate:SetAttribute("RaceStartTrackId", track.id)
	gate.Parent = model
	labelGui(gate, "Race: " .. track.name, 11, 180)

	local n = #track.checkpoints
	for i = 1, n do
		local ang = (i - 1) / n * math.pi * 2
		local pos = center + Vector3.new(math.cos(ang) * TRACK_RADIUS, TRACK_Y_OFFSET, math.sin(ang) * TRACK_RADIUS)
		makeCheckpoint(model, track.id, i, pos, track.checkpointRadius, i == n)
	end

	print("[Racing] Utopia underground arena built - " .. tostring(n) .. " checkpoints (groundY=" .. tostring(math.floor(gy)) .. ")")
end

return UtopiaUndergroundRaceBuilder
