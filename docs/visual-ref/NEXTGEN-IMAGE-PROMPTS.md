# Next-Gen Art — ChatGPT/DALL·E 3 Image Prompts (เมือง · รถ · เผ่า)

> 15 มิ.ย. 2026 · ใช้กับ pipeline `AI-ASSET-WORKFLOW.md` · กฎเหล็ก `feedback-graphics-benchmark`: **ต้องสวยกว่า/เทียบเท่า benchmark ก่อน deploy**
> วิธีใช้: วางใน **ChatGPT Pro (DALL·E 3)** เพื่อได้ concept + **orthographic reference** → ผลิตจริงด้วย Leonardo.ai/Midjourney v6 → Krea upscale 4K-8K → (3D) Meshy/Tripo → Blender → MeshPart · (texture) NormalMap-Online → SurfaceAppearance · (skybox) Blockade Labs
> **เคล็ด:** สำหรับงาน 3D ขอภาพเป็น "orthographic, front/side/top, neutral grey background, even lighting, no shadows" เพื่อ Meshy/Tripo แปลงแม่น

## 0. STYLE BIBLE (วางนำหน้าทุก prompt เพื่อความเป็นเอกภาพ)
```
Art direction: Next-Gen stylized-realism for a premium mobile MMORPG, PBR materials
(physically based: albedo + normal + roughness + metalness), cinematic global illumination,
volumetric light, crisp readable silhouettes for small mobile screens, AAA game key-art quality,
cohesive color script per district, 8K, ultra-detailed. NOT classic blocky Roblox.
```

---

## 1. เมือง (Environment concept + skybox + PBR) — 5 districts

### NeonUtopia (Human · เมืองแข่งรถหลัก) — beat **Velocity Outlast**
```
[STYLE BIBLE] Wide establishing key-art of a neon-cyberpunk human megacity at golden-hour
turning to night: glossy wet asphalt race boulevards, holographic billboards, glass skyscrapers
with emissive trim, elevated highway loops, a start/finish racing arch. Reflective puddles,
chromatic neon reflections, light rain. Mood: electric, aspirational. Must look better than
Velocity Outlast. 16:9 cinematic.
```
- Skybox (Blockade): `360 equirectangular HDRI, neon cyberpunk city dusk, magenta-cyan gradient sky, distant skyline glow`
- PBR textures: `wet asphalt`, `brushed metal guardrail`, `holographic glass` (flat tileable → NormalMap-Online)

### Solhaven (Elf · cozy/sanctuary) — beat **Grow a Garden / Adopt Me** (ความอบอุ่นน่าอยู่)
```
[STYLE BIBLE] Sun-drenched eternal-day elven sanctuary town: warm golden light, white-and-gold
organic architecture woven with living trees, flower gardens, gentle waterfalls, cozy market
stalls, floating lanterns. Mood: serene, welcoming, wholesome. Cohesive warm pastel palette.
```
- Skybox: `360 HDRI, eternal warm sunny day, soft golden clouds, gentle bloom`
- PBR: `polished white marble with gold inlay`, `mossy stone`, `flower-bed soil`

### Nocturne Alley (Dark Elf · nightlife/PvP) — beat **Blox Fruits / club games**
```
[STYLE BIBLE] Perpetual-twilight neon back-alley nightlife district: narrow streets, dense
neon signage (purple/teal), steam vents, rooftop drift-race track, graffiti, dark-elf banners.
Mood: mysterious, edgy, electric. Deep shadows + saturated neon rim light.
```
- Skybox: `360 HDRI, eternal twilight, deep indigo sky, distant city neon haze, faint stars`
- PBR: `rain-slick cobblestone`, `neon-lit brick`, `graffiti metal shutter`

