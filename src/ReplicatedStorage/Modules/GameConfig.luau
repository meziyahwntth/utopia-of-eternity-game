--!strict
--[[
	Utopia of Eternity — shared constants.
	IP-safe original universe · 5 MVP places.
]]

local GameConfig = {}

GameConfig.GAME_NAME = "Utopia of Eternity"
GameConfig.VERSION = "0.3.0-design"
GameConfig.WEB_DOMAIN = "utopiaofeternity.com"
GameConfig.WEB_URL = "https://utopiaofeternity.com"

-- Places (MVP soft launch)
GameConfig.Places = {
	Hub = { id = 0, name = "Utopia Plaza Hub", dayMode = "permanent_day", subtitle = "Central Plaza" },
	Solhaven = { id = 0, name = "Solhaven", dayMode = "permanent_day" },
	Nocturne = { id = 0, name = "Nocturne Alley", dayMode = "permanent_twilight" },
	EternityCity = {
		id = 0,
		name = "Utopia of Eternity",
		subtitle = "The Eternal City",
		dayMode = "permanent_day",
	},
	DeathValley = {
		id = 0,
		name = "หุบเขามรณะ",
		subtitle = "Death Valley",
		dayMode = "eternal_night",
		planet = "Hellbound",
	},
}

-- Roblox universe ID (filled from PlaceSecrets.UniverseId via BridgeBootstrap)
GameConfig.UniverseId = 0

-- Official Roblox Community (filled from PlaceSecrets.CreatorGroupId via BridgeBootstrap)
GameConfig.Community = {
	groupId = 0,
	url = "",
	experienceUrl = "",
}

-- Economy caps (server-authoritative)
GameConfig.MAX_UTOPIA = 9_999_999_999
GameConfig.MAX_KEYS_DISPLAYED = "??"

-- Bridge (set URLs in production via secret — never commit keys)
GameConfig.Bridge = {
	LOG_ANALYZER_URL = "",
	FAN_SCAN_URL = "", -- e.g. https://api.utopiaofeternity.com/utopia/fan-scan
	FAN_SCAN_REPORT_URL = "", -- derived from FAN_SCAN_URL + /report if unset
	FACE_CAPTURE_URL = "", -- e.g. http://127.0.0.1:8787/utopia/face-capture
	CREATOR_PAYOUT_PUSH_URL = "",
	CREATOR_PAYOUT_SYNC_URL = "", -- Phase T — poll exportedAt / paid status
	BRIDGE_KEY = "", -- X-Utopia-Bridge-Key header (from BridgeSecrets.luau)
	FAN_SCAN_POLL_SECONDS = 600,
	CREATOR_PAYOUT_SYNC_POLL_SECONDS = 300,
}

