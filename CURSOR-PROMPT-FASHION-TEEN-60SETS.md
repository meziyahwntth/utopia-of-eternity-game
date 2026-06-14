# CURSOR PROMPT — Teen Fashion 60 Sets (Wave 2)
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก TeenTrendFashionSets.luau (30 ชุด wave 1)
> ⚠️ Roblox ToS: ห้าม explicit nudity — ใช้ crop top, mini, bodycon, cut-out แทน (DTI-safe)

---

## บริบท

Wave 1 (30 ชุด) ใน `TeenTrendFashionSets.luau` เป็นแนว clean/formal  
Wave 2 นี้เน้น: **Edgy · Flirty · Party · Dark Glam · Alt · Festival** — สไตล์ที่ฮิตใน DTI / Royale High / Dress to Impress

**ไฟล์ที่ต้องแก้/สร้าง:**
| ไฟล์ | Action |
|------|--------|
| `TeenTrendFashionSets.luau` | เพิ่ม 60 set ใน `TeenTrendFashionSets.All` (ต่อจาก entry สุดท้าย) |
| `docs/visual-ref/fashion/teen-trend/README.md` | เพิ่ม #31–90 ใน index table |

**Helper functions ที่ใช้ (มีอยู่แล้วในไฟล์):**
```lua
S = Shirt · P = Pants · H = Hat · R = Hair · F = Face
N = Neck · B = Back · W = Shoes · A = Aura
set(id, name, tag, robux, pieces)
```

---

## Slot Reference (ราคาต่อชิ้น)

| Tier | Robux ต่อชิ้น | ตัวอย่าง |
|------|--------------|---------|
| Basic | 99–149 | Shoes, Accessory |
| Standard | 199–299 | Shirt, Pants, Hat |
| Premium | 349–499 | Dress, Hair, Aura |
| Bundle | 999–1,499 | ราคา Bundle ทั้งชุด |

---

## หมวด A — Street Chic & Baddie Glam (Sets 31–40)

```lua
-- ===== SET 31 =====
set("crop_street_queen", "Crop Street Queen", "BaddieStreet", 1099, {
  S("csq_crop_blazer",    "Cut-Off Blazer Crop", 279),
  P("csq_biker_shorts",   "Biker Shorts Chain", 199),
  W("csq_chunky_boots",   "Chunky Lug Boots", 229),
  H("csq_bucket_hat",     "Bucket Hat Tilted", 149),
  A("csq_gold_chain_aura","Gold Chain Aura", 299),
}),

-- ===== SET 32 =====
set("bodycon_night_rave", "Bodycon Night Rave", "ClubGlam", 1199, {
  S("bnr_sequin_bodycon",  "Silver Sequin Bodycon Dress", 399),
  W("bnr_clear_heel",      "Clear Platform Heels", 249),
  N("bnr_crystal_choker",  "Crystal Statement Choker", 179),
  F("bnr_glitter_liner",   "Glitter Wing Liner", 149),
  A("bnr_disco_aura",      "Disco Ball Aura", 349),
}),

-- ===== SET 33 =====
set("cutout_cyber_vixen", "Cut-Out Cyber Vixen", "CyberEdge", 1249, {
  S("ccv_cutout_top",      "Holographic Cut-Out Top", 319),
  P("ccv_latex_mini",      "Faux Latex Mini Skirt", 259),
  W("ccv_thighhigh_cyber", "Cyber Thigh-High Boots", 289),
  R("ccv_silver_ponytail", "High Silver Ponytail", 219),
  A("ccv_hologram_aura",   "Hologram Pulse Aura", 329),
}),

-- ===== SET 34 =====
set("cherry_bomb_street", "Cherry Bomb Street", "StreetBomb", 1099, {
  S("cbs_cherry_crop",     "Cherry Patch Crop Tee", 249),
  P("cbs_denim_micro",     "Micro Denim Skirt", 219),
  W("cbs_platform_mary",   "Platform Mary Jane", 199),
  N("cbs_cherry_charm",    "Cherry Charm Necklace", 149),
  A("cbs_cherry_bloom_aura","Cherry Blossom Aura", 279),
}),

-- ===== SET 35 =====
set("neon_baddie_runway", "Neon Baddie Runway", "NeonBaddie", 1299, {
  S("nbr_neon_corset",     "Neon Green Corset Top", 349),
  P("nbr_neon_flare",      "Neon Flare Pants", 279),
  W("nbr_platform_sneak",  "Neon Platform Sneakers", 229),
  H("nbr_visor_neon",      "Neon Visor Cap", 179),
  A("nbr_electric_aura",   "Electric Neon Aura", 349),
}),

-- ===== SET 36 =====
set("barbiecore_malibu", "Barbiecore Malibu", "Barbiecore", 1399, {
  S("bcm_pink_corset",     "Hot Pink Corset Mini Dress", 449),
  W("bcm_pink_mule",       "Pink Feather Mule Heels", 279),
  H("bcm_blonde_side_part","Blonde Side Part Waves", 299),
  F("bcm_barbie_lash",     "Doll Lash Face", 179),
  A("bcm_pink_cloud_aura", "Pink Cloud Aura", 349),
}),

-- ===== SET 37 =====
set("slay_golden_hour", "Slay Golden Hour", "GoldenSlay", 1199, {
  S("sgh_gold_bodysuit",   "Metallic Gold Bodysuit", 369),
  P("sgh_satin_wide_leg",  "Bronze Satin Wide Leg", 249),
  W("sgh_kitten_heel",     "Gold Kitten Heel", 219),
  B("sgh_chain_belt",      "Gold Chain Belt Back", 199),
  A("sgh_sunburst_aura",   "Sunburst Aura", 329),
}),

-- ===== SET 38 =====
set("bimbocore_bubblegum", "Bimbocore Bubblegum", "Bimbocore", 1099, {
  S("bcb_fluffy_crop",     "Fluffy Bubblegum Crop Top", 299),
  P("bcb_micro_puff",      "Puff Micro Skirt", 229),
  W("bcb_heart_heels",     "Heart-Cut Platform Heels", 249),
  R("bcb_high_pigtails",   "High Pigtails Voluminous", 269),
  A("bcb_bubblegum_aura",  "Bubblegum Pop Aura", 299),
}),

-- ===== SET 39 =====
set("downtown_off_shoulder", "Downtown Off-Shoulder", "UrbanChic", 1149, {
  S("dos_off_knit",        "Off-Shoulder Knit Crop", 279),
  P("dos_cargo_mini",      "Cargo Mini Skirt", 229),
  W("dos_lace_boots",      "Ankle Lace-Up Boots", 219),
  N("dos_layered_chain",   "Layered Chain Set", 169),
  A("dos_city_glow_aura",  "City Glow Aura", 299),
}),

-- ===== SET 40 =====
set("vsco_beach_baddie", "VSCO Beach Baddie", "BeachBaddie", 1049, {
  S("vbb_crop_hoodie",     "Crop Zip-Up Hoodie", 259),
  P("vbb_biker_denim",     "Biker Denim Shorts", 199),
  W("vbb_foam_slide",      "Chunky Foam Slides", 179),
  B("vbb_tote_shell",      "Shell Tote Bag", 199),
  A("vbb_ocean_aura",      "Ocean Breeze Aura", 279),
}),
```