### EternityCity (Alien · flagship เมืองลอยฟ้า) — **beat Nexus** (กราฟิกหน้าตาเกม สำคัญสุด)
```
[STYLE BIBLE] Breathtaking floating utopian city above a sea of clouds at golden dawn:
advanced alien-elegant architecture, soaring spires, sky bridges, marina with luminous water,
aurora ribbons in sky, hyperspace gate landmark. Mood: transcendent, awe-inspiring, sacred-tech.
This is the game's hero shot — must surpass Nexus (Roblox Connect 2023 winner) in lighting,
reflections, texture detail.
```
- Skybox: `360 HDRI, dawn above clouds, golden + aurora ribbons, god rays`
- PBR: `iridescent alien alloy`, `luminous marble`, `energy-vein glass`

### DeathValley / Hellbound (Orc สูญพันธุ์ · horror) — beat **DOORS / The Mimic / Pressure** (atmosphere ไม่เน้น gore)
```
[STYLE BIBLE] Eternal-night ruined orc homeworld valley on a dead volcanic planet: shattered
monolithic orc architecture, cooling lava cracks glowing dim red, ash fog, sandstorm haze,
broken statues of fallen orc warlords, faint ghostly wraith light. Mood: oppressive dread,
mournful, mysterious — atmospheric horror NOT gore. Restricted visibility, heavy fog.
```
- Skybox: `360 HDRI, eternal night, ash-choked sky, dim blood-red horizon glow, no stars`
- PBR: `cracked volcanic basalt with ember glow`, `ancient carved orc stone`, `ash-covered ground`

---

## 2. รถ (NeonUtopia racing) — beat Velocity Outlast
```
[STYLE BIBLE] Orthographic product shots (front, side, rear, 3/4) of a futuristic hypercar,
neutral grey studio background, even lighting, no harsh shadows — for 3D reconstruction.
Sleek aerodynamic body, glossy candy-red paint with carbon-fiber accents, glowing underglow,
detailed wheels/brakes. Clean readable silhouette. 4 separate views.
```
- เพิ่มชุดสี/รุ่นตาม Grandeur Rank: `same car, common→legendary trims (matte→chrome→holographic)`
- → Meshy/Tripo (PBR maps) → Blender ลด poly mobile → MeshPart

## 3. เผ่า (4 playable) — character concept บนทรง mesh-body จริง
> หมายเหตุ: avatar ในเกม = Roblox skinned mesh → ขอภาพ "orthographic T-pose, front+side, neutral background" เพื่อทำ mesh/แมป wearable. โทนตรง STYLE BIBLE
```
[STYLE BIBLE] Orthographic character sheet (front + side, T-pose, neutral grey bg, even light):
- Human: athletic techwear human, neon-city styling
- Elf: tall graceful high-elf, light/gold robes, nature motifs
- Dark Elf: lithe dark-elf, dark armor with neon-purple runes, hooded
- Alien: elegant humanoid alien, iridescent skin, bio-luminescent tech accents
Consistent proportions across all 4 for one shared skeleton. Stylized-realism, PBR-ready.
```

## 4. ไอเทม/ไอคอน (UI) — คมชัด mobile + สไตล์เดียวกัน
```
[STYLE BIBLE] Game item icon, centered on transparent/neutral bg, bold readable silhouette,
soft inner glow, consistent rim-light, mobile-legible at 80px. Subject: <weapon/card-rune/skill>.
```
- ใช้ Cursor batch ผลิตชุด → Krea upscale → Asset Manager (Cowork ทำ batch prompt + อัปโหลด/wire)

---

## ลำดับใช้งาน
1. Praphan/Cursor เจนภาพตาม prompts (env hero shots ก่อน — โดยเฉพาะ EternityCity = หน้าตาเกม)
2. ตัดสินผ่าน benchmark (ไม่ชน = เจนซ้ำ/ปรับ ไม่ deploy)
3. Cowork: ทำ Cursor batch สำหรับ icon, อัปโหลด Asset Manager, ดึง ID, wire catalog, import MeshPart, จัดวาง, publish, verify
4. บันทึกชื่อไฟล์ตาม catalog field (`conceptArtFile`/`refImage`/`icon`/`iconAssetId`)
