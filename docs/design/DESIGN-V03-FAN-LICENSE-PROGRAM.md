# Eternity Forge — Fan License Program (V03)

**Game:** Utopia of Eternity · **Program:** Eternity Forge · **Version:** 0.3.0  
**Status:** Design + server-side scoring scaffold (`FanExperienceGuard.luau`)

---

## 1. Purpose

Detect fan-made Roblox experiences that use Utopia IP, route them through compliance review, and offer **licensed partnership** (revenue share + premium cosmetic catalog) instead of only DMCA takedowns.

---

## 2. Detection Pipeline

```
Bridge cron (FAN_SCAN_URL)
  → keyword match (GameConfig.FanLicense.IpKeywords)
  → CCU / visits thresholds (GameConfig.Security)
  → policy flag scan
  → FanExperienceGuard:Evaluate()
  → LogExportBridge → offline AI review queue
  → human: warn | license offer | DMCA
```

**In-game:** players can report fan games via Support Desk; reports enqueue the same log channel.

---

## 3. Verdicts

| Verdict | Meaning | Action |
|---------|---------|--------|
| `UNLICENSED_OK` | Low score, no monetization | Monitor only |
| `PARTNER_ELIGIBLE` | IP match + monetization, clean policy | Offer Eternity Forge tier |
| `REVIEW` | High CCU/visits or ambiguous | Manual review |
| `VIOLATION` | Policy red flags + high score | Warn → DMCA if unresolved |

---

## 4. Eternity Forge Tiers

| Tier | CCU | Revenue share | Catalog |
|------|-----|---------------|---------|
| **Forge Apprentice** | 0–1K | 10% | Basic asset kit |
| **Forge Artisan** | 1K–10K | 20% | Radiant skins, glow weapons |
| **Forge Master** | 10K+ | 25% | Master bundle + aura pass |

Default share when tier unspecified: **15%** (`GameConfig.FanLicense.DefaultRevenueSharePercent`).

---

## 5. Premium Licensed UGC (cosmetic only)

| Item | Robux range | Notes |
|------|-------------|-------|
| Radiant Skin | 499–999 | Glow variants, no stat bonus |
| Prism Weapon FX | 799–1,499 | VFX only |
| Eternity Aura Pass | 1,999–4,999 | Seasonal aura |
| Master Bundle | 2,999–9,999 | Limited drops |

**Rule:** No pay-to-win claims; all items cosmetic. Enforced via `PolicyRedFlags`.

---

## 6. Policy Red Flags

- `official_p2w_claim` — implies official P2W
- `asset_rip` — stolen meshes/audio from main game
- `external_robux_trade` — off-platform Robux sales
- `adult_content` — age-inappropriate content
- `impersonate_official` — fake “official” branding

---

## 7. Roblox License Manager

After main experience publish:

1. Register **Utopia of Eternity** trademark/wordmark in [Roblox License Manager](https://create.roblox.com/dashboard/creations/experiences/licensing).
2. Map Eternity Forge tiers to licensed creator groups.
3. Distribute premium UGC through official group catalog only.

---

## 8. Code References

- `GameConfig.FanLicense` — tiers, keywords, catalog pricing
- `GameConfig.Bridge.FAN_SCAN_URL` — Bridge endpoint (set in production secrets)
- `FanExperienceGuard.luau` — scoring + log export
- `SecurityCore.server.luau` — init + `_G.UtopiaSecurity.FanExperienceGuard`

---

## 9. Naming (post city rebrand)

| Display | Code key |
|---------|----------|
| Utopia of Eternity (flagship city) | `Places.EternityCity` |
| หุบเขามรณะ | `Places.DeathValley` |
| Eternity Sanctuary | `Sanctuary.Names.EternityCity` |
| จุดไฟชีวิต | `Sanctuary.Names.DeathValley` |
