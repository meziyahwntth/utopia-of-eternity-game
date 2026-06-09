--!strict
--[[
	Copy to PlaceSecrets.luau (gitignored).
	Set each Roblox Place ID after creating universe places in Creator Dashboard.
	See docs/P0-PUBLISH-SETUP.md

	Find IDs: Creator Dashboard → Your experience → Places → copy Place ID from URL
	Example URL: https://create.roblox.com/dashboard/creations/experiences/UNIVERSE_ID/places/PLACE_ID/overview
]]
return {
	-- Optional — used by Bridge Open Cloud + payout export
	UniverseId = 0,
	CreatorGroupId = 0,

	Hub = 0,
	Solhaven = 0,
	Nocturne = 0,
	EternityCity = 0,
	DeathValley = 0,
}
