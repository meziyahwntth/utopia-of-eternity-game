--!strict
--[[
	Fashion Show contest service — state machine: Idle → Registration → Dressing → Runway → Voting → Results
	Uses PrismFashionCatalog for round themes. Server-side voting + Luminite rewards via DV_LuminiteShards.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismFashionCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismFashionCatalog"))

local FashionShowService = {}

export type FashionState = "Idle" | "Registration" | "Dressing" | "Runway" | "Voting" | "Results"

export type Contestant = {
	userId: number,
	name: string,
	outfitSetId: string,
	outfitName: string,
}

local STATE_ORDER: { FashionState } = {
	"Idle",
	"Registration",
	"Dressing",
	"Runway",
	"Voting",
	"Results",
}

local currentState: FashionState = "Idle"
local roundNumber = 0
local stateEndsAt = 0
local themeSetId = ""
local themeSetName = ""

local registrants: { [number]: boolean } = {}
local outfits: { [number]: { setId: string, setName: string } } = {}
local votes: { [number]: number } = {} -- voterUserId -> targetUserId
local voteCounts: { [number]: number } = {} -- contestantUserId -> count

local stageRoot: BasePart? = nil
local running = false

local function isTestMode(): boolean
	return RunService:IsStudio()
end

local function getDurations(): { [FashionState]: number }
	if isTestMode() then
		return GameConfig.FashionShow.StateDurationsTestMode
	end
	return GameConfig.FashionShow.StateDurationsProduction
end

local function getMinPlayers(): number
	if isTestMode() then
		return GameConfig.FashionShow.MinPlayersTestMode
	end
	return GameConfig.FashionShow.MinPlayersProduction
end

local function findStageRoot(): BasePart?
	if stageRoot and stageRoot.Parent then
		return stageRoot
	end
	local city = workspace:FindFirstChild("UtopiaEternityCity")
	if city then
		local stage = city:FindFirstChild("UtopiaFashionStage", true)
		if stage then
			local root = stage:FindFirstChild("FashionStageRoot")
			if root and root:IsA("BasePart") then
				stageRoot = root
				return root
			end
		end
	end
	return nil
end

local function syncAttributes()
	local root = findStageRoot()
	if root then
		root:SetAttribute("FashionState", currentState)
		root:SetAttribute("FashionRound", roundNumber)
	end
	workspace:SetAttribute("FashionState", currentState)
	workspace:SetAttribute("FashionRound", roundNumber)
end

local function clearRoundData()
	table.clear(registrants)
	table.clear(outfits)
	table.clear(votes)
	table.clear(voteCounts)
end

local function pickThemeSet(): (string, string)
	local sets = PrismFashionCatalog.getAllSets()
	if #sets == 0 then
		return "prismwake_gala", "Prismwake Gala"
	end
	local idx = (roundNumber % #sets) + 1
	local set = sets[idx]
	return set.id, set.displayName
end

local function getContestants(): { Contestant }
	local list: { Contestant } = {}
	for userId, outfit in outfits do
		local player = Players:GetPlayerByUserId(userId)
		local name = if player then player.Name else ("Player_" .. userId)
		table.insert(list, {
			userId = userId,
			name = name,
			outfitSetId = outfit.setId,
			outfitName = outfit.setName,
		})
	end
	table.sort(list, function(a, b)
		return a.userId < b.userId
	end)
	return list
end

local function contestantCount(): number
	local n = 0
	for _ in outfits do
		n += 1
	end
	return n
end

local function grantLuminite(player: Player, amount: number)
	local shards = player:GetAttribute("DV_LuminiteShards")
	if typeof(shards) ~= "number" then
		shards = 0
	end
	player:SetAttribute("DV_LuminiteShards", shards + amount)
end

local function distributeRewards()
	local bestUserId: number? = nil
	local bestVotes = -1
	for userId, count in voteCounts do
		if count > bestVotes then
			bestVotes = count
			bestUserId = userId
		end
	end

	for userId, _ in outfits do
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			continue
		end
		grantLuminite(player, GameConfig.FashionShow.ParticipantLuminite)
	end

	if bestUserId and bestVotes > 0 then
		local winner = Players:GetPlayerByUserId(bestUserId)
		if winner then
			grantLuminite(winner, GameConfig.FashionShow.WinnerLuminite)
			winner:SetAttribute("FashionTitle", GameConfig.FashionShow.WinnerTitle)
			print(string.format("[FashionShow] Winner %s (%d votes) +%d Luminite", winner.Name, bestVotes, GameConfig.FashionShow.WinnerLuminite))
		end
	end
end

function FashionShowService.getState(): FashionState
	return currentState
end

function FashionShowService.getInfo(player: Player): { [string]: any }
	local myVote: number? = nil
	local voted = votes[player.UserId]
	if voted then
		myVote = voted
	end
	return {
		state = currentState,
		round = roundNumber,
		secondsRemaining = math.max(0, math.floor(stateEndsAt - os.clock())),
		contestants = getContestants(),
		myVoteTarget = myVote,
		themeSet = {
			id = themeSetId,
			displayName = themeSetName,
		},
		minPlayers = getMinPlayers(),
		isRegistered = registrants[player.UserId] == true,
		testMode = isTestMode(),
	}
end

function FashionShowService.join(player: Player): (boolean, string)
	if currentState ~= "Registration" then
		return false, "Registration is not open"
	end
	if registrants[player.UserId] then
		return false, "Already registered"
	end
	registrants[player.UserId] = true
	return true, "Joined fashion show round " .. tostring(roundNumber)
end

function FashionShowService.submitOutfit(player: Player, setId: string): (boolean, string)
	if currentState ~= "Dressing" then
		return false, "Not in dressing phase"
	end
	if not registrants[player.UserId] then
		return false, "Not registered for this round"
	end
	local set = PrismFashionCatalog.getSetById(setId)
	if not set then
		return false, "Unknown outfit set"
	end
	outfits[player.UserId] = { setId = set.id, setName = set.displayName }
	player:SetAttribute("FashionOutfitSet", set.id)
	return true, "Outfit submitted: " .. set.displayName
end

function FashionShowService.castVote(player: Player, targetUserId: number): (boolean, string)
	if currentState ~= "Voting" then
		return false, "Voting is not open"
	end
	if targetUserId == player.UserId then
		return false, "Cannot vote for yourself"
	end
	if not outfits[targetUserId] then
		return false, "Target is not a contestant"
	end
	if votes[player.UserId] then
		return false, "Already voted this round"
	end
	votes[player.UserId] = targetUserId
	voteCounts[targetUserId] = (voteCounts[targetUserId] or 0) + 1
	return true, "Vote recorded"
end

local function enterState(state: FashionState, duration: number)
	currentState = state
	stateEndsAt = os.clock() + duration
	syncAttributes()
	print(string.format("[FashionShow] Round %d → %s (%ds)", roundNumber, state, duration))
end

local function runStateLoop()
	while running do
		clearRoundData()
		roundNumber += 1
		themeSetId, themeSetName = pickThemeSet()

		local durations = getDurations()
		enterState("Idle", durations.Idle)
		task.wait(durations.Idle)

		enterState("Registration", durations.Registration)
		task.wait(durations.Registration)

		local registered = 0
		for _ in registrants do
			registered += 1
		end
		if registered < getMinPlayers() then
			warn(string.format("[FashionShow] Round %d cancelled — %d/%d players", roundNumber, registered, getMinPlayers()))
			continue
		end

		enterState("Dressing", durations.Dressing)
		task.wait(durations.Dressing)

		-- Auto-assign theme set for players who didn't submit
		for userId in registrants do
			if not outfits[userId] then
				outfits[userId] = { setId = themeSetId, setName = themeSetName }
			end
		end

		if contestantCount() < getMinPlayers() then
			warn(string.format("[FashionShow] Round %d cancelled after dressing — insufficient outfits", roundNumber))
			continue
		end

		enterState("Runway", durations.Runway)
		task.wait(durations.Runway)

		enterState("Voting", durations.Voting)
		task.wait(durations.Voting)

		enterState("Results", durations.Results)
		distributeRewards()
		task.wait(durations.Results)
	end
end

function FashionShowService.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		-- Wait for world build
		for _ = 1, 120 do
			if findStageRoot() then
				break
			end
			task.wait(1)
		end
		syncAttributes()
		print("[FashionShow] Service started — testMode=", isTestMode(), "minPlayers=", getMinPlayers())
		runStateLoop()
	end)
end

return FashionShowService
