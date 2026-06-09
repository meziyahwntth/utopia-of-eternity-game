--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local PrismDeathValleySurvivalConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismDeathValleySurvivalConfig"))
local WorldPlaceGuard = require(ServerScriptService:WaitForChild("World"):WaitForChild("WorldPlaceGuard"))

local DeathValleyBeaconService = require(script.Parent:WaitForChild("DeathValleyBeaconService"))
local DeathValleyNightService = require(script.Parent:WaitForChild("DeathValleyNightService"))
local DeathValleyReviveService = require(script.Parent:WaitForChild("DeathValleyReviveService"))
local DeathValleyCheckpointService = require(script.Parent:WaitForChild("DeathValleyCheckpointService"))
local DeathValleyPOIService = require(script.Parent:WaitForChild("DeathValleyPOIService"))
local DeathValleyWeeklyBossService = require(script.Parent:WaitForChild("DeathValleyWeeklyBossService"))
local DeathValleyLfgService = require(script.Parent:WaitForChild("DeathValleyLfgService"))
local DeathValleyLeaderboardService = require(script.Parent:WaitForChild("DeathValleyLeaderboardService"))
local DeathValleySeasonService = require(script.Parent:WaitForChild("DeathValleySeasonService"))
local DeathValleySpiritChamberService = require(script.Parent:WaitForChild("DeathValleySpiritChamberService"))
local DeathValleySeasonalRingService = require(script.Parent:WaitForChild("DeathValleySeasonalRingService"))
local DeathValleyLfgQueueService = require(script.Parent:WaitForChild("DeathValleyLfgQueueService"))
local DeathValleyLfgInviteService = require(script.Parent:WaitForChild("DeathValleyLfgInviteService"))
local DeathValleySeasonRewardService = require(script.Parent:WaitForChild("DeathValleySeasonRewardService"))
local DeathValleySeasonRolloverService = require(script.Parent:WaitForChild("DeathValleySeasonRolloverService"))
local DeathValleyLfgFriendsService = require(script.Parent:WaitForChild("DeathValleyLfgFriendsService"))
local DeathValleySeasonAdminService = require(script.Parent:WaitForChild("DeathValleySeasonAdminService"))

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getSurvivalState = remotes:WaitForChild("GetSurvivalState") :: RemoteFunction
local depositBeaconFuel = remotes:WaitForChild("DepositBeaconFuel") :: RemoteFunction
local upgradeBeacon = remotes:WaitForChild("UpgradeBeacon") :: RemoteFunction
local startReviveChannel = remotes:WaitForChild("StartReviveChannel") :: RemoteFunction
local completeReviveChannel = remotes:WaitForChild("CompleteReviveChannel") :: RemoteFunction
local getCheckpointStatus = remotes:WaitForChild("GetCheckpointStatus") :: RemoteFunction
local startWeeklyBoss = remotes:WaitForChild("StartWeeklyBoss") :: RemoteFunction
local attackWeeklyBoss = remotes:WaitForChild("AttackWeeklyBoss") :: RemoteFunction
local postLfgListing = remotes:WaitForChild("PostLfgListing") :: RemoteFunction
local joinLfgListing = remotes:WaitForChild("JoinLfgListing") :: RemoteFunction
local leaveLfgListing = remotes:WaitForChild("LeaveLfgListing") :: RemoteFunction
local getLfgListings = remotes:WaitForChild("GetLfgListings") :: RemoteFunction
local getLeaderboard = remotes:WaitForChild("GetLeaderboard") :: RemoteFunction
local getCurrentSeason = remotes:WaitForChild("GetCurrentSeason") :: RemoteFunction
local getSeasonalRingStatus = remotes:WaitForChild("GetSeasonalRingStatus") :: RemoteFunction
local claimSeasonalShrine = remotes:WaitForChild("ClaimSeasonalShrine") :: RemoteFunction
local enqueueLfgQueue = remotes:WaitForChild("EnqueueLfgQueue") :: RemoteFunction
local dequeueLfgQueue = remotes:WaitForChild("DequeueLfgQueue") :: RemoteFunction
local getLfgQueueState = remotes:WaitForChild("GetLfgQueueState") :: RemoteFunction
local sendLfgInvite = remotes:WaitForChild("SendLfgInvite") :: RemoteFunction
local acceptLfgInvite = remotes:WaitForChild("AcceptLfgInvite") :: RemoteFunction
local declineLfgInvite = remotes:WaitForChild("DeclineLfgInvite") :: RemoteFunction
local getPendingLfgInvites = remotes:WaitForChild("GetPendingLfgInvites") :: RemoteFunction
local getSeasonHistory = remotes:WaitForChild("GetSeasonHistory") :: RemoteFunction
local getSeasonRewardStatus = remotes:WaitForChild("GetSeasonRewardStatus") :: RemoteFunction
local claimSeasonReward = remotes:WaitForChild("ClaimSeasonReward") :: RemoteFunction
local getLfgFriendsList = remotes:WaitForChild("GetLfgFriendsList") :: RemoteFunction
local sendLfgFriendInvite = remotes:WaitForChild("SendLfgFriendInvite") :: RemoteFunction
local getRolloverStatus = remotes:WaitForChild("GetRolloverStatus") :: RemoteFunction
local adminForceSeasonRollover = remotes:WaitForChild("AdminForceSeasonRollover") :: RemoteFunction
local adminDeliverRolloverRewards = remotes:WaitForChild("AdminDeliverRolloverRewards") :: RemoteFunction
local getStudioAdminStatus = remotes:WaitForChild("GetStudioAdminStatus") :: RemoteFunction
local adminResetSeasonPointer = remotes:WaitForChild("AdminResetSeasonPointer") :: RemoteFunction

