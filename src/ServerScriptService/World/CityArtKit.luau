--!strict
--[[
	City art direction kit — pearl/gold/cyan resort city vocabulary.
	Reused by UtopiaPlaza, EternityTower, boulevard beauty passes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

export type Palette = typeof(GameConfig.CityPalette)
export type Budget = WorldBuildBudget.Budget

export type KitContext = {
	parent: Instance,
	palette: Palette,
	budget: Budget?,
}

local CityArtKit = {}

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	opts: { transparency: number?, collide: boolean? }?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = if opts then opts.transparency or 0 else 0
	part.CanCollide = if opts and opts.collide ~= nil then opts.collide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function track(ctx: KitContext, n: number)
	if ctx.budget then
		WorldBuildBudget:add(ctx.budget, n)
	end
end

function CityArtKit.palmTree(ctx: KitContext, baseCf: CFrame): Model
	local palette = ctx.palette
	local model = Instance.new("Model")
	model.Name = "PalmTree"
	model.Parent = ctx.parent

	local trunk = addPart(model, "Trunk", Vector3.new(1.4, 10, 1.4), baseCf * CFrame.new(0, 5, 0), palette.Gold, Enum.Material.Wood)
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local leaf = addPart(
			model,
			"Leaf_" .. i,
			Vector3.new(1.2, 6, 0.4),
			baseCf * CFrame.new(math.cos(angle) * 2.5, 10.5, math.sin(angle) * 2.5) * CFrame.Angles(0, angle, math.rad(35)),
			Color3.fromRGB(55, 130, 95),
			Enum.Material.Grass,
			{ collide = false }
		)
		leaf.CanCollide = false
	end
	model.PrimaryPart = trunk
	track(ctx, 6)
	return model
end

function CityArtKit.goldPlanter(ctx: KitContext, baseCf: CFrame, radius: number?): Model
	local palette = ctx.palette
	local r = radius or 3
	local model = Instance.new("Model")
	model.Name = "GoldPlanter"
	model.Parent = ctx.parent

	local basin = addPart(
		model,
		"Basin",
		Vector3.new(r * 2, 2.2, r * 2),
		baseCf * CFrame.new(0, 1.1, 0),
		palette.Gold,
		Enum.Material.Metal
	)
	addPart(
		model,
		"Soil",
		Vector3.new(r * 1.6, 0.8, r * 1.6),
		baseCf * CFrame.new(0, 2.4, 0),
		Color3.fromRGB(72, 58, 42),
		Enum.Material.Ground
	)
	addPart(
		model,
		"Bush",
		Vector3.new(r * 1.2, 2.4, r * 1.2),
		baseCf * CFrame.new(0, 3.8, 0),
		Color3.fromRGB(62, 125, 88),
		Enum.Material.Grass,
		{ collide = false }
	)
	model.PrimaryPart = basin
	track(ctx, 3)
	return model
end

function CityArtKit.canalEdgeGlow(ctx: KitContext, center: Vector3, length: number, width: number, axis: "X" | "Z"): Folder
	local palette = ctx.palette
	local folder = Instance.new("Folder")
	folder.Name = "CanalEdgeGlow"
	folder.Parent = ctx.parent

	local size = if axis == "X" then Vector3.new(length, 0.35, 0.6) else Vector3.new(0.6, 0.35, length)
	local offset = if axis == "X" then Vector3.new(0, 0, width / 2) else Vector3.new(width / 2, 0, 0)

	for _, sign in { -1, 1 } do
		addPart(
			folder,
			"Edge_" .. sign,
			size,
			CFrame.new(center + offset * sign),
			palette.CyanBright,
			Enum.Material.Neon,
			{ transparency = 0.08, collide = false }
		)
	end
	track(ctx, 2)
	return folder
end

function CityArtKit.archRib(ctx: KitContext, origin: CFrame, span: number): Model
	local palette = ctx.palette
	local ArchRibKit = require(ServerStorage:WaitForChild("WorldKits"):WaitForChild("ArchRibKit"))
	local rib = ArchRibKit:Create(1, origin, {
		parent = ctx.parent,
		budget = ctx.budget,
		palette = palette,
		span = span,
	})
	rib.Name = "CityArchRib"
	return rib
end

function CityArtKit.glassRail(ctx: KitContext, origin: CFrame, length: number, height: number, axis: "X" | "Z"): Folder
	local palette = ctx.palette
	local folder = Instance.new("Folder")
	folder.Name = "GlassRail"
	folder.Parent = ctx.parent

	local panelSize = if axis == "X" then Vector3.new(length, height, 0.25) else Vector3.new(0.25, height, length)
	local panel = addPart(folder, "GlassPanel", panelSize, origin * CFrame.new(0, height / 2, 0), palette.Cyan, Enum.Material.Glass, {
		transparency = 0.45,
		collide = false,
	})
	panel.Reflectance = 0.2

	local trimSize = if axis == "X" then Vector3.new(length, 0.25, 0.5) else Vector3.new(0.5, 0.25, length)
	addPart(folder, "GoldCap", trimSize, origin * CFrame.new(0, height, 0), palette.Gold, Enum.Material.Metal, { collide = false })

	local postCount = math.max(2, math.floor(length / 8))
	for i = 0, postCount do
		local t = if postCount == 0 then 0 else i / postCount
		local offset = if axis == "X" then Vector3.new((t - 0.5) * length, 0, 0) else Vector3.new(0, 0, (t - 0.5) * length)
		addPart(folder, "Post_" .. i, Vector3.new(0.5, height, 0.5), origin * CFrame.new(offset + Vector3.new(0, height / 2, 0)), palette.Pearl, Enum.Material.Marble)
	end

	track(ctx, 2 + postCount + 1)
	return folder
end

function CityArtKit.laneRoad(ctx: KitContext, origin: CFrame, length: number, laneCount: number): Folder
	local palette = ctx.palette
	local folder = Instance.new("Folder")
	folder.Name = "LaneRoad"
	folder.Parent = ctx.parent

	local roadW = laneCount * 6 + 4
	addPart(folder, "Asphalt", Vector3.new(roadW, 0.35, length), origin * CFrame.new(0, 0.15, 0), palette.Slate, Enum.Material.Asphalt)

	for lane = 1, laneCount - 1 do
		local x = -roadW / 2 + lane * (roadW / laneCount)
		for z = -length / 2 + 2, length / 2 - 2, 10 do
			addPart(
				folder,
				string.format("Dash_L%d_Z%d", lane, z),
				Vector3.new(0.35, 0.1, 4),
				origin * CFrame.new(x, 0.35, z),
				palette.Gold,
				Enum.Material.Neon,
				{ collide = false }
			)
		end
	end

	for _, side in { -1, 1 } do
		addPart(
			folder,
			"Curb_" .. side,
			Vector3.new(0.6, 0.5, length),
			origin * CFrame.new(side * (roadW / 2 + 0.3), 0.25, 0),
			palette.Pearl,
			Enum.Material.Marble
		)
	end

	track(ctx, 2 + (laneCount - 1) * math.floor(length / 10) + 2)
	return folder
end

function CityArtKit.cafeSet(ctx: KitContext, origin: CFrame): Folder
	local palette = ctx.palette
	local folder = Instance.new("Folder")
	folder.Name = "CafeSet"
	folder.Parent = ctx.parent

	for i = 1, 3 do
		local x = (i - 2) * 5
		addPart(folder, "Table_" .. i, Vector3.new(3, 1, 3), origin * CFrame.new(x, 0.5, 0), palette.Pearl, Enum.Material.Marble)
		for _, z in { -1.8, 1.8 } do
			addPart(folder, "Chair_" .. i .. "_" .. z, Vector3.new(1.2, 2, 1.2), origin * CFrame.new(x, 1, z), palette.Steel, Enum.Material.Metal)
		end
	end

	local umbrella = addPart(folder, "UmbrellaPole", Vector3.new(0.4, 7, 0.4), origin * CFrame.new(0, 3.5, -6), palette.Gold, Enum.Material.Metal)
	addPart(
		folder,
		"UmbrellaCanopy",
		Vector3.new(8, 0.3, 8),
		origin * CFrame.new(0, 7, -6),
		palette.Cyan,
		Enum.Material.Fabric,
		{ collide = false }
	)
	umbrella.CanCollide = false

	track(ctx, 10)
	return folder
end

return CityArtKit
