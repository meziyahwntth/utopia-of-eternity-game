--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))
local HellboundTerminalService = require(script.Parent:WaitForChild("HellboundTerminalService"))

HellboundTerminalService.init()

local function wireDepartureGate(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Board for Hellbound"
		prompt.ObjectText = "Interstellar Terminal"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 1
		prompt.Parent = part
	end
	prompt.Triggered:Connect(function(player)
		local mode = part:GetAttribute("TransportMode")
		if typeof(mode) ~= "string" then
			mode = "PublicAirplane"
		end
		local ok, msg = HellboundTerminalService.depart(player, mode)
		player:SetAttribute("HellboundDepartMsg", msg)
		if not ok then
			warn("[Hellbound] Depart failed:", msg)
		end
	end)
end

local function wireEternityCity(world: Model)
	for _, desc in world:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("HellboundDepartureGate") == true then
			wireDepartureGate(desc)
		end
	end
end

local function bootstrap()
	local placeKey = WorldPlaceGuard:GetCurrentPlaceKey()
	if placeKey == "EternityCity" then
		local world = Workspace:FindFirstChild("UtopiaEternityCity") :: Model?
		if world then
			wireEternityCity(world)
		else
			Workspace.ChildAdded:Connect(function(child)
				if child.Name == "UtopiaEternityCity" then
					task.defer(function()
						wireEternityCity(child :: Model)
					end)
				end
			end)
		end
	end
end

task.defer(bootstrap)
print("[Hellbound] Terminal handlers online")
