# Legendary Weapons — ChatGPT Generated Catalog

Original concept art สร้างด้วย ChatGPT · ตั้งชื่อตาม**ชนิดอาวุธ** · cosmetic PvE เท่านั้น (ไม่มี stat pay-to-win)

**Config:** `src/ReplicatedStorage/Modules/PrismLegendaryWeaponsCatalog.luau`  
**Concept art:** `assets/weapons/generated/`  
**Commerce:** Prism Weapon Gallery (`weapon_gallery`) · Luxury Galleria preview  
**Dungeon:** Hellbound Loadout UI → เลือก skin คู่กับ light/heavy loadout slot

---

## รายการอาวุธ (13 ชิ้น)

### Light slot (7)

| ID | ชื่อ | ชนิด | dmg/hit (stub) | ไฟล์ |
|----|------|------|----------------|------|
| `blood_knife` | Blood Knife | Dagger | 12 | `blood-knife.png` |
| `m16` | M16 | Assault Rifle | 15 | `m16.png` |
| `ak47` | AK-47 | Assault Rifle | 15 | `ak47.png` |
| `m4a1` | M4A1 | Assault Rifle | 14 | `m4a1.png` |
| `goddess_fan` | Goddess Fan | Fan | 13 | `goddess-fan.png` |
| `demon_slaying_spear` | Demon-Slaying Spear | Spear | 16 | `demon-slaying-spear.png` |
| `immortal_sword` | Immortal Sword | Longsword | 15 | `immortal-sword.png` |

### Heavy slot (6)

| ID | ชื่อ | ชนิด | dmg/hit (stub) | ไฟล์ |
|----|------|------|----------------|------|
| `machine_gun` | Machine Gun | LMG | 18 | `machine-gun.png` |
| `bazooka` | Bazooka | Launcher | 25 | `bazooka.png` |
| `bazuka` | Bazuka | Launcher | 25 | `bazuka-lion.png` |
| `thors_hammer` | Thor's Hammer | Hammer | 22 | `thors-hammer.png` |
| `demon_slayer_sword` | Demon Slayer Sword | Greatsword | 20 | `demon-slayer-sword.png` |
| `heavenly_sword` | Heavenly Sword | Greatsword | 20 | `heavenly-sword.png` |

---

## Pipeline ถัดไป (Blockbench / Roblox)

1. ใช้ concept art ใน `assets/weapons/generated/` เป็น reference
2. Model ใน Blockbench → export `.fbx` / Roblox mesh
3. Upload เป็น UGC / MeshPart → ลง `PrismCatalogAssets.registerMesh(id, assetId)`
4. Developer Product ต่อชิ้น → `PrismCatalogAssets.registerProduct(id, productId)`

---

## Studio QA

1. **Loadout Kiosk** (Death Valley Zone 1) → เพิ่ม Light Weapon → กดปุ่ม **Light:** เลือก skin
2. Lock loadout → ดู `DungeonLightWeapon` / `DungeonHeavyWeapon` ใน Player attributes
3. Boss fight → dmg/hit ตาม skin (เช่น Bazooka = 25)
4. **Prism Weapon Gallery** (Eternity City · key 15+) → แสดง 13 ชิ้นใน shop catalog

---

## Code map

```
PrismLegendaryWeaponsCatalog.luau  — master list + boss hit damage
PrismCatalogAssets.luau            — commerce entries (from catalog)
DungeonLoadoutCalculator.luau      — validate weaponSkins + getBossHitDamage
DungeonLoadoutService.luau         — catalog.legendaryWeapons + save
CommerceShopService.server.luau    — PrismWeaponGallery shop
```
