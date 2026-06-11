--!strict
--[[
	Hero mesh slot — ServerStorage.HeroMeshes.<key> or AssetService:CreateMeshPartAsync.

	MeshPart.MeshId is read-only at runtime; never Instance.new + assign MeshId.
]]
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

export type SpawnResult = {
	instance: Instance,
	source: "storage" | "async",
	key: string,
}

local HeroMeshKit = {}

local function meshUri(meshId: string): string
	if string.sub(meshId, 1, 13) == "rbxassetid://" then
		return meshId
	end
	return "rbxassetid://" .. meshId
end

local function applyMeshPartTransform(meshPart: MeshPart, baseCf: CFrame, spec: { Scale: number?, YOffset: number?, Rotation: Vector3? })
	local scale = spec.Scale or 1
	meshPart.Size = meshPart.MeshSize * scale
	local yOff = spec.YOffset or 0
	local rot = spec.Rotation or Vector3.zero
	local halfY = meshPart.Size.Y * 0.5
	meshPart.CFrame = baseCf * CFrame.new(0, yOff + halfY, 0) * CFrame.Angles(rot.X, rot.Y, rot.Z)
	meshPart.Anchored = true
	meshPart.CanCollide = false
end

local function applyTransform(instance: Instance, baseCf: CFrame, spec: { Scale: number?, YOffset: number?, Rotation: Vector3? })
	local yOff = spec.YOffset or 0
	local rot = spec.Rotation or Vector3.zero
	local cf = baseCf * CFrame.new(0, yOff, 0) * CFrame.Angles(rot.X, rot.Y, rot.Z)

	if instance:IsA("MeshPart") then
		applyMeshPartTransform(instance, baseCf, spec)
		return
	end

	if instance:IsA("Model") then
		instance:PivotTo(cf)
		if spec.Scale and spec.Scale ~= 1 then
			instance:ScaleTo(spec.Scale)
		end
	elseif instance:IsA("BasePart") then
		instance.CFrame = cf
		if spec.Scale and spec.Scale ~= 1 and instance:IsA("Part") then
			instance.Size = instance.Size * spec.Scale
		end
	end

	for _, desc in instance:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
	end
end

local function createMeshPartAsync(meshId: string): MeshPart?
	local uri = meshUri(meshId)
	local ok, result = pcall(function()
		local content = Content.fromUri(uri)
		return AssetService:CreateMeshPartAsync(content, {
			CollisionFidelity = Enum.CollisionFidelity.Box,
		})
	end)
	if not ok then
		warn(string.format("[HeroMeshKit] CreateMeshPartAsync failed for %s: %s", uri, tostring(result)))
		return nil
	end
	if not result or not result:IsA("MeshPart") then
		warn("[HeroMeshKit] CreateMeshPartAsync returned unexpected type for ", uri)
		return nil
	end
	return result
end

function HeroMeshKit.getSpec(key: string): { MeshId: string?, Scale: number?, YOffset: number?, Rotation: Vector3? }?
	local meshes = GameConfig.HeroMeshes
	if not meshes then
		return nil
	end
	return meshes[key]
end

function HeroMeshKit.attachExterior(parent: Instance, key: string, baseCf: CFrame): SpawnResult?
	local spec = HeroMeshKit.getSpec(key)
	if not spec then
		return nil
	end

	local heroFolder = ServerStorage:FindFirstChild("HeroMeshes")
	local stored = if heroFolder then heroFolder:FindFirstChild(key) else nil
	if stored and (stored:IsA("Model") or stored:IsA("MeshPart") or stored:IsA("BasePart")) then
		local clone = stored:Clone()
		clone.Name = key .. "HeroMesh"
		applyTransform(clone, baseCf, spec)
		clone.Parent = parent
		return { instance = clone, source = "storage", key = key }
	end

	if spec.MeshId then
		local meshPart = createMeshPartAsync(spec.MeshId)
		if not meshPart then
			warn(string.format("[HeroMeshKit] hero mesh unavailable for %s — procedural interior only", key))
			return nil
		end
		meshPart.Name = key .. "HeroMesh"
		meshPart.Material = Enum.Material.SmoothPlastic
		meshPart.Color = GameConfig.CityPalette.Pearl
		applyTransform(meshPart, baseCf, spec)
		meshPart.Parent = parent
		return { instance = meshPart, source = "async", key = key }
	end

	return nil
end

function HeroMeshKit.collectActiveKeys(results: { SpawnResult? }): string
	local keys: { string } = {}
	for _, result in results do
		if result then
			table.insert(keys, result.key)
		end
	end
	return table.concat(keys, ",")
end

-- Deprecated alias — exterior attach only; call after procedural district exists
function HeroMeshKit.spawn(parent: Instance, key: string, baseCf: CFrame): SpawnResult?
	return HeroMeshKit.attachExterior(parent, key, baseCf)
end

return HeroMeshKit
