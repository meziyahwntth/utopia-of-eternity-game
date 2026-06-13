--!strict
--[[
	PetService (Backlog B) — equip/unequip/grant, spawn model, follow loop, buff attributes
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PetConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetConfig"))
local PetStore = require(script.Parent:WaitForChild("PetStore"))

local PetService = {}

local activePetModels: { [number]: Model } = {}
local followConns: { [number]: RBXScriptConnection } = {}
local remotes: Folder? = nil

local RARITY_COLORS: { [PetConfig.PetRarity]: BrickColor } = {
	Common = BrickColor.new("Bright blue"),
	Rare = BrickColor.new("Bright orange"),
	Epic = BrickColor.new("Bright violet"),
	Legendary = BrickColor.new("Bright yellow"),
}

local function findPetConfig(petId: string): PetConfig.PetEntry?
	for _, entry in PetConfig.Pets do
		if entry.id == petId then
			return entry
		end
	end
	return nil
end

local function destroyActiveModel(userId: number)
	local conn = followConns[userId]
	if conn then
		conn:Disconnect()
		followConns[userId] = nil
	end
	local model = activePetModels[userId]
	if model and model.Parent then
		model:Destroy()
	end
	activePetModels[userId] = nil
end

local function applyBuffAttributes(player: Player, petCfg: PetConfig.PetEntry?)
	if petCfg then
		player:SetAttribute("PetExpBonus", petCfg.buff.expBonus)
		player:SetAttribute("PetPickupRadius", petCfg.buff.pickupRadius)
		player:SetAttribute("PetLuckBonus", petCfg.buff.luckBonus)
		player:SetAttribute("ActivePetId", petCfg.id)
	else
		player:SetAttribute("PetExpBonus", 0)
		player:SetAttribute("PetPickupRadius", 0)
		player:SetAttribute("PetLuckBonus", 0)
		player:SetAttribute("ActivePetId", nil)
	end
end

local function spawnPetModel(player: Player, petCfg: PetConfig.PetEntry): Model?
	local char = player.Character
	if not char then
		return nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "Pet_" .. tostring(player.UserId)

	local body = Instance.new("Part")
	body.Name = "PetBody"
	body.Size = Vector3.new(2, 2, 2)
	body.CFrame = hrp.CFrame * CFrame.new(3, 0, 0)
	body.Anchored = false
	body.CanCollide = false
	body.Massless = true
	body.BrickColor = RARITY_COLORS[petCfg.rarity] or BrickColor.new("Bright blue")
	body.Shape = Enum.PartType.Ball
	body.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = hrp
	weld.Parent = body
	weld.Enabled = false

	local nameTag = Instance.new("BillboardGui")
	nameTag.Size = UDim2.fromOffset(100, 30)
	nameTag.StudsOffset = Vector3.new(0, 2, 0)
	nameTag.AlwaysOnTop = true
	nameTag.Parent = body

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 1)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextScaled = true
	nameLbl.Text = petCfg.icon .. " " .. petCfg.nameTH
	nameLbl.Parent = nameTag

	model.PrimaryPart = body
	model.Parent = Workspace

	return model
end

local function startFollowLoop(player: Player, petModel: Model)
	local userId = player.UserId
	local existing = followConns[userId]
	if existing then
		existing:Disconnect()
	end

	followConns[userId] = RunService.Heartbeat:Connect(function()
		if not player.Parent or not petModel.Parent then
			destroyActiveModel(userId)
			return
		end
		local char = player.Character
		if not char then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local body = petModel:FindFirstChild("PetBody") :: BasePart?
		if not hrp or not body then
			return
		end

		local offset = hrp.CFrame:VectorToWorldSpace(Vector3.new(-3, 0, 2))
		local target = hrp.Position + offset + Vector3.new(0, 1, 0)
		body.CFrame = CFrame.new(body.Position:Lerp(target, 0.08))
	end)
end

local function fireEquipped(player: Player, petId: string, petCfg: PetConfig.PetEntry)
	if not remotes then
		return
	end
	local ev = remotes:FindFirstChild("PetEquipped") :: RemoteEvent?
	if ev then
		ev:FireClient(player, petId, petCfg.buff.expBonus, petCfg.buff.pickupRadius, petCfg.buff.luckBonus)
	end
end

local function fireUnequipped(player: Player)
	if not remotes then
		return
	end
	local ev = remotes:FindFirstChild("PetUnequipped") :: RemoteEvent?
	if ev then
		ev:FireClient(player)
	end
end

local function spawnEquippedPet(player: Player, petId: string, petCfg: PetConfig.PetEntry): (boolean, string)
	destroyActiveModel(player.UserId)

	local model = spawnPetModel(player, petCfg)
	if not model then
		return false, "spawn ไม่สำเร็จ"
	end

	activePetModels[player.UserId] = model
	startFollowLoop(player, model)
	applyBuffAttributes(player, petCfg)
	fireEquipped(player, petId, petCfg)
	return true, petCfg.nameTH .. " ออกมาแล้ว!"
end

function PetService.equipPet(player: Player, petId: string): (boolean, string)
	local petCfg = findPetConfig(petId)
	if not petCfg then
		return false, "ไม่พบ pet"
	end

	if not PetStore.setActive(player.UserId, petId) then
		return false, "ไม่มี pet นี้ในคอลเลกชัน"
	end

	return spawnEquippedPet(player, petId, petCfg)
end

function PetService.unequipPet(player: Player)
	PetStore.setActive(player.UserId, nil)
	destroyActiveModel(player.UserId)
	applyBuffAttributes(player, nil)
	fireUnequipped(player)
end

function PetService.grantPet(player: Player, petId: string): (boolean, string)
	local petCfg = findPetConfig(petId)
	if not petCfg then
		return false, "ไม่พบ pet"
	end
	if not PetStore.addPet(player.UserId, petId) then
		return false, "มี pet นี้แล้ว"
	end
	return true, "ได้รับ " .. petCfg.nameTH .. "!"
end

function PetService.getCollection(player: Player): { string }
	return PetStore.get(player.UserId).ownedPets
end

function PetService.getActivePetId(player: Player): string?
	return PetStore.get(player.UserId).activePetId
end

function PetService.respawnActivePet(player: Player)
	local activeId = PetStore.get(player.UserId).activePetId
	if not activeId then
		return
	end
	local petCfg = findPetConfig(activeId)
	if not petCfg then
		return
	end
	spawnEquippedPet(player, activeId, petCfg)
end

function PetService.onPlayerRemoving(player: Player)
	destroyActiveModel(player.UserId)
end

function PetService.init(remotesFolder: Folder)
	remotes = remotesFolder

	Players.PlayerRemoving:Connect(PetService.onPlayerRemoving)

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			PetService.respawnActivePet(player)
		end)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			PetService.respawnActivePet(player)
		end)
	end
end

return PetService
