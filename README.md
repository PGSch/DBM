# DBM-Onyxia

Deadly Boss Mods pack for **Onyxia's Lair**. It loads on demand when DBM needs this zone and includes two boss modules: **Onyxia** and **Basalthane**.

This README documents the **stock Onyxia encounter** plus the **custom Basalthane module** and the **implementation details** added for timers, warnings, options, and the out-of-combat test preview.

---

## Pack layout

| Piece | Role |
|--------|------|
| `DBM-Onyxia.toc` | Declares the addon, interface version, load zone **Onyxia's Lair**, load order (`localization.en.lua` → `Onyxia.lua` → `Basalthane.lua`). |
| `Onyxia.lua` | Classic Onyxia encounter. |
| `Basalthane.lua` | Custom boss mod for **Basalthane** (creature id **10185**), same addon id **`DBM-Onyxia`**, **sub-tab index `1`** so it appears as a second boss entry under this raid pack in `/dbm`. |
| `localization.en.lua` | English strings for Onyxia and Basalthane (including custom option and timer labels). |

---

## Basalthane — encounter behaviour (summary)

`Basalthane.lua` uses `RegisterCombat("combat")` and filters events so abilities are attributed to NPC **10185** (`GetCIDFromGUID`).

### Announcements and special warnings

| Event | Spell id | Behaviour |
|--------|-----------|------------|
| **Annihilation Strike** | 2108206 | Spell announce on `SPELL_CAST_START`. |
| **Inferno Trail** | 2108217 | Spell announce on `SPELL_CAST_START`. |
| **Eruption** | 2108227 | Spell announce on `SPELL_CAST_START`, **cast bar**, and **next** timer only (no player icons or yells; ground pool applies too late in the log to drive callouts). |
| **Heat Splash** | 2108212 | Client log name **Igneous Impact**: announce + next timer refresh on the **first** `SPELL_DAMAGE` / `SPELL_MISSED` per wave from the boss (`DBM:AntiSpam`), not on `SPELL_CAST_SUCCESS` (that event does not appear for this id in the sample log). |
| **Flash Burn** | 2108201 | Special warning **you** on `SPELL_AURA_APPLIED` (player dest, boss as source in mod logic). |

### Cast bars (time from cast start to impact)

| Ability | Duration (s) |
|---------|----------------|
| Annihilation Strike | 3 |
| Inferno Trail | 3 |
| Eruption | 5 |

### Cooldown / “next” timers

Constants are tuned from a reference combat log (see file header in `Basalthane.lua`); adjust if your server differs.

| Timer | Role |
|--------|------|
| **First Annihilation Strike** | Time from pull to first Annihilation cast start (~3 s). Implemented with a **separate** `NewNextTimer` + option key so it does not share a toggle with “next” (same spell id **2108206**). |
| **Next Annihilation Strike** | ~18 s after each Annihilation cast start; after **Eruption** starts, next Annihilation is pushed to ~11 s from that cast. |
| **Next Inferno Trail** | Seeded on pull (~6 s), then ~14 s between Inferno casts; first cycle after the first Annihilation uses a short Inferno delay (~3 s), later cycles often ~11 s after Annihilation until the pattern resets. |
| **Next Heat Splash** | Seeded at pull (~152 s to first wave in sample log); repeat ~131 s (`cdHeatSplashRepeat`), refreshed from damage events. Tune `firstHeatSplash` / `cdHeatSplashRepeat` if your server differs. |
| **Next Eruption** | ~56 s between Eruptions; first Eruption ~48 s from pull. |

### Pillar phase — boss “stun” bar

When a **Volatile Pillar** dies, the log shows Basalthane applying **Cracked Armor** (**2108234**) to **himself**. The mod treats that as a **~20 s** window where the boss’s normal rhythm is interrupted.

- **On apply** (boss source and destination, same unit): `NewBuffActiveTimer` runs **20 s** with a custom bar title via **`TimerPillarStun`** in `localization.en.lua` (default: “Basalthane stunned (pillar)”).  
- **On remove** on the boss: timer cancelled early if the aura drops before 20 s.

Tweak `pillarStunDuration` and/or `TimerPillarStun` if your build uses a different duration or name.

---

## Heat Splash — custom addition (details)

Heat Splash was added as a full **warning + next timer** pair, with explicit DBM option keys so entries always show correctly in **DBM → Raid mods → Onyxia's Lair → Basalthane**.

