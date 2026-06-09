# Death Valley Phase N — Cross-Server Social Loadout

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-M-PRESET-SHARE-PLAZA.md`

---

## Phase N Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| N1 | **Cross-Server Preset Notify** | MessagingService `UtopiaDV_PRESET_SHARE_v1` · toast + inbox refresh |
| N2 | **Share Code / Link** | `UTOPIA-XXXXXXXX` · MemoryStore 24h · redeem → inbox |
| N3 | **Solhaven + Nocturne Plaza** | `LoadoutPlazaKit` + mirror auto-rotate |
| N4 | **Friend Online + City** | MemoryStore presence · join toast · LFG/Shared UI tags |

---

## N1 — Cross-Server Preset Notify

- `DeathValleyLoadoutPresetShareService` publishes when target offline on server
- RemoteEvent: `PresetShareReceived`
- Attribute: `DV_PresetShareMsg` (same as Phase M)

---

## N2 — Share Code

- Remotes: `GeneratePresetShareCode`, `RedeemPresetShareCode`, `GetActivePresetShareCodes`
- MemoryStore: `UtopiaDV_PresetCode_v1` (TTL 24h)
- PlayerStore: `activeShareCodes` (max 5)
- UI: Shared tab → Redeem box + Generate Code

---

## N3 — Plaza Expansion

| Place | Builder | Origin |
|-------|---------|--------|
| Solhaven | `SolhavenWorldBuilder` | `(0, 0, -18)` |
| Nocturne | `NocturneWorldBuilder` | `(0, 0, 18)` |

`LOADOUT_WORLDS` + mirror wiring includes `UtopiaSolhaven`, `UtopiaNocturne`.

---

## N4 — Friend Presence

- Service: `DeathValleyFriendPresenceService.luau`
- MemoryStore: `UtopiaDV_Presence_v1` (180s TTL, 60s heartbeat)
- MessagingService: `UtopiaDV_PRESENCE_v1`
- RemoteEvent: `FriendPresenceNotify`
- Client toast: `DeathValleyFriendPresenceToast.client.luau`
- Friends list fields: `online`, `placeKey`, `placeDisplayName`

---

## Validation

```bash
rg "FriendPresence|PresetShareCode|GeneratePresetShare|UtopiaSolhaven|UtopiaNocturne" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
```

---

## Studio Test

1. Two clients, different `SimulatePlaceKey` (Hub + Eternity City)
2. Share preset → cross-server toast on target
3. Generate code on A → redeem on B
4. Friend joins → toast shows city name
5. Solhaven/Nocturne: wardrobe terminal + rotating mirror
