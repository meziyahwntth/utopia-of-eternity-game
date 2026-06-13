--!strict
--[[
	VisiblePowerClient (P7) — Highlight outline + PointLight per tier (T4+)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local tierChanged = remotes:WaitForChild("TierChanged") :: RemoteEvent
local tierBroadcast = remotes:WaitForChild("PlayerTierBroadcast") :: RemoteEvent

type AuraState = {
	color: Color3,
	intensity: number,
	enabled: boolean,
}

local selfAura: AuraState? = nil
local otherAuras: { [number]: AuraState } = {}

local function applyAura(character: Model, auraColor: Color3, glowIntensity: number, enabled: boolean)
	local old = character:FindFirstChild("TierAura")
	if old then
		old:Destroy()
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local oldLight = hrp:FindFirstChild("TierLight")
		if oldLight then
			oldLight:Destroy()
		end
	end

	if not enabled or glowIntensity == 0 then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TierAura"
	highlight.OutlineColor = auraColor
	highlight.OutlineTransparency = 1 - (glowIntensity / 5)
	highlight.FillTransparency = 1
	highlight.Parent = character

	if hrp then
		local light = Instance.new("PointLight")
		light.Name = "TierLight"
		light.Color = auraColor
		light.Brightness = glowIntensity * 0.6
		light.Range = 10 + (glowIntensity * 4)
		light.Parent = hrp
	end
end

local function applySelfAura()
	if not selfAura then
		return
	end
	local char = localPlayer.Character
	if char then
		applyAura(char, selfAura.color, selfAura.intensity, selfAura.enabled)
	end
end

tierChanged.OnClientEvent:Connect(function(_tier, auraEnabled, auraColor, glowIntensity)
	selfAura = {
		color = auraColor :: Color3,
		intensity = glowIntensity :: number,
		enabled = auraEnabled :: boolean,
	}
	applySelfAura()
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	applySelfAura()
end)

tierBroadcast.OnClientEvent:Connect(function(userId, _tier, auraEnabled, auraColor, glowIntensity)
	local uid = userId :: number
	if uid == localPlayer.UserId then
		return
	end
	local state: AuraState = {
		color = auraColor :: Color3,
		intensity = glowIntensity :: number,
		enabled = auraEnabled :: boolean,
	}
	otherAuras[uid] = state

	local target = Players:GetPlayerByUserId(uid)
	if target and target.Character then
		applyAura(target.Character, state.color, state.intensity, state.enabled)
	end
end)

Players.PlayerAdded:Connect(function(other)
	other.CharacterAdded:Connect(function(char)
		local state = otherAuras[other.UserId]
		if state then
			task.wait(0.5)
			applyAura(char, state.color, state.intensity, state.enabled)
		end
	end)
	if other.Character then
		local state = otherAuras[other.UserId]
		if state then
			applyAura(other.Character, state.color, state.intensity, state.enabled)
		end
	end
end)

Players.PlayerRemoving:Connect(function(other)
	otherAuras[other.UserId] = nil
end)
