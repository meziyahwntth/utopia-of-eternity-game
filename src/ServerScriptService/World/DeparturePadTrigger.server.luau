--!strict
-- DeparturePadTrigger — ProximityPrompt opens Air Transport UI panel
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local showTransportUI = ensure("RemoteEvent", "ShowAirTransportUI") :: RemoteEvent

local function wirePad(pad: BasePart)
	if pad:FindFirstChild("AirTransportUIPrompt") then
		return
	end

	local detector = Instance.new("ProximityPrompt")
	detector.Name = "AirTransportUIPrompt"
	detector.ActionText = "ขึ้นยาน → Utopia"
	detector.ObjectText = "✈ Air Transport"
	detector.MaxActivationDistance = 12
	detector.KeyboardKeyCode = Enum.KeyCode.G
	detector.RequiresLineOfSight = false
	detector.Parent = pad

	detector.Triggered:Connect(function(player: Player)
		showTransportUI:FireClient(player)
	end)
end

local function findPads()
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "AirTransportDeparturePad" then
			wirePad(d)
		end
	end
end

task.spawn(function()
	task.wait(3)
	findPads()
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and d.Name == "AirTransportDeparturePad" then
			task.defer(function()
				wirePad(d)
			end)
		end
	end)
	print("[DeparturePad] UI prompt scanner online")
end)
