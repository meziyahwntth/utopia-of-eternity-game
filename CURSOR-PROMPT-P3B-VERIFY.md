# CURSOR PROMPT — P3-B Clan Core: rojo build + luau-lsp verify

> สร้าง: 13 มิ.ย. 2026 · commit หลังจาก addd02d (P3-B WIP)
> งานที่เพิ่งเสร็จ: project.json + SocialHandlers wire + GuildClient เขียนแล้ว

## งานที่ทำเสร็จแล้ว (Cowork เขียน)

| ไฟล์ | สถานะ |
|------|--------|
| `default.project.json` | เพิ่ม Social/GuildStore + Social/GuildService แล้ว |
| `src/ServerScriptService/Social/SocialHandlers.server.luau` | wire guild remotes ทั้งหมด + GuildService.init() |
| `src/StarterPlayer/StarterPlayerScripts/GuildClient.client.luau` | ใหม่ — /clancreate /claninvite /clanleave /clan + popup + panel |

## สิ่งที่ต้องทำ (Cursor รัน)

### 1. rojo build

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p3b-verify.rbxlx
```

**ต้องการ:** `rojo build` สำเร็จ (ไม่มี error ใด ๆ)

### 2. luau-lsp analyze (strict mode)

```bash
luau-lsp analyze \
  --definitions=roblox.d.luau \
  src/ServerScriptService/Social/SocialHandlers.server.luau \
  src/ServerScriptService/Social/GuildService.luau \
  src/ServerScriptService/Social/GuildStore.luau \
  src/StarterPlayer/StarterPlayerScripts/GuildClient.client.luau
```

**ต้องการ:** ไม่มี error (warning ได้ถ้าไม่ใช่ type error)

### 3. ตรวจสอบเพิ่มเติม (manual)

- GuildStore + GuildService อยู่ใน Social folder ใน rbxlx หรือไม่ (ใช้ Rojo Studio หรือ file-tree ใน rbxlx)
- GuildClient.client.luau อยู่ใน StarterPlayerScripts หรือไม่

### 4. git commit (ถ้าผ่านทุกข้อ)

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
git add -A
git commit -m "P3-B Clan core: wire SocialHandlers + GuildClient + project.json"
```

### 5. รายงานกลับ

วาง output ของ rojo build + luau-lsp ทั้งหมดในหน้าต่าง Cowork ใหม่ พร้อมระบุ:
- ✅ BUILD OK / ❌ BUILD FAIL (ระบุ error)
- ✅ STRICT CLEAN / ❌ TYPE ERRORS (ระบุ error พร้อม line)
- commit hash ถ้า commit สำเร็จ

---

## ดูตัวอย่างก่อนหน้า

`CURSOR-PROMPT-P3A-VERIFY.md` — pattern เดียวกัน ใช้เป็น reference ได้
