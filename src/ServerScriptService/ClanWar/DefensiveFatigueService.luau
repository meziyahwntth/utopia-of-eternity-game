--!strict
--[[
	DefensiveFatigueService (P5) — weekly fort HP decay for owned territories
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TerritoryStore = require(script.Parent:WaitForChild("TerritoryStore"))
local ClanWarConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClanWarConfig"))

local WEEK_SECONDS = 7 * 24 * 60 * 60

local DefensiveFatigueService = {}

function DefensiveFatigueService.runDecay()
	for _, zone in ClanWarConfig.Zones do
		local territory = TerritoryStore.get(zone.id)
		if territory.ownerClanId ~= "" then
			local newHp = math.max(
				ClanWarConfig.FortHpMinimum,
				territory.fortHp - ClanWarConfig.FortHpDecayPerWeek
			)
			territory.fortHp = newHp
			territory.weeksClaimed += 1
			TerritoryStore.save(zone.id, territory)
			print(string.format("[DefensiveFatigue] %s: fortHp → %d (week %d)", zone.id, newHp, territory.weeksClaimed))
		end
	end
end

function DefensiveFatigueService.init()
	local function scheduleNext()
		task.delay(WEEK_SECONDS, function()
			DefensiveFatigueService.runDecay()
			scheduleNext()
		end)
	end
	scheduleNext()
end

return DefensiveFatigueService
