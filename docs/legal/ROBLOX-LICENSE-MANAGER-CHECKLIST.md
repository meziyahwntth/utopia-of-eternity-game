# Roblox License Manager — Post-Publish Checklist

**Game:** Utopia of Eternity · **Program:** Eternity Forge  
**When:** หลัง publish experience หลักบน Roblox แล้วเท่านั้น

---

## 1. ลงทะเบียน IP ใน License Manager

1. เปิด [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations)
2. เลือก Universe **Utopia of Eternity**
3. ไปที่ **Monetization → Licensing** (License Manager)
4. ลงทะเบียน:
   - ชื่อเกม: **Utopia of Eternity**
   - คำสำคัญ: `Utopia Plaza`, `Luminling`, `Prism Key`, `หุบเขามรณะ`, `Solhaven`, `Nocturne Alley`
5. บันทึก license policy สำหรับ fan games (อนุญาต cosmetic fan use ผ่าน Eternity Forge เท่านั้น)

---

## 2. Eternity Forge — Licensed Creator Tiers

| Tier | เงื่อนไข | Revenue share |
|------|----------|---------------|
| Forge Apprentice | CCU &lt; 1K | 10% |
| Forge Artisan | 1K–10K CCU, like ratio ≥ 0.8 | 20% |
| Forge Master | CCU ≥ 10K | 25% |

Premium UGC ผ่าน official group catalog เท่านั้น (499–9999 Robux, cosmetic only).

---

## 3. Fan Game Workflow

```
Bridge cron → PUT /utopia/fan-scan (candidates)
     ↓
Roblox FanScanBridge poll → FanExperienceGuard score
     ↓
LogExportBridge → AI review queue
     ↓
Human: warn | license offer | DMCA
```

---

## 4. Pre-publish (ทำก่อน License Manager)

- [ ] Roblox search ชื่อเกม + เมือง (ไม่มี duplicate)
- [ ] Place IDs ใส่ใน `PlaceSecrets.luau`
- [ ] `BridgeSecrets.luau` ชี้ production Bridge URL
- [ ] HttpService enabled
- [ ] ทุก mesh/audio มี provenance

---

## 5. Post-publish (หลัง License Manager)

- [ ] เปิด fan-scan cron บน Bridge
- [ ] ทดสอบ `GET /utopia/fan-scan` จาก game server
- [ ] ประกาศ Eternity Forge ใน DevForum / Discord partner channel
- [ ] อัปเดต `utopiaofeternity.com` Terms เรื่อง licensed fan content

---

## Reference

- `docs/DESIGN-V03-FAN-LICENSE-PROGRAM.md`
- `docs/IP-AUDIT-UTOPIA-OF-ETERNITY.md`
- [Roblox Licensing docs](https://create.roblox.com/docs/production/publishing/licensing)
