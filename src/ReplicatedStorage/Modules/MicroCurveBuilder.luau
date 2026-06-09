--!strict
--[[
	Micro-voxel curve approximation — Quant Build technique for Roblox.
	Circle/dome/arc via tiny parts on Bresenham grid.
]]
local MicroCurveBuilder = {}

export type BuildOpts = {
	voxelStuds: number?,
	color: Color3?,
	material: Enum.Material?,
	parent: Instance?,
	name: string?,
	collision: boolean?,
	filled: boolean?,
	budget: { count: number, max: number }?,
}

local DEFAULT_OPTS: BuildOpts = {
	voxelStuds = 0.1,
	color = Color3.fromRGB(212, 175, 55),
	material = Enum.Material.Neon,
	collision = false,
	filled = true,
}

local function mergeOpts(opts: BuildOpts?): BuildOpts
	opts = opts or {}
	return {
		voxelStuds = opts.voxelStuds or DEFAULT_OPTS.voxelStuds,
		color = opts.color or DEFAULT_OPTS.color,
		material = opts.material or DEFAULT_OPTS.material,
		parent = opts.parent,
		name = opts.name,
		collision = if opts.collision ~= nil then opts.collision else DEFAULT_OPTS.collision,
		filled = if opts.filled ~= nil then opts.filled else DEFAULT_OPTS.filled,
		budget = opts.budget,
	}
end

local function canAdd(budget: { count: number, max: number }?): boolean
	if not budget then
		return true
	end
	return budget.count < budget.max
end

local function trackAdd(budget: { count: number, max: number }?)
	if budget then
		budget.count += 1
	end
end

local function makeVoxel(pos: Vector3, size: number, opts: BuildOpts): Part?
	if not canAdd(opts.budget) then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = opts.name or "MicroVoxel"
	p.Size = Vector3.new(size, size, size)
	p.CFrame = CFrame.new(pos)
	p.Anchored = true
	p.CanCollide = opts.collision == true
	p.Color = opts.color :: Color3
	p.Material = opts.material :: Enum.Material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.parent then
		p.Parent = opts.parent
	end
	trackAdd(opts.budget)
	return p
end

-- Midpoint circle — returns integer lattice offsets (x, z) from center
local function circlePoints(radiusBlocks: number): { Vector2 }
	local points: { Vector2 } = {}
	local r = math.max(1, math.floor(radiusBlocks))
	local x = 0
	local z = r
	local d = 1 - r

	local function addOctant(cx: number, cz: number)
		table.insert(points, Vector2.new(cx, cz))
		table.insert(points, Vector2.new(-cx, cz))
		table.insert(points, Vector2.new(cx, -cz))
		table.insert(points, Vector2.new(-cx, -cz))
		table.insert(points, Vector2.new(cz, cx))
		table.insert(points, Vector2.new(-cz, cx))
		table.insert(points, Vector2.new(cz, -cx))
		table.insert(points, Vector2.new(-cz, -cx))
	end

	while x <= z do
		addOctant(x, z)
		if d < 0 then
			d += 2 * x + 3
		else
			d += 2 * (x - z) + 5
			z -= 1
		end
		x += 1
	end
	return points
end

function MicroCurveBuilder:fillCircle(center: Vector3, radiusStuds: number, y: number, opts: BuildOpts?): { Part }
	local o = mergeOpts(opts)
	local v = o.voxelStuds :: number
	local blockRadius = math.max(2, math.floor(radiusStuds / v))
	local parts: { Part } = {}
	local seen: { [string]: boolean } = {}

	if o.filled then
		for bx = -blockRadius, blockRadius do
			for bz = -blockRadius, blockRadius do
				if bx * bx + bz * bz <= blockRadius * blockRadius then
					local pos = Vector3.new(center.X + bx * v, y, center.Z + bz * v)
					local part = makeVoxel(pos, v, o)
					if part then
						table.insert(parts, part)
					end
				end
			end
		end
	else
		for _, pt in circlePoints(blockRadius) do
			local key = string.format("%d,%d", pt.X, pt.Y)
			if not seen[key] then
				seen[key] = true
				local pos = Vector3.new(center.X + pt.X * v, y, center.Z + pt.Y * v)
				local part = makeVoxel(pos, v, o)
				if part then
					table.insert(parts, part)
				end
			end
		end
	end
	return parts
end

function MicroCurveBuilder:fillEllipse(center: Vector3, radiusX: number, radiusZ: number, y: number, opts: BuildOpts?): { Part }
	local o = mergeOpts(opts)
	local v = o.voxelStuds :: number
	local parts: { Part } = {}
	local bxMax = math.max(2, math.floor(radiusX / v))
	local bzMax = math.max(2, math.floor(radiusZ / v))
	for bx = -bxMax, bxMax do
		for bz = -bzMax, bzMax do
			local nx = bx / bxMax
			local nz = bz / bzMax
			if nx * nx + nz * nz <= 1 then
				local pos = Vector3.new(center.X + bx * v, y, center.Z + bz * v)
				local part = makeVoxel(pos, v, o)
				if part then
					table.insert(parts, part)
				end
			end
		end
	end
	return parts
end

function MicroCurveBuilder:fillDome(center: Vector3, radiusStuds: number, heightStuds: number, opts: BuildOpts?): Model
	local o = mergeOpts(opts)
	local v = o.voxelStuds :: number
	local model = Instance.new("Model")
	model.Name = o.name or "MicroDome"
	model.Parent = o.parent

	local layers = math.max(3, math.floor(heightStuds / v))
	for layer = 0, layers do
		local t = layer / layers
		local layerRadius = radiusStuds * math.cos(t * math.pi / 2)
		local y = center.Y + layer * v
		self:fillCircle(Vector3.new(center.X, 0, center.Z), layerRadius, y, {
			voxelStuds = v,
			color = o.color,
			material = o.material,
			parent = model,
			collision = o.collision,
			filled = true,
			budget = o.budget,
		})
	end
	return model
end

function MicroCurveBuilder:fillArc(points: { Vector3 }, widthStuds: number, opts: BuildOpts?): { Part }
	local o = mergeOpts(opts)
	local v = o.voxelStuds :: number
	local halfW = math.max(1, math.floor((widthStuds / v) / 2))
	local parts: { Part } = {}
	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		local seg = b - a
		local len = seg.Magnitude
		local steps = math.max(1, math.floor(len / v))
		for s = 0, steps do
			local alpha = s / steps
			local pos = a:Lerp(b, alpha)
			for w = -halfW, halfW do
				local offset = Vector3.new(w * v, 0, 0)
				local part = makeVoxel(pos + offset, v, o)
				if part then
					table.insert(parts, part)
				end
			end
		end
	end
	return parts
end

function MicroCurveBuilder:weldBatch(parts: { BasePart }, parent: Instance, batchName: string)
	local model = Instance.new("Model")
	model.Name = batchName
	model.Parent = parent
	for _, p in parts do
		p.Parent = model
	end
	return model
end

return MicroCurveBuilder