---

## หมวด B — Party Night & Disco Glam (Sets 41–50)

```lua
-- ===== SET 41 =====
set("disco_silver_queen", "Disco Silver Queen", "Disco", 1299, {
  S("dsq_mirror_halter",   "Mirror Halter Mini Dress", 429),
  W("dsq_silver_platform", "Silver Disco Platform", 269),
  R("dsq_voluminous_blow", "Voluminous Blowout Hair", 289),
  F("dsq_glitter_cheek",   "Glitter Cheek Face", 179),
  A("dsq_mirror_ball_aura","Mirror Ball Aura", 399),
}),

-- ===== SET 42 =====
set("party_girl_velvet", "Party Girl Velvet", "PartyGirl", 1199, {
  S("pgv_velvet_slip",     "Velvet Slip Mini Dress", 379),
  W("pgv_strappy_heel",    "Strappy High Heel", 249),
  N("pgv_pearl_drop",      "Pearl Drop Earrings", 169),
  B("pgv_mini_evening_bag","Mini Evening Bag", 189),
  A("pgv_velvet_glow",     "Velvet Glow Aura", 329),
}),

-- ===== SET 43 =====
set("club_queen_latex", "Club Queen Latex", "ClubEdge", 1349, {
  S("cql_latex_corset_set","Faux Latex Corset Set", 449),
  P("cql_latex_mini_skirt","Faux Latex Mini", 279),
  W("cql_thigh_stiletto",  "Thigh-High Stiletto Boot", 329),
  R("cql_slick_bun",       "Sleek Low Bun", 199),
  A("cql_pulse_aura",      "Dark Pulse Aura", 349),
}),

-- ===== SET 44 =====
set("new_years_sparkle", "New Year's Sparkle", "NewYearGlam", 1449, {
  S("nys_sequin_halter",   "Champagne Sequin Halter", 449),
  P("nys_feather_trim",    "Feather-Trim Mini Skirt", 299),
  W("nys_gold_strappy",    "Gold Strappy Sandal Heel", 249),
  H("nys_tiara_gem",       "Crystal Midnight Tiara", 279),
  A("nys_firework_aura",   "Firework Burst Aura", 399),
}),

-- ===== SET 45 =====
set("valentines_red_hot", "Valentine's Red Hot", "ValentineGlam", 1299, {
  S("vrh_red_corset_dress","Red Satin Corset Mini", 429),
  W("vrh_red_platform",    "Red Patent Platform Heel", 269),
  N("vrh_heart_necklace",  "Heart Drop Necklace", 179),
  F("vrh_red_lip_glam",    "Red Lip Glam Face", 169),
  A("vrh_rose_petal_aura", "Rose Petal Shower Aura", 369),
}),

-- ===== SET 46 =====
set("summer_festival_glam", "Summer Festival Glam", "FestivalHot", 1199, {
  S("sfg_crochet_crop",    "Crochet Crop Top", 279),
  P("sfg_denim_cut_off",   "Denim Cut-Off Shorts", 209),
  W("sfg_cowboy_glitter",  "Glitter Cowboy Boot", 259),
  H("sfg_flower_crown",    "Wildflower Crown", 199),
  A("sfg_golden_hour_aura","Golden Hour Aura", 319),
}),

-- ===== SET 47 =====
set("bratz_doll_revival", "Bratz Doll Revival", "Bratz", 1349, {
  S("bdr_graphic_crop",    "Graphic Logo Crop", 299),
  P("bdr_plaid_mini",      "Plaid Mini Skirt", 239),
  W("bcdr_platform_boots", "Chunky Platform Boots", 289),
  F("bdr_glossy_bratz",    "Glossy Bratz Make-up", 199),
  A("bdr_shimmer_aura",    "Shimmer Pop Aura", 299),
}),

-- ===== SET 48 =====
set("songkran_neon_splash", "Songkran Neon Splash 2027", "Songkran2027", 1249, {
  S("sns_tropical_halter", "Tropical Neon Halter", 319),
  P("sns_sarong_mini",     "Wrap Sarong Mini", 229),
  W("sns_platform_sandal", "Neon Platform Sandal", 229),
  H("sns_water_gun_back",  "Water Gun Back Prop", 249),
  A("sns_water_splash_aura","Water Splash Aura", 349),
}),

-- ===== SET 49 =====
set("rave_butterfly_glow", "Rave Butterfly Glow", "RaveGlow", 1299, {
  S("rbg_butterfly_halter","UV Butterfly Halter Set", 369),
  P("rbg_shorts_gem",      "Crystal-Trim Hot Shorts", 239),
  W("rbg_platform_uv",     "UV Glow Platform", 259),
  B("rbg_butterfly_wings", "Holographic Wings", 349),
  A("rbg_uv_glow_aura",    "UV Butterfly Aura", 399),
}),

-- ===== SET 50 =====
set("midsummer_sorbet", "Midsummer Sorbet", "SummerPastel", 1099, {
  S("mss_sorbet_tube",     "Sorbet Color-Block Tube Dress", 329),
  W("mss_espadrille",      "Platform Espadrille", 219),
  N("mss_beaded_choker",   "Beaded Pastel Choker", 159),
  H("mss_bucket_pastel",   "Pastel Bucket Hat", 179),
  A("mss_sorbet_mist_aura","Sorbet Mist Aura", 299),
}),
```