-- Security thresholds
GameConfig.Security = {
	SUSPICION_KICK = 100,
	SUSPICION_WARN = 50,
	EVASION_BLOCK = 60,
	EVASION_FLAG = 40,
	STRIKE2_BAN_SECONDS = 604800, -- 7 days
	MOVEMENT_CHECK_INTERVAL = 0.5,
	MAX_WALK_SPEED_MULTIPLIER = 1.5,
	TELEPORT_STUD_THRESHOLD = 50,
	SAVE_COOLDOWN = 3,

	-- Category I — Griefing
	GRIEFING_WINDOW_SECONDS = 600,
	GRIEFING_INSTANT_BAN = 100,
	GRIEFING_TEMP_BAN = 75,
	SANCTUARY_STRIKE_THRESHOLD = 3,
	PVP_GRIEF_WINDOW_SECONDS = 120,
	PVP_SAME_VICTIM_KILL_LIMIT = 5,
	DEATH_VALLEY_SABOTAGE_BAN_THRESHOLD = 4,

	-- Economy inflation / duping
	ECONOMY_MAX_SINGLE_DELTA = 500_000,
	ECONOMY_VELOCITY_WINDOW_SECONDS = 60,
	ECONOMY_MAX_IN_PER_WINDOW = 2_000_000,
	ECONOMY_MAX_TX_PER_WINDOW = 30,
	ECONOMY_DUMP_WINDOW_SECONDS = 3600,
	ECONOMY_DUMP_UNIQUE_SELLERS = 8,
	ECONOMY_DUMP_VOLUME_THRESHOLD = 50_000,
	ECONOMY_CIRCUIT_BREAK_SECONDS = 1800,
	ECONOMY_FLOW_LOG_MAX = 500,

	-- Emulator / multi-account (device block — Roblox has no raw IP in Luau)
	EMULATOR_PUNISH_THRESHOLD = 60,
	EMULATOR_CLUSTER_ACCOUNT_LIMIT = 4,
	EMULATOR_CLUSTER_WINDOW_SECONDS = 300,
	EMULATOR_MAX_ACCOUNT_AGE_DAYS = 3,
	DEVICE_BAN_FIRST_SECONDS = 604800, -- 7 days

	-- Severe offenses → instant permanent ban
	SEVERE_REASONS = {
		HONEYPOT = true,
		BACKDOOR = true,
		EXECUTOR = true,
		SERVER_FLOOD = true,
	},

	-- Log export for offline AI review
	LOG_EXPORT_QUEUE_MAX = 200,
	LOG_EXPORT_BATCH_SIZE = 50,
	LOG_EXPORT_INTERVAL_SECONDS = 120,

	-- Fan experience scan (Bridge cron supplies candidates)
	FAN_REVIEW_CCU_THRESHOLD = 500,
	FAN_REVIEW_VISITS_THRESHOLD = 1_000_000,
	FAN_VIOLATION_SCORE = 80,
	FAN_PARTNER_ELIGIBLE_SCORE = 40,
}

-- Eternity Forge — licensed fan game program
GameConfig.FanLicense = {
	ProgramName = "Eternity Forge",
	DefaultRevenueSharePercent = 15,
	IpKeywords = {
		"utopia of eternity",
		"utopia plaza",
		"luminling",
		"prism key",
		"หุบเขามรณะ",
		"death valley",
		"solhaven",
		"nocturne alley",
	},
	Tiers = {
		Apprentice = {
			label = "Forge Apprentice",
			minCcu = 0,
			maxCcu = 1000,
			revenueSharePercent = 10,
			catalog = "basic_asset_kit",
		},
		Artisan = {
			label = "Forge Artisan",
			minCcu = 1000,
			maxCcu = 10000,
			minLikeRatio = 0.8,
			revenueSharePercent = 20,
			catalog = "radiant_skins_glow_weapons",
		},
		Master = {
			label = "Forge Master",
			minCcu = 10000,
			revenueSharePercent = 25,
			catalog = "master_bundle_aura_pass",
		},
	},
	PremiumCatalog = {
		RadiantSkin = { minRobux = 499, maxRobux = 999, cosmeticOnly = true },
		PrismWeaponFx = { minRobux = 799, maxRobux = 1499, cosmeticOnly = true },
		EternityAuraPass = { minRobux = 1999, maxRobux = 4999, cosmeticOnly = true },
		MasterBundle = { minRobux = 2999, maxRobux = 9999, cosmeticOnly = true, limited = true },
	},
	PolicyRedFlags = {
		"official_p2w_claim",
		"asset_rip",
		"external_robux_trade",
		"adult_content",
		"impersonate_official",
	},
}

-- Prism Keys — numbered 1–99 · ดอก 1–5 fixed · 6+ random tiers · ghost trade 3→1
GameConfig.PrismKeys = {
	FIRST_STATIC_KEY_INDEX = 1,
	FIXED_KEY_COUNT = 5,
	RANDOM_FROM_EARN_ORDER = 6,
	RANDOM_TIER_MILESTONES = { 25, 40, 60, 80 },
	MAX_KEY_NUMBER = 99,
	ROTATE_FROM_KEY_INDEX = 2,
	ROTATE_EVERY_PATCH = true,
	DISPLAY_COUNT = "??",
	LIVE_MIRROR_UNLOCK_KEY = 25,
	TRADE_COST = 3,
	GHOST_ZONE_INDICES = { 3, 4, 5 },
	GHOST_DWELL_SECONDS = 600,
	GHOST_TRADE_TIMEOUT_SECONDS = 60,
}

