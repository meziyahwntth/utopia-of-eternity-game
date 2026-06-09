--!strict
--[[
	Greybox commerce districts for Eternity City — shops + peace zones.
	Design: docs/FASHION-AND-SHOPS-DESIGN.md · PrismCommerceConfig.luau
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local PrismCommerceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCommerceConfig"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local CommerceDistrictBuilder = {}

local function tagPeaceZone(part: BasePart, shopId: string, radiusStuds: number)
	part:SetAttribute("CommercePeaceZone", true)
	part:SetAttribute("ShopId", shopId)
	part:SetAttribute("PeaceRadiusStuds", radiusStuds)
	part:SetAttribute("NoPvP", GameConfig.CommercePeaceZone.NoPvP)
	part:SetAttribute("NoCombatTools", GameConfig.CommercePeaceZone.NoCombatTools)
end

local function makeShopKiosk(
	parent: Instance,
	shop: PrismCommerceConfig.ShopEntry,
	position: Vector3,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	floorY: number?
)
	local y = floorY or 2
	local base = Instance.new("Part")
	base.Name = "Shop_" .. shop.id
	base.Size = Vector3.new(18, 4, 14)
	base.CFrame = CFrame.new(position.X, y, position.Z)
	base.Anchored = true
	base.Color = profile.Palette.Pearl
	base.Material = Enum.Material.SmoothPlastic
	base.Parent = parent
	WorldBuildBudget:add(budget, 1)

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(16, 3, 0.4)
	sign.CFrame = base.CFrame * CFrame.new(0, 5, -7.2)
	sign.Anchored = true
	sign.Color = profile.Palette.Gold
	sign.Material = Enum.Material.Neon
	sign.Parent = base
	WorldBuildBudget:add(budget, 1)

	local peaceDisc = Instance.new("Part")
	peaceDisc.Name = "PeaceZone"
	peaceDisc.Size = Vector3.new(shop.peaceZoneRadiusStuds * 2, 0.3, shop.peaceZoneRadiusStuds * 2)
	peaceDisc.CFrame = CFrame.new(position.X, 0.4, position.Z)
	peaceDisc.Anchored = true
	peaceDisc.CanCollide = false
	peaceDisc.Transparency = 0.92
	peaceDisc.Color = profile.Palette.Cyan
	peaceDisc.Material = Enum.Material.Neon
	peaceDisc.Parent = parent
	tagPeaceZone(peaceDisc, shop.id, shop.peaceZoneRadiusStuds)
	WorldBuildBudget:add(budget, 1)

	local npcPad = Instance.new("Part")
	npcPad.Name = "NPCPad"
	npcPad.Size = Vector3.new(6, 0.2, 6)
	npcPad.CFrame = base.CFrame * CFrame.new(0, 2.2, 4)
	npcPad.Anchored = true
	npcPad.CanCollide = false
	npcPad.Transparency = 0.5
	npcPad.Color = profile.Palette.Cyan
	npcPad.Material = Enum.Material.Neon
	npcPad.Parent = base
	WorldBuildBudget:add(budget, 1)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = shop.displayName
	prompt.MaxActivationDistance = 12
	prompt.Parent = base

	if shop.shopType == "SeasonalPopUp" then
		local month = tonumber(os.date("!%m")) or 1
		local seasons = GameConfig.Seasons
		local seasonName = seasons[((month - 1) % #seasons) + 1]
		base:SetAttribute("SeasonPopUpName", seasonName)
		prompt.ObjectText = shop.displayName .. " · " .. seasonName

		local themes = GameConfig.SeasonThemes
		local theme = if typeof(themes) == "table" then themes[seasonName] else nil
		if typeof(theme) == "table" then
			if typeof(theme.signColor) == "Color3" then
				sign.Color = theme.signColor
			end
			if typeof(theme.accent) == "Color3" then
				npcPad.Color = theme.accent
				peaceDisc.Color = theme.accent
			end
		end

		local banner = Instance.new("Part")
		banner.Name = "SeasonBanner"
		banner.Size = Vector3.new(16, 0.6, 0.6)
		banner.CFrame = sign.CFrame * CFrame.new(0, 2.2, 0)
		banner.Anchored = true
		banner.Material = Enum.Material.Neon
		banner.Color = if typeof(theme) == "table" and typeof(theme.accent) == "Color3"
			then theme.accent
			else profile.Palette.Cyan
		banner.Parent = base
		WorldBuildBudget:add(budget, 1)

		local particles = Instance.new("ParticleEmitter")
		particles.Name = "SeasonSparkle"
		particles.Rate = 4
		particles.Lifetime = NumberRange.new(1.2, 2)
		particles.Speed = NumberRange.new(0.5, 1.5)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.Size = NumberSequence.new(0.15)
		particles.LightEmission = 0.8
		particles.Color = ColorSequence.new(
			if typeof(theme) == "table" and typeof(theme.accent) == "Color3" then theme.accent else profile.Palette.Cyan
		)
		particles.Parent = banner
	end
end

local function buildAuroraMegaMall(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = Instance.new("Folder")
	district.Name = "AuroraMegaMall"
	district.Parent = parent

	local origin = Vector3.new(-60, 0, -80)
	OrganicCSGBuilder:createSpire(origin, 90, 14, {
		color = profile.Palette.Pearl,
		material = Enum.Material.SmoothPlastic,
		parent = district,
		name = "MegaMallTower",
	})
	WorldBuildBudget:add(budget, 2)

	for floor = 1, 5 do
		local band = Instance.new("Part")
		band.Name = "FloorBand_" .. floor
		band.Size = Vector3.new(32, 2, 32)
		band.CFrame = CFrame.new(origin + Vector3.new(0, floor * 16, 0))
		band.Anchored = true
		band.Color = profile.Palette.Pearl
		band.Material = Enum.Material.SmoothPlastic
		band.Parent = district
		OrganicCSGBuilder:createGlassBand(band.CFrame.Position, 34, 1.5, {
			parent = district,
			color = profile.Palette.Cyan,
		})
		WorldBuildBudget:add(budget, 2)
	end

	local mallShops = {
		"eternity_luxury_galleria",
		"prism_wardrobe",
		"world_culture_pavilion",
		"stellar_salon",
		"prism_beauty",
		"eternity_aesthetics",
	}
	local offsets = {
		Vector3.new(-40, 0, -80),
		Vector3.new(-25, 0, -95),
		Vector3.new(-60, 0, -110),
		Vector3.new(-95, 0, -95),
		Vector3.new(-25, 0, -65),
		Vector3.new(-95, 0, -65),
	}
	for i, shopId in mallShops do
		for _, shop in PrismCommerceConfig.Shops do
			if shop.id == shopId then
				makeShopKiosk(district, shop, offsets[i], profile, budget)
				break
			end
		end
	end

	-- Sky Lounge marker (floor 50 — visual flag)
	local skyLounge = Instance.new("Part")
	skyLounge.Name = "SkyLoungeFloor50"
	skyLounge.Size = Vector3.new(20, 1, 20)
	skyLounge.CFrame = CFrame.new(origin + Vector3.new(0, 85, 0))
	skyLounge.Anchored = true
	skyLounge.Color = profile.Palette.Gold
	skyLounge.Material = Enum.Material.Neon
	skyLounge:SetAttribute("RequiresKey", 20)
	skyLounge.Parent = district
	WorldBuildBudget:add(budget, 1)

	-- Live Mirror kiosk (key 25)
	local liveMirror = Instance.new("Part")
	liveMirror.Name = "PrismLiveMirrorKiosk"
	liveMirror.Size = Vector3.new(8, 10, 8)
	liveMirror.CFrame = CFrame.new(origin + Vector3.new(20, 5, -80))
	liveMirror.Anchored = true
	liveMirror.Color = profile.Palette.Cyan
	liveMirror.Material = Enum.Material.Glass
	liveMirror.Transparency = 0.3
	liveMirror:SetAttribute("RequiresKey", 25)
	liveMirror:SetAttribute("FaceMode", "PrismLiveMirror")
	liveMirror.Parent = district
	WorldBuildBudget:add(budget, 1)
end

local function buildMarinaShowroom(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = Instance.new("Folder")
	district.Name = "MarinaShowroomStrip"
	district.Parent = parent

	local pier = Instance.new("Part")
	pier.Name = "ShowroomPier"
	pier.Size = Vector3.new(120, 1, 30)
	pier.CFrame = CFrame.new(220, 1, -40)
	pier.Anchored = true
	pier.Color = profile.Palette.Pearl
	pier.Material = Enum.Material.SmoothPlastic
	pier.Parent = district
	WorldBuildBudget:add(budget, 1)

	MicroCurveBuilder:fillArc({
		Vector3.new(170, 1.5, -40),
		Vector3.new(200, 1.5, -55),
		Vector3.new(240, 1.5, -40),
		Vector3.new(270, 1.5, -25),
	}, 4, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Gold,
		material = Enum.Material.Neon,
		parent = district,
		collision = false,
		budget = budget,
	})

	local marinaIds = { "prism_motors", "prism_service_center", "neon_alley_tune" }
	local marinaPos = {
		Vector3.new(180, 0, -40),
		Vector3.new(220, 0, -40),
		Vector3.new(260, 0, -40),
	}
	for i, shopId in marinaIds do
		for _, shop in PrismCommerceConfig.Shops do
			if shop.id == shopId then
				makeShopKiosk(district, shop, marinaPos[i], profile, budget)
				break
			end
		end
	end
end

local function buildCanalCommerce(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = parent:FindFirstChild("CanalPromenade")
	if not district then
		district = Instance.new("Folder")
		district.Name = "CanalPromenade"
		district.Parent = parent
	end

	local canalShops = { "accessory_lane", "luminling_clinic", "preset_bazaar" }
	local canalPos = {
		Vector3.new(40, 0, 75),
		Vector3.new(100, 0, 85),
		Vector3.new(70, 0, 55),
	}
	for i, shopId in canalShops do
		for _, shop in PrismCommerceConfig.Shops do
			if shop.id == shopId then
				makeShopKiosk(district, shop, canalPos[i], profile, budget)
				break
			end
		end
	end
end

local function buildSkyRailCommerce(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = parent:FindFirstChild("SkyRailPlaza")
	if not district then
		return
	end

	local skyShops = { "mount_emporium", "stable_care", "weapon_gallery", "seasonal_pop_up", "sky_vet" }
	local skyPos = {
		Vector3.new(-50, 0, -50),
		Vector3.new(-20, 0, -55),
		Vector3.new(20, 0, -50),
		Vector3.new(50, 0, -45),
		Vector3.new(0, 0, -65),
	}
	for i, shopId in skyShops do
		for _, shop in PrismCommerceConfig.Shops do
			if shop.id == shopId then
				makeShopKiosk(district, shop, skyPos[i], profile, budget)
				break
			end
		end
	end
end

local function buildTwilightCommerce(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = parent:FindFirstChild("TwilightOverpass")
	if not district then
		return
	end

	local twilightShops = { "photo_boutique", "emote_stage_shop" }
	local twilightPos = {
		Vector3.new(-115, 0, 75),
		Vector3.new(-85,  0, 85),
	}
	for i, shopId in twilightShops do
		for _, shop in PrismCommerceConfig.Shops do
			if shop.id == shopId then
				makeShopKiosk(district, shop, twilightPos[i], profile, budget)
				break
			end
		end
	end
end

local function buildHellboundTerminal(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	local district = Instance.new("Folder")
	district.Name = "HellboundTerminal"
	district.Parent = parent

	local pad = Instance.new("Part")
	pad.Name = "AirfieldPad"
	pad.Size = Vector3.new(80, 1, 50)
	pad.CFrame = CFrame.new(240, 2, 80)
	pad.Anchored = true
	pad.Color = profile.Palette.Pearl
	pad.Material = Enum.Material.SmoothPlastic
	pad.Parent = district
	WorldBuildBudget:add(budget, 1)

	OrganicCSGBuilder:createDome(Vector3.new(240, 8, 80), 16, {
		color = profile.Palette.Pearl,
		parent = district,
		name = "TerminalDome",
	})

	for _, shop in PrismCommerceConfig.Shops do
		if shop.id == "hellbound_terminal" then
			makeShopKiosk(district, shop, Vector3.new(240, 0, 80), profile, budget)
			break
		end
	end

	local marker = Instance.new("Part")
	marker.Name = "HyperspaceSpectatorMarker"
	marker.Size = Vector3.new(4, 4, 4)
	marker.CFrame = CFrame.new(240, 40, 80)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker:SetAttribute("SpectatorEvent", "HellboundJumpSpectator")
	marker.Parent = district
	WorldBuildBudget:add(budget, 1)

	local departGate = Instance.new("Part")
	departGate.Name = "HellboundDepartureGate"
	departGate.Size = Vector3.new(20, 12, 8)
	departGate.CFrame = CFrame.new(240, 6, 95)
	departGate.Anchored = true
	departGate.Color = profile.Palette.Cyan
	departGate.Material = Enum.Material.Neon
	departGate.Parent = district
	departGate:SetAttribute("HellboundDepartureGate", true)
	departGate:SetAttribute("TransportMode", "PublicAirplane")
	departGate:SetAttribute("PlaceKey", "DeathValley")

	local departPrompt = Instance.new("ProximityPrompt")
	departPrompt.ActionText = "Board for Hellbound"
	departPrompt.ObjectText = "Hyperspace Departure"
	departPrompt.MaxActivationDistance = 16
	departPrompt.HoldDuration = 1.2
	departPrompt.Parent = departGate
	WorldBuildBudget:add(budget, 1)
end

function CommerceDistrictBuilder:BuildAll(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	buildAuroraMegaMall(parent, profile, budget)
	buildMarinaShowroom(parent, profile, budget)
	buildCanalCommerce(parent, profile, budget)
	buildSkyRailCommerce(parent, profile, budget)
	buildTwilightCommerce(parent, profile, budget)
	buildHellboundTerminal(parent, profile, budget)
	print("[Utopia] Commerce districts built — " .. #PrismCommerceConfig.Shops .. " shop entries")
end

return CommerceDistrictBuilder
