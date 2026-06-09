--!strict
--[[
	Phase B — Whispering Grove clue + Hollow Lake opt-in scare.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local DeathValleyExpansionService = require(script.Parent:WaitForChild("DeathValleyExpansionService"))
local DeathValleySeasonalRingService = require(script.Parent:WaitForChild("DeathValleySeasonalRingService"))

local DeathValleyPOIService = {}

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local poiClueEvent = remotes:WaitForChild("PoiClueDiscovered") :: RemoteEvent
local hollowScareEvent = remotes:WaitForChild("HollowLakeScare") :: RemoteEvent

local discovered: { [string]: boolean } = {}
local scareCooldownUntil = 0

local function playerCanAccessPoi(player: Player, poi: PrismDeathValleySurvivalConfig.PoiDef): boolean
	return DeathValleyExpansionService.getUnlockedRing() >= poi.ring
end

function DeathValleyPOIService.discoverClue(player: Player, poiId: string): (boolean, string)
	local poi: PrismDeathValleySurvivalConfig.PoiDef? = nil
	for _, def in PrismDeathValleySurvivalConfig.POIs do
		if def.id == poiId then
			poi = def
			break
		end
	end
	if not poi then
		return false, "Unknown POI"
	end
	if not playerCanAccessPoi(player, poi) then
		return false, "Horizon ring locked — survive more nights"
	end
	if discovered[poiId] then
		return true, poi.clueText or poi.displayName
	end
	discovered[poiId] = true
	player:SetAttribute("DV_Poi_" .. poiId, true)
	local clue = poi.clueText or poi.displayName
	poiClueEvent:FireClient(player, {
		poiId = poiId,
		displayName = poi.displayName,
		clueText = clue,
		prismKeyHint = poi.prismKeyHint,
	})
	return true, clue
end

function DeathValleyPOIService.triggerHollowScare(player: Player): (boolean, string)
	if os.clock() < scareCooldownUntil then
		return false, "The lake is still..."
	end
	local poi: PrismDeathValleySurvivalConfig.PoiDef? = nil
	for _, def in PrismDeathValleySurvivalConfig.POIs do
		if def.id == "hollow_lake" then
			poi = def
			break
		end
	end
	if not poi then
		return false, "Hollow Lake missing"
	end
	if not playerCanAccessPoi(player, poi) then
		return false, "Horizon ring locked"
	end
	scareCooldownUntil = os.clock() + 45
	hollowScareEvent:FireClient(player, {
		poiId = "hollow_lake",
		message = "Something rises from the hollow...",
	})
	DeathValleyPOIService.discoverClue(player, "hollow_lake")
	return true, "You peer into the hollow"
end

function DeathValleyPOIService.claimSeasonalShrine(player: Player): (boolean, string)
	return DeathValleySeasonalRingService.claimShrineReward(player)
end

function DeathValleyPOIService.wireWorld(world: Model)
	for _, desc in world:GetDescendants() do
		if desc:IsA("BasePart") then
			local poiId = desc:GetAttribute("PoiId")
			if typeof(poiId) == "string" then
				local prompt = desc:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					if desc:GetAttribute("SeasonalShrine") == true then
						prompt.Triggered:Connect(function(triggerPlayer)
							local ok, msg = DeathValleyPOIService.claimSeasonalShrine(triggerPlayer)
							triggerPlayer:SetAttribute("DV_SeasonalShrineMsg", msg)
							if not ok then
								warn("[DeathValley] Seasonal shrine:", msg)
							end
						end)
					elseif desc:GetAttribute("OptInScare") == true then
						prompt.Triggered:Connect(function(player)
							DeathValleyPOIService.triggerHollowScare(player)
						end)
					else
						prompt.Triggered:Connect(function(player)
							DeathValleyPOIService.discoverClue(player, poiId)
						end)
					end
				end
			end
		end
	end
end

return DeathValleyPOIService
