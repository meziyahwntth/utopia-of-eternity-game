# 2026-06-13 — Crafting / Grandeur System ✅

## Commit: 3488b91 → origin/main

## สิ่งที่สร้าง
- `CraftingService.luau` — canCraft(), craft() + best-effort rollback, getAllRecipes()
- `CraftingHandlers.server.luau` — RF: GetAllRecipes, CraftItem, GetInventory, GetCredits
- `CraftingClient.client.luau` — ⚒ panel มุมขวาบน, recipe list, ✅/❌ material check, craft button
- `ItemCraftingConfig.luau` — +StarSword2 (base:SW1), +IronArmor1 (base:LeatherArmor)

## Recipes
- StarSword1 → StarSword2: StoneFragment×100 + IronOre×30 + 200 credits
- StarSword2 → StarSword3: StoneFragment×500 + IronOre×200 + MagicCrystal×50 + 1000 credits
- LeatherArmor → IronArmor1: IronOre×50 + StoneFragment×20 + 150 credits

## Economy loop ครบแล้ว
Kill NPC → Drop materials → Craft items → ใช้งาน / ขาย P2P

## ต่อไป
- TradingClient credit offer UI (เพิ่ม credit input ใน trade window)
- รอ Story Bible จาก ChatGPT → NpcDialogueConfig
