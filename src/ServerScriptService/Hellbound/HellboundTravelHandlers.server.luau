--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))
local HellboundTravelService = require(script.Parent:WaitForChild("HellboundTravelService"))
local DeathValleySpiritChamberService = require(ServerScriptService:WaitForChild("DeathValley"):WaitForChild("DeathValleySpiritChamberService"))

local remotes = ReplicatedStorage:WaitForChild("HellboundRemotes")
local beginTravel = remotes:WaitForChild("BeginHellboundTravel") :: RemoteFunction
local getTravelState = remotes:WaitForChild("GetHellboundTravelState") :: RemoteFunction

HellboundTravelService.init()

beginTravel.OnServerInvoke = function(player: Player, mode: string?)
	return HellboundTravelService.beginTravel(player, mode)
end

getTravelState.OnServerInvoke = function(player: Player)
	return HellboundTravelService.buildPublicState(player)
end

local CHAMBER_INDEX: { [string]: number } = {
	SpiritChamber1 = 1,
	SpiritChamber2 = 2,
	SpiritChamber3 = 3,
}

local function wireStation(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	local action = part:GetAttribute("HellboundAction")
	local chamberIndex = CHAMBER_INDEX[part.Name]

	if chamberIndex then
		prompt.ActionText = "Enter Combat"
		prompt.Triggered:Connect(function(player)
			DeathValleySpiritChamberService.beginChamber(player, chamberIndex, part.Position)
		end)
		return
	end

	if action == "BeginTravel" then
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("HellboundArrivalFromTerminal") == true then
				player:SetAttribute("HellboundAtPeakColony", true)
				return
			end
			HellboundTravelService.beginTravel(player, "PublicAirplane")
		end)
	elseif action == "ContinueTravel" then
		prompt.Triggered:Connect(function(player)
			local idx = CHAMBER_INDEX[part.Name]
			if idx and not DeathValleySpiritChamberService.isChamberCleared(player, idx) then
				player:SetAttribute("DV_SpiritMsg", "Clear chamber combat first")
				return
			end
			if player:GetAttribute("HellboundTravelComplete") == true then
				local char = player.Character
				local target = part:GetAttribute("TeleportTarget")
				if char and typeof(target) == "Vector3" then
					char:PivotTo(CFrame.new(target))
				end
			else
				HellboundTravelService.beginTravel(player, "WalkPipeline")
			end
		end)
	elseif action == "ArriveSanctuary" then
		prompt.Triggered:Connect(function(player)
			if not DeathValleySpiritChamberService.allChambersCleared(player) then
				player:SetAttribute("DV_SpiritMsg", "Clear all Spirit Lock chambers")
				return
			end
			local char = player.Character
			if char then
				char:PivotTo(CFrame.new(0, 5, 0))
			end
			player:SetAttribute("HellboundAtSanctuary", true)
		end)
	end
end

local function wireWorld(world: Model)
	for _, desc in world:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("HellboundStation") == true then
			wireStation(desc)
		end
	end
end

local function bootstrap()
	if WorldPlaceGuard:GetCurrentPlaceKey() ~= "DeathValley" then
		return
	end
	local world = Workspace:FindFirstChild("UtopiaDeathValley") :: Model?
	if world then
		wireWorld(world)
	else
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "UtopiaDeathValley" then
				task.defer(function()
					wireWorld(child :: Model)
				end)
			end
		end)
	end
end

task.defer(bootstrap)
print("[Hellbound] Travel handlers online — Death Valley pipeline")