---

## หมวด C — Dark Alt & Gothic Glam (Sets 51–60)

```lua
-- ===== SET 51 =====
set("dark_fairy_nocturne", "Dark Fairy Nocturne", "DarkFairy", 1349, {
  S("dfn_dark_tulle_corset","Black Tulle Corset Dress", 449),
  W("dfn_pointed_boot",    "Witchy Pointed Boot", 279),
  B("dfn_dark_wings",      "Dark Feather Wings", 349),
  R("dfn_side_swept_dark", "Side-Swept Dark Waves", 229),
  A("dfn_shadow_fairy_aura","Shadow Fairy Aura", 399),
}),

-- ===== SET 52 =====
set("gothic_lolita_prism", "Gothic Lolita Prism", "GothLolita", 1449, {
  S("glp_gothic_lolita_dress","Gothic Lolita Dress", 499),
  W("glp_platform_doll_shoe","Platform Doll Shoe", 259),
  H("glp_mini_top_hat",    "Mini Top Hat + Veil", 299),
  N("glp_cameo_choker",    "Cameo Lace Choker", 199),
  A("glp_gothic_rose_aura","Gothic Rose Aura", 369),
}),

-- ===== SET 53 =====
set("witch_academy_dark", "Witch Academy Dark", "DarkWitch", 1199, {
  S("wad_academic_cape",   "Dark Academic Cape Dress", 399),
  W("wad_lace_combat",     "Lace Combat Boot", 249),
  H("wad_wide_brim_witch", "Wide-Brim Witch Hat", 229),
  B("wad_spellbook_back",  "Floating Spellbook", 279),
  A("wad_hex_aura",        "Hex Spiral Aura", 349),
}),

-- ===== SET 54 =====
set("blood_moon_vampire", "Blood Moon Vampire", "Vampire", 1299, {
  S("bmv_vampire_gown",    "Crimson Vampire Gown", 429),
  W("bmv_heeled_boot",     "Heeled Lace Vampire Boot", 269),
  R("bmv_widow_peak_hair", "Widow's Peak Dark Hair", 239),
  F("bmv_pale_fang_face",  "Pale Fang Make-up", 199),
  A("bmv_blood_moon_aura", "Blood Moon Aura", 399),
}),

-- ===== SET 55 =====
set("punk_riot_girl", "Punk Riot Girl", "Punk", 1149, {
  S("prg_tartan_crop",     "Tartan Crop Jacket Set", 329),
  P("prg_fishnet_layer",   "Fishnet-Layer Mini Skirt", 239),
  W("prg_studded_boot",    "Studded Combat Boot", 259),
  H("prg_liberty_spikes",  "Liberty Spike Hair", 279),
  A("prg_anarchy_aura",    "Anarchy Static Aura", 319),
}),

-- ===== SET 56 =====
set("shadow_doll_void", "Shadow Doll Void", "VoidDoll", 1349, {
  S("sdv_shadow_dress",    "Shadow Doll Dress", 429),
  W("sdv_ribbon_ankle",    "Black Ribbon Ankle Boot", 259),
  R("sdv_twin_drills",     "Twin Drill Black Hair", 299),
  F("sdv_void_eye_face",   "Void Eye Make-up", 189),
  A("sdv_void_mist_aura",  "Void Mist Aura", 399),
}),

-- ===== SET 57 =====
set("darkwave_cyber_angel", "Darkwave Cyber Angel", "CyberAngel", 1249, {
  S("dca_cyber_angel_top", "Cyber Angel Crop Harness", 369),
  P("dca_circuit_mini",    "Circuit Mini Skirt", 249),
  W("dca_angel_platform",  "Angel Wing Platform", 289),
  B("dca_mech_wings",      "Mechanical Angel Wings", 389),
  A("dca_cyber_halo_aura", "Cyber Halo Aura", 369),
}),

-- ===== SET 58 =====
set("halloween_glam_witch", "Halloween Glam Witch", "HalloweenGlam", 1349, {
  S("hgw_glam_witch_dress","Glam Witch Sequin Dress", 449),
  W("hgw_platform_heel_bat","Bat-Buckle Platform Heel", 279),
  H("hgw_witch_hat_gems",  "Jeweled Witch Hat", 299),
  N("hgw_spider_web_cape", "Spider Web Cape", 239),
  A("hgw_haunted_aura",    "Haunted Sparkle Aura", 369),
}),

-- ===== SET 59 =====
set("alt_fairy_grunge", "Alt Fairy Grunge", "AltFairy", 1199, {
  S("afg_grunge_fairy_top","Grunge Fairy Crop Top", 319),
  P("afg_tutu_over_shorts","Tutu Over Ripped Shorts", 249),
  W("afg_platform_fairy",  "Glitter Platform Boot", 269),
  B("afg_iridescent_wings","Iridescent Fairy Wings", 329),
  A("afg_alt_fairy_aura",  "Alt Fairy Dust Aura", 349),
}),

-- ===== SET 60 =====
set("devil_angel_split", "Devil Angel Split", "DevilAngel", 1399, {
  S("das_half_split_dress","Half Devil-Angel Mini Dress", 449),
  W("das_split_heel",      "Split Black-White Heel", 279),
  H("das_halo_horn_set",   "Halo + Tiny Horn Set", 299),
  F("das_split_face",      "Devil-Angel Split Make-up", 199),
  A("das_chaos_aura",      "Chaos Balance Aura", 399),
}),
```

