--!strict
--[[
	SkyCityLift (V2) — ยกเมือง Utopia of Eternity ลอยฟ้าเหนือเมฆ (สรวงสวรรค์)

	วิธี: PivotTo ทั้ง Model "UtopiaEternityCity" ขึ้น +SkyAltitude ตอนจบ build
	      → ยกทุกอย่างพร้อมกัน (greybox, hero mesh, spawn, NPC, pickup, landmark)
	      → SanctuarySpawn ลอยขึ้นด้วย ดังนั้น VoidRecovery กู้คนตกกลับจุดที่ถูกต้อง

	idempotent: ใช้ attribute "SkyLifted" กันยกซ้ำ (รองรับ augment/skip/saved-rbxlx)
	ทุกอย่างห่อ pcall — ถ้า fail เมืองยัง build ได้ปกติ (แค่ไม่ลอย)
]]
local Workspace = game:GetService("Workspace")

local SkyCityLift = {}

local CLOUD_GAP = 160 -- ชั้นเมฆอยู่ใต้พื้นเมืองเท่านี้ (studs)

-- สร้าง "ทะเลเมฆ" ใต้เมือง (แพปุยเมฆโปร่งแสง) + volumetric Clouds เสริมบรรยากาศ
local function buildCloudDeck(altitude: number)
	local existing = Workspace:FindFirstChild("SkyEnvironment")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "SkyEnvironment"

	local deckY = altitude - CLOUD_GAP
	local rings = {
		{ radius = 0, count = 1 },
		{ radius = 440, count = 10 },
		{ radius = 760, count = 16 },
		{ radius = 1080, count = 22 },
	}

	for _, ring in rings do
		for i = 1, ring.count do
			local angle = (i / ring.count) * math.pi * 2
			local puff = Instance.new("Part")
			puff.Name = "CloudPuff"
			puff.Shape = Enum.PartType.Ball
			puff.Anchored = true
			puff.CanCollide = false
			puff.CanQuery = false
			puff.CanTouch = false
			puff.CastShadow = false
			puff.Material = Enum.Material.SmoothPlastic
			puff.Color = Color3.fromRGB(248, 250, 255)
			puff.Transparency = 0.25
			local s = 130 + math.random() * 170
			puff.Size = Vector3.new(s, s * 0.5, s)
			local jitter = (math.random() - 0.5) * 90
			puff.Position =
				Vector3.new(math.cos(angle) * ring.radius, deckY + jitter, math.sin(angle) * ring.radius)
			puff.Parent = folder
		end
	end

	-- กำแพงล่องหนรอบขอบเมือง — กันตกขอบ (เปิดช่องให้ระบบขนส่ง P2 ภายหลัง)
	local BARRIER_RADIUS = 720
	local BARRIER_HEIGHT = 140
	local segments = 28
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local wall = Instance.new("Part")
		wall.Name = "SkyEdgeBarrier"
		wall.Anchored = true
		wall.CanCollide = true
		wall.CanQuery = false
		wall.CastShadow = false
		wall.Transparency = 1
		-- X = ความยาวตามเส้นรอบวง (tangent), Z = ความหนาแนวรัศมี → CFrame.lookAt หันหน้าเข้าศูนย์กลาง
		wall.Size = Vector3.new((2 * math.pi * BARRIER_RADIUS) / segments + 8, BARRIER_HEIGHT, 8)
		local px = math.cos(angle) * BARRIER_RADIUS
		local pz = math.sin(angle) * BARRIER_RADIUS
		wall.CFrame = CFrame.lookAt(Vector3.new(px, altitude + BARRIER_HEIGHT * 0.4, pz), Vector3.new(0, altitude, 0))
		wall.Parent = folder
	end

	folder.Parent = Workspace

	-- volumetric Clouds (best-effort — บรรยากาศหมอกฟ้า)
	pcall(function()
		local terrain = Workspace:FindFirstChildOfClass("Terrain")
		if terrain and not terrain:FindFirstChildOfClass("Clouds") then
			local clouds = Instance.new("Clouds")
			clouds.Cover = 0.7
			clouds.Density = 0.55
			clouds.Color = Color3.fromRGB(255, 255, 255)
			clouds.Parent = terrain
		end
	end)

	return folder
end

-- ยกเมืองลอยฟ้า (เรียกได้หลายครั้ง — กันซ้ำด้วย attribute)
function SkyCityLift.apply(model: Model, altitude: number)
	if not model or altitude <= 0 then
		return
	end
	if model:GetAttribute("SkyLifted") then
		return
	end

	local ok, err = pcall(function()
		local pivot = model:GetPivot()
		model:PivotTo(pivot + Vector3.new(0, altitude, 0))
		model:SetAttribute("SkyLifted", true)
		model:SetAttribute("SkyAltitude", altitude)
		buildCloudDeck(altitude)
	end)

	if not ok then
		warn("[SkyCityLift] lift failed:", err)
	else
		print(string.format("[SkyCityLift] Utopia ยกลอยฟ้า +%d studs เหนือทะเลเมฆ", altitude))
	end
end

return SkyCityLift
