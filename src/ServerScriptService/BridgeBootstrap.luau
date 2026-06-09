--!strict
--[[
	Apply BridgeSecrets + PlaceSecrets into GameConfig (idempotent).
	Required by GameBootstrap and SecurityCore before other systems start.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local BridgeBootstrap = {}
local applied = false

local function tryRequire(name: string): any?
	local secretsFolder = ServerScriptService:FindFirstChild("Secrets")
	if not secretsFolder then
		return nil
	end
	local inst = secretsFolder:FindFirstChild(name)
	if not inst or not inst:IsA("ModuleScript") then
		return nil
	end
	local ok, value = pcall(require, inst)
	if ok then
		return value
	end
	warn("[Utopia] Failed to load secret module:", name, value)
	return nil
end

function BridgeBootstrap:Apply()
	if applied then
		return
	end
	applied = true

	local bridgeSecrets = tryRequire("BridgeSecrets")
	if bridgeSecrets then
		if bridgeSecrets.BRIDGE_KEY then
			GameConfig.Bridge.BRIDGE_KEY = bridgeSecrets.BRIDGE_KEY
		end
		if bridgeSecrets.LOG_ANALYZER_URL then
			GameConfig.Bridge.LOG_ANALYZER_URL = bridgeSecrets.LOG_ANALYZER_URL
		end
		if bridgeSecrets.FAN_SCAN_URL then
			GameConfig.Bridge.FAN_SCAN_URL = bridgeSecrets.FAN_SCAN_URL
			if not bridgeSecrets.FAN_SCAN_REPORT_URL then
				GameConfig.Bridge.FAN_SCAN_REPORT_URL = bridgeSecrets.FAN_SCAN_URL .. "/report"
			end
		end
		if bridgeSecrets.FAN_SCAN_REPORT_URL then
			GameConfig.Bridge.FAN_SCAN_REPORT_URL = bridgeSecrets.FAN_SCAN_REPORT_URL
		end
		if bridgeSecrets.CREATOR_PAYOUT_PUSH_URL then
			GameConfig.Bridge.CREATOR_PAYOUT_PUSH_URL = bridgeSecrets.CREATOR_PAYOUT_PUSH_URL
		end
		if bridgeSecrets.CREATOR_PAYOUT_SYNC_URL then
			GameConfig.Bridge.CREATOR_PAYOUT_SYNC_URL = bridgeSecrets.CREATOR_PAYOUT_SYNC_URL
		elseif bridgeSecrets.CREATOR_PAYOUT_PUSH_URL then
			GameConfig.Bridge.CREATOR_PAYOUT_SYNC_URL = string.gsub(
				bridgeSecrets.CREATOR_PAYOUT_PUSH_URL,
				"/push$",
				"/sync"
			)
		end
	end

	local placeSecrets = tryRequire("PlaceSecrets")
	if placeSecrets then
		for key, value in placeSecrets do
			if key == "UniverseId" or key == "CreatorGroupId" then
				continue
			end
			local placeId = value
			local placeCfg = (GameConfig.Places :: any)[key]
			if placeCfg and typeof(placeId) == "number" and placeId > 0 then
				placeCfg.id = placeId
			end
		end
		if typeof(placeSecrets.UniverseId) == "number" and placeSecrets.UniverseId > 0 then
			(GameConfig :: any).UniverseId = placeSecrets.UniverseId
		end
		if typeof(placeSecrets.CreatorGroupId) == "number" and placeSecrets.CreatorGroupId > 0 then
			local dv = GameConfig.DeathValley :: any
			if dv and typeof(dv.CreatorPayout) == "table" then
				dv.CreatorPayout.groupId = placeSecrets.CreatorGroupId
			end
			local community = (GameConfig :: any).Community
			if typeof(community) == "table" then
				community.groupId = placeSecrets.CreatorGroupId
				community.url = string.format(
					"https://www.roblox.com/communities/%d/Utopia-of-Eternity",
					placeSecrets.CreatorGroupId
				)
			end
		end
		if typeof(placeSecrets.UniverseId) == "number" and placeSecrets.UniverseId > 0 then
			local community = (GameConfig :: any).Community
			if typeof(community) == "table" then
				community.experienceUrl = string.format(
					"https://www.roblox.com/games/%d/Utopia-of-Eternity",
					placeSecrets.UniverseId
				)
			end
		end
	end

	require(ServerScriptService:WaitForChild("CatalogBootstrap")):Apply()
end

return BridgeBootstrap