-- Face creation — Template Forge (default) + Prism Live Mirror (key 25)
-- Full spec: docs/FACE-CREATION-SYSTEM.md · PrismFaceConfig.luau
GameConfig.FaceCreation = {
	DefaultMode = "TemplateForge",
	LiveMirrorUnlockKeys = 25,
	NoGalleryUpload = true,
	CaptureAppOnly = true,
}

-- Rotating helper NPCs (good behavior reward — rare)
GameConfig.HelperNPC = {
	MAX_ACTIVE_PER_CITY = 1,
	MIN_PATCHES_BETWEEN_VISITS = 2,
	REPUTATION_THRESHOLD = 80,
}

-- Seasonal events (future per-country servers)
GameConfig.Seasons = {
	"Halloween",
	"Christmas",
	"NewYear",
	"ChineseNewYear",
	"Songkran",
	"LoyKrathong",
	"SummerFestival",
}

-- Seasonal pop-up shop theming (Phase S)
GameConfig.SeasonThemes = {
	Halloween = {
		accent = Color3.fromRGB(255, 120, 40),
		signColor = Color3.fromRGB(180, 80, 20),
		badge = "Halloween",
	},
	Christmas = {
		accent = Color3.fromRGB(80, 200, 120),
		signColor = Color3.fromRGB(200, 40, 50),
		badge = "Christmas",
	},
	NewYear = {
		accent = Color3.fromRGB(255, 215, 80),
		signColor = Color3.fromRGB(180, 160, 60),
		badge = "New Year",
	},
	ChineseNewYear = {
		accent = Color3.fromRGB(220, 50, 50),
		signColor = Color3.fromRGB(180, 30, 30),
		badge = "Chinese New Year",
	},
	Songkran = {
		accent = Color3.fromRGB(0, 180, 255),
		signColor = Color3.fromRGB(40, 140, 220),
		badge = "Songkran",
	},
	LoyKrathong = {
		accent = Color3.fromRGB(255, 180, 60),
		signColor = Color3.fromRGB(200, 120, 40),
		badge = "Loy Krathong",
	},
	SummerFestival = {
		accent = Color3.fromRGB(0, 220, 255),
		signColor = Color3.fromRGB(255, 80, 180),
		badge = "Summer Fest",
	},
}

-- Eternity City commerce — cosmetic only, peace zones (see PrismCommerceConfig.luau)
GameConfig.CommercePeaceZone = {
	NoPvP = true,
	NoCombatTools = true,
	NoVehicleRam = true,
	EmoteBonus = true,
	GriefingGuard = "strict",
}

-- Mount seat capacity (Sanctuary summon / Outskirts rules apply separately)
-- Source of truth: VehicleMountCatalog.buildMountSeatsMap() — legacy aliases kept for older scripts
GameConfig.MountSeats = {
	Sedan4Door = 8,
	PickupTruck = 14,
	Motorcycle = 4,
	Rabbit = 2,
	Tiger = 3,
	Lion = 3,
	Swan = 4,
	Dragon = 8,
	Unicorn = 3,
	PrismHoverShuttle = 20, -- public transit only — not personal mount
	BoatSmall = 4,
	big_bike = 4,
	sports_car = 4,
	sedan = 8,
	pickup_truck = 14,
	dog = 2,
	cat = 2,
	rabbit = 2,
	legendary_swan = 4,
	pegasus = 2,
	amphibious_flying_motorcycle = 2,
	flying_car_boat_hybrid = 4,
	public_transport_airplane = 40,
	private_jet = 8,
	speedboat = 4,
}

-- Eternity City access tiers — mirrors PrismKeyProgression.EternityCityAccess
GameConfig.EternityCityAccess = {
	PreviewTourMaxKeys = 9,
	FreeRoamMinKeys = 10,
	ZoneGateKeys = {
		[11] = "CanalPromenade",
		[15] = "SkyRailPlaza",
		[20] = "FullCity",
	},
	KeysForbiddenInCity = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
	GateKeysInCity = { 11, 15, 20 },
}