local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

getSurvivalState.OnServerInvoke = function(_player: Player)
	return DeathValleyNightService.buildPublicState()
end

getCheckpointStatus.OnServerInvoke = function(_player: Player)
	return DeathValleyCheckpointService.toPublicPayload()
end

startWeeklyBoss.OnServerInvoke = function(player: Player)
	return DeathValleyWeeklyBossService.startBoss(player)
end

attackWeeklyBoss.OnServerInvoke = function(player: Player)
	return DeathValleyWeeklyBossService.attackBoss(player)
end

postLfgListing.OnServerInvoke = function(player: Player, zoneId: string)
	if not allow(player, "PostLfgListing", 3, 60) then
		return false, "Rate limited"
	end
	return DeathValleyLfgService.postListing(player, zoneId)
end

joinLfgListing.OnServerInvoke = function(player: Player, listingId: string)
	if not allow(player, "JoinLfgListing", 5, 30) then
		return false, "Rate limited"
	end
	return DeathValleyLfgService.joinListing(player, listingId)
end

leaveLfgListing.OnServerInvoke = function(player: Player)
	return DeathValleyLfgService.leaveListing(player)
end

getLfgListings.OnServerInvoke = function(_player: Player)
	return DeathValleyLfgService.getListings()
end

enqueueLfgQueue.OnServerInvoke = function(player: Player, zoneId: string)
	if not allow(player, "EnqueueLfgQueue", 4, 30) then
		return false, "Rate limited"
	end
	if typeof(zoneId) ~= "string" then
		return false, "Invalid zone"
	end
	return DeathValleyLfgQueueService.enqueue(player, zoneId)
end

dequeueLfgQueue.OnServerInvoke = function(player: Player)
	return DeathValleyLfgQueueService.dequeue(player)
end

getLfgQueueState.OnServerInvoke = function(_player: Player)
	return DeathValleyLfgQueueService.getQueueSnapshot()
end

getLeaderboard.OnServerInvoke = function(player: Player, seasonId: string?)
	if typeof(seasonId) == "string" and seasonId ~= "" then
		return DeathValleyLeaderboardService.toPublicPayload(player, seasonId)
	end
	return DeathValleyLeaderboardService.toPublicPayload(player)
end

getSeasonHistory.OnServerInvoke = function(_player: Player)
	return DeathValleySeasonService.listHistoricalSeasons(12)
end

getSeasonRewardStatus.OnServerInvoke = function(player: Player, seasonId: string)
	if typeof(seasonId) ~= "string" or seasonId == "" then
		return { claimable = false }
	end
	return DeathValleySeasonRewardService.getClaimStatus(player, seasonId)
end

claimSeasonReward.OnServerInvoke = function(player: Player, seasonId: string)
	if not allow(player, "ClaimSeasonReward", 2, 60) then
		return false, "Rate limited"
	end
	if typeof(seasonId) ~= "string" then
		return false, "Invalid season"
	end
	return DeathValleySeasonRewardService.claimReward(player, seasonId)
end

sendLfgInvite.OnServerInvoke = function(player: Player, targetUserId: number)
	if not allow(player, "SendLfgInvite", 5, 30) then
		return false, "Rate limited"
	end
	if typeof(targetUserId) ~= "number" then
		return false, "Invalid target"
	end
	return DeathValleyLfgInviteService.sendInvite(player, targetUserId)
end

acceptLfgInvite.OnServerInvoke = function(player: Player, inviteId: string)
	if typeof(inviteId) ~= "string" then
		return false, "Invalid invite"
	end
	return DeathValleyLfgInviteService.acceptInvite(player, inviteId)
end

declineLfgInvite.OnServerInvoke = function(player: Player, inviteId: string)
	if typeof(inviteId) ~= "string" then
		return false, "Invalid invite"
	end
	return DeathValleyLfgInviteService.declineInvite(player, inviteId)
