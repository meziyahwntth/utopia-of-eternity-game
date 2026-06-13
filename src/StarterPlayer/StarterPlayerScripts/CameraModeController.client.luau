--!strict
--[[
	CameraModeController (P7) — 1st / 3rd / TopDown toggle (key C + UI button)
]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

type CameraMode = "FirstPerson" | "ThirdPerson" | "TopDown"
local MODES: { CameraMode } = { "FirstPerson", "ThirdPerson", "TopDown" }

local TOP_DOWN_HEIGHT = 60

local modeLabels: { [CameraMode]: string } = {
	FirstPerson = "📷 1st",
	ThirdPerson = "📷 3rd",
	TopDown = "📷 Top",
}

local currentModeIndex = 2
local topDownConn: RBXScriptConnection?

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CameraHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 3
screenGui.Parent = playerGui

local camBtn = Instance.new("TextButton")
camBtn.Size = UDim2.fromScale(0.08, 0.05)
camBtn.Position = UDim2.fromScale(0.91, 0.01)
camBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
camBtn.BackgroundTransparency = 0.2
camBtn.TextColor3 = Color3.new(1, 1, 1)
camBtn.TextScaled = true
camBtn.Text = "📷 3rd"
camBtn.Parent = screenGui

local function applyMode(mode: CameraMode)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	if mode == "FirstPerson" then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		camera.CameraType = Enum.CameraType.Custom
	elseif mode == "ThirdPerson" then
		player.CameraMode = Enum.CameraMode.Classic
		camera.CameraType = Enum.CameraType.Custom
	elseif mode == "TopDown" then
		player.CameraMode = Enum.CameraMode.Classic
		camera.CameraType = Enum.CameraType.Scriptable
	end
end

local function stopTopDown()
	if topDownConn then
		topDownConn:Disconnect()
		topDownConn = nil
	end
end

local function startTopDown()
	stopTopDown()
	topDownConn = RunService.RenderStepped:Connect(function()
		local char = player.Character
		if not char then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		local target = hrp.Position + Vector3.new(0, TOP_DOWN_HEIGHT, 0)
		camera.CFrame = CFrame.new(target, hrp.Position)
	end)
end

local function switchMode(newIndex: number)
	currentModeIndex = ((newIndex - 1) % #MODES) + 1
	local mode: CameraMode = MODES[currentModeIndex]

	if mode == "TopDown" then
		startTopDown()
	else
		stopTopDown()
	end
	applyMode(mode)

	player:SetAttribute("CameraMode", mode)
	camBtn.Text = modeLabels[mode]
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end
	if input.KeyCode == Enum.KeyCode.C then
		switchMode(currentModeIndex + 1)
	end
end)

camBtn.MouseButton1Click:Connect(function()
	switchMode(currentModeIndex + 1)
end)

player.CharacterAdded:Connect(function()
	task.wait(0.1)
	local saved = player:GetAttribute("CameraMode")
	if typeof(saved) == "string" then
		for i, m in ipairs(MODES) do
			if m == saved then
				switchMode(i)
				return
			end
		end
	end
	switchMode(currentModeIndex)
end)

if player.Character then
	task.defer(function()
		switchMode(currentModeIndex)
	end)
end
