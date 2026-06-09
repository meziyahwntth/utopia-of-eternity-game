--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PrismKeyService = require(script.Parent:WaitForChild("PrismKeyService"))
local PrismKeyGhostNpcService = require(script.Parent:WaitForChild("PrismKeyGhostNpcService"))
local PrismKeyRandomPools = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyRandomPools"))

local remotes = ReplicatedStorage:WaitForChild("PrismKeyRemotes")
local getOwnedKeys = remotes:WaitForChild("GetOwnedKeys") :: RemoteFunction
local executeKeyTrade = remotes:WaitForChild("ExecuteKeyTrade") :: RemoteFunction

local RateLimiter = require(ServerScriptService:WaitForChild("Security"):WaitForChild("RateLimiter"))

local function allow(player: Player, name: string, maxTokens: number, windowSeconds: number): boolean
	return RateLimiter:TryConsume(player, name, {
		maxTokens = maxTokens,
		refillPerSecond = maxTokens / windowSeconds,
	})
end

getOwnedKeys.OnServerInvoke = function(player: Player)
	if not allow(player, "GetOwnedKeys", 15, 60) then
		return { ok = false, message = "Rate limited" }
	end
	return {
		ok = true,
		keys = PrismKeyService.getOwnedKeys(player),
		count = PrismKeyService.getKeyCount(player),
		tradeCost = PrismKeyRandomPools.TradeCost,
	}
end

executeKeyTrade.OnServerInvoke = function(player: Player, sacrificeKeys: { number }, targetKeyNumber: number)
	if not allow(player, "ExecuteKeyTrade", 3, 60) then
		return false, "Rate limited"
	end
	if PrismKeyGhostNpcService.getActiveSessionPlayer() ~= player then
		return false, "Talk to the ghost and finish within 1 minute"
	end
	if PrismKeyGhostNpcService.isSessionExpired() then
		PrismKeyGhostNpcService.cancelSession("timeout")
		return false, "Too slow — the ghost has moved on"
	end
	if typeof(targetKeyNumber) ~= "number" then
		return false, "Invalid target key"
	end
	if typeof(sacrificeKeys) ~= "table" or #sacrificeKeys ~= PrismKeyRandomPools.TradeCost then
		return false, string.format("Select exactly %d keys to trade", PrismKeyRandomPools.TradeCost)
	end

	local ok, msg = PrismKeyService.tradeKeysForNumber(player, sacrificeKeys, targetKeyNumber)
	if ok then
		PrismKeyGhostNpcService.completeTrade(player)
	end
	return ok, msg
end

-- Ghost NPC spawns when Death Valley world exists
task.defer(function()
	local world = workspace:FindFirstChild("UtopiaDeathValley")
	if world then
		local anchorsFolder = world:FindFirstChild("PrismKeyGhostAnchors")
		if anchorsFolder then
			local anchors: { { zoneIndex: number, cframe: CFrame } } = {}
			for _, inst in anchorsFolder:GetChildren() do
				if inst:IsA("BasePart") then
					local z = inst:GetAttribute("GhostZoneIndex")
					if typeof(z) == "number" then
						table.insert(anchors, { zoneIndex = z, cframe = inst.CFrame })
					end
				end
			end
			table.sort(anchors, function(a, b)
				return a.zoneIndex < b.zoneIndex
			end)
			PrismKeyGhostNpcService.start(world, anchors)
		else
			PrismKeyGhostNpcService.start(nil, nil)
		end
	else
		PrismKeyGhostNpcService.start(nil, nil)
	end
end)

print("[PrismKey] Trade handlers online")
