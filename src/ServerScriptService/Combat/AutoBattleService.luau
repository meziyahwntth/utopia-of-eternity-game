--!strict
--[[
	AutoBattleService (P3-C+) — per-player auto-battle toggle state.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatConfig"))

export type AutoBattleState = {
	enabled: boolean,
	targetId: number?,
}

local AutoBattleService = {}

local playerAutoBattleState: { [number]: AutoBattleState } = {}

function AutoBattleService.getState(userId: number): AutoBattleState
	local s = playerAutoBattleState[userId]
	if s then
		return s
	end
	return { enabled = false, targetId = nil }
end

function AutoBattleService.setAutoMode(player: Player, enabled: any, targetId: any?): (boolean, string)
	if typeof(enabled) ~= "boolean" then
		return false, "ข้อมูลไม่ถูกต้อง"
	end
	local tid: number? = nil
	if typeof(targetId) == "number" then
		tid = targetId
	end
	playerAutoBattleState[player.UserId] = {
		enabled = enabled,
		targetId = tid,
	}
	if enabled then
		return true, "Auto-Battle เปิด"
	end
	return true, "Auto-Battle ปิด"
end

function AutoBattleService.defaultSkill(): string
	return CombatConfig.DefaultSkillId
end

return AutoBattleService