---

## หมวด D — Fantasy & Cosplay Fusion (Sets 61–70)

```lua
-- ===== SET 61 =====
set("crystal_mage_girl", "Crystal Mage Girl", "MageGirl", 1249, {
  S("cmg_crystal_robe",    "Crystal Mage Crop Robe", 369),
  P("cmg_gem_leggings",    "Gem-Print Leggings", 229),
  W("cmg_crystal_boot",    "Crystal Shard Boot", 279),
  H("cmg_mage_hat_gems",   "Jeweled Mage Hat", 259),
  A("cmg_crystal_burst_aura","Crystal Burst Aura", 359),
}),

-- ===== SET 62 =====
set("ocean_siren_deep", "Ocean Siren Deep", "DeepSiren", 1349, {
  S("osd_scale_corset",    "Iridescent Scale Corset", 419),
  P("osd_mermaid_mini",    "Mermaid Fin Mini Skirt", 279),
  W("osd_fin_boot",        "Sea Fin Platform Boot", 289),
  B("osd_trident_prop",    "Mini Trident Back Prop", 299),
  A("osd_deep_current_aura","Deep Current Aura", 379),
}),

-- ===== SET 63 =====
set("elven_twilight_archer","Elven Twilight Archer", "ElfArcher", 1299, {
  S("eta_elf_crop_armor",  "Elven Crop Leather Armor", 389),
  P("eta_leaf_skirt",      "Leaf-Trim Mini Skirt", 249),
  W("eta_thigh_elf_boot",  "Thigh-High Elf Boot", 299),
  B("eta_bow_back",        "Elven Bow Back Prop", 319),
  A("eta_forest_shimmer",  "Forest Shimmer Aura", 349),
}),

-- ===== SET 64 =====
set("lunar_goddess_silk", "Lunar Goddess Silk", "LunarGoddess", 1449, {
  S("lgs_moon_silk_gown",  "Moon Silk Drape Mini", 479),
  W("lgs_moonstone_heel",  "Moonstone Crystal Heel", 279),
  H("lgs_crescent_crown",  "Crescent Moon Crown", 319),
  N("lgs_star_drop",       "Star Drop Pendant", 199),
  A("lgs_moonbeam_aura",   "Moonbeam Aura", 429),
}),

-- ===== SET 65 =====
set("dark_magical_girl", "Dark Magical Girl", "DarkMagical", 1349, {
  S("dmg_dark_seifuku",    "Dark Sailor Seifuku Dress", 419),
  W("dmg_platform_ribbon", "Platform Ribbon Boot", 279),
  H("dmg_dark_twin_bow",   "Dark Twin Bow Set", 249),
  B("dmg_dark_wand",       "Dark Staff Wand Prop", 309),
  A("dmg_dark_star_aura",  "Dark Star Magical Aura", 389),
}),

-- ===== SET 66 =====
set("cyberpunk_neon_idol", "Cyberpunk Neon Idol", "CyberIdol", 1299, {
  S("cni_neon_idol_set",   "Neon Idol Stage Outfit", 399),
  W("cni_cyber_boot_glow", "Glow Circuit Boot", 279),
  H("cni_hologram_headset","Hologram AR Headset", 259),
  F("cni_neon_face_lines", "Neon Circuit Face Lines", 189),
  A("cni_cyber_star_aura", "Cyber Star Aura", 349),
}),

-- ===== SET 67 =====
set("prism_angel_wings", "Prism Angel Wings", "PrismAngel", 1399, {
  S("paw_prism_halter",    "Prism Light Halter Dress", 449),
  W("paw_crystal_platform","Crystal Platform Sandal", 279),
  B("paw_prism_wings",     "Prism Spectrum Wings", 429),
  R("paw_halo_braid",      "Halo Braid Hair", 259),
  A("paw_prism_light_aura","Prism Light Aura", 449),
}),

-- ===== SET 68 =====
set("sakura_warrior_girl", "Sakura Warrior Girl", "SakuraWarrior", 1249, {
  S("swg_haori_crop",      "Crop Haori Warrior Top", 369),
  P("swg_hakama_mini",     "Short Hakama Skirt", 249),
  W("swg_armored_boot",    "Armored Sandal Boot", 279),
  B("swg_katana_back",     "Sakura Katana Back", 329),
  A("swg_sakura_storm_aura","Sakura Storm Aura", 359),
}),

-- ===== SET 69 =====
set("celestial_stardust", "Celestial Stardust", "Celestial", 1349, {
  S("csd_galaxy_bodysuit", "Galaxy Print Mini Bodysuit", 409),
  W("csd_star_platform",   "Star Platform Heel", 269),
  H("csd_nebula_crown",    "Nebula Gem Crown", 299),
  R("csd_galaxy_waves",    "Galaxy Ombré Waves", 289),
  A("csd_stardust_aura",   "Stardust Trail Aura", 419),
}),

-- ===== SET 70 =====
set("dragon_empress", "Dragon Empress", "DragonEmpress", 1499, {
  S("de_dragon_qi_dress",  "Dragon Qi Pao Mini Dress", 499),
  W("de_dragon_platform",  "Dragon Scale Platform", 309),
  H("de_dragon_headdress", "Dragon Empress Headdress", 349),
  B("de_dragon_tail",      "Dragon Tail Back Prop", 369),
  A("de_dragon_flame_aura","Dragon Flame Aura", 449),
}),
```

