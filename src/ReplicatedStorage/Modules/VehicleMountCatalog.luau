--!strict
--[[
	Vehicles + mounts catalog — Eternity City premium shop & key rewards.
	Ref images: docs/visual-ref/eternity-city/
]]

export type TravelMode = "Land" | "Air" | "Water" | "Tri"
export type DoorType = "GullWing" | "OpenTop" | "None"
export type CatalogCategory = "Vehicle" | "Mount" | "Transit"

export type SummonZone = "Sanctuary" | "Outskirts" | "Water" | "SkyLane"

export type CatalogEntry = {
	id: string,
	displayName: string,
	category: CatalogCategory,
	travelMode: TravelMode,
	doorType: DoorType?,
	seatCount: number,
	refImage: string,
	summonZone: SummonZone,
	eternityShopOnly: boolean?,
	keyRewardEligible: boolean?,
	iconAssetId: string?,
}

local VehicleMountCatalog = {}

local ICONS: { [string]: string } = {
	["amphibious_flying_motorcycle"] = "rbxassetid://131937012876652",
	["flying_car_boat_hybrid"] = "rbxassetid://86794600437117",
	["big_bike"] = "rbxassetid://127337459723099",
	["sports_car"] = "rbxassetid://93208287150310",
	["sedan"] = "rbxassetid://119728073566090",
	["pickup_truck"] = "rbxassetid://109323264607459",
	["van"] = "rbxassetid://78283126115161",
	["public_transport_bus"] = "rbxassetid://123349143644096",
	["jeep"] = "rbxassetid://74486478556685",
	["public_transport_airplane"] = "rbxassetid://127420478291204",
	["private_jet"] = "rbxassetid://105086144486137",
	["speedboat"] = "rbxassetid://139949962258926",
	["public_transport_boat"] = "rbxassetid://123420885777156",
	["prism_hover_shuttle"] = "rbxassetid://123349143644096",
	["pegasus"] = "rbxassetid://123314756359923",
	["hippogriff"] = "rbxassetid://91394478666144",
	["white_stag"] = "rbxassetid://73879090995676",
	["griffin"] = "rbxassetid://117205257612614",
	["dragon"] = "rbxassetid://121476509159294",
	["dragon_female"] = "rbxassetid://93941416576869",
	["unicorn"] = "rbxassetid://86136120729971",
	["flamingo"] = "rbxassetid://104344791260914",
	["legendary_swan"] = "rbxassetid://97666811262566",
	["dog"] = "rbxassetid://78755674352797",
	["cat"] = "rbxassetid://129621262197960",
	["rabbit"] = "rbxassetid://78477229008513",
	["tiger"] = "rbxassetid://118256628837583",
	["lion"] = "rbxassetid://76928135120535",
	["swan"] = "rbxassetid://116190761548823",
}

local function entry(
	id: string,
	displayName: string,
	category: CatalogCategory,
	travelMode: TravelMode,
	doorType: DoorType?,
	seatCount: number,
	refImage: string,
	summonZone: SummonZone,
	opts: { eternityShopOnly: boolean?, keyRewardEligible: boolean? }?
): CatalogEntry
	return {
		id = id,
		displayName = displayName,
		category = category,
		travelMode = travelMode,
		doorType = doorType,
		seatCount = seatCount,
		refImage = refImage,
		summonZone = summonZone,
		iconAssetId = ICONS[id],
		eternityShopOnly = if opts then opts.eternityShopOnly else nil,
		keyRewardEligible = if opts then opts.keyRewardEligible else nil,
	}
end