end

getPendingLfgInvites.OnServerInvoke = function(player: Player)
	return DeathValleyLfgInviteService.getPendingInvites(player)
end

getLfgFriendsList.OnServerInvoke = function(player: Player)
	return DeathValleyLfgFriendsService.getFriendsList(player)
end

sendLfgFriendInvite.OnServerInvoke = function(player: Player, targetUserId: number)
	if not allow(player, "SendLfgFriendInvite", 5, 30) then
		return false, "Rate limited"
	end
	if typeof(targetUserId) ~= "number" then
		return false, "Invalid target"
	end
	return DeathValleyLfgFriendsService.sendFriendInvite(player, targetUserId)
end

getRolloverStatus.OnServerInvoke = function(_player: Player)
	return DeathValleySeasonRolloverService.toPublicPayload()
end

adminForceSeasonRollover.OnServerInvoke = function(player: Player)
	if not allow(player, "AdminForceSeasonRollover", 2, 120) then
		return false, "Rate limited"
	end
	return DeathValleySeasonAdminService.forceSeasonRollover(player)
end

adminDeliverRolloverRewards.OnServerInvoke = function(player: Player)
	if not allow(player, "AdminDeliverRolloverRewards", 3, 60) then
		return false, "Rate limited"
	end
	return DeathValleySeasonAdminService.deliverRolloverRewards(player)
end

getStudioAdminStatus.OnServerInvoke = function(player: Player)
	return DeathValleySeasonAdminService.toPublicPayload(player)
end

adminResetSeasonPointer.OnServerInvoke = function(player: Player)
	if not allow(player, "AdminResetSeasonPointer", 2, 120) then
		return false, "Rate limited"
	end
	return DeathValleySeasonAdminService.resetSeasonPointer(player)
end

getCurrentSeason.OnServerInvoke = function(_player: Player)
	return DeathValleySeasonService.toPublicPayload()
end

getSeasonalRingStatus.OnServerInvoke = function(_player: Player)
	return DeathValleySeasonalRingService.toPublicPayload()
end

claimSeasonalShrine.OnServerInvoke = function(player: Player)
	if not allow(player, "ClaimSeasonalShrine", 2, 60) then
		return false, "Rate limited"
	end
	return DeathValleySeasonalRingService.claimShrineReward(player)
end

depositBeaconFuel.OnServerInvoke = function(player: Player)
	if not allow(player, "DepositBeaconFuel", 8, 30) then
		return false, "Rate limited"
	end
	local ok, msg = DeathValleyBeaconService.depositFuel(PrismDeathValleySurvivalConfig.FuelDepositAmount)
	if ok then
		remotes:WaitForChild("SurvivalStateChanged"):FireAllClients(DeathValleyNightService.buildPublicState())
	end
	return ok, msg
end

upgradeBeacon.OnServerInvoke = function(player: Player)
	if not allow(player, "UpgradeBeacon", 3, 60) then
		return false, "Rate limited"
	end
	local ok, msg = DeathValleyBeaconService.tryUpgrade(player)
	if ok then
		remotes:WaitForChild("SurvivalStateChanged"):FireAllClients(DeathValleyNightService.buildPublicState())
	end
	return ok, msg
end

startReviveChannel.OnServerInvoke = function(player: Player, targetUserId: number)
	if not allow(player, "StartReviveChannel", 5, 30) then
		return false, "Rate limited", nil
	end
	return DeathValleyReviveService.startReviveChannel(player, targetUserId)
end

completeReviveChannel.OnServerInvoke = function(player: Player)
	if not allow(player, "CompleteReviveChannel", 5, 30) then
		return false, "Rate limited"
	end
	return DeathValleyReviveService.completeReviveChannel(player)
end

