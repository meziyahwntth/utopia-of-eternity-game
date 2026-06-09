--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local MovementValidator = {}

local lastPositions: { [number]: { position: Vector3, time: number } } = {}
local speedStrikes: { [number]: number } = {}

local SuspicionTracker
local SentinelStrike

function MovementValidator:Init(deps: { SuspicionTracker: any, SentinelStrike: any })
	SuspicionTracker = deps.SuspicionTracker
	SentinelStrike = deps.SentinelStrike
end

local function getHumanoidRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function MovementValidator:TrackPlayer(player: Player)
	local root = getHumanoidRoot(player)
	if not root then
		return
	end
	local userId = player.UserId
	local now = os.clock()
	local previous = lastPositions[userId]
	lastPositions[userId] = { position = root.Position, time = now }
	if not previous or not SuspicionTracker then
		return
	end
	local deltaTime = now - previous.time
	if deltaTime <= 0 then
		return
	end
	local distance = (root.Position - previous.position).Magnitude
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local maxSpeed = (humanoid and humanoid.WalkSpeed or 16) * GameConfig.Security.MAX_WALK_SPEED_MULTIPLIER
	local impliedSpeed = distance / deltaTime
	if distance >= GameConfig.Security.TELEPORT_STUD_THRESHOLD and deltaTime <= GameConfig.Security.MOVEMENT_CHECK_INTERVAL then
		local score = SuspicionTracker:Add(player, 25, "TELEPORT_DETECTED")
		if score >= GameConfig.Security.SUSPICION_KICK and SentinelStrike then
			SentinelStrike:Warn(player, "Teleport exploit", score)
		end
		return
	end
	if impliedSpeed > maxSpeed then
		speedStrikes[userId] = (speedStrikes[userId] or 0) + 1
		if speedStrikes[userId] >= 3 then
			speedStrikes[userId] = 0
			local score = SuspicionTracker:Add(player, 10, "SPEED_HACK")
			if score >= GameConfig.Security.SUSPICION_KICK and SentinelStrike then
				SentinelStrike:Warn(player, "Speed exploit", score)
			end
		end
	else
		speedStrikes[userId] = 0
	end
end

function MovementValidator:Start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.Security.MOVEMENT_CHECK_INTERVAL)
			for _, player in Players:GetPlayers() do
				self:TrackPlayer(player)
			end
		end
	end)
end

function MovementValidator:ClearPlayer(player: Player)
	lastPositions[player.UserId] = nil
	speedStrikes[player.UserId] = nil
end

return MovementValidator