---

## หมวด E — Seasonal Events (Sets 71–80)

```lua
-- ===== SET 71 =====
set("christmas_snow_glam", "Christmas Snow Glam", "ChristmasGlam", 1349, {
  S("csg_velvet_xmas",     "Velvet Red Christmas Dress", 449),
  W("csg_fur_platform",    "White Fur Platform Boot", 279),
  H("csg_santa_mini_hat",  "Mini Santa Hat + Bells", 229),
  N("csg_gold_star_drop",  "Gold Star Drop Necklace", 179),
  A("csg_snowfall_aura",   "Snowfall Aura", 399),
}),

-- ===== SET 72 =====
set("songkran_lotus_dance","Songkran Lotus Dance", "SongkranDance", 1249, {
  S("sld_lotus_halter",    "Lotus Bloom Halter Dress", 399),
  W("sld_gold_sandal",     "Gold Thai Sandal", 219),
  H("sld_lotus_crown",     "Lotus Crown Headdress", 279),
  B("sld_water_jar_prop",  "Decorative Water Jar Prop", 259),
  A("sld_water_lotus_aura","Water Lotus Aura", 369),
}),

-- ===== SET 73 =====
set("loy_krathong_river", "Loy Krathong River Light", "LoyKrathong", 1299, {
  S("lkr_thai_silk_off",   "Thai Silk Off-Shoulder Dress", 429),
  W("lkr_thai_wedge",      "Thai Silk Wedge", 239),
  H("lkr_krathong_crown",  "Krathong Crown Headdress", 299),
  N("lkr_gold_collar",     "Gold Traditional Collar", 219),
  A("lkr_river_lantern_aura","River Lantern Aura", 389),
}),

-- ===== SET 74 =====
set("halloween_witch_pop", "Halloween Witch Pop", "HalloweenPop", 1199, {
  S("hwp_candy_witch_set", "Candy Corn Witch Set", 359),
  W("hwp_boot_web",        "Spider Web Platform Boot", 259),
  H("hwp_pop_witch_hat",   "Pop Art Witch Hat", 249),
  B("hwp_candy_bag",       "Trick or Treat Bag", 229),
  A("hwp_candy_ghost_aura","Candy Ghost Aura", 329),
}),

-- ===== SET 75 =====
set("cny_dragon_parade", "CNY Dragon Parade", "ChineseNewYear", 1349, {
  S("cdp_red_qipao_mini",  "Red Dragon Qipao Mini", 449),
  W("cdp_red_platform",    "Red Satin Platform", 269),
  H("cdp_dragon_hairpin",  "Dragon Hairpin Set", 259),
  N("cdp_jade_pendant",    "Jade Good Luck Pendant", 199),
  A("cdp_dragon_parade_aura","Dragon Parade Aura", 399),
}),

-- ===== SET 76 =====
set("summer_pool_party", "Summer Pool Party", "PoolParty", 1099, {
  S("spp_swimwear_cover",  "Pastel Swimwear Cover-Up Set", 329),
  W("spp_pool_slides",     "Puffy Pool Slides", 179),
  H("spp_sun_hat_beach",   "Big Sun Hat", 199),
  F("spp_bronzed_face",    "Sun-Kissed Bronzed Face", 169),
  A("spp_pool_splash_aura","Pool Splash Aura", 299),
}),

-- ===== SET 77 =====
set("february_dream", "February Dream", "ValentineSoft", 1149, {
  S("fd_lilac_flutter",    "Lilac Flutter Mini Dress", 369),
  W("fd_mauve_platform",   "Mauve Platform Heel", 249),
  N("fd_pearl_heart",      "Pearl + Heart Choker", 179),
  H("fd_heart_clips",      "Heart Hair Clip Set", 169),
  A("fd_love_petal_aura",  "Love Petal Aura", 329),
}),

-- ===== SET 78 =====
set("new_year_countdown", "New Year Countdown", "NYCountdown", 1399, {
  S("nyc_gold_micro_dress","Gold Micro Dress Sequin", 479),
  W("nyc_ankle_strap_gold","Gold Ankle-Strap Heel", 259),
  H("nyc_party_crown",     "Party Crown + Confetti", 249),
  F("nyc_glitter_eye",     "Midnight Glitter Eye", 189),
  A("nyc_countdown_aura",  "Countdown Firework Aura", 429),
}),

-- ===== SET 79 =====
set("pride_rainbow_rave", "Pride Rainbow Rave", "PrideRave", 1249, {
  S("prr_rainbow_corset",  "Rainbow Corset Mini", 399),
  W("prr_rainbow_boot",    "Rainbow Platform Boot", 269),
  H("prr_rainbow_afro",    "Rainbow Afro Puff", 299),
  B("prr_rainbow_wings",   "Rainbow Angel Wings", 359),
  A("prr_rainbow_aura",    "Rainbow Pride Aura", 399),
}),

-- ===== SET 80 =====
set("back_to_school_glam","Back to School Glam", "SchoolGlam", 1099, {
  S("bsg_glam_uniform",    "Glam Plaid Uniform Dress", 349),
  W("bsg_loafer_platform", "Platform Loafer", 229),
  H("bsg_ribbon_ponytail", "Ribbon Ponytail Hair", 219),
  B("bsg_glitter_bag",     "Glitter Mini Backpack", 219),
  A("bsg_studious_aura",   "Studious Star Aura", 289),
}),
```