VehicleMountCatalog.Entries = {
	-- Tri vehicles
	entry("amphibious_flying_motorcycle", "Amphibious Flying Motorcycle", "Vehicle", "Tri", "GullWing", 2, "vehicles/tri/amphibious_flying_motorcycle.png", "SkyLane", { eternityShopOnly = true }),
	entry("flying_car_boat_hybrid", "Flying Car-Boat Hybrid", "Vehicle", "Tri", "OpenTop", 4, "vehicles/tri/flying_car_boat_hybrid.png", "SkyLane", { eternityShopOnly = true }),
	-- Land vehicles
	entry("big_bike", "Big Bike", "Vehicle", "Land", "GullWing", 4, "vehicles/land/big_bike.png", "Outskirts", { keyRewardEligible = true, eternityShopOnly = true }),
	entry("sports_car", "Sports Car", "Vehicle", "Land", "OpenTop", 4, "vehicles/land/sports_car.png", "Outskirts", { keyRewardEligible = true, eternityShopOnly = true }),
	entry("sedan", "Sedan", "Vehicle", "Land", "GullWing", 8, "vehicles/land/sedan.png", "Outskirts", { keyRewardEligible = true, eternityShopOnly = true }),
	entry("pickup_truck", "Pickup Truck", "Vehicle", "Land", "OpenTop", 14, "vehicles/land/pickup_truck_1.png", "Outskirts", { keyRewardEligible = true, eternityShopOnly = true }),
	entry("van", "Van", "Vehicle", "Land", "GullWing", 8, "vehicles/land/van.png", "Outskirts", { eternityShopOnly = true }),
	entry("public_transport_bus", "Public Transport Bus", "Transit", "Land", "GullWing", 20, "vehicles/land/public_transport_bus.png", "Sanctuary"),
	entry("jeep", "Jeep", "Vehicle", "Land", "OpenTop", 8, "vehicles/land/jeep.png", "Outskirts", { eternityShopOnly = true }),
	-- Air
	entry("public_transport_airplane", "Public Transport Airplane", "Transit", "Air", "GullWing", 40, "vehicles/air/public_transport_airplane.png", "SkyLane"),
	entry("private_jet", "Private Jet", "Vehicle", "Air", "GullWing", 8, "vehicles/air/private_jet.png", "SkyLane", { eternityShopOnly = true }),
	-- Water
	entry("speedboat", "Speedboat", "Vehicle", "Water", "OpenTop", 4, "vehicles/water/speedboat.png", "Water", { eternityShopOnly = true }),
	entry("public_transport_boat", "Public Transport Boat", "Transit", "Water", "GullWing", 12, "vehicles/water/public_transport_boat.png", "Water"),
	-- Transit system
	entry("prism_hover_shuttle", "Prism Hover Shuttle", "Transit", "Air", "GullWing", 20, "vehicles/land/public_transport_bus.png", "Sanctuary"),
	-- Tri mounts
	entry("pegasus", "Pegasus", "Mount", "Tri", "None", 2, "mounts/tri/pegasus.png", "Sanctuary", { eternityShopOnly = true }),
	entry("hippogriff", "Hippogriff", "Mount", "Tri", "None", 2, "mounts/tri/hippogriff.png", "Sanctuary", { eternityShopOnly = true }),
	entry("white_stag", "White Stag", "Mount", "Tri", "None", 2, "mounts/tri/white_stag.png", "Sanctuary", { eternityShopOnly = true }),
	entry("griffin", "Griffin", "Mount", "Tri", "None", 3, "mounts/tri/griffin.png", "Sanctuary", { eternityShopOnly = true }),
	entry("dragon", "Dragon", "Mount", "Tri", "None", 8, "mounts/tri/dragon_male.png", "Sanctuary", { eternityShopOnly = true }),
	entry("dragon_female", "Dragon (Female)", "Mount", "Tri", "None", 8, "mounts/tri/dragon_female.png", "Sanctuary", { eternityShopOnly = true }),
	entry("unicorn", "Unicorn", "Mount", "Tri", "None", 3, "mounts/tri/unicorn.png", "Sanctuary", { eternityShopOnly = true }),
	entry("flamingo", "Flamingo", "Mount", "Tri", "None", 2, "mounts/tri/flamingo.png", "Sanctuary", { eternityShopOnly = true }),
	entry("legendary_swan", "Legendary Swan", "Mount", "Tri", "None", 4, "mounts/tri/legendary_swan.png", "Sanctuary", { eternityShopOnly = true }),
	-- Land mounts
	entry("dog", "Dog", "Mount", "Land", "None", 2, "mounts/land/dog.png", "Sanctuary", { keyRewardEligible = true }),
	entry("cat", "Cat", "Mount", "Land", "None", 2, "mounts/land/cat.png", "Sanctuary", { keyRewardEligible = true }),
	entry("rabbit", "Rabbit", "Mount", "Land", "None", 2, "mounts/land/rabbit.png", "Sanctuary", { keyRewardEligible = true }),
	entry("tiger", "Tiger", "Mount", "Land", "None", 3, "mounts/land/tiger.png", "Sanctuary", { eternityShopOnly = true }),
	entry("lion", "Lion", "Mount", "Land", "None", 3, "mounts/land/lion.png", "Sanctuary", { eternityShopOnly = true }),
	-- Water mount
	entry("swan", "Swan", "Mount", "Water", "None", 4, "mounts/water/swan.png", "Water", { eternityShopOnly = true }),
}

