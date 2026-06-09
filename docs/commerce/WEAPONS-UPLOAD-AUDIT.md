# Weapon Upload Audit — รอบ 1 vs รอบ 2

> สร้างหลัง feedback ผู้ใช้: ควรถามเรื่องภาพซ้ำก่อน merge เข้า catalog

## สรุปผลตรวจ (MD5)

| ผล | รายละเอียด |
|----|------------|
| **อาวุธ unique ใน catalog** | **13 ชิ้น** (ไม่มี pixel ซ้ำข้าม id) |
| **ไฟล์ซ้ำ 100%** | รอบ 1 (ChatGPT ชื่อ timestamp) = รอบ 2 (ชื่อไฟล์) — **bytes เหมือนกันทุกไฟล์** |
| **อาวุธ unique ที่หาย** | **0** — ไม่มีภาพอาวุธรอบ 1 ที่ยังไม่ได้ลง catalog |
| **ภาพ 17:xx ChatGPT** | เป็น **เมือง/ยานพาหนะ** (Eternity City) — **ไม่ใช่อาวุธ** |

---

## Timeline ที่ reconstruct ได้

### รอบ 1 (~8 มิ.ย. 19:01–19:34) — อาวุธ melee ไม่มีชื่อในไฟล์

| Timestamp | MD5 ตรงกับ | ชื่อที่ใช้ใน catalog ตอนนี้ |
|-----------|------------|---------------------------|
| `19_01_28` | Immortal Sword | `immortal_sword` |
| `19_05_21` | Thor's Hammer | `thors_hammer` |
| `19_08_58` | Blood Knife | `blood_knife` |
| `19_12_50` | Heavenly Sword | `heavenly_sword` |
| `19_16_29` | Demon-Slaying Spear | `demon_slaying_spear` |
| `19_28_51` | Demon Slayer Sword | `demon_slayer_sword` |
| `19_34_35` | Goddess Fan | `goddess_fan` |

### รอบ 2 (~9 มิ.ย.) — อัปโหลดชื่อไฟล์ + ปืนครบ

ไฟล์ `Blood Knife`, `Heavenly Sword`, … **byte ตรงกับรอบ 1 ทุกคู่** (อัปซ้ำ ไม่ใช่ art ใหม่)

ชื่อที่ลืมในรอบ 2 แล้วมาแจ้งในแชท:
- `Thor's hammer-….png` = ซ้ำ `19_05_21`
- `Immortal Sword-….png` = ซ้ำ `19_01_28`

### ปืน (รอบ 2 — ชื่อครบตั้งแต่แรก)

`M16`, `AK-47`, `M4A1`, `Machine Gun`, `Bazooka`, `Bazuka` — **1 ไฟล์ต่อ 1 ชนิด ไม่มี duplicate ใน source**

---

## สิ่งที่ agent ทำผิด (ควรทำก่อน merge)

1. **ไม่ถาม** ว่ามี 2 รอบอัปโหลด
2. **ไม่รัน hash dedup** ก่อนสร้าง catalog
3. **เดาชื่อ** `Longsword` จาก `19_01_28` แทนที่จะถาม → แก้เป็น Immortal Sword แล้ว
4. **สับสน** ChatGPT 17:xx (เมือง) กับ 19:xx (อาวุธ)

---

## Catalog ปัจจุบัน (13 unique)

ดู `manifest.json` + `PrismLegendaryWeaponsCatalog.luau`

**ดาบ 3:** Immortal Sword (light) · Demon Slayer Sword (heavy) · Heavenly Sword (heavy)  
**หอก 1:** Demon-Slaying Spear  
**พัด 1:** Goddess Fan  
**ค้อน 1:** Thor's Hammer  
**มีด 1:** Blood Knife  
**ปืน 6:** M16 · AK-47 · M4A1 · Machine Gun · Bazooka · Bazuka  

---

## ถ้าต้องการ art เพิ่ม

ถ้าคุณ **ตั้งใจ** ให้รอบ 1 / 2 เป็นคนละภาพ (ดาบ/หอก/พัดคนละแบบ) แต่ไฟล์ที่อัปมาเป็น pixel เดียวกัน — ต้อง **generate / อัปโหลดไฟล์ใหม่** แล้วแจ้งชื่อ

---

## ขั้นตอนบังคับก่อนเพิ่มอาวุธครั้งถัดไป

```bash
# ใน assets/weapons/generated/
md5 *.png | sort
# ถามผู้ใช้: รอบนี้แทนของเดิมหรือเพิ่มใหม่?
# อัปเดต manifest.json + PrismLegendaryWeaponsCatalog.luau พร้อมกัน
```