---

## หมวด F — Prestige & Runway Couture (Sets 81–90)

```lua
-- ===== SET 81 =====
set("couture_black_swan", "Couture Black Swan", "BlackSwan", 1599, {
  S("cbs_black_tutu_gown", "Black Feather Tutu Gown", 549),
  W("cbs_ballet_heel",     "Black Ballet Heel", 299),
  H("cbs_feather_crown",   "Black Feather Crown", 329),
  F("cbs_black_eye_art",   "Black Eye Art Face", 219),
  A("cbs_obsidian_aura",   "Obsidian Feather Aura", 499),
}),

-- ===== SET 82 =====
set("white_swan_premiere","White Swan Premiere", "WhiteSwan", 1599, {
  S("wsp_white_tutu_gown", "White Feather Tutu Gown", 549),
  W("wsp_white_ballet",    "White Satin Ballet Heel", 299),
  H("wsp_white_crown",     "White Pearl Crown", 329),
  F("wsp_pearl_blush",     "Pearl Blush Face", 199),
  A("wsp_swan_grace_aura", "Swan Grace Aura", 499),
}),

-- ===== SET 83 =====
set("met_gala_prism", "Met Gala Prism", "MetGalaPrism", 1699, {
  S("mgp_avant_garde",     "Avant-Garde Prism Gown", 599),
  W("mgp_sculptural_heel", "Sculptural Art Heel", 329),
  H("mgp_editorial_hat",   "Editorial Sculpture Hat", 369),
  N("mgp_statement_neck",  "Statement Gem Neckpiece", 279),
  A("mgp_runway_aura",     "Runway Flash Aura", 549),
}),

-- ===== SET 84 =====
set("versace_gold_luxe", "Versace-Inspired Gold Luxe", "GoldLuxe", 1499, {
  S("vgl_gold_chain_dress","Gold Chain Mini Dress", 499),
  W("vgl_chain_sandal",    "Chain Gladiator Heel", 299),
  R("vgl_sleek_gold_blow", "Sleek Golden Blowout", 289),
  N("vgl_baroque_collar",  "Baroque Gold Collar", 249),
  A("vgl_luxe_gold_aura",  "Luxe Gold Aura", 469),
}),

-- ===== SET 85 =====
set("crystal_ice_queen", "Crystal Ice Queen", "IceQueen", 1449, {
  S("ciq_ice_gown",        "Crystal Ice Gown", 499),
  W("ciq_ice_platform",    "Ice Crystal Platform", 289),
  H("ciq_ice_crown",       "Ice Spike Crown", 339),
  R("ciq_silver_ice_hair", "Silver Ice Waves Hair", 279),
  A("ciq_blizzard_aura",   "Blizzard Aura", 449),
}),

-- ===== SET 86 =====
set("obsidian_dark_queen","Obsidian Dark Queen", "DarkQueen", 1499, {
  S("odq_dark_gown",       "Obsidian Fitted Gown", 499),
  W("odq_obsidian_boot",   "Obsidian Heel Boot", 299),
  H("odq_dark_crown",      "Obsidian Spiked Crown", 349),
  B("odq_shadow_cape",     "Shadow Silk Cape", 329),
  A("odq_void_queen_aura", "Void Queen Aura", 499),
}),

-- ===== SET 87 =====
set("cyber_queen_2077",  "Cyber Queen 2077", "CyberQueen", 1449, {
  S("cq_cyber_suit",       "Cyber-Tech Bodysuit", 479),
  W("cq_magnet_boot",      "Maglev Platform Boot", 309),
  H("cq_neon_visor",       "Neon HUD Visor", 279),
  B("cq_tech_wing",        "Tech-Wing Backpiece", 389),
  A("cq_cyber_pulse_aura", "Cyber Pulse Aura", 449),
}),

-- ===== SET 88 =====
set("ethereal_goddess", "Ethereal Goddess", "Goddess", 1549, {
  S("eg_goddess_drape",    "Ethereal Drape Gown", 529),
  W("eg_gilded_sandal",    "Gilded Gladiator Sandal", 289),
  H("eg_laurel_halo",      "Gold Laurel Halo Crown", 319),
  B("eg_sheer_cape",       "Sheer Gold Cape", 349),
  A("eg_divine_glow_aura", "Divine Glow Aura", 519),
}),

-- ===== SET 89 =====
set("sakura_empress_bloom","Sakura Empress Bloom", "SakuraEmpress", 1499, {
  S("seb_sakura_furisode", "Sakura Furisode Mini", 499),
  W("seb_zori_platform",   "Modern Zori Platform", 289),
  H("seb_kanzashi_sakura", "Kanzashi Sakura Crown", 339),
  N("seb_silk_obi_bow",    "Silk Obi Bow Belt", 249),
  A("seb_sakura_fall_aura","Sakura Petal Fall Aura", 479),
}),

-- ===== SET 90 =====
set("prismwake_gala_v2",  "Prismwake Gala v2 Deluxe", "PrismGala2", 1699, {
  S("pgv2_prism_halter_gown","Prism Halter Column Gown", 549),
  W("pgv2_prism_heel",     "Prism Crystal Heel", 319),
  H("pgv2_prism_tiara",    "Prism Light Tiara", 339),
  B("pgv2_prism_train",    "Prism Light Train", 399),
  A("pgv2_prism_rainbow_aura","Prism Rainbow Aura", 549),
}),
```

