# GDD — ระบบเช่าร้านค้าผู้เล่น (Player Shop Rental) + Hellbound Lore Update
> บันทึกจากบรีฟ Praphan 12 มิ.ย. 2026 · สถานะ: อนุมัติแล้ว — เริ่มเฟส A

## ✅ การตัดสินใจ (Praphan 12 มิ.ย. 2026)
- **รูปแบบรับเงินผู้ขาย: เครดิตในเกม (Shop Credit ledger)** — Robux ผู้ซื้อเข้าบัญชีเกมผ่าน Developer Products, ผู้ขายรับเครดิตในเกมตามราคาขาย ใช้ซื้อของ/สิทธิพิเศษในเกม (pattern DeathValleyCreatorRevenueService)
- **ส่งดีไซน์: ตู้ Decal ในเกม** — ผู้เล่นอัปโหลดภาพเป็น Decal บน Roblox → กรอก asset id ในตู้ส่งดีไซน์ → คิว Admin → สร้างไอเทมส่งให้ · **ห้ามใช้อีเมล/ชี้นำออกแพลตฟอร์ม** (ผลตรวจนโยบาย 12 มิ.ย.: Community Standards "Directing Users Off-Platform")
- ผลตรวจนโยบายฉบับเต็ม: ดูท้ายไฟล์ §3
> เกี่ยวข้อง: WORLD-GUIDE-CITIES.md · PrismCommerceConfig · DeathValleyCreatorRevenueService (pattern จ่ายส่วนแบ่ง)

## 1. ระบบเช่าร้านค้า — UtopiaPlaza + EternityTower

### 1.1 ที่อยู่ร้าน (Shop Address)
- ร้านทุกห้องในห้างทั้ง 2 อาคารมี **เลขชั้น + เลขห้อง** ติดหน้าร้านเหมือนบ้านเลขที่ เช่น `UP-3-07` (UtopiaPlaza ชั้น 3 ห้อง 07), `ET-2-04`
- มี **ป้ายชื่อร้าน** (ผู้เช่าตั้งเอง — ผ่าน TextService filter เสมอ)
- โครง: UtopiaPlaza mall 5 ชั้น (MALL_FLOORS=5) + EternityTower showroom F1-4 → กำหนด slot ร้านต่อชั้นตอน implement (builder สร้างห้องแถว + ป้าย)

### 1.2 โซนประเภทร้าน (แยกชัดเจน)
| โซน | สินค้า | อาคารแนะนำ |
|---|---|---|
| เสื้อผ้าเครื่องแต่งกาย | เสื้อ กางเกง รองเท้า ชุด | UP ชั้น 1-2 |
| เครื่องประดับ | สร้อยคอ แหวน ต่างหู ฯ | UP ชั้น 3 |
| สัตว์เลี้ยงน่ารัก | pets | UP ชั้น 4 |
| ยานพาหนะ | รถ เรือ ยานบิน | ET ชั้น 1-2 |
| สัตว์พาหนะ | mounts | ET ชั้น 3 |
| อาวุธ | ปืน ดาบ (PvE-only) | ET ชั้น 4 |
- ร้านในโซนใดขายได้เฉพาะหมวดของโซนนั้น (validate ฝั่ง server)

### 1.3 NPC ประชาสัมพันธ์ (Shop Promoter)
- ยืนที่ **จุดเกิดทุกแห่ง** (Sanctuary ทุก place ที่เกี่ยวข้อง — เริ่ม EternityCity)
- ประกาศข้อความเหนือหัวเป็นระยะ (BillboardGui วน text ทุก ~8 วิ)
- คุยแล้วเปิด **Dialog Q&A ที่ตั้งค่าไว้** (config table คำถาม→คำตอบ): ค่าเช่า, วิธีเช่า, ขายอะไรได้, ส่วนแบ่ง, วิธีส่งดีไซน์
- ปุ่มจบบทสนทนา: "พาไปดูห้องว่าง" → waypoint/teleport ไปห้างพร้อมไฮไลต์ห้องว่าง