-- Prism Hover Shuttle — inter-city public transit (Sanctuary stops)
GameConfig.PublicTransit = {
	VehicleName = "Prism Hover Shuttle",
	SeatCount = 20,
	DepartureIntervalSeconds = 900, -- 15 minutes
	BoardingOpenSeconds = 120,
	WaitForFullSeats = false,
	Route = { "Hub", "Solhaven", "Nocturne", "EternityCity", "DeathValley" },
	StopDwellSeconds = 30,
	DevFastIntervalSeconds = 0, -- set to 60 in Studio dev if needed
}

-- Hover flight — instant direction change, no runway takeoff/landing
GameConfig.HoverFlight = {
	InstantTurn = true,
	CruiseSpeedStudsPerSecond = 80,
	LowAltitudeStuds = 40,
	CloudLayerStuds = 400,
	HeavenLayerStuds = 800,
	LowCruiseSeconds = 25,
	AscendSeconds = 20,
	HeavenSeconds = 15,
	ArrivalHeavenSeconds = 10,
	DescendSeconds = 25,
	LowApproachSeconds = 15,
	PlayerHideBelowStuds = 350,
}

-- Sanctuary Plaza — expanded social hubs (studs approximate)
GameConfig.Sanctuary = {
	DefaultRadiusStuds = 120,
	EternityCityRadiusStuds = 280,
	MinSpawnPointsPerCity = 3,
	EternityCityMinSpawnPoints = 8,
	Names = {
		Hub = "Prism Heart Plaza",
		Solhaven = "Sunhaven Sanctuary",
		Nocturne = "Twilight Meet Point",
		EternityCity = "Eternity Sanctuary",
		DeathValley = "จุดไฟชีวิต",
	},
}

-- หุบเขามรณะ co-op (lessons from 99 Nights player feedback)
-- Planet Hellbound — docs/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md
GameConfig.Hellbound = {
	PlanetName = "Hellbound",
	PlanetSubtitle = "มุ่งหน้าสู่ขุมนรก",
	DeparturePlaceKey = "EternityCity",
	TerminalZoneId = "HellboundInterstellarTerminal",
	HyperdriveEngineName = "Hyperdrive",
	SpectatorEventName = "HellboundJumpSpectator",
}

GameConfig.SocialDungeons = {
	TeamSizes = { 2, 5, 10, 20, 50 },
	EntryRatio = 0.50,
	SuccessRatio = 0.75,
	Docs = "docs/systems/SOCIAL-DUNGEON-SYSTEM.md",
}

