# MemPalace Diary — Pet Drop from NPC Kill
**วันที่:** 13 มิ.ย. 2026
**Commit:** aa0df7f → pushed 99852be..aa0df7f main → origin/main

## งานที่ทำ

เพิ่ม pet drop จากการ kill NPC เข้าระบบ NpcDrop ที่มีอยู่แล้ว

## ไฟล์ที่แก้

| ไฟล์ | สิ่งที่เปลี่ยน |
|------|--------------|
| `NpcDropConfig.luau` | `DropEntry` type: +`dropType: "item"\|"pet"`, +`petId: string?` · pet entries ใน NPC 2/3/5 |
| `NpcDropService.luau` | `rollDrops()` handle dropType="pet" · `grantDrops()` → `PetService.grantPet()` · skip เงียบถ้า "มี pet นี้แล้ว" |
| `DropNotifClient.client.luau` | `🐾 ได้รับสัตว์เลี้ยง: ...` notification สีชมพู (255,180,255) |

## Drop rates

| NPC | Pet | Chance |
|-----|-----|--------|
| NPC 2 ซอมบี้ | slime_blue | 2% |
| NPC 3 อัศวินมืด | fox_fire | 0.8% |
| NPC 5 Boss | slime_blue | 10% |
| NPC 5 Boss | fox_fire | 4% |
| NPC 5 Boss | dragon_mini | 1% |

## ผลทดสอบ

`rollDrops(5) × 20` → 5/20 trials ได้ pet (dragon_mini trial 1, slime_blue trials 5/6/18, fox_fire trial 17)
ตรงกับ expected rate (Boss รวม ~15% chance per trial)

## Status

BUILD ✅ · STRICT ⚠️ roblox.d.luau missing (known issue, ไม่ blocking)
