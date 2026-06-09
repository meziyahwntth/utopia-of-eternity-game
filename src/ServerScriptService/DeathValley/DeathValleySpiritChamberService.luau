--!strict
--[[
	Phase D/E — Spirit Lock Chamber combat (co-op sessions, shared robot waves).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PrismHellboundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismHellboundConfig"))

local DeathValleySpiritChamberService = {}

export type ChamberProgress = {
	chamberIndex: number,
	cleared: boolean,
	active: boolean,
	remaining: number,
}

type ChamberSession = {
	id: string,
	chamberIndex: number,
	origin: Vector3,
	members: { [number]: true },
	remaining: number,
	active: boolean,
	cleared: boolean,
	folder: Folder,
}

local playerProgress: { [number]: { [number]: ChamberProgress } } = {}
local sessions: { [string]: ChamberSession } = {}
local playerSession: { [number]: string } = {}
local aiConn: RBXScriptConnection? = nil

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local chamberChanged = remotes:WaitForChild("SpiritChamberStateChanged") :: RemoteEvent

local ROBOT_COLOR = Color3.fromRGB(120, 140, 160)
local ROBOT_SIZE = Vector3.new(3, 6, 3)

local function sessionKey(chamberIndex: number): string
	return "chamber_" .. chamberIndex
end

local function getChamberDef(index: number): PrismHellboundConfig.SpiritChamber?
	return PrismHellboundConfig.SpiritChambers[index]
end

local function ensureProgress(player: Player): { [number]: ChamberProgress }
	if not playerProgress[player.UserId] then
		playerProgress[player.UserId] = {}
		for i = 1, #PrismHellboundConfig.SpiritChambers do
			playerProgress[player.UserId][i] = {
				chamberIndex = i,
				cleared = false,
				active = false,
				remaining = 0,
			}
		end
	end
	return playerProgress[player.UserId]
end

local function isChamberUnlocked(player: Player, index: number): boolean
	if index == 1 then
		return true
	end
	local progress = ensureProgress(player)
	local prev = progress[index - 1]
	return prev ~= nil and prev.cleared
end

local function countMembers(session: ChamberSession): number
	local n = 0
	for _ in session.members do
		n += 1
	end
	return n
end

local function spawnRobot(parent: Instance, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "SpiritRobot"
	local core = Instance.new("Part")
	core.Name = "HumanoidRootPart"
	core.Size = ROBOT_SIZE
	core.Color = ROBOT_COLOR
	core.Material = Enum.Material.Metal
	core.Anchored = false
	core.CFrame = CFrame.new(position)
	core.Parent = model
	model.PrimaryPart = core
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 50
	hum.Health = 50
	hum.WalkSpeed = 14
	hum.Parent = model
	core.Touched:Connect(function(hit)
		local char = hit:FindFirstAncestorOfClass("Model")
		if not char then
			return
		end
		local target = Players:GetPlayerFromCharacter(char)
		if not target then
			return
		end
		local targetHum = char:FindFirstChildOfClass("Humanoid")
		if targetHum and targetHum.Health > 0 then
			targetHum:TakeDamage(8)
		end
	end)
	model.Parent = parent
	return model
end

local function nearestMemberPosition(session: ChamberSession): Vector3?
	local bestDist = math.huge
	local bestPos: Vector3? = nil
	local origin = session.origin
	for userId in session.members do
		local member = Players:GetPlayerByUserId(userId)
		if member and member.Character and member.Character:FindFirstChild("HumanoidRootPart") then
			local pos = (member.Character.HumanoidRootPart :: BasePart).Position
			local dist = (pos - origin).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestPos = pos
			end
		end
	end
	return bestPos
end

local function startAi()
	if aiConn then
		return
	end
	aiConn = RunService.Heartbeat:Connect(function(dt)
		for _, session in sessions do
			if not session.active or session.cleared or not session.folder.Parent then
				continue
			end
			local goal = nearestMemberPosition(session)
			if not goal then
				continue
			end
			for _, model in session.folder:GetChildren() do
				if model:IsA("Model") and model.PrimaryPart then
					local hum = model:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						local dir = (goal - model.PrimaryPart.Position) * Vector3.new(1, 0, 1)
						if dir.Magnitude > 2 then
							model.PrimaryPart.CFrame += dir.Unit * hum.WalkSpeed * dt
						end
					end
				end
			end
		end
	end)
end

local function syncMemberProgress(session: ChamberSession)
	for userId in session.members do
		local progress = playerProgress[userId]
		if progress then
			local entry = progress[session.chamberIndex]
			if entry then
				entry.active = session.active and not session.cleared
				entry.remaining = session.remaining
				entry.cleared = session.cleared
			end
		end
	end
end

local function broadcastSession(session: ChamberSession)
	syncMemberProgress(session)
	for userId in session.members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			local progress = ensureProgress(member)
			local list: { ChamberProgress } = {}
			for i = 1, #PrismHellboundConfig.SpiritChambers do
				table.insert(list, progress[i])
			end
			chamberChanged:FireClient(member, {
				chambers = list,
				allCleared = progress[#PrismHellboundConfig.SpiritChambers].cleared,
				coOpSize = countMembers(session),
				sessionId = session.id,
			})
		end
	end
end

local function clearSession(session: ChamberSession)
	if session.folder.Parent then
		session.folder:Destroy()
	end
	for userId in session.members do
		playerSession[userId] = nil
		local member = Players:GetPlayerByUserId(userId)
		if member then
			member:SetAttribute("DV_SpiritChamberActive", nil)
		end
	end
	sessions[sessionKey(session.chamberIndex)] = nil
end

local function completeSession(session: ChamberSession)
	session.active = false
	session.cleared = true
	session.remaining = 0
	for userId in session.members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			local progress = ensureProgress(member)
			progress[session.chamberIndex].cleared = true
			progress[session.chamberIndex].active = false
			progress[session.chamberIndex].remaining = 0
			member:SetAttribute("DV_SpiritChamber_" .. session.chamberIndex, true)
			member:SetAttribute("DV_SpiritChamberActive", nil)
		end
	end
	broadcastSession(session)
	clearSession(session)
end

local function addMemberToSession(player: Player, session: ChamberSession): (boolean, string)
	if session.members[player.UserId] then
		return true, "Already in co-op session"
	end
	if session.cleared or not session.active then
		return false, "Session ended"
	end
	session.members[player.UserId] = true
	playerSession[player.UserId] = session.id
	player:SetAttribute("DV_SpiritChamberActive", session.chamberIndex)
	broadcastSession(session)
	local def = getChamberDef(session.chamberIndex)
	local name = if def then def.name else "Spirit Lock"
	return true, string.format("Joined co-op %s (%d players)", name, countMembers(session))
end

local function createSession(player: Player, chamberIndex: number, origin: Vector3): (boolean, string)
	local def = getChamberDef(chamberIndex)
	if not def then
		return false, "Invalid chamber"
	end

	local key = sessionKey(chamberIndex)
	local existing = sessions[key]
	if existing and existing.active and not existing.cleared then
		return addMemberToSession(player, existing)
	end

	local session: ChamberSession = {
		id = HttpService:GenerateGUID(false),
		chamberIndex = chamberIndex,
		origin = origin,
		members = { [player.UserId] = true },
		remaining = def.robotGuards,
		active = true,
		cleared = false,
		folder = Instance.new("Folder"),
	}
	session.folder.Name = "SpiritRobots_" .. chamberIndex
	session.folder.Parent = workspace
	sessions[key] = session
	playerSession[player.UserId] = session.id
	player:SetAttribute("DV_SpiritChamberActive", chamberIndex)

	local count = def.robotGuards
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local pos = origin + Vector3.new(math.cos(angle) * 14, 3, math.sin(angle) * 14)
		local robot = spawnRobot(session.folder, pos)
		local hum = robot:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				session.remaining = math.max(0, session.remaining - 1)
				if session.remaining <= 0 then
					completeSession(session)
				else
					broadcastSession(session)
				end
			end)
		end
	end

	startAi()
	broadcastSession(session)
	return true, string.format("%s — defeat %d robots (co-op enabled)", def.name, count)
end

function DeathValleySpiritChamberService.beginChamber(player: Player, chamberIndex: number, origin: Vector3): (boolean, string)
	local def = getChamberDef(chamberIndex)
	if not def then
		return false, "Invalid chamber"
	end
	if not isChamberUnlocked(player, chamberIndex) then
		return false, "Clear previous chamber first"
	end
	local progress = ensureProgress(player)
	if progress[chamberIndex].cleared then
		return true, def.name .. " already cleared"
	end

	local key = sessionKey(chamberIndex)
	local active = sessions[key]
	if active and active.active and not active.cleared then
		return addMemberToSession(player, active)
	end

	if progress[chamberIndex].active then
		return false, "Chamber already active"
	end

	return createSession(player, chamberIndex, origin)
end

function DeathValleySpiritChamberService.isChamberCleared(player: Player, chamberIndex: number): boolean
	local progress = ensureProgress(player)
	return progress[chamberIndex].cleared
end

function DeathValleySpiritChamberService.allChambersCleared(player: Player): boolean
	local progress = ensureProgress(player)
	return progress[#PrismHellboundConfig.SpiritChambers].cleared
end

function DeathValleySpiritChamberService.onPlayerRemoving(player: Player)
	local sid = playerSession[player.UserId]
	if sid then
		for _, session in sessions do
			if session.id == sid then
				session.members[player.UserId] = nil
				if countMembers(session) == 0 then
					clearSession(session)
				else
					broadcastSession(session)
				end
				break
			end
		end
		playerSession[player.UserId] = nil
	end
	playerProgress[player.UserId] = nil
end

return DeathValleySpiritChamberService
