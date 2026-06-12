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
	NeonUtopia = require(script.Parent.NeonUtopiaWorldBuilder),
}

-- Expose ให้ BuildOrchestrator ใช้ routing table เดียวกัน (Blueprint §5 — additive)
WorldBootstrap.BUILDERS = BUILDERS

function WorldBootstrap:BuildAll()
	for _, builder in BUILDERS do
		builder:Build()
	end
end

-- Blueprint §5: wrapper เรียก BuildOrchestrator (จุดเดียวที่ห่อ pcall + set WorldBuildState)
-- lazy require กัน require cycle (orchestrator require WorldBootstrap เพื่อใช้ BUILDERS)
function WorldBootstrap:BuildCurrent()
	local orchestrator = require(script.Parent.BuildOrchestrator) :: any
	orchestrator:Run()
end

return WorldBootstrap
