# GDD — Social & Voice System (P3-Social)
**โปรเจกต์:** Utopia of Eternity · **วันที่:** 12 มิ.ย. 2026 · **สถานะ:** ออกแบบ → เริ่ม implement
**การตัดสินใจ Praphan:** Voice = **Teleport-to-join** (เชิญเพื่อน → teleport มา server เดียวกัน → คุยเสียงได้จริง)

> เป้าหมาย: ให้เล่นสนุกแบบไม่ต้องพิมพ์คีย์บอร์ด (เหมือนยุคร้านเน็ต Ragnarok/Lineage/CS/SF + โปรแกรมคุยเสียง) — ปาร์ตี้/แคลนคุยสดได้ ปุ่มเปิด-ปิดไมค์ พร้อมระบบข้อความครบ

---

## 0. ข้อจำกัด Roblox ที่ออกแบบรอบไว้ (สำคัญ)
| เรื่อง | ความจริง Roblox | ทางออกในดีไซน์ |
|------|----------------|----------------|
| Voice ข้าม server/เมือง | **ทำไม่ได้** (voice = ใน server เดียว) | **Teleport-to-join**: รับเชิญ → teleport มา server เดียวกัน |
| Voice ต้องยืนยันอายุ | ผู้เล่นต้อง verify (ID 13+) | text ใช้ได้ทุกคน · voice = bonus เมื่อ verified · ถ้าไม่ verified ซ่อนปุ่มไมค์ + แจ้งเหตุผล |
| Voice เฉพาะกลุ่ม (ปาร์ตี้/โทร) | default เป็น spatial (ระยะ) | ใช้ **Audio API** (AudioDeviceInput/Output + Wires) route เสียงเฉพาะสมาชิกกลุ่ม |
| ข้อความข้าม server | cross-server chat live แล้ว + MessagingService | ใช้ MessagingService สำหรับ whisper/invite/presence ข้ามเมือง |

---

## 1. ระบบที่จะสร้าง (เป็น global — ทุกเมือง)

### 1.1 Friends & Presence (แจ้งเตือนออนไลน์)
- แจ้งเตือนเมื่อ **เพื่อน / สมาชิกกิลด์-แคลน เข้าเกม** (toast + เสียง — ปิดได้ใน settings)
- **reuse:** `DeathValleyFriendPresenceService` + `FriendPresenceToast` + `SocialJoinDigest` → ยกเป็น `Social/FriendPresenceService` (global)

### 1.2 Party (ปาร์ตี้)
- กลุ่มชั่วคราว อยู่ **server เดียวกัน** (เพื่อรองรับ voice) · หัวหน้าปาร์ตี้ · สูงสุด ~6-8 คน
- **ช่องแชทปาร์ตี้** (TextChatService custom channel) + **Party Voice** (push-to-talk)
- **reuse:** `DeathValleyLfgService`/`LfgInviteService`/`LfgCrossServerService` (party + invite ข้าม server มีแล้ว) → ยกเป็น `Social/PartyService`
- **⏱️ Teleport-to-join cooldown = 30 นาที/คน (Praphan 12 มิ.ย.):** การรับเชิญแล้ว teleport ข้ามเมืองมาหาเพื่อน มี cooldown **1800 วินาที** ต่อผู้เล่น — กันใช้เป็น "fast travel ฟรี" ข้ามเมืองรัวๆ (ไม่ให้ทำลายระบบค่าโดยสารเครื่องบิน P2) · ถ้ายังติด cooldown → แจ้ง "ต้องรออีก X นาที หรือใช้เครื่องบิน" · เก็บ `TeleportToJoinLastAt` (attribute/DataStore) · `SocialConfig.TeleportToJoinCooldownSeconds = 1800`

