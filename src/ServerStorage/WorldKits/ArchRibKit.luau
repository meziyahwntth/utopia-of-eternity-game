--!strict
--[[
	Procedural NP_Arch_Rib_01–08 — Blockbench mesh placeholder via organic + micro trim.
	Studio: replace with imported .rbxm when art pipeline ready.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local OrganicCSGBuilder = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("OrganicCSGBuilder"))

local ArchRibKit = {}

export type RibOpts = {
	span: number?,
	height: number?,
	palette: { Pearl: Color3, PearlAlt: Color3?, Gold: Color3, Cyan: Color3 }?,
	parent: Instance?,
	budget: { count: number, max: number }?,
}

local RIB_VARIANTS = {
	{ span = 24, height = 14, trim = 0.1 },
	{ span = 30, height = 18, trim = 0.1 },
	{ span = 36, height = 20, trim = 0.12 },
	{ span = 20, height = 12, trim = 0.1 },
	{ span = 40, height = 22, trim = 0.1 },
	{ span = 28, height = 16, trim = 0.12 },
	{ span = 32, height = 19, trim = 0.1 },
	{ span = 44, height = 24, trim = 0.1 },
}

function ArchRibKit:Create(index: number, origin: CFrame, opts: RibOpts?): Model
	opts = opts or {}
	local variant = RIB_VARIANTS[((index - 1) % #RIB_VARIANTS) + 1]
	local span = opts.span or variant.span
	local height = opts.height or variant.height
	local palette = opts.palette or {
		Pearl = Color3.fromRGB(245, 245, 240),
		Gold = Color3.fromRGB(212, 175, 55),
		Cyan = Color3.fromRGB(0, 229, 255),
	}

	local model = Instance.new("Model")
	model.Name = string.format("NP_Arch_Rib_%02d", index)
	model.Parent = opts.parent

	OrganicCSGBuilder:createArch(origin, span, height, 2.5, {
		color = palette.Pearl,
		material = Enum.Material.SmoothPlastic,
		parent = model,
		name = "RibArch",
	})

	local arcPoints: { Vector3 } = {}
	local steps = 12
	for i = 0, steps do
		local t = i / steps
		local angle = math.pi * t
		local x = math.cos(angle) * span * 0.5
		local y = math.sin(angle) * height
		table.insert(arcPoints, (origin * CFrame.new(x, y, 0)).Position)
	end

	MicroCurveBuilder:fillArc(arcPoints, 1.2, {
		voxelStuds = variant.trim,
		color = palette.Gold,
		material = Enum.Material.Neon,
		parent = model,
		collision = false,
		budget = opts.budget,
	})

	MicroCurveBuilder:fillArc(arcPoints, 0.6, {
		voxelStuds = variant.trim,
		color = palette.Cyan,
		material = Enum.Material.Neon,
		parent = model,
		collision = false,
		budget = opts.budget,
	})

	return model
end

function ArchRibKit:CreateAll(origin: CFrame, spacing: number, parent: Instance, budget: { count: number, max: number }?, opts: RibOpts?): { Model }
	local models: { Model } = {}
	for i = 1, 8 do
		local cf = origin * CFrame.new((i - 4.5) * spacing, 0, 0)
		local callOpts: RibOpts = {
			parent = parent,
			budget = budget,
		}
		if opts then
			if opts.span then callOpts.span = opts.span end
			if opts.height then callOpts.height = opts.height end
			if opts.palette then
				local bodyColor = if i % 2 == 0 and opts.palette.PearlAlt then opts.palette.PearlAlt else opts.palette.Pearl
				callOpts.palette = {
					Pearl = bodyColor,
					Gold = opts.palette.Gold,
					Cyan = opts.palette.Cyan,
				}
			end
		end
		table.insert(models, self:Create(i, cf, callOpts))
	end
	return models
end

return ArchRibKit
