# DBM-Onyxia

Deadly Boss Mods pack for **Onyxia's Lair**. It loads on demand when DBM needs this zone and includes two boss modules: **Onyxia** and **Basalthane**.

---

## Basalthane module — summary

`Basalthane.lua` targets **Basalthane** (NPC **10185**). Combat is detected with `RegisterCombat("combat")` when you enter combat with that creature.

### Announcements and special warnings

| Event | Behaviour |
|--------|------------|
| **Annihilation Strike** (2108206) | Spell announce on cast start. |
| **Inferno Trail** (2108217) | Spell announce on cast start. |
| **Eruption** (2108227) | Spell announce on cast start. |
| **Fierce Blow** (975011) | Target announce on the player hit (cast success). |
| **Flash Burn** (2108201) | Special warning **you** when the debuff is applied to you (boss as source). |
| **Magma Pool** (2108233) | Special warning **you** when the ground debuff from Eruption applies to you; sends a **/yell** using the configured phrase (default: “Eruption on me!”). |

### Cast bars

Bars for the time from **cast start** to expected impact (values tuned from combat logs):

- Annihilation Strike — 3 s  
- Inferno Trail — 3 s  
- Eruption — 5 s  

### Cooldown / “next” timers

Timers are aligned to observed log timings; boss movement or pillar phases can shift real casts slightly.

| Timer | Role |
|--------|------|
| **First Annihilation Strike** | Time from pull to the first Annihilation Strike cast start (~3 s). |
| **Next Annihilation Strike** | Repeating cadence after each Annihilation cast start (~18 s); after **Eruption** starts, the next Annihilation timer is pushed to ~11 s from that cast. |
| **Next Inferno Trail** | Seeded on pull (~6 s after pull), then ~14 s between Inferno casts; first cycle after the first Annihilation uses a shorter Inferno delay (~3 s), later cycles use ~11 s after Annihilation until the pattern resets on the next Inferno line. |
| **Next Fierce Blow** | ~7.5 s between casts; first bar ~10.3 s from pull. |
| **Next Eruption** | ~56 s between Eruption casts; first Eruption bar ~48 s from pull. |

*(Exact constants live at the top of `Basalthane.lua` if you need to tweak them.)*

### Pillar phase — boss “stun” bar

When a **Volatile Pillar** dies, the combat log shows Basalthane applying **Cracked Armor** (spell **2108234**) to **himself**. That moment is treated as the start of a **~20 s** window where the boss effectively stops his normal cast rhythm (no separate “Stun” aura was used in the reference logs).

- **On apply** (boss source and destination, same unit): a **buff/active** bar runs for **20 seconds** (label: “Basalthane stunned (pillar)” in English).  
- **On remove** of that debuff on the boss: the bar is **cancelled** early if the aura drops before 20 s.

If your live server uses a different duration, change `pillarStunDuration` (and optionally the `TimerPillarStun` string in `localization.en.lua`).

### Test pull timers (out of combat)

The Basalthane DBM panel includes a **misc** button: **“Test pull timers (short preview)”**.

- **Only usable while not in combat.** If you are in combat, DBM prints a short message and does nothing.  
- Starts the same pull timers as `OnCombatStart` (with zero delay), runs for **12 seconds**, then calls `Stop()` on the mod if you are still not in combat (clears preview bars).  
- Useful for checking bar layout and which toggles are enabled without pulling the boss.

---

## Instructions

### Requirements

- **DBM-Core** (see `DBM-Onyxia.toc`: `RequiredDeps: DBM-Core`).  
- Interface version in the `.toc` must match your client (currently **30300** in this repo).

### Installation

1. Copy the **`DBM-Onyxia`** folder into your WoW `Interface\AddOns` directory (same layout as in this repository).  
2. Ensure **DBM-Core** is installed and enabled.  
3. Restart the client or `/reload`.  
4. In the AddOns list, enable **DBM-Onyxia** (and DBM-Core).

### Loading and options

- This pack is **Load on Demand** (`LoadOnDemand: 1`). DBM loads it when you are in **Onyxia's Lair** (see `X-DBM-Mod-LoadZone` in the `.toc`).  
- Open **DBM → Options → Raid mods** (or your client’s equivalent path), find **Onyxia's Lair**, then select **Basalthane**.  
- Enable or disable each timer, warning, and the pillar stun bar as usual.  
- Two separate toggles control **first** vs **next** Annihilation Strike timers so labels stay clear even though both use the same spell id.

### Localization

- Default strings for Basalthane live in **`localization.en.lua`** under the `Basalthane` section (`SetGeneralLocalization`, `SetTimerLocalization`, `SetOptionLocalization`, `SetMiscLocalization`).  
- To support another locale, add a file (for example `localization.de.lua`) and list it in **`DBM-Onyxia.toc`** in the correct load order (localization before `Onyxia.lua` and `Basalthane.lua`).

### Tuning from new logs

Timers and constants in `Basalthane.lua` were derived from a specific combat log (`logs/2026-04-16-18.04.22 WoWCombatLog.txt` referenced in the file header). If Blizzard changes timings or spell ids:

1. Update the numeric constants and/or spell ids at the top of **`Basalthane.lua`**.  
2. Adjust **`localization.en.lua`** if option descriptions or player-facing strings should change.

---

## Files in this pack (Basalthane-related)

| File | Purpose |
|------|---------|
| `Basalthane.lua` | Boss mod logic, events, timers, test preview. |
| `localization.en.lua` | English strings for Onyxia and Basalthane. |
| `DBM-Onyxia.toc` | AddOn metadata and load order. |
| `Onyxia.lua` | Onyxia encounter (separate from Basalthane). |

---

## Disclaimer

DBM timers and warnings are **best-effort** based on observed combat log behaviour. They are not guaranteed to match every difficulty, hotfix, or private-server variant. Verify in-game and adjust constants as needed.