local function wireExitPortal(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	local placeKey = part:GetAttribute("PlaceKey")
	if typeof(placeKey) ~= "string" then
		placeKey = GameConfig.DeathValley.ExitPortalPlaceKey
	end
	prompt.Triggered:Connect(function(player)
		local ok, err = PlaceTeleport:TeleportPlayer(player, placeKey :: PlaceTeleport.PlaceKey)
		if not ok then
			warn("[DeathValley] Exit portal:", err)
			player:SetAttribute("DV_ExitMessage", err or "Configure Hub PlaceId in PlaceSecrets")
		end
	end)
end

local function wireUpgradeKiosk(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		local ok, msg = DeathValleyBeaconService.tryUpgrade(player)
		player:SetAttribute("DV_LastUpgradeMsg", msg)
		remotes:WaitForChild("SurvivalStateChanged"):FireAllClients(DeathValleyNightService.buildPublicState())
	end)
end

local function wireFuelDepot(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		local ok, msg = DeathValleyBeaconService.depositFuel(PrismDeathValleySurvivalConfig.FuelDepositAmount)
		player:SetAttribute("DV_LastFuelMsg", msg)
		remotes:WaitForChild("SurvivalStateChanged"):FireAllClients(DeathValleyNightService.buildPublicState())
		if not ok then
			warn("[DeathValley]", player.Name, msg)
		end
	end)
end

local function wireCheckpointTerminal(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "View Checkpoint"
		prompt.ObjectText = "Session Save"
		prompt.MaxActivationDistance = 10
		prompt.Parent = part
	end
	prompt.Triggered:Connect(function(player)
		local snap = DeathValleyCheckpointService.toPublicPayload()
		if snap then
			player:SetAttribute(
				"DV_LastCheckpointMsg",
				string.format("Saved: Night %d · Beacon Lv%d · Fuel %.0f", snap.currentNight - 1, snap.beaconLevel, snap.beaconFuel)
			)
		else
			player:SetAttribute("DV_LastCheckpointMsg", "Upgrade Beacon to Lv3 to enable checkpoint saves")
		end
		player:SetAttribute("DV_OpenGlobalLeaderboard", true)
	end)
end

local function wireWeeklyBossArena(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		local ok, msg = DeathValleyWeeklyBossService.startBoss(player)
		player:SetAttribute("DV_WeeklyBossMsg", msg)
		if not ok then
			warn("[DeathValley] Weekly boss:", msg)
		end
	end)
end

local function wireLfgBoard(part: BasePart)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		player:SetAttribute("DV_OpenLfgBoard", true)
	end)
end

local function wireWorldInteractions(world: Model)
	for _, desc in world:GetDescendants() do
		if desc:IsA("BasePart") then
			if desc.Name == "ExitPortal" or desc:GetAttribute("ExitPortal") == true then
				wireExitPortal(desc)
			elseif desc.Name == "BeaconFuelDepot" or desc:GetAttribute("BeaconFuelDepot") == true then
				wireFuelDepot(desc)
			elseif desc.Name == "BeaconUpgradeKiosk" or desc:GetAttribute("BeaconUpgradeKiosk") == true then
				wireUpgradeKiosk(desc)
			elseif desc:GetAttribute("CheckpointTerminal") == true then
				wireCheckpointTerminal(desc)
			elseif desc:GetAttribute("WeeklyBossArena") == true then
				wireWeeklyBossArena(desc)
			elseif desc:GetAttribute("LfgBoard") == true then
				wireLfgBoard(desc)
			end
		end
	end
	DeathValleyPOIService.wireWorld(world)
end

local function bootstrap()
	if WorldPlaceGuard:GetCurrentPlaceKey() ~= "DeathValley" then
		return
	end

	DeathValleyReviveService.start()
	DeathValleyLfgQueueService.ensureSubscribed()
	DeathValleyLfgInviteService.ensureSubscribed()
	DeathValleySeasonRolloverService.tryProcessRollover()

	Players.PlayerRemoving:Connect(function(player)
		DeathValleyLfgService.onPlayerRemoving(player)
		DeathValleyLfgQueueService.onPlayerRemoving(player)
		DeathValleyLfgInviteService.onPlayerRemoving(player)
		DeathValleySpiritChamberService.onPlayerRemoving(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		if player:GetAttribute("DV_LuminiteShards") == nil then
			player:SetAttribute("DV_LuminiteShards", PrismDeathValleySurvivalConfig.StartingLuminiteShards)
		end
		task.defer(function()
			DeathValleyLfgQueueService.handleArrival(player)
			DeathValleyLfgInviteService.handleArrival(player)
			DeathValleySeasonRolloverService.deliverPendingForPlayer(player)
			local snap = DeathValleyCheckpointService.tryRestoreServerFromPlayer(player)
			if snap then
				DeathValleyNightService.applyCheckpoint(snap)
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("DV_LuminiteShards") == nil then
			player:SetAttribute("DV_LuminiteShards", PrismDeathValleySurvivalConfig.StartingLuminiteShards)
		end
		local snap = DeathValleyCheckpointService.tryRestoreServerFromPlayer(player)
		if snap then
			DeathValleyNightService.applyCheckpoint(snap)
			break
		end
	end

	local function tryStart()
		local world = Workspace:FindFirstChild("UtopiaDeathValley") :: Model?
		if world then
			wireWorldInteractions(world)
			DeathValleyNightService.start(world)
			return true
		end
		return false
	end

	if not tryStart() then
		local conn: RBXScriptConnection?
		conn = Workspace.ChildAdded:Connect(function(child)
			if child.Name == "UtopiaDeathValley" then
				task.defer(function()
					tryStart()
					if conn then
						conn:Disconnect()
					end
				end)
			end
		end)
	end
end

task.defer(bootstrap)
print("[DeathValley] Survival handlers online")