### 1.4 การเช่า (Rent Flow)
- ผู้เล่นเดินดูห้องว่าง → ป้ายหน้าร้าน "ว่าง — กดเพื่อเช่า" → UI แสดงเลขห้อง/ชั้น/โซน/ราคา → **กดชำระ Robux ทันที** (Developer Product ราย tier ราคา)
- สัญญาเช่า: มีอายุ (เช่น 7/30 วัน — เลือกตอนกด) เก็บใน DataStore `ShopLease_v1` {ownerId, roomId, zone, expiresAt, shopName}
- หมดอายุ → ร้านกลับเป็น "ว่าง" สินค้าคืนเข้า inventory เจ้าของอัตโนมัติ
- ⚠️ ประเด็น Roblox: เงิน Robux จากการเช่า/ซื้อทั้งหมดเข้าบัญชีเกม (group) — ผู้เล่นผู้ขายรับเป็น **เครดิตในเกม + ระบบส่วนแบ่ง creator** (pattern เดียวกับ DeathValleyCreatorRevenueService/RequestCreatorPayout ที่มีอยู่) ไม่ใช่ Robux ตรง

### 1.5 สินค้าที่ขายได้
- ทุกไอเทมที่ระบบรู้จัก (catalog id): ของจากร้านเกม, ของดรอปจากบอส/โปสเตอร์, ของรางวัลกิจกรรม
- **Catalog ตั้งต้น = 58 เซ็ตแฟชั่นที่ออกแบบแล้ว** (Praphan ยืนยัน 12 มิ.ย. 2026 — จะสร้างเพิ่มต่อเนื่อง):
  | แหล่ง | จำนวน | โมดูล data | ภาพ concept |
  |---|---|---|---|
  | Teen Trend (DTI-style) | 30 เซ็ต | `TeenTrendFashionSets.luau` | `docs/visual-ref/fashion/teen-trend/` |
  | National (ชุดประจำชาติ 19 ปท. + Thai Heritage) | 20 เซ็ต | `NationalFashionSets.luau` | `docs/visual-ref/fashion/national/` |
  | Seasonal/Signature | 8 เซ็ต (43 ไอเทม) | `PrismFashionCatalog.luau` | `docs/visual-ref/fashion/concepts/` |
  - ใช้เป็นสินค้าโซน **Clothing (UP ชั้น 1-2)**: ขายในร้านเกม + ผู้เล่นซื้อแล้วนำไปวางขายต่อในร้านเช่า (escrow ตาม §1.7)
  - เฟส B ต้องรวม 3 โมดูลนี้เป็น **unified item catalog** (id → displayName, slot, zone, ราคา, ภาพ) แบบ data-driven — เพิ่มเซ็ตใหม่ได้โดยแก้เฉพาะโมดูล data ไม่แตะ service
- **ไอเทมดีไซน์เอง**: ผู้เล่นออกแบบเสื้อผ้า/เครื่องประดับ → ส่งภาพให้ Admin → Admin สร้างไอเทม + ส่งให้ผู้เล่นวางขาย
  - ⚠️ ช่องทาง "อีเมล" เสี่ยงผิด Roblox Community Standards (ห้ามพาผู้เล่นออกนอกแพลตฟอร์ม/แชร์ข้อมูลติดต่อ) — **ทางที่ปลอดภัย**: ผู้เล่นอัปโหลดภาพเป็น Decal บน Roblox (ผ่าน moderation ของ Roblox เอง) แล้วกรอก asset id ใน "ตู้ส่งดีไซน์" ในเกม → Admin เห็นคิวใน dashboard → สร้างไอเทม → ระบบส่งเข้า inventory ผู้เล่น · อีเมลใช้ได้เฉพาะช่องทางนอกเกม (Discord/กลุ่ม) ที่ผู้เล่น 13+ เข้าเองโดยเกมไม่ชี้นำ

### 1.6 การจัดวางสินค้า (Display Wall)
- สินค้าวางบน **ผนังร้าน** เป็นกริดช่องวาง (ShelfSlot) — แต่ละช่อง: ภาพสินค้า (decal/viewport) + ชื่อ + ราคา + สต๊อก
- จัดระเบียบด้วย **โฟลเดอร์หมวด** บนผนัง: เสื้อ / กางเกง / รองเท้า / เครื่องประดับ / สร้อยคอ / แหวน ฯ (header แถวละหมวด)
- เจ้าของร้านจัดผ่าน UI "จัดการร้าน": เลือกไอเทมจาก inventory → กำหนดช่อง + ราคา (tier) + จำนวน

