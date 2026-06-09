# Death Valley Phase O — Friend Join, Push Hook & Preset Bazaar

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-N-CROSS-SERVER-SOCIAL.md`

---

## Phase O Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| O1 | **Teleport to Friend** | `TeleportToPlaceInstance` via presence `jobId` + `placeKey` |
| O2 | **Offline / Push Notify** | DataStore join digest + optional bridge → Open Cloud hook |
| O3 | **Preset Bazaar** | Public marketplace browse / publish / acquire / like |

---

## O1 — Join Friend

- Service: `DeathValleyFriendJoinService.luau`
- Remotes: `TeleportToFriend`, `GetFriendJoinPreview`
- Uses `DeathValleyFriendPresenceService` presence record
- TeleportData: `dvFriendJoin` · cooldown 45s
- UI: **Join** on Shared tab friends, friend-online toast, LFG friend tags

---

## O2 — Notifications

### In-game (always works)

- `DeathValleySocialNotifyService` — `socialNotifyQueue` in PlayerStore
- Queued on preset share (and bridge hook when opted in)
- `DeathValleyJoinDataService` — drain queue on join → `SocialNotifyDigest`
- Launch deep link: `LaunchData.utopiaPresetCode` or `UTOPIA-XXXXXXXX` auto-redeem

### Out-of-game push (optional)

Roblox **Experience Notifications** require Open Cloud from an external server — not available in-experience Luau alone.

- Bridge endpoint: `POST /utopia/social-notify/push` (queues to `bridge/data/social-notify-queue.jsonl`)
- Game posts when `notifyPrefs.pushOptIn == true`
- Configure `SOCIAL_NOTIFY_PUSH_URL` in `BridgeSecrets.luau`
- Wire Open Cloud sender separately (production)

Remotes: `GetSocialNotifyPreview`, `SetSocialNotifyPrefs`

---

## O3 — Preset Bazaar

- Service: `DeathValleyLoadoutPresetMarketService.luau`
- MemoryStore: sorted listings + detail map (7-day TTL)
- Remotes: `BrowsePresetMarket`, `PublishPresetMarket`, `AcquirePresetMarket`, `LikePresetMarket`, `GetPresetMarket`
- UI: **Bazaar** tab in unified wardrobe + plaza terminal `Preset Bazaar`
- Acquire → inbox (same ownership rules as Shared tab)

---

## Validation

```bash
rg "FriendJoin|PresetMarket|SocialNotify|TeleportToFriend|Preset Bazaar" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
curl -s http://127.0.0.1:8011/health
```

---

## Studio Test

1. Two clients · different cities · friend online toast → **Join**
2. Share preset while target offline → target joins → join digest toast
3. Publish slot to Bazaar · second player **Get** → Shared inbox
4. Launch with preset code in LaunchData (Studio test via TeleportData)
5. Enable Push in Bazaar tab · verify bridge queue file (if bridge running)