---

## Image Prompts สำหรับ Generate Concept (Midjourney / Leonardo.ai)

> ใช้ prompt เหล่านี้สร้างภาพ concept · save ที่ `docs/visual-ref/fashion/teen-trend/` ชื่อ `teen-{set_id_with_dashes}.png`

### หมวด A — Street Chic & Baddie
```
teen-crop-street-queen: "Gen Z girl teen, crop blazer cut-off, biker shorts with gold chain belt, 
chunky lug-sole boots, bucket hat tilted, urban street background, DTI Roblox fashion style, 
front-facing character turnaround, white background, vibrant colors, no text" --ar 3:4

teen-bodycon-night-rave: "Roblox-style teen girl, silver sequin bodycon mini dress, clear platform 
heels, crystal statement choker, glitter wing liner, disco club background, character sheet, 
white background, stylized proportions, game-ready fashion illustration" --ar 3:4

teen-barbiecore-malibu: "Roblox fashion teen girl character, hot pink corset mini dress, 
feather mule heels, blonde waves hair, Barbiecore aesthetic, pastel pink background, 
front-view character design, DTI game style illustration" --ar 3:4

teen-bimbocore-bubblegum: "Teen girl Roblox character, fluffy bubblegum pink crop top, 
puff micro skirt, heart platform heels, voluminous high pigtails, Y2K Bimbocore aesthetic, 
candy pink background, game fashion concept art, white background" --ar 3:4
```