### 1.7 สต๊อกจริง + กันโกง (สำคัญสุด)
- **Server-authoritative ทั้งหมด**: inventory + สต๊อกอยู่ DataStore ฝั่ง server เท่านั้น client เป็นแค่จอแสดง
- วางขาย = **ย้ายของออกจาก inventory ผู้ขายเข้า escrow ของร้าน** (ไม่ใช่ copy) — มี 1 ชุดขายได้ 1 ชุด
- ซื้อ = ProcessReceipt ยืนยันการจ่ายแล้วเท่านั้น → ตัด escrow → เข้ากระเป๋าผู้ซื้อ → เครดิตส่วนแบ่งผู้ขาย → ถ้า stock=0 ช่องว่าง
- กันปั๊มของ: ทุกไอเทม instance มี **uid เดียว** (GUID) ติดตัว, การย้ายทุกครั้งเป็น transaction (UpdateAsync + idempotency key จาก receiptId), RemoteGuard + rate limit ทุก remote, ห้าม client ส่งราคาหรือ id ของสินค้าที่ตัวเองไม่ได้ถือ, log ทุก transaction (audit trail), EconomyGuard ตรวจ pattern ผิดปกติ (ขาย-ซื้อวนเร็ว, ของ uid ซ้ำ = duplicate alert + freeze)

### 1.8 ลำดับ implement แนะนำ (3 เฟส)
1. **เฟส A — โครงร้าน**: เลขชั้น/ห้อง/ป้ายชื่อใน 2 ห้าง + DataStore lease + UI เช่า + Developer Products ค่าเช่า + NPC promoter
2. **เฟส B — ขายของ**: inventory uid system + display wall + ซื้อขาย escrow + ProcessReceipt + ส่วนแบ่ง creator ledger
3. **เฟส C — ดีไซน์เอง + ความปลอดภัย**: ตู้ส่งดีไซน์ (decal id) + admin queue + EconomyGuard duplicate detection + audit dashboard

## 2. Lore/กติกาที่ยืนยันเพิ่ม (อัปเดต World Guide แล้ว)
- NPC แลกกุญแจชื่อ **"วิญญาณวีรชน"** ล่องลอย **ด่าน 3-6** ด่านละ 10 นาที (เดิมเขียน 3-5)
- กุญแจ tier ตามเดิม: #1-5 fixed → สุ่ม 6-25 → มี #25 ปลด 26-40 → #40 ปลด 41-60 → #60 ปลด 61-80 → #80 ปลด 81-99 · แลก 3 ดอกใดก็ได้ = เลือก 1 ดอก
- **อาวุธระยะไกลทุกชนิดเป็น PvE-only**: ยิงได้เฉพาะ มอนสเตอร์/บอส/NPC — โจมตีผู้เล่นไม่ได้ · NPC อมตะ (ไม่รับ damage)
- Death Valley dungeon: โซน 2 คน → ลึกขึ้นทีมใหญ่ขึ้น → โซนสุดท้าย 50 คน, reward +10% ต่อโซน (ลึกสุด 200%), กุญแจ 1 ดอก/คน/โซน เมื่ออยู่ครบ+ทำบทบาท (เกณฑ์ตาม WORLD-GUIDE)
- บทบาททีม: Medic (ชุดกลุ่ม 50 ชิ้น=น้ำหนักเต็ม อาวุธเบา, รักษา 3 วิ 80%) · ชุดส่วนตัว (9 วิ 50%) · Heavy + Ammo Carrier · Trapper (ชะลอ/DoT/AOE)

## 3. ผลตรวจนโยบาย Roblox (12 มิ.ย. 2026)
- Developer Products เก็บค่าเช่า/ค่าสินค้า = ถูกนโยบาย (monetization มาตรฐาน, Roblox หัก ~30%)
- ToU ห้ามผู้เล่นรับ/แจกจ่าย Robux นอกช่องทางที่อนุญาต → ผู้ขายรับ Robux ตรงไม่ได้ → ใช้เครดิตในเกม (เลือกแล้ว) · group payout จ่ายมือทำได้ (สมาชิก ≥14 วัน + pending 72 ชม.) แต่ระบบจ่ายอัตโนมัติ = พื้นที่เทา
- ไอเทมขายต่อต้องไม่มาจากกล่องสุ่มที่ซื้อด้วยเงิน (simulated gambling) — ของดรอป/กิจกรรม = ผ่าน
- ห้ามอีเมล/ชี้นำออกแพลตฟอร์ม (Community Standards: Directing Users Off-Platform, Sharing Personal Information) → ใช้ตู้ Decal
- แหล่ง: about.roblox.com/community-standards · create.roblox.com/docs/production/monetization/developer-products · help.roblox.com ToU + DevEx ToU
