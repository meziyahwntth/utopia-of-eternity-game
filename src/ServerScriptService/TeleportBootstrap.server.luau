--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))

local function onPromptTriggered(player: Player, placeKey: PlaceTeleport.PlaceKey)
	local ok, err = PlaceTeleport:TeleportPlayer(player, placeKey)
	if not ok and err then
		warn("[Utopia] Teleport failed for", player.Name, placeKey, err)
	end
end

local function wireKiosk(part: BasePart)
	local placeKey = part:GetAttribute("PlaceKey")
	if typeof(placeKey) ~= "string" then
		return
	end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		onPromptTriggered(player, placeKey :: PlaceTeleport.PlaceKey)
	end)
end

local HUB_MODEL_NAMES = { "UtopiaHubWorld", "UtopiaHubGreybox" }

local function wireAll()
	for _, modelName in HUB_MODEL_NAMES do
		local hub = Workspace:FindFirstChild(modelName)
		if hub then
			for _, desc in hub:GetDescendants() do
				if desc:IsA("BasePart") and string.find(desc.Name, "Teleport_") == 1 then
					wireKiosk(desc)
				end
			end
		end
	end
end

Workspace.ChildAdded:Connect(function(child)
	if table.find(HUB_MODEL_NAMES, child.Name) then
		task.defer(wireAll)
	end
end)

task.defer(wireAll)

print("[Utopia] Teleport kiosks wired")
