--!strict
--[[
	Prism Hover Shuttle — departs every 15 minutes, does not wait for full seats.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local ShuttleGreyboxBuilder = require(script.Parent.Parent.ShuttleGreyboxBuilder)
local ShuttleJourney = require(script.Parent.ShuttleJourney)
local ShuttlePassengerManager = require(script.Parent.ShuttlePassengerManager)

local shuttleBuild: ShuttleGreyboxBuilder.ShuttleBuild? = nil
local running = false

local function getInterval(): number
	local dev = GameConfig.PublicTransit.DevFastIntervalSeconds
	if dev and dev > 0 then
		return dev
	end
	return GameConfig.PublicTransit.DepartureIntervalSeconds
end

local function ensureShuttle(): ShuttleGreyboxBuilder.ShuttleBuild
	if shuttleBuild and shuttleBuild.Model.Parent then
		return shuttleBuild
	end

	local folder = Workspace:FindFirstChild("UtopiaShuttle", true)
	if folder then
		local model = folder:FindFirstChild("PrismHoverShuttle", true)
		if model and model:IsA("Model") then
			local root = model:FindFirstChild("ShuttleRoot") :: BasePart?
			if root then
				local seats: { VehicleSeat } = {}
				for _, child in model:GetChildren() do
					if child:IsA("VehicleSeat") then
						table.insert(seats, child)
					end
				end
				shuttleBuild = {
					Model = model,
					Root = root,
					Seats = seats,
					StopCFrame = root.CFrame,
					DockCFrame = root.CFrame,
				}
				return shuttleBuild
			end
		end
	end

	local origin = CFrame.new(0, 0, 0)
	for _, modelName in { "UtopiaHubWorld", "UtopiaEternityCity", "UtopiaSolhaven", "UtopiaNocturne", "UtopiaDeathValley", "UtopiaHubGreybox" } do
		local world = Workspace:FindFirstChild(modelName)
		if world then
			local spawn = world:FindFirstChild("SanctuarySpawn", true)
				or world:FindFirstChild("SanctuarySpawn_1", true)
			if spawn and spawn:IsA("BasePart") then
				origin = spawn.CFrame
				break
			end
		end
	end
	local folder = Workspace:FindFirstChild("UtopiaShuttle", true)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "UtopiaShuttle"
		folder.Parent = Workspace
	end
	shuttleBuild = ShuttleGreyboxBuilder:BuildAtSanctuary(folder, origin)
	return shuttleBuild
end

local function runDeparture()
	if running then
		return
	end
	running = true
	local build = ensureShuttle()
	local placeKey = ShuttlePassengerManager:GetCurrentPlaceKey()

	task.wait(GameConfig.PublicTransit.StopDwellSeconds)
	ShuttleJourney:RunLeg(build, placeKey)
	running = false
end

task.spawn(function()
	task.wait(5)
	while true do
		task.spawn(runDeparture)
		task.wait(getInterval())
	end
end)

print("[Utopia Shuttle] Scheduler online — interval", getInterval(), "seconds")
