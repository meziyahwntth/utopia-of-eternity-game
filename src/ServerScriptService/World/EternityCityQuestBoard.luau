--!strict
--[[
	Festival Phase 2 — Daily Quest Board Art
	Places a Quest Board part in Sanctuary near countdown sign
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EternityCityQuestBoard = {}

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function EternityCityQuestBoard.setup(model: Model, palette: any)
	local folder = Instance.new("Folder")
	folder.Name = "QuestBoard"
	folder.Parent = model

	-- Position: near sanctuary spawn (loadout plaza area)
	local origin = model:GetPivot().Position + Vector3.new(8, 3, 62)

	-- Main board panel
	local board = addPart(
		folder,
		"QuestBoardPanel",
		Vector3.new(16, 10, 0.6),
		CFrame.new(origin.X, origin.Y + 5, origin.Z),
		palette.Midnight,
		Enum.Material.Slate
	)
	board:SetAttribute("QuestBoard", true)

	-- Neon frame
	addPart(
		folder,
		"QuestBoardFrameTop",
		Vector3.new(16.5, 0.3, 0.7),
		CFrame.new(origin.X, origin.Y + 10.1, origin.Z - 0.3),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addPart(
		folder,
		"QuestBoardFrameBot",
		Vector3.new(16.5, 0.3, 0.7),
		CFrame.new(origin.X, origin.Y + 0.1, origin.Z - 0.3),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addPart(
		folder,
		"QuestBoardFrameL",
		Vector3.new(0.3, 10, 0.7),
		CFrame.new(origin.X - 8.1, origin.Y + 5, origin.Z - 0.3),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addPart(
		folder,
		"QuestBoardFrameR",
		Vector3.new(0.3, 10, 0.7),
		CFrame.new(origin.X + 8.1, origin.Y + 5, origin.Z - 0.3),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)

	-- BillboardGui for quest list
	local bgui = Instance.new("BillboardGui")
	bgui.Name = "QuestBoardGui"
	bgui.Adornee = board
	bgui.Size = UDim2.fromOffset(300, 180)
	bgui.Parent = board

	local bgFrame = Instance.new("Frame")
	bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.5
	bgFrame.Size = UDim2.fromScale(1, 1)
	bgFrame.Parent = bgui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = bgFrame

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = palette.Gold
	bgStroke.Thickness = 1.5
	bgStroke.Parent = bgFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = palette.Cyan
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Text = "Daily Quests\nLoading..."
	label.TextWrapped = true
	label.Parent = bgFrame

	-- Open button above board
	local openBtn = addPart(
		folder,
		"QuestBoardOpenBtn",
		Vector3.new(4, 1.5, 0.4),
		CFrame.new(origin.X, origin.Y + 10.5, origin.Z - 1),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)

	local openGui = Instance.new("SurfaceGui")
	openGui.Face = Enum.NormalId.Front
	openGui.Parent = openBtn

	local openLabel = Instance.new("TextLabel")
	openLabel.Size = UDim2.fromScale(1, 1)
	openLabel.BackgroundTransparency = 1
	openLabel.TextColor3 = Color3.fromRGB(15, 20, 35)
	openLabel.TextScaled = true
	openLabel.Font = Enum.Font.GothamBold
	openLabel.Text = "OPEN"
	openLabel.Parent = openGui

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Quest Board"
	prompt.ObjectText = "Daily Quests"
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = board

	-- Spotlight
	local light = Instance.new("PointLight")
	light.Color = palette.Amber
	light.Brightness = 1.5
	light.Range = 20
	light.Parent = openBtn

	print("[Festival] Quest Board placed — Sanctuary")
end

return EternityCityQuestBoard