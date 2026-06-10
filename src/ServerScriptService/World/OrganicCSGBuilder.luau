--!strict
--[[
	Organic primitives — mesh-based domes, arches, spires (Hybrid layer).
]]
local OrganicCSGBuilder = {}

export type ShapeOpts = {
	color: Color3?,
	material: Enum.Material?,
	parent: Instance?,
	name: string?,
	transparency: number?,
	collision: boolean?,
}

local function part(name: string, size: Vector3, cf: CFrame, opts: ShapeOpts): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = if opts.collision ~= nil then opts.collision else true
	p.Color = opts.color or Color3.fromRGB(90, 105, 125)
	p.Material = opts.material or Enum.Material.SmoothPlastic
	p.Transparency = opts.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.parent then
		p.Parent = opts.parent
	end
	return p
end

function OrganicCSGBuilder:createDome(center: Vector3, radius: number, opts: ShapeOpts?): Model
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = opts.name or "OrganicDome"
	model.Parent = opts.parent

	local shell = part("DomeShell", Vector3.new(radius * 2, radius, radius * 2), CFrame.new(center + Vector3.new(0, radius * 0.5, 0)), opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.55, 1)
	mesh.Parent = shell
	shell.Parent = model

	return model
end

function OrganicCSGBuilder:createArch(origin: CFrame, span: number, height: number, thickness: number, opts: ShapeOpts?): Model
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = opts.name or "OrganicArch"
	model.Parent = opts.parent

	local segments = 8
	for i = 0, segments do
		local t = i / segments
		local angle = math.pi * t
		local x = math.cos(angle) * span * 0.5
		local y = math.sin(angle) * height
		local seg = part(
			"ArchSeg_" .. i,
			Vector3.new(thickness, thickness * 2, span / segments + thickness),
			origin * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, -angle + math.pi / 2),
			opts
		)
		seg.Parent = model
	end

	return model
end

function OrganicCSGBuilder:createSpire(base: Vector3, height: number, radius: number, opts: ShapeOpts?): Model
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = opts.name or "OrganicSpire"
	model.Parent = opts.parent

	local shaft = part("SpireShaft", Vector3.new(radius * 2, height, radius * 2), CFrame.new(base + Vector3.new(0, height / 2, 0)), opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, height / (radius * 2), 1)
	mesh.Parent = shaft
	shaft.Parent = model

	local tip = part(
		"SpireTip",
		Vector3.new(radius, radius * 2, radius),
		CFrame.new(base + Vector3.new(0, height + radius, 0)),
		{ color = opts.color, material = Enum.Material.Neon, parent = model, collision = false }
	)
	local tipMesh = Instance.new("SpecialMesh")
	tipMesh.MeshType = Enum.MeshType.Sphere
	tipMesh.Scale = Vector3.new(0.6, 1.2, 0.6)
	tipMesh.Parent = tip

	return model
end

function OrganicCSGBuilder:createGlassBand(center: Vector3, radius: number, height: number, opts: ShapeOpts?): Part
	opts = opts or {}
	local band = part(
		opts.name or "GlassBand",
		Vector3.new(radius * 2.1, height, radius * 2.1),
		CFrame.new(center + Vector3.new(0, height / 2, 0)),
		{
			color = opts.color or Color3.fromRGB(0, 229, 255),
			material = Enum.Material.Glass,
			transparency = 0.45,
			collision = false,
			parent = opts.parent,
		}
	)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(1, 1, 0.15)
	mesh.Parent = band
	return band
end

return OrganicCSGBuilder