### หมวด B — Party Night & Disco
```
teen-disco-silver-queen: "Roblox teen girl, mirror/silver disco halter mini dress, 
silver platform shoes, voluminous blowout hair, glitter cheek makeup, 
retro-future disco aesthetic, sparkle background, front-view fashion character sheet" --ar 3:4

teen-valentines-red-hot: "Roblox DTI style teen girl, red satin corset mini dress, 
red patent platform heels, heart drop necklace, red lip glam, rose petal background, 
Valentine's Day aesthetic, white background, fashion concept" --ar 3:4

teen-songkran-neon-splash-2027: "Roblox teen girl character, tropical neon halter dress, 
mini sarong wrap, platform sandals, colorful water festival Songkran Thai aesthetic, 
water splash elements background, vibrant turquoise-coral color palette, 
front-view character design" --ar 3:4

teen-rave-butterfly-glow: "Roblox teen girl, UV holographic butterfly halter set, 
crystal-trim hot shorts, UV glow platforms, holographic butterfly wings, 
neon rave party aesthetic, black light glow effects background, 
game fashion illustration" --ar 3:4
```

### หมวด C — Dark Alt & Gothic
```
teen-dark-fairy-nocturne: "Roblox teen girl, black tulle corset mini dress, 
dark feather wings, witchy boots, dark fairy nocturne aesthetic, 
moonlit forest background, ethereal dark fantasy style, white background, 
front-view fashion character concept" --ar 3:4

teen-blood-moon-vampire: "Roblox teen girl character, crimson vampire mini gown, 
heeled lace vampire boots, widow's peak dark dramatic hair, 
blood moon aesthetic, gothic elegant, dark rose red atmosphere, 
white background game fashion sheet" --ar 3:4

teen-punk-riot-girl: "Roblox teen girl, tartan crop jacket, fishnet-layer mini skirt, 
studded combat boots, liberty spikes hair, punk rock aesthetic, 
urban grunge background, game-ready fashion character illustration, 
vibrant punk palette" --ar 3:4

teen-devil-angel-split: "Roblox teen girl, half black half white mini dress split design, 
split black-white platform heels, one halo one tiny horn, split makeup, 
devil angel duality aesthetic, gradient red-white background, 
DTI fashion character art" --ar 3:4
```

### หมวด D — Fantasy & Couture
```
teen-dragon-empress: "Roblox teen girl, red dragon qi pao mini dress, 
dragon scale platform heels, imperial dragon empress headdress, 
dragon tail back prop accessory, Chinese imperial fantasy aesthetic, 
red-gold ornate background, game fashion character sheet" --ar 3:4

teen-celestial-stardust: "Roblox teen girl, galaxy print mini bodysuit, 
star platform heels, nebula gem crown, galaxy ombre waves hair, 
celestial space aesthetic, cosmos nebula background, 
game-ready fashion illustration, front-view" --ar 3:4

teen-prism-angel-wings: "Roblox teen girl, prism light halter mini dress, 
crystal platform sandals, large prism spectrum rainbow wings, 
halo braid hair, divine light prism aesthetic, 
white-rainbow light background, DTI style fashion art" --ar 3:4
```

---

## default.project.json — ไม่ต้องแก้
TeenTrendFashionSets.luau อยู่ใน ReplicatedStorage ผ่าน folder path อัตโนมัติ

## README.md update
เพิ่มบรรทัด #31–90 ในตาราง `docs/visual-ref/fashion/teen-trend/README.md` ตาม naming rule:
`teen-{set_id_with_dashes}.png`

---

## Git commit

```bash
git add src/ReplicatedStorage/Modules/TeenTrendFashionSets.luau
git add docs/visual-ref/fashion/teen-trend/README.md
git commit -m "feat(Fashion): Teen Trend Wave 2 — 60 new sets

- Sets 31-40: Street Chic & Baddie Glam (Barbiecore, Bimbocore, Neon Baddie)
- Sets 41-50: Party Night & Disco (Club, Rave, Valentines, Songkran 2027)
- Sets 51-60: Dark Alt & Gothic Glam (DarkFairy, GothLolita, VampireGlam)
- Sets 61-70: Fantasy & Cosplay (DragonEmpress, CelestialStardust, PrismAngel)
- Sets 71-80: Seasonal Events (Christmas, Songkran, LoyKrathong, NYCountdown)
- Sets 81-90: Prestige Couture (BlackSwan, MetGala, EtherealGoddess, PrismGala2)
Total: 90 sets in catalog (30 wave1 + 60 wave2)"
```

## รายงานกลับ

- ✅/❌ BUILD · commit hash
- จำนวน set ที่เพิ่มได้ทั้งหมด
