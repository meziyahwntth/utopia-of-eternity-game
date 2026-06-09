--!strict
--[[
	Server gate for Prism Live Mirror — requires key count >= 25.
	MVP stub: key count from attribute until PrismKeyService DataStore exists.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PrismFaceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismFaceConfig"))

local function getPlayerKeyCount(player: Player): number
	local attr = player:GetAttribute("PrismKeyCount")
	if typeof(attr) == "number" then
		return attr
	end
	return 0
end

local function onLiveMirrorTouched(part: BasePart, player: Player)
	if part:GetAttribute("FaceMode") ~= "PrismLiveMirror" then
		return
	end
	local required = part:GetAttribute("RequiresKey")
	if typeof(required) ~= "number" then
		required = PrismFaceConfig.UnlockLiveMirrorKeyCount
	end
	local keys = getPlayerKeyCount(player)
	local ageDays = player.AccountAge
	if not PrismFaceConfig.canUseLiveMirror(keys, ageDays) then
		warn(
			"[PrismFace] Live Mirror denied for",
			player.Name,
			"keys=",
			keys,
			"need=",
			required
		)
		return
	end
	player:SetAttribute("PrismLiveMirrorUnlocked", true)
	print("[PrismFace] Live Mirror session allowed for", player.Name)
end

-- Wire kiosks when world builds (attributes set by CommerceDistrictBuilder)
task.defer(function()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name == "PrismLiveMirrorKiosk" then
			inst:SetAttribute("RequiresKey", GameConfig.PrismKeys.LIVE_MIRROR_UNLOCK_KEY)
		end
	end
end)

return {
	getPlayerKeyCount = getPlayerKeyCount,
	canUseLiveMirror = function(player: Player): boolean
		return PrismFaceConfig.canUseLiveMirror(getPlayerKeyCount(player), player.AccountAge)
	end,
}
