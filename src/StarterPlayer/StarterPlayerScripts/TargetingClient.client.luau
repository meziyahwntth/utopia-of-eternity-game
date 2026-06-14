--!strict
--[[
	TargetingClient (Next-Gen Mobile RPG) — Auto-Lock Targeting.
	- Tap/click an enemy NPC → lock on (ring + name/HP indicator)
	- Tap empty space → clears a soft (unlocked) target
	- Lock/Unlock HUD button (mobile, thumb-reachable, Scale-based)
	- Drives TargetingController.update() each frame (HP refresh / auto-clear)
	Visuals + target state live in the shared TargetingController so
	AutoBattleClient reuses the same lock.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Targeting = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TargetingController"))

local SOFT_KEEP_RANGE = 80 -- soft targets beyond this auto-clear (locked persist)

local function getRoot(model: Instance?): BasePart?
	if not model or not model:IsA("Model") then
		return nil
	end
	local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if r and r:IsA("BasePart") then r else nil
end

----------------------------------------------------------------
-- Tap / click selection (camera raycast)
----------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function enemyFromInstance(inst: Instance?): Model?
	local cur = inst
	while cur and cur ~= Workspace do
		if cur:IsA("Model") and Targeting.isEnemy(cur) then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function handleTap(screenPos: Vector2)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local char = localPlayer.Character
	rayParams.FilterDescendantsInstances = if char then { char } else {}

	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
	local enemy = if hit then enemyFromInstance(hit.Instance) else nil

	if enemy then
		Targeting.setTarget(enemy, true) -- tap an enemy = lock on
	elseif not Targeting.isLocked() then
		Targeting.clear() -- tap empty with no lock = deselect
	end
end

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return -- tapped on UI, ignore
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		handleTap(Vector2.new(input.Position.X, input.Position.Y))
	end
end)

----------------------------------------------------------------
-- Lock / Unlock HUD button (mobile-first: Scale + AspectRatio)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TargetingGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local btn = Instance.new("TextButton")
btn.Name = "LockToggle"
btn.AnchorPoint = Vector2.new(1, 1)
btn.Position = UDim2.new(1, -16, 1, -150) -- right side, above skill area
btn.Size = UDim2.new(0.13, 0, 0.13, 0)
btn.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
btn.AutoButtonColor = true
btn.Text = "🎯"
btn.TextScaled = true
btn.TextColor3 = Color3.fromRGB(240, 240, 255)
btn.Visible = false
btn.Parent = gui
do
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = btn
	local sz = Instance.new("UISizeConstraint")
	sz.MinSize = Vector2.new(44, 44)
	sz.MaxSize = Vector2.new(76, 76)
	sz.Parent = btn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = btn
end

local nameTag = Instance.new("TextLabel")
nameTag.Name = "TargetName"
nameTag.AnchorPoint = Vector2.new(1, 1)
nameTag.Position = UDim2.new(1, -16, 1, -150 - 4) -- just above the button
nameTag.Size = UDim2.new(0.32, 0, 0.035, 0)
nameTag.BackgroundTransparency = 1
nameTag.Font = Enum.Font.GothamBold
nameTag.TextScaled = true
nameTag.TextColor3 = Color3.fromRGB(255, 235, 160)
nameTag.TextStrokeTransparency = 0.4
nameTag.TextXAlignment = Enum.TextXAlignment.Right
nameTag.Text = ""
nameTag.Visible = false
nameTag.Parent = gui
do
	local sz = Instance.new("UISizeConstraint")
	sz.MaxSize = Vector2.new(260, 26)
	sz.Parent = nameTag
end

local function refreshButton(targetModel: Model?, locked: boolean)
	if targetModel then
		btn.Visible = true
		nameTag.Visible = true
		nameTag.Text = targetModel.Name
		if locked then
			btn.Text = "🔒"
			btn.BackgroundColor3 = Color3.fromRGB(150, 45, 50)
		else
			btn.Text = "🎯"
			btn.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
		end
	else
		btn.Visible = false
		nameTag.Visible = false
	end
end

btn.Activated:Connect(function()
	Targeting.toggleLock()
end)

Targeting.onChanged(refreshButton)

----------------------------------------------------------------
-- Per-frame update (HP refresh / auto-clear)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local char = localPlayer.Character
	Targeting.update(SOFT_KEEP_RANGE, getRoot(char))
end)