### 1.3 Guild / Clan (กิลด์/แคลน)
- กลุ่ม**ถาวร** (DataStore) · ชื่อ/ตรา/สมาชิก/ยศ (Leader/Officer/Member) · คลังกิลด์ (ภายหลัง)
- **ช่องแชทกิลด์** (cross-server text ผ่าน MessagingService) + **Guild Voice** (เมื่ออยู่ server เดียวกัน / จุดรวมพลกิลด์)
- ใหม่: `Social/GuildService` (+ `GuildStore` DataStore) — *งานใหม่หลัก*

### 1.4 Whisper (กระซิบ / ข้อความส่วนตัว)
- `/w <ชื่อ> <ข้อความ>` → ส่งหาเพื่อนไม่ว่าอยู่เมืองไหน (MessagingService) · ช่องแชทส่วนตัว
- ใหม่: `Social/WhisperService`

### 1.5 Voice — Push-to-Talk (Audio API)
- **ปุ่มเปิด/ปิดไมค์** (กดค้าง = พูด / toggle ได้) · ใช้กับ ปาร์ตี้ / แคลน / โทรส่วนตัว
- **ปุ่ม "โทร" ในทุกช่องแชท** (whisper/party/guild) → ขอคุยสด → อีกฝ่ายรับ → (ถ้าคนละ server) teleport มารวม → เปิด voice
- เทคนิค: `VoiceChatService` + Audio API (`AudioDeviceInput` ของผู้พูด → `Wire` → `AudioDeviceOutput` ของสมาชิกกลุ่ม) ตัด spatial ออกให้ได้ยินทั่วกลุ่ม
- ใหม่: `Social/VoiceChannelService` (server) + `VoiceControlUI` (client mic button)

### 1.6 Audio Settings (ตั้งค่าเสียง)
- สไลเดอร์/สวิตช์แยก: **เสียงระบบเกม (SFX)** · **เพลง (Music)** · **เสียงแจ้งเตือน** · **เสียงคุย (Voice)**
- ปิดเพลง/SFX/แจ้งเตือนได้เพื่อสมาธิ แต่ voice ยังได้ยิน (และกลับกัน)
- เทคนิค: SoundGroup แยก (Music/SFX/UI) + ปรับ Volume ต่อกลุ่ม · เก็บ preference ใน DataStore
- ใหม่: `Social/AudioSettingsService` + `AudioSettingsUI`

---

## 2. Slash Commands (ไม่ต้องเปิดเมนู)
| คำสั่ง | ผล |
|-------|-----|
| `/invite <ชื่อ>` | เชิญเพื่อนเข้าปาร์ตี้ (ข้ามเมืองได้ — รับแล้ว teleport มา) |
| `/w <ชื่อ> <ข้อความ>` หรือ `/whisper` | กระซิบส่วนตัว |
| `/call <ชื่อ>` | ขอคุยเสียงส่วนตัว |
| `/party` `/leave` | ดู/ออกปาร์ตี้ |
| `/guild <ข้อความ>` `/g` | แชทกิลด์ |
| `/p <ข้อความ>` | แชทปาร์ตี้ |
- เทคนิค: TextChatService **ChatCommands** (รองรับ `/` natively) + custom TextChannels

---

## 3. สถาปัตยกรรม (Modular — ServerScriptService/Social/ ใหม่)
```
ServerScriptService/Social/
  FriendPresenceService   (global — reuse DV)   · online notify
  PartyService            (reuse DV Lfg)         · party + invite + teleport-to-join
  GuildService + GuildStore (ใหม่)               · กิลด์/แคลนถาวร
  WhisperService          (ใหม่)                 · กระซิบ cross-server
  VoiceChannelService     (ใหม่)                 · Audio API route เสียงกลุ่ม
  AudioSettingsService    (ใหม่)                 · SoundGroup + preference
  SocialRemoteSetup.server / SocialHandlers.server
ReplicatedStorage/Modules/
  SocialConfig            · ขนาดปาร์ตี้, ยศกิลด์, ช่อง, fare teleport
StarterPlayer/StarterPlayerScripts/
  SocialHUD.client        · ปุ่มปาร์ตี้/กิลด์/เพื่อน, รายชื่อ, แชท
  VoiceControlUI.client   · ปุ่มเปิด/ปิดไมค์ + ปุ่มโทรในแชท
  AudioSettingsUI.client  · สไลเดอร์เสียง
```
- **ข้ามเซิร์ฟเวอร์:** MessagingService (invite/whisper/presence/guild chat)
- **teleport รวมตัว:** TeleportService (รับเชิญ/รับสาย → ย้ายมา server หัวหน้า)
- **server-authoritative + กันบอท/สแปม:** ผ่าน RemoteGuard + rate-limit (ต่อ P6)