function VehicleMountCatalog.getEntry(id: string): CatalogEntry?
	for _, e in VehicleMountCatalog.Entries do
		if e.id == id then
			return e
		end
	end
	return nil
end

function VehicleMountCatalog.getSeatCount(id: string): number
	local e = VehicleMountCatalog.getEntry(id)
	if e then
		return e.seatCount
	end
	return 0
end

function VehicleMountCatalog.getShopEntries(eternityOnly: boolean): { CatalogEntry }
	local list: { CatalogEntry } = {}
	for _, e in VehicleMountCatalog.Entries do
		if eternityOnly and e.eternityShopOnly ~= true then
			continue
		end
		if e.category == "Transit" then
			continue
		end
		table.insert(list, e)
	end
	return list
end

function VehicleMountCatalog.getKeyRewardVehicles(): { CatalogEntry }
	local ids = { "big_bike", "sports_car", "sedan", "pickup_truck" }
	local list: { CatalogEntry } = {}
	for _, id in ids do
		local e = VehicleMountCatalog.getEntry(id)
		if e then
			table.insert(list, e)
		end
	end
	return list
end

function VehicleMountCatalog.getKeyRewardPets(): { CatalogEntry }
	local ids = { "dog", "cat", "rabbit" }
	local list: { CatalogEntry } = {}
	for _, id in ids do
		local e = VehicleMountCatalog.getEntry(id)
		if e then
			table.insert(list, e)
		end
	end
	return list
end

function VehicleMountCatalog.buildMountSeatsMap(): { [string]: number }
	local map: { [string]: number } = {}
	for _, e in VehicleMountCatalog.Entries do
		map[e.id] = e.seatCount
	end
	map.Sedan4Door = VehicleMountCatalog.getSeatCount("sedan")
	map.PickupTruck = VehicleMountCatalog.getSeatCount("pickup_truck")
	map.Motorcycle = VehicleMountCatalog.getSeatCount("big_bike")
	map.Rabbit = VehicleMountCatalog.getSeatCount("rabbit")
	map.Tiger = VehicleMountCatalog.getSeatCount("tiger")
	map.Lion = VehicleMountCatalog.getSeatCount("lion")
	map.Swan = VehicleMountCatalog.getSeatCount("swan")
	map.Dragon = VehicleMountCatalog.getSeatCount("dragon")
	map.Unicorn = VehicleMountCatalog.getSeatCount("unicorn")
	map.PrismHoverShuttle = VehicleMountCatalog.getSeatCount("prism_hover_shuttle")
	map.BoatSmall = VehicleMountCatalog.getSeatCount("speedboat")
	return map
end

return VehicleMountCatalog