GameConfig.DeathValley = {
	Planet = "Hellbound",
	PartySize = 4,
	FriendsOnlyDefault = true,
	DifficultyScalesWithParty = true,
	DifficultyDownscaleOnLeave = true,
	SharedBeaconFuel = true,
	SanctuaryRadiusStuds = 120,
	ExitPortalPlaceKey = "Hub",
	SurvivalDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-A-SURVIVAL.md",
	ExpansionDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-B-EXPANSION.md",
	PersistenceDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-C-PERSISTENCE.md",
	LiveOpsDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-D-LIVEOPS.md",
	CrossWorldDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-E-CROSSWORLD.md",
	MatchmakingDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-F-GLOBAL-MATCHMAKING.md",
	SocialRewardsDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-G-SOCIAL-REWARDS.md",
	RolloverSocialDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-H-ROLLOVER-SOCIAL.md",
	PresentationAdminDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-I-PRESENTATION-ADMIN.md",
	CosmeticPersistenceDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-J-COSMETIC-PERSISTENCE.md",
	LoadoutHubDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-K-LOADOUT-HUB.md",
	UnifiedMirrorDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-L-UNIFIED-MIRROR.md",
	PresetSharePlazaDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-M-PRESET-SHARE-PLAZA.md",
	CrossServerSocialDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-N-CROSS-SERVER-SOCIAL.md",
	FriendJoinBazaarDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-O-FRIEND-JOIN-BAZAAR.md",
	PresetPackFeaturedDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-P-PACKS-FEATURED-PUSH.md",
	CommerceCreatorRotationDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-Q-COMMERCE-CREATOR-ROTATION.md",
	GroupPayoutUgcSeasonalDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-R-PAYOUT-UGC-SEASONAL.md",
	GroupPayoutAutomationDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-S-PAYOUT-UGC-POLISH.md",
	GroupPayoutSyncDocs = "docs/death-valley/phases/DEATH-VALLEY-PHASE-T-PAYOUT-SYNC.md",
	FeaturedListingIds = {} :: { string },
	CreatorPayout = {
		minCredits = 100,
		groupId = 0,
	},
	UgcCreatorPack = {
		minRobux = 49,
		maxRobux = 499,
		priceTiers = { 49, 99, 149, 199, 249, 299, 399, 499 },
		maxLinkedPerPlayer = 3,
	},
	SeasonalFeaturedRotation = {
		packIdsBySeasonName = {
			Halloween = { "dv_pack_survivor_starter", "dv_pack_commerce_luxury" },
			Christmas = { "dv_pack_hellbound_elite", "dv_pack_commerce_creator_spotlight" },
			Songkran = { "dv_pack_commerce_luxury", "dv_pack_survivor_starter" },
			LoyKrathong = { "dv_pack_commerce_creator_spotlight", "dv_pack_veteran_trail" },
		},
		listingTags = { "community", "seasonal" },
	},
	MegaDungeon = {
		Id = "dv_mega_abyss",
		Zones = { 2, 5, 10, 20, 50 },
		RewardBonusPerZone = 0.10,
		KeyPerZonePerPlayer = 1,
		Docs = "docs/death-valley/DEATH-VALLEY-MEGA-DUNGEON.md",
	},
}

-- New player guide (toggle)
GameConfig.Onboarding = {
	GuideEnabledDefault = true,
	AllowToggle = true,
}

-- World build — Hybrid microcurve pipeline (see docs/WORLD-BUILD-MICROCURVE-SPEC.md)
GameConfig.WorldBuild = {
	MobileMaxParts = 10000,
	PCMaxParts = 18000,
	DefaultLodDistanceStuds = 512,
	MicroTrimDistanceStuds = 128,
	-- SpawnService: รอ WorldBuildState ready นานสุดกี่วินาทีก่อนปล่อย character ลง emergency floor
	ReadyTimeoutSeconds = 60,
}

-- Pearl & Gold contrast palette for Eternity City buildings (not terrain colormap)
-- Pearl must stay below near-white threshold (225,225,225) on every channel
GameConfig.CityPalette = {
	Pearl = Color3.fromRGB(218, 214, 205),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(120, 200, 220),
	CyanBright = Color3.fromRGB(0, 229, 255),
	Twilight = Color3.fromRGB(10, 22, 40),
	Amber = Color3.fromRGB(255, 179, 71),
	Steel = Color3.fromRGB(90, 105, 125),
	Slate = Color3.fromRGB(55, 68, 88),
	Midnight = Color3.fromRGB(25, 35, 50),
	Teal = Color3.fromRGB(45, 115, 135),
}

-- Eternity City lighting — tuned for Marble/Metal specular on Pearl & Gold landmarks
GameConfig.CityLighting = {
	ClockTime = 11,
	GeographicLatitude = 22,
	Brightness = 2.2,
	Ambient = Color3.fromRGB(132, 140, 158),
	OutdoorAmbient = Color3.fromRGB(168, 175, 192),
	EnvironmentDiffuseScale = 0.5,
	EnvironmentSpecularScale = 1.0,
	Atmosphere = {
		Density = 0.22,
		Offset = 0.1,
		Glare = 0.42,
		Haze = 0.85,
	},
	Bloom = {
		Intensity = 0.35,
		Size = 16,
		Threshold = 0.9,
	},
	PointLights = {
		{ name = "SanctuaryGlow", landmarkKey = "LoadoutPlaza", yOffset = 28, colorKey = "Cyan", range = 300, brightness = 2.4 },
		{ name = "AuroraSpireGlow", landmarkKey = "AuroraOrigin", yOffset = 70, colorKey = "Gold", range = 220, brightness = 2.2 },
		{ name = "MarinaGlow", landmarkKey = "MarinaCenter", yOffset = 18, colorKey = "Cyan", range = 180, brightness = 1.6 },
		{ name = "SkyRailGlow", landmarkKey = "SkyRailOrigin", yOffset = 32, colorKey = "Gold", range = 140, brightness = 1.2 },
		{ name = "FashionStageGlow", landmarkKey = "FashionStage", yOffset = 20, colorKey = "Gold", range = 72, brightness = 0.85 },
	},
	FashionStageLights = {
		SpotLight = { brightness = 1.5, range = 28, angle = 35 },
		TrussPoint = { brightness = 0.5, range = 10 },
	},
}

