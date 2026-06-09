--!strict
--[[
	Greybox spawn points for วิญญาณแลกกุญแจ — Mega Dungeon zones 3–5
]]

local DeathValleyKeyGhostBuilder = {}

export type GhostZoneAnchor = {
	zoneIndex: number,
	zoneId: string,
	cframe: CFrame,
}

function DeathValleyKeyGhostBuilder:Build(parent: Model): { GhostZoneAnchor }
	local folder = Instance.new("Folder")
	folder.Name = "PrismKeyGhostAnchors"
	folder.Parent = parent

	local anchors: { GhostZoneAnchor } = {
		{
			zoneIndex = 3,
			zoneId = "raid_cavern",
			cframe = CFrame.new(120, 6, -40),
		},
		{
			zoneIndex = 4,
			zoneId = "legion_pass",
			cframe = CFrame.new(200, 8, -80),
		},
		{
			zoneIndex = 5,
			zoneId = "abyss_throne",
			cframe = CFrame.new(280, 10, -120),
		},
	}

	for _, anchor in anchors do
		local pad = Instance.new("Part")
		pad.Name = "GhostAnchor_Z" .. tostring(anchor.zoneIndex)
		pad.Size = Vector3.new(14, 1, 14)
		pad.CFrame = anchor.cframe
		pad.Anchored = true
		pad.CanCollide = false
		pad.Transparency = 0.7
		pad.Color = Color3.fromRGB(120, 80, 180)
		pad.Material = Enum.Material.Neon
		pad.Parent = folder
		pad:SetAttribute("GhostZoneIndex", anchor.zoneIndex)
		pad:SetAttribute("GhostZoneId", anchor.zoneId)
	end

	return anchors
end

return DeathValleyKeyGhostBuilder
