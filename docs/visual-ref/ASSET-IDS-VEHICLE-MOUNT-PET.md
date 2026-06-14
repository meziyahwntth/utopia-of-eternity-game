# Roblox Asset IDs — Vehicle / Mount / Pet (uploaded 15 มิ.ย. 2026)

> Group: **Utopia of Eternity** (groupId 791898614) · uploaded via Studio Asset Manager bulk import (place "Utopia Weapon Assets")
> Asset name in Roblox = `Images/<basename>`. All wired into catalogs (see below).

## Pets → `PetConfig.luau` field `icon` (emoji → rbxassetid)
| pet id | asset id |
|---|---|
| slime_blue | 138487953541573 |
| fox_fire | 94490112251523 |
| dragon_mini | 98499021931067 |
| crystal_rabbit | 103273831527460 |
| mushroom_sprite | 126189643034355 |
| star_chick | 81004155038651 |
| ghost_jellyfish | 113290820796207 |
| shadow_wolf_pup | 74162290323997 |
| neon_frog | 134943372981857 |
| thunder_hawk | 75483387691040 |
| prism_butterfly | 96679716545386 |
| angel_kitten | 127689295003888 |
| void_cat | 87992026158397 |
| ice_fox | 82556607209146 |
| golden_turtle | 92494964147160 |
| phoenix_chick | 103561676668329 |
| void_imp | 124102144066293 |
| prism_core_orb | 121609318249639 |

## Vehicles / Transit → `VehicleMountCatalog.luau` `ICONS[id]` (new field `iconAssetId`)
| entry id | asset id | note |
|---|---|---|
| amphibious_flying_motorcycle | 131937012876652 | |
| flying_car_boat_hybrid | 86794600437117 | |
| big_bike | 127337459723099 | |
| sports_car | 93208287150310 | |
| sedan | 119728073566090 | |
| pickup_truck | 109323264607459 | image basename pickup_truck_1 |
| van | 78283126115161 | |
| public_transport_bus | 123349143644096 | |
| jeep | 74486478556685 | |
| public_transport_airplane | 127420478291204 | |
| private_jet | 105086144486137 | |
| speedboat | 139949962258926 | |
| public_transport_boat | 123420885777156 | |
| prism_hover_shuttle | 123349143644096 | reuses public_transport_bus image |

## Mounts → `VehicleMountCatalog.luau` `ICONS[id]`
| entry id | asset id | image basename |
|---|---|---|
| pegasus | 123314756359923 | pegasus |
| hippogriff | 91394478666144 | hippogriff |
| white_stag | 73879090995676 | white_stag |
| griffin | 117205257612614 | griffin |
| dragon | 121476509159294 | dragon_male |
| dragon_female | 93941416576869 | dragon_female |
| unicorn | 86136120729971 | unicorn |
| flamingo | 104344791260914 | flamingo |
| legendary_swan | 97666811262566 | legendary_swan |
| dog | 78755674352797 | dog |
| cat | 129621262197960 | cat |
| rabbit | 78477229008513 | rabbit |
| tiger | 118256628837583 | tiger |
| lion | 76928135120535 | lion |
| swan | 116190761548823 | swan |

**Note:** refImage paths (for 3D modeling reference) kept unchanged in VehicleMountCatalog; `iconAssetId` is additive.
**Technique:** Asset Manager multi-select fails via automation (Shift/Cmd not registering). Reliable extraction = user multi-selects + Insert as Decals → command-bar Lua `MarketplaceService:GetProductInfo(id).Name` to print `name=id` pairs.