---

## 4. นำ Engagement เกมคลาสสิกมาใช้ (Ragnarok/Lineage/Yulgang/CS/SF)
จากวิจัย: เกมเหล่านี้ดังเพราะ **community = "บ้านหลังที่สอง"** — guild politics/alliances, PvP, **castle siege (War of Emporium)**, สงครามกิลด์, ทัวร์นาเมนต์ในร้าน, ปาร์ตี้แกรินด์
| บทเรียน | ใช้กับ Utopia |
|--------|--------------|
| Guild war / castle siege (Ragnarok WoE, Lineage) | อีเวนต์**สงครามแคลน**ชิงพื้นที่/ธง (ต่อ P8) |
| Party grind ดันเจี้ยน | ปาร์ตี้ + voice ลุย Death Valley/MegaZone ด้วยกัน |
| Clan = สังคม/ตัวตน | ตรา/ยศ/แชท/voice แคลน + แจ้งเตือนสมาชิก |
| FPS ทีม (CS/SF) | โหมดทีม + voice push-to-talk สื่อสารเร็ว |
| ร้านเน็ต = เล่นด้วยกันต่อหน้า | teleport-to-join ให้เพื่อนมาอยู่ด้วยกันจริง |

---

## 5. แผน Implement (sub-phase — ทำทีละชิ้น ทดสอบก่อนไปต่อ)
| # | งาน | reuse? |
|---|-----|--------|
| **S1** | SocialConfig + ยก FriendPresence เป็น global (แจ้งเตือนเพื่อนออนไลน์ทุกเมือง) | reuse DV |
| **S2** | PartyService global + `/invite` + teleport-to-join + ช่องแชทปาร์ตี้ | reuse Lfg |
| **S3** | WhisperService `/w` cross-server + ช่องแชทส่วนตัว | ใหม่ |
| **S4** | GuildService + GuildStore + ช่องแชทกิลด์ + แจ้งเตือนสมาชิก | ใหม่ |
| **S5** | AudioSettings (SoundGroup + UI ปิดเพลง/SFX/แจ้งเตือน) | ใหม่ |
| **S6** | VoiceChannelService (Audio API) + ปุ่มไมค์ + ปุ่มโทร + `/call` | ใหม่ (เสี่ยงสุด — prototype) |
| **S7** | กันสแปม/บอท (rate-limit, RemoteGuard) + playtest | ต่อ P6 |

> Voice (S6) ทำท้ายสุด เพราะเสี่ยง/ต้องการ age-verify — text social (S1-S5) ใช้งานได้เต็มก่อน

---

## 6. จุดที่อาจต้องยืนยันภายหลัง
- ขนาดปาร์ตี้สูงสุด (เสนอ 6), จำนวนสมาชิกแคลนสูงสุด (เสนอ 50), ยศแคลน (Leader/Officer/Member)
- ค่าใช้จ่าย teleport-to-join: ✅ **ฟรี แต่ cooldown 30 นาที/คน** (Praphan ยืนยัน) — กันใช้แทนเครื่องบิน
- สร้างแคลนใช้อะไร (robux/กุญแจ/ฟรี?) — เสนอ robux เล็กน้อยกันสแปมแคลน

*จบ GDD — เริ่ม S1*
