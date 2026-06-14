# 2026-06-13 — Backlog-B: Pet/Companion System ✅

## สรุป
เสร็จและ push → origin/main commit **01a376b**

## ไฟล์ที่สร้าง
- `ReplicatedStorage/Modules/PetConfig.luau` — 3 pets (slime_blue/fox_fire/dragon_mini), buff + rarity + obtainMethod
- `ServerScriptService/Commerce/PetStore.luau` — DataStore `UtopiaPet_v1`, owned list + activePetId
- `ServerScriptService/Commerce/PetService.luau` — equip/unequip/grant/grantPet, Heartbeat follow loop (lerp 0.08), placeholder ball model, remotes init
- `ServerScriptService/Commerce/PetHandlers.server.luau` — wire EquipPet/UnequipPet/GetPetCollection RF ผ่าน `SocialRemotes`
- `StarterPlayerScripts/PetClient.client.luau` — 🐾 toggle button, collection grid, buff label (EXP%/Drop%)

## Buff Wiring
- `expBonus` → `PlayerLevelService.getExpGainMultiplier()` → combat kill EXP
- `luckBonus` → `PlayerItemStore.addItem()` drop qty
- `pickupRadius` → attribute พร้อม (pickup system ยังไม่มี)

## แก้จาก prompt
- unequip bug: เพิ่ม `unequipPet()` ก่อน equip ใหม่
- respawn: pet กลับมาหลัง `CharacterAdded`
- EXP kill ทำงานโดยไม่ต้องมี event buff

## สถานะ gameplay-blocking backlog
**ทุกรายการเสร็จแล้ว (Event banner / Camera persist / PvP gate / Pet) — 0 blockers เหลือ**

## งาน optional ที่ยังไม่ทำ
- Custom 3D pet models
- Pet drop / quest grant automation
- TradingClient credit offer UI
- Bounty post escrow
- PlayerLevelService full (ยังเป็น stub)