| Item | Implementation |
|------|----------------|
| **Spell id** | `2108212` — placed in the same custom **21082xxx** band as other Basalthane spells. **Confirm in-game** (combat log or `/dump GetSpellInfo(2108212)`) if bars never update or the name is wrong. |
| **Events** | `SPELL_DAMAGE` and `SPELL_MISSED` (boss source, spell **2108212**); **`DBM:AntiSpam(2, "BasalthaneHeatSplash")`** so one wave does not spam dozens of refreshes. |
| **Bar label** | `NewNextTimer(..., "TimerNextHeatSplashBar", true, "TimerNextHeatSplash")` plus **`SetTimerLocalization`** → bar text **“Next Heat Splash”** (does not depend on the client knowing the spell name). |
| **Options** | `WarnHeatSplash` and `TimerNextHeatSplash` with **`SetOptionLocalization`** strings in `localization.en.lua` (plain English descriptions for the GUI). |
| **`OnInitialize`** | If `TimerNextHeatSplash` or `WarnHeatSplash` is **missing** from saved options, it is set to **`true`**. DBM treats a **nil** option as off; without this, new toggles could fail to show bars or the test preview until options are merged correctly. |

---

## DBM options and localization (custom patterns)

### Same spell id, two timers (Annihilation)

Annihilation Strike uses **one spell id** for both “first after pull” and “next after cast”. DBM’s auto-generated option ids would collide, so the mod uses **explicit option names** and **localized descriptions**:

- `TimerFirstAnnihilationStrike`  
- `TimerNextAnnihilationStrike`  

Strings live in **`localization.en.lua`** under `SetOptionLocalization`.

### `NewNextTimer` / `NewSpellAnnounce` arguments

- For optional `timerText`, pass **`nil`**, not **`true`**. In DBM-Core, **`true` is mis-parsed** as `optionDefault` (arg shuffle), which breaks the options table and GUI.  
- Heat Splash uses **`timerText`** `"TimerNextHeatSplashBar"` only for the **display string** key; the **boolean default** for the timer is still the fourth argument (`true`), and the **option key** is the fifth (`"TimerNextHeatSplash"`).

### Timer bar titles vs spell names

- **Pillar stun:** `TimerPillarStun` maps to “Basalthane stunned (pillar)” because the spell name (Cracked Armor) is not player-facing.  
- **Heat Splash:** `TimerNextHeatSplashBar` maps to “Next Heat Splash” for a stable label even if `GetSpellInfo(2108212)` is missing on the client.

---

## Test pull timers (out of combat)

The Basalthane panel exposes a **misc** button (**`TimerTestButton`**): **“Test pull timers (short preview)”**.

| Behaviour | Detail |
|-----------|--------|
| **Combat** | Only works **out of combat**; otherwise `TimerTestInCombat` is printed. |
| **Flow** | `Stop()` clears bars, sets an internal preview flag, calls **`OnCombatStart(0)`** (same pull timers as a real pull, including **Heat Splash**), schedules **`TimerTestPreviewEnd`** after **`timerTestPreviewSeconds`** (12 s). |
| **Cleanup** | If still not in combat when the preview ends, **`Stop()`** clears the preview bars. |
| **Options** | Respects per-timer / per-warning toggles. If **Heat Splash** (or anything else) is disabled in the GUI, that bar will not appear in the preview. |

---

## Instructions

### Requirements

- **DBM-Core** (`RequiredDeps` in `DBM-Onyxia.toc`).  
- **Interface** version in the `.toc` must match your client (this repo uses **30300**).

### Installation

1. Copy the **`DBM-Onyxia`** folder into `Interface\AddOns` (same layout as in the repo).  
2. Enable **DBM-Core** and **DBM-Onyxia**.  
3. Restart or `/reload`.

### Loading and options

- **Load on Demand:** DBM loads the pack in **Onyxia's Lair** (`X-DBM-Mod-LoadZone`).  
- Open **DBM → Options → Raid mods → Onyxia's Lair**, then select **Onyxia** or **Basalthane**.  
- Basalthane lists separate toggles for **first** vs **next** Annihilation, all standard cast/next timers, pillar stun, **Heat Splash** warning/timer, and the **test preview** button label.

### Localization

- Defaults for Basalthane are in **`localization.en.lua`** (`SetGeneralLocalization`, `SetTimerLocalization`, `SetOptionLocalization`, `SetMiscLocalization`).  
- Add another locale by creating e.g. `localization.de.lua` and listing it in **`DBM-Onyxia.toc`** before the boss `.lua` files.

### Tuning from new logs

1. Adjust spell ids and numeric constants at the top of **`Basalthane.lua`**.  
2. Update **`localization.en.lua`** if option wording or yell text should change.  
3. For Heat Splash, prefer verifying **spell id** and **timings** from a fresh combat log if the ability was not in the original reference log.

---

## Files in this pack (reference)

| File | Purpose |
|------|---------|
| `Basalthane.lua` | Basalthane: events, timers, pillar stun, Heat Splash, `OnInitialize`, test preview. |
| `localization.en.lua` | English strings and custom option/timer labels for Onyxia and Basalthane. |
| `DBM-Onyxia.toc` | Addon metadata and load order. |
| `Onyxia.lua` | Onyxia encounter. |
| `README.md` | This document. |

---

## Disclaimer

DBM behaviour is **best-effort** from combat logs and in-game testing. Timings and spell ids may differ by patch, difficulty, or private-server data. Confirm in-game and adjust constants as needed.
