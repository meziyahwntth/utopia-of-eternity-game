--!strict
--[[
	Phase M — Shared loadout plaza terminals + mirror for Hub / Eternity City.
]]

local LoadoutPlazaKit = {}

local function addLabel(parent: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
end

export type PlazaOptions = {
	origin: Vector3?,
	wardrobeLabel: string?,
	mirrorLabel: string?,
	autoRotate: boolean?,
}

function LoadoutPlazaKit.addTerminals(parent: Instance, options: PlazaOptions?)
	local origin = if options and options.origin then options.origin else Vector3.zero
	local wardrobeLabel = if options and options.wardrobeLabel then options.wardrobeLabel else "Valley Wardrobe"

	local terminals = {
		{ offset = Vector3.new(-10, 0, 8), mode = "loadout", label = wardrobeLabel, color = Color3.fromRGB(120, 80, 160) },
		{ offset = Vector3.new(-22, 0, 8), mode = "titles", label = "Title Registry", color = Color3.fromRGB(255, 200, 90) },
		{ offset = Vector3.new(10, 0, 8), mode = "shared", label = "Preset Share", color = Color3.fromRGB(80, 120, 180) },
		{ offset = Vector3.new(22, 0, 8), mode = "market", label = "Preset Bazaar", color = Color3.fromRGB(90, 150, 120) },
	}
	for _, entry in terminals do
		local kiosk = Instance.new("Part")
		kiosk.Name = "ValleyLoadout_" .. entry.mode
		kiosk.Size = Vector3.new(8, 10, 8)
		kiosk.CFrame = CFrame.new(origin + entry.offset + Vector3.new(0, 5, 0))
		kiosk.Anchored = true
		kiosk.Color = entry.color
		kiosk.Material = Enum.Material.Neon
		kiosk.Parent = parent
		kiosk:SetAttribute("ValleyLoadoutTerminal", true)
		kiosk:SetAttribute("LoadoutPickerMode", entry.mode)
		addLabel(kiosk, entry.label)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = entry.label
		prompt.ActionText = if entry.mode == "titles"
			then "Titles"
			elseif entry.mode == "shared" then "Share"
			elseif entry.mode == "market" then "Bazaar"
			else "Wardrobe"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.3
		prompt.Parent = kiosk
	end
end

function LoadoutPlazaKit.addMirror(parent: Instance, options: PlazaOptions?)
	local origin = if options and options.origin then options.origin else Vector3.new(0, 0, 52)
	local mirrorLabel = if options and options.mirrorLabel then options.mirrorLabel else "Valley Mirror"
	local autoRotate = if options and options.autoRotate ~= nil then options.autoRotate else true

	local mirror = Instance.new("Model")
	mirror.Name = "ValleyLoadoutMirror"
	mirror.Parent = parent
	mirror:SetAttribute("ValleyLoadoutMirror", true)
	mirror:SetAttribute("MirrorAutoRotate", autoRotate)
	mirror:SetAttribute("MirrorRotateSpeed", 0.35)

	local platform = Instance.new("Part")
	platform.Name = "MirrorPlatform"
	platform.Size = Vector3.new(24, 1, 10)
	platform.CFrame = CFrame.new(origin + Vector3.new(0, 0.5, 0))
	platform.Anchored = true
	platform.Color = Color3.fromRGB(40, 35, 55)
	platform.Material = Enum.Material.Glass
	platform.Transparency = 0.2
	platform.Parent = mirror

	local trigger = Instance.new("Part")
	trigger.Name = "MirrorTrigger"
	trigger.Size = Vector3.new(8, 8, 8)
	trigger.CFrame = CFrame.new(origin + Vector3.new(0, 4, -6))
	trigger.Anchored = true
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.Parent = mirror
	addLabel(trigger, mirrorLabel)

	for index, x in { -7, 0, 7 } do
		local pedestal = Instance.new("Part")
		pedestal.Name = "MirrorPedestal_" .. tostring(index)
		pedestal.Size = Vector3.new(4, 0.5, 4)
		pedestal.CFrame = CFrame.new(origin + Vector3.new(x, 1.2, 0))
		pedestal.Anchored = true
		pedestal.Color = Color3.fromRGB(90, 70, 120)
		pedestal.Material = Enum.Material.Neon
		pedestal:SetAttribute("MirrorOffset", Vector3.new(0, 2.5, 0))
		pedestal.Parent = mirror
	end
end

function LoadoutPlazaKit.addPlaza(parent: Instance, options: PlazaOptions?)
	local folder = Instance.new("Folder")
	folder.Name = "LoadoutPlaza"
	folder.Parent = parent
	LoadoutPlazaKit.addTerminals(folder, options)
	LoadoutPlazaKit.addMirror(folder, options)
	return folder
end

return LoadoutPlazaKit