-- EternityCity heightmap import spec — values from scripts/gen-eternity-terrain.py v3 + meta JSON
GameConfig.TerrainProfile = {
	Version = "v3",
	MapSize = 2048,
	HeightmapResolution = 1024,
	RegionHeight = 256,
	ImportPositionY = 128,
	PlateauHeightMap = 70,
	SeaLevelHeightMap = 52,
	PlateauY = 72,
	SeaLevelY = 53,
	PlateauCenterPixel = Vector2.new(480, 543),
	BayCenterPixel = Vector2.new(940, 103),
	PlateauCenterStud = Vector3.new(-64, 72, 62),
	BayCenterStud = Vector3.new(856, 53, -818),
	MapEdgeInsetStuds = 32,
	-- Landmark XZ on plateau (Y snapped via EternityTerrainSetup.getGroundY)
	Landmarks = {
		AuroraOrigin = Vector3.new(-64, 72, 62),
		MarinaCenter = Vector3.new(200, 72, -40),
		CanalPathOffset = Vector3.new(-84, 72, 82),
		SkyRailOrigin = Vector3.new(-64, 72, 102),
		TwilightOrigin = Vector3.new(-164, 72, 142),
		FashionStage = Vector3.new(-194, 72, 177),
		LoadoutPlaza = Vector3.new(-64, 72, 82),
		MegaMallBase = Vector3.new(-94, 72, -88),
		UtopiaPlaza = Vector3.new(-134, 72, -68),
		EternityTower = Vector3.new(60, 72, 140),
	},
}

-- Hero mesh landmarks — MeshId fallback when ServerStorage.HeroMeshes.<key> absent
GameConfig.HeroMeshes = {
	UtopiaPlaza = {
		MeshId = "rbxassetid://103489658289034",
		Scale = 15,
		YOffset = 0,
		Rotation = Vector3.zero,
	},
	EternityTower = {
		MeshId = "rbxassetid://110883199256677",
		Scale = 60,
		YOffset = 0,
		Rotation = Vector3.zero,
	},
}

-- Fashion Show — Dress-to-Impress style contest (Eternity City festival zone)
GameConfig.FashionShow = {
	RoundIntervalSeconds = 1800, -- production: 30 min per full cycle
	MinPlayersProduction = 3,
	MinPlayersTestMode = 1,
	StateDurationsProduction = {
		Idle = 30,
		Registration = 240,
		Dressing = 360,
		Runway = 240,
		Voting = 600,
		Results = 360,
	},
	StateDurationsTestMode = {
		Idle = 5,
		Registration = 15,
		Dressing = 15,
		Runway = 12,
		Voting = 18,
		Results = 10,
	},
	WinnerLuminite = 15,
	ParticipantLuminite = 3,
	WinnerTitle = "Fashion Star",
}

-- Studio: when PlaceId == 0, simulate this place for world build (set nil for Hub)
GameConfig.StudioDev = {
	SimulatePlaceKey = "EternityCity" :: string?,
	-- Studio-only: seed creator credits for payout UI smoke test (never runs on live servers)
	SeedCreatorTestCredits = true,
}

-- Sanctuary / mount zones
GameConfig.Zones = {
	SANCTUARY = "SANCTUARY",
	CITY = "CITY",
	OUTSKIRTS = "OUTSKIRTS",
	SKY_LANE = "SKY_LANE", -- hover corridor (no runway)
	PVP_ARENA = "PVP_ARENA",
}

return GameConfig
