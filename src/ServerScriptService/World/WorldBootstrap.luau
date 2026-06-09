--!strict
--[[
	Routes world build to the correct place builder.
]]
local WorldBootstrap = {}

local BUILDERS = {
	Hub = require(script.Parent.HubWorldBuilder),
	Solhaven = require(script.Parent.SolhavenWorldBuilder),
	Nocturne = require(script.Parent.NocturneWorldBuilder),
	EternityCity = require(script.Parent.EternityCityWorldBuilder),
	DeathValley = require(script.Parent.DeathValleyWorldBuilder),
}

function WorldBootstrap:BuildAll()
	for _, builder in BUILDERS do
		builder:Build()
	end
end

function WorldBootstrap:BuildCurrent()
	local guard = require(script.Parent.WorldPlaceGuard)
	local key = guard:GetCurrentPlaceKey()
	local builder = BUILDERS[key]
	if builder then
		builder:Build()
	end
end

return WorldBootstrap
