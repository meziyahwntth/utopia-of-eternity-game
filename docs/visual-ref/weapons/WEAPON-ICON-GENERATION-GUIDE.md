# Weapon Icon Generation Guide — Utopia of Eternity
> สร้าง: 13 มิ.ย. 2026 | วัตถุประสงค์: Icons สำหรับ Radial Menu + Card/Rune UI

---

## ขั้นตอนภาพรวม

```
ChatGPT DALL-E 3 / Leonardo.ai  →  Krea.ai Upscale 4K  →  Roblox Asset Manager
(Generate icon)                      (UpRes + sharpen)       (Upload as Image/Decal)
```

---

## Platform Settings

### Leonardo.ai (แนะนำ — ผลดีที่สุดสำหรับ game icons)
- **Model:** Leonardo Kino XL หรือ Phoenix
- **Dimensions:** 1024×1024 (สี่เหลี่ยม)
- **Guidance:** 7–8
- **Steps:** 30–40
- **Negative Prompt (ใส่ทุกครั้ง):**
  ```
  blurry, watermark, text, signature, frame, border, realistic photo, hands, human figure, low quality
  ```

### ChatGPT DALL-E 3
- เลือก **Square (1:1)** ทุกครั้ง
- Style: **Vivid**
- วางแค่ prompt block ด้านล่างได้เลย

---

## Icon Prompts — Wave 2 Weapons (Priority Order)

> **Style suffix** — ต่อท้ายทุก prompt:
> `game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed`

---

### 1. `weapon-eternity-blade-icon.png` ★★★★★ (Mythic)
```
Legendary longsword floating upright, white pearl blade with gold filigree patterns, prism crystal core emitting rainbow light diffraction, ornate gold crossguard, glowing edge aura, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 2. `weapon-void-cleaver-icon.png` ★★★★
```
Massive greatsword floating upright, obsidian black blade with purple void energy cracks glowing, dark void mist flowing from edges, heavy ornate dark handle, rune engravings, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 3. `weapon-prism-railgun-icon.png` ★★★★ (LMG)
```
Futuristic LMG railgun, white and gold body, rainbow prismatic energy coils along barrel, glowing crystal power cell, holographic sight, sleek sci-fi fantasy design, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 4. `weapon-void-cannon-icon.png` ★★★★
```
Heavy shoulder-mounted fantasy cannon, black matte metal with purple singularity void energy swirling in barrel, ornate dark engravings, ominous glow, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 5. `weapon-sakura-katana-icon.png` ★★★★
```
Elegant katana floating upright, pale pink translucent blade with cherry blossom petal etching, rose gold and gold tsuba guard, silk wrapped handle, faint falling sakura petals, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 6. `weapon-celestial-longbow-icon.png` ★★★★
```
Fantasy longbow, golden body with star constellation patterns glowing, arrow of pure white light nocked, stardust particle trail, glowing limb tips, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 7. `weapon-prism-crystal-staff-icon.png` ★★★
```
Tall mage staff floating vertically, large rainbow-refracting crystal prism orb at top, gold filigree staff body, glowing arcane runes, magical light beams radiating, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 8. `weapon-eternal-staff-divine-icon.png` ★★★
```
Divine holy staff floating vertically, pure white crystal top with golden angel wings spread, golden staff body with feather engravings, radiant holy light halo, celestial glow, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 9. `weapon-cathedral-greatsword-icon.png` ★★★★
```
Enormous cathedral-style greatsword, dark charcoal blade with golden cross inlays, orange fire aura burning along edges, gothic ornate handle with gems, imposing fantasy weapon, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

### 10. `weapon-solar-hammer-icon.png` ★★★★
```
Massive fantasy warhammer, golden head with sunburst relief carvings, blazing solar fire energy emanating from striking face, heavy stone-and-gold shaft, earth-cracking aura, game inventory icon, dark navy vignette background, centered weapon, dramatic rim light, no text, square format, ultra-detailed
```

---

## หลัง Generate เสร็จ

### Krea.ai Upscale (ทุกภาพ)
1. ไปที่ **krea.ai → Upscale**
2. Upload PNG ที่ได้
3. เลือก **4x upscale** + **Creative Enhance**
4. Download → บันทึกทับไฟล์เดิม

### นำเข้า Roblox Studio
1. **Asset Manager** → ปุ่ม **Upload** (↑) → เลือกทุกไฟล์พร้อมกัน
2. Type: **Image**
3. คัดลอก Asset ID ที่ได้ → วางใน `WeaponConfig.luau` แต่ละ weapon ช่อง `iconId`

---

## ไฟล์บันทึก

เซฟ PNG ทั้งหมดลงใน:
```
docs/visual-ref/weapons/icons/
```
