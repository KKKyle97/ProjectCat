# S-02 · Fishing Loop

> **Status**: Approved
> **Author**: Design session 2026-05-29
> **Last Updated**: 2026-05-29
> **Implements Pillar**: Pillar 1 (The Cat Does the Work) · Pillar 2 (Collection is Knowledge, Not Luck) · Pillar 5 (Check-In is Rewarding, Never Punishing)

## Overview

The Fishing Loop drives all progress in Cat & Hook through a Pomodoro-style session model. Before each session, the player sets a **session timer** (5–60 minutes, via slider) and a **break timer** (also player-set), then the cat fishes autonomously for the full duration — no input required. Session length directly influences catch quality: rare fish become progressively more likely as the session advances, rewarding patience. High-quality bait or a better rod can achieve the same outcome in a shorter session, giving players two equally valid paths to the same catch. When the session ends, the cat takes the player-set break (animated rest, idle behaviour), then automatically starts a new session with the same settings. Changing rod, bait, or area halts the current session — the cat finishes the cast in progress, then returns to setup so the player can adjust and start fresh. Whatever was already caught stays in the bucket. The loop continues indefinitely, accumulating catches whether or not the player is watching.

## Player Fantasy

When the player sets the timer, they feel like they're starting a shared work block — the cat is committing to its session just as the player is committing to theirs. Glancing over mid-session and seeing the line bob, a catch land, the bucket filling — it feels like a quiet partnership. At break time there's a small ritual: the cat stretches and grooms while the player decides what to try next. The session model turns the game from "a thing running in the background" into "a companion on the same schedule." The fish that require patience feel *earned* — not because the game forced you to wait, but because you chose to let the session run long, and the cat found something special near the end.

## Detailed Design

### Core Rules

1. **Session timer**: Set by the player via a slider, range 5–60 minutes (integer minutes). Persists as the default for subsequent auto-loop sessions.
2. **Break timer**: Set by the player via a separate slider, range 1–30 minutes. Persists as default. The cat plays idle/break animations during this period.
3. **Cast cycle**: During a session, the cat casts automatically on a timer driven by the equipped rod's `cast_interval` stat. Each completed cast produces exactly one fish drawn from the weighted catch table.
4. **Session progress**: `session_progress = elapsed_time / session_duration`, clamped 0.0–1.0. This value scales rare and uncommon fish weights upward as the session advances (see Formulas).
5. **Catch selection**: On each catch, the system builds a weighted table: each fish species' `base_weight` is multiplied by its `session_multiplier(session_progress)` and any active `bait_multiplier`. Weights are renormalized to sum to 100, then a random draw selects the species.
6. **Bucket**: Caught fish are appended to the bucket array. Capacity is defined by the equipped rod's `bucket_capacity` stat. When the bucket is full, the current cast completes and its catch is added, then casting pauses until any fish is removed.
7. **Equipment changes halt the session**: Changing rod, bait, or area during an active session (CASTING or PAUSED) triggers a 2-second confirmation prompt ("End session?"). If the player confirms (or the prompt times out), the current cast completes and its fish is banked, the session halts, the system enters SETUP state, and session progress resets to 0. If the player dismisses the prompt within 2 seconds, the session continues uninterrupted. Fish already in the bucket are unaffected. Cosmetic changes (active cat) do not trigger the prompt or halt the session.
8. **Session end**: When `elapsed_time >= session_duration`, the current cast completes (fish in progress is caught and banked), then the break timer begins.
9. **Break**: No casting during break. Cat plays break animations. Player may adjust settings freely. A new session starts automatically when the break timer expires, using the current settings.
10. **Offline resolution**: Session and cast timers advance in real time. On app restore, the system calculates elapsed time, resolves all pending casts up to bucket capacity, and advances session progress to the correct value. Excess casts beyond bucket capacity are discarded (the cat stopped when the bucket was full).
11. **First session defaults**: Session timer = 25 min, break timer = 5 min. A one-time hint on first launch explains the session model.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
| ---- | ---- | ---- | ---- |
| **SETUP** | First launch; break timer expires; equipment changed mid-session | Player starts session | Sliders visible. Cat sits idle at water's edge. No casting. Session progress = 0. |
| **CASTING** | Session starts; bucket not full; previous cast resolved | Cast elapses → CATCHING; bucket fills → PAUSED; session timer expires → BREAK; equipment changed → current cast completes → SETUP | Cast animation plays. Session progress advances. Cast countdown active. |
| **CATCHING** | Cast interval completes | Catch resolved, bucket not full → CASTING; Catch resolved, bucket now full → PAUSED | Weighted draw selects species. Fish banked. Catch animation plays. Album and bait-use events emitted. |
| **PAUSED** | Bucket reaches capacity | Fish removed → CASTING; equipment changed → SETUP | Cat sits idle (full-bucket animation). Session timer and progress continue. |
| **BREAK** | Session timer expires | Break timer expires → SETUP; player manually starts new session → SETUP | Cat plays break animations. No casting. Settings freely adjustable — no session to halt. |
| **OFFLINE_RESOLVE** | App restored after absence during CASTING or PAUSED only | Resolution complete | Elapsed time calculated. Pending casts resolved to bucket capacity. Session progress updated. Correct state entered. BREAK/SETUP closures do not enter this state — handled by Edge Cases directly. |

### Interactions with Other Systems

| System | Data In | Data Out | Owner | Contract Status |
| ---- | ---- | ---- | ---- | ---- |
| S-01 Widget Window | *(none)* | Animation state signal: SETUP / CASTING / CATCHING / PAUSED / BREAK | Fishing Loop owns state; S-01 renders it | ✅ Confirmed (S-01 GDD) |
| S-04 Rod System | `cast_interval` (seconds), `bucket_capacity` (int) | *(none)* | Rod System owns stats; Fishing Loop reads on session start and rod change (which halts session) | ⚠️ Provisional — S-04 not designed |
| S-05 Bait System | `bait_family` (string), `bait_multiplier` (float, expected ×4), `uses_remaining` (int) | `consume_use` event on each cast while bait active | Bait System owns inventory; Fishing Loop reads multiplier and triggers consumption | ⚠️ Provisional — S-05 not designed |
| S-07 Area Progression | `area_catch_table`: array of `{species_id, base_weight, rarity_tier, family}` | *(none)* | Area Progression owns tables; Fishing Loop loads active table on area change or session start (area change halts session) | ⚠️ Provisional — S-07 not designed |
| S-03 Fish Album | *(none)* | `catch_event {species_id, size_cm}` emitted on each CATCHING resolution | Fishing Loop emits; Album listens | S-03 not yet designed |
| S-06 Cat Market | *(none)* | `bucket_contents`: read-only array reference | Fishing Loop owns bucket; Market reads for sell UI | S-06 not yet designed |
| S-08 Save System | `session_elapsed`, `session_duration`, `break_duration`, `bucket_contents`, `session_progress` on load | Same fields written on: catch, session end, break end, app close | Save System owns file; Fishing Loop provides state snapshot | S-08 not yet designed |

## Formulas

> All values are placeholder tuning anchors. Numbers will be adjusted during playtesting — the formulas and their relationships are locked; the constants are not.

### Session Progress Multiplier

Controls how session duration shifts catch probabilities. Applied to each species' `base_weight` before bait modifiers, before renormalization.

```
progress_multiplier(tier, p) = M_min[tier] + p * (M_max[tier] - M_min[tier])
```

| Variable | Type | Description |
| ---- | ---- | ---- |
| `tier` | enum {Common, Uncommon, Rare} | Rarity tier of the species |
| `p` | float [0.0–1.0] | `session_elapsed / session_duration`, clamped |
| `M_min[tier]` | float | Multiplier at session start (p = 0.0) |
| `M_max[tier]` | float | Multiplier at session end (p = 1.0) |

| Tier | M_min (p=0.0) | M_max (p=1.0) | Notes |
| ---- | ---- | ---- | ---- |
| Common | 1.00 | 0.85 | Gentle inverse — commons become a smaller share as session advances |
| Uncommon | 0.80 | 1.20 | Moderate positive slope |
| Rare | 0.40 | 2.00 | Steep arc — the Pomodoro payoff |

### Catch Weight Resolution (full order)

```
Step 1: adjusted_weight[s] = base_weight[s] × progress_multiplier(tier(s), p)
Step 2: if s is in active bait_target_family: adjusted_weight[s] ×= bait_multiplier  (default ×4)
Step 3: total_weight = Σ adjusted_weight[all species]
Step 4: final_probability[s] = adjusted_weight[s] / total_weight
```

### Cast Interval

```
cast_interval(rod_tier) = I_base × decay_rate ^ (rod_tier - 1)
```

| Variable | Default | Safe Range | Notes |
| ---- | ---- | ---- | ---- |
| `I_base` | 150 sec | 120–180 | Base interval at T1 (~2:30 per fish) |
| `decay_rate` | 0.72 | 0.65–0.80 | Lower = steeper per-tier improvement |
| `rod_tier` | int [1–5] | — | — |

| Rod Tier | Interval | Fish/hr |
| ---- | ---- | ---- |
| T1 | 150 s (2:30) | 24 |
| T2 | 108 s (1:48) | 33 |
| T3 | 78 s (1:18) | 46 |
| T4 | 56 s (0:56) | 64 |
| T5 | 40 s (0:40) | 89 |

### Bucket Capacity

```
bucket_capacity(rod_tier) = floor(B_base × growth_rate ^ (rod_tier - 1))
```

| Variable | Default | Safe Range | Notes |
| ---- | ---- | ---- | ---- |
| `B_base` | 25 fish | 20–35 | T1 bucket fills in ~62 min at T1 cast rate |
| `growth_rate` | 1.50 | 1.30–1.75 | Higher = bucket upgrades feel more impactful |

| Rod Tier | Capacity | Fill time at tier rate |
| ---- | ---- | ---- |
| T1 | 25 | ~62 min |
| T2 | 37 | ~67 min |
| T3 | 56 | ~73 min |
| T4 | 84 | ~78 min |
| T5 | 126 | ~84 min |

Fill time stays roughly stable (~62–84 min) across all tiers by design — the idle check-in rhythm doesn't inflate dramatically as the player upgrades.

### Worked Examples

Area table used in all examples: Catfish (Common, weight 60) · Perch (Uncommon, weight 30) · Golden Koi (Rare, weight 10)

| Case | Session Progress | Bait on Rare | Catfish % | Perch % | Golden Koi % |
| ---- | ---- | ---- | ---- | ---- | ---- |
| A — start, no bait | 0.0 | None | 68.18% | 27.27% | **4.55%** |
| B — end, no bait | 1.0 | None | 47.66% | 33.64% | **18.69%** |
| C — start, bait | 0.0 | ×4 | 60.00% | 24.00% | **16.00%** |
| D — end, bait | 1.0 | ×4 | 30.54% | 21.56% | **47.90%** |

Cases B and C produce nearly identical rare probability (~16–18%) — mathematical confirmation that *patience* and *good bait* are equivalent paths to the same outcome. Case D (full session + matching bait) is the premium ceiling at ~48%.

### Fish Size (Cosmetic)

```
catch_size_cm = clamp(
    base_size_cm + size_variance_cm × normal_sample(mean=0, stddev=0.5),
    base_size_cm - size_variance_cm × 1.5,
    base_size_cm + size_variance_cm × 3.0
)
```

| Variable | Source | Notes |
| ---- | ---- | ---- |
| `base_size_cm` | Species data file | Mean size for the species |
| `size_variance_cm` | Species data file | Spread constant (not the stddev directly) |
| Effective stddev | `size_variance_cm × 0.5` | ~95% of catches within ±1 variance unit of mean |

Asymmetric clamp ceiling (×3.0) allows record-sized fish without producing undersized fish below biological minimum. ~1-in-370 catches reach the record ceiling — the "legendary size" tier that triggers the personal-best animation.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
| ---- | ---- | ---- |
| Player changes rod, bait, or area during CASTING | 2-second confirmation prompt shown. If confirmed (or times out): current cast completes, fish banked, session halts, SETUP entered, progress resets to 0. If dismissed: session continues uninterrupted. | Confirmation prevents accidental progress loss (Pillar 5) |
| Player changes rod, bait, or area during PAUSED | Same confirmation prompt. If confirmed: session halts immediately (no cast in flight), SETUP entered, progress resets. If dismissed: PAUSED state continues. | Same rule; PAUSED has no active cast |
| Player changes active cat (cosmetic) during a session | No halt; animation updates at next catch event | Cosmetics don't affect fishing outcome |
| Session timer expires while cat is mid-cast | Current cast completes and fish is banked; break begins | Never discard a cast in progress |
| Bait runs out (uses_remaining → 0) mid-cast | Current cast completes using the last use; multiplier reverts to ×1.0 from the following cast; no halt | Depletion is not a player-initiated change; degrades gracefully |
| Session timer = 5 min (minimum), bucket fills before session ends | PAUSED activates; session timer continues; session ends when timer expires regardless of bucket state | Session is a time commitment, not a fish count |
| App closed during active session | On reopen: offline resolution calculates elapsed time, resolves casts to bucket capacity, advances session_progress | Rule 10 |
| App closed during break | On reopen: if break timer elapsed → SETUP shown; if not elapsed → remaining break time displayed | Break timer is real-time |
| Break timer slider at minimum (1 min) | Slider minimum is 1 min; player cannot set below this value | Slider range enforces the floor; no separate system enforcement needed |
| Player attempts to switch to a locked area | Change rejected silently; current area retained; lock state shown in area UI | Area Progression owns the gate; Fishing Loop respects it |
| Session progress reaches 1.0 before session timer expires | Multipliers stay at M_max; no further shift; session continues until timer expires | Clamped at 1.0; no overtime bonus beyond the ceiling |
| `normal_sample` produces extreme outlier for fish size | Clamp formula handles it; ceiling is `base_size_cm + size_variance_cm × 3.0` | Defined ceiling in size formula |

## Dependencies

| System | Direction | Nature | Status |
| ---- | ---- | ---- | ---- |
| S-01 Widget Window | Fishing Loop depends on S-01 | Provides render surface (upper 360×480 zone); receives animation state signal (SETUP / CASTING / CATCHING / PAUSED / BREAK) | ✅ Confirmed — S-01 GDD Approved |
| S-04 Rod System | Fishing Loop depends on S-04 | Provides `cast_interval` and `bucket_capacity` per equipped tier; read on session start and on rod change (which halts session). Rod's catch-rate effect is fully captured by `cast_interval` — no separate bonus field required. | ⚠️ Provisional — S-04 not yet designed |
| S-05 Bait System | Fishing Loop depends on S-05 | Provides `bait_family`, `bait_multiplier` (×4 default), `uses_remaining`; Fishing Loop emits `consume_use` event on each cast while bait active | ⚠️ Provisional — S-05 not yet designed |
| S-07 Area Progression | Fishing Loop depends on S-07 | Provides active area's `catch_table` array `{species_id, base_weight, rarity_tier}`; loaded on session start and on area change (which halts session) | ⚠️ Provisional — S-07 not yet designed |
| S-03 Fish Album | S-03 depends on Fishing Loop | Fishing Loop emits `catch_event {species_id, size_cm}` on each CATCHING resolution; Album listens | S-03 not yet designed |
| S-06 Cat Market | S-06 depends on Fishing Loop | Fishing Loop exposes `bucket_contents` as a read-only array; Market reads it for the sell UI | S-06 not yet designed |
| S-08 Save System | Bidirectional | Save System reads: `session_elapsed`, `session_duration`, `break_duration`, `session_progress`, `bucket_contents`, `active_state` on load. Fishing Loop writes these on: catch event, session end, break end, equipment-halt, app close | S-08 not yet designed |

**Note for downstream GDD authors**:
- S-04 (Rod System) must expose `cast_interval` (seconds) and `bucket_capacity` (int) per tier. Rod catch rate is fully encoded in `cast_interval` — no additional modifier field is needed.
- S-05 (Bait System) must expose `bait_family` (string, e.g. `"Cyprinidae"`), `bait_multiplier` (float, default ×4.0), and `uses_remaining` (int). Bait targets a named fish family, NOT a rarity tier.
- S-07 (Area Progression) must deliver `catch_table` as an array of `{species_id, base_weight, rarity_tier, family}`. The `family` field is the string that `bait_family` matches against (e.g., Carp species belong to `"Cyprinidae"`; a Worm Bait with `bait_family = "Cyprinidae"` boosts all Carp-family species regardless of their rarity tier). These are the provisional contracts this GDD establishes.

## Tuning Knobs

All values live in `res://config/fishing_config.gd`. No magic numbers in scene files.

| Parameter | Default | Safe Range | Too High | Too Low |
| ---- | ---- | ---- | ---- | ---- |
| `session_timer_min` | 5 min | 2–10 min | Long minimum forces commitment; alienates casual players | Too short; sessions feel trivial |
| `session_timer_max` | 60 min | 45–120 min | Sessions become unrealistically long for a desktop idle game | Ceiling too low; caps the patience mechanic |
| `break_timer_min` | 1 min | 0.5–3 min | Long enforced minimum disrupts fast re-launch | No visual break transition; jarring loop |
| `break_timer_max` | 30 min | 15–60 min | — | — |
| `M_min[Rare]` | 0.40 | 0.20–0.60 | Lower = harsher short-session penalty | Higher = short sessions nearly as good as long; patience loses meaning |
| `M_max[Rare]` | 2.00 | 1.50–3.00 | Higher = full-session ceiling very high; may destabilize economy | Lower = patience barely rewarded |
| `M_min[Uncommon]` | 0.80 | 0.60–0.95 | — | Uncommons too rare at session start |
| `M_max[Uncommon]` | 1.20 | 1.10–1.60 | — | — |
| `M_min[Common]` | 1.00 | 0.90–1.10 | Commons too frequent at session start | — |
| `M_max[Common]` | 0.85 | 0.70–1.00 | Must stay ≤ M_min[Common] | If equal to M_min, flat curve; rares can't grow share |
| `I_base` | 150 sec | 120–180 | Longer waits; cozy but risks feeling empty | Fish arrive too fast; bucket fills before player checks in |
| `decay_rate` | 0.72 | 0.65–0.80 | Lower = steeper tier improvement | Higher = rods feel underpowered |
| `B_base` | 25 fish | 20–35 | Longer unattended idle; may reduce check-in frequency too much | Bucket fills very fast; too frequent interruptions |
| `growth_rate` | 1.50 | 1.30–1.75 | Higher bucket tiers may remove all check-in rhythm | Bucket upgrades feel negligible |

**Coupled parameters**: `I_base` + `decay_rate` must be tuned together with `B_base` + `growth_rate`. The goal is to keep "fill time at tier rate" stable across all rod tiers (~60–90 min). Changing one without the other will cause bucket pacing to drift.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
| ---- | ---- | ---- | ---- |
| CASTING state | Cast animation: cat winds up, line arcs out, bobber lands | Light cast whoosh | Must-have |
| Line bobbing (waiting) | Bobber idle animation; cat ear flick at random intervals | Ambient water loop | Must-have |
| CATCHING — Common fish | Standard catch arc: fish jumps into bucket | Soft splash + plop | Must-have |
| CATCHING — Uncommon fish | Slightly larger arc; cat looks more pleased | Slightly brighter plop | Should-have |
| CATCHING — Rare fish | Bigger animation beat; water splash; cat reaction | Distinct chime or splash variant | Must-have |
| CATCHING — New species (first catch) | Catch animation + brief album-discovery flash | Discovery sound | Must-have |
| CATCHING — New size record | Standard catch + subtle shimmer on fish sprite | Short sparkle sound | Should-have |
| PAUSED (bucket full) | Cat sets rod down; looks at full bucket; shrugs | No audio | Must-have |
| BREAK state | Cat stretches, grooms, drinks water, yawns | Soft ambient; no cast sounds | Must-have |
| Session halted by equipment change | Cat pauses mid-action; looks at player; returns to idle | Brief stop sound | Should-have |

## UI Requirements

| Element | Location | Visibility | Notes |
| ---- | ---- | ---- | ---- |
| Session timer slider | SETUP panel (compact window lower area) | SETUP state only | 5–60 min range; shows selected duration as text |
| Break timer slider | SETUP panel, below session slider | SETUP state only | 1–30 min range |
| Start session button | SETUP panel | SETUP state only | Tapping starts session and hides sliders |
| Session progress indicator | Subtle bar or ring at widget edge | CASTING and PAUSED | Low-visual-weight; doesn't demand attention |
| Session time remaining | Small text near progress indicator | CASTING and PAUSED | e.g. "18 min left" |
| Break countdown | Replaces session timer display | BREAK state | e.g. "Break: 3 min" |
| Bucket fill indicator | Bucket icon with fill level | Always visible (compact window) | Tapping opens market panel |
| Equipment-halt notification | Brief toast: "Session ended — settings changed" | On SETUP entry via halt | Disappears after 3 seconds |

## Acceptance Criteria

- [ ] Cat begins casting within 1 second of session start
- [ ] Session progress value advances continuously from 0.0 to 1.0 over the set duration
- [ ] Catch probability at session start and end matches the worked examples in Formulas (within ±1% over 1000 simulated catches)
- [ ] Matching bait at session start (p=0, ×4) produces ~16% rare probability (within ±2% over 1000 catches)
- [ ] Changing rod, bait, or area during CASTING halts the session after the current cast completes
- [ ] Changing rod, bait, or area during PAUSED halts the session immediately
- [ ] Changing the active cat during CASTING does NOT halt the session
- [ ] Fish already in the bucket are never removed by an equipment change or session halt
- [ ] Bait depletion (uses → 0) does not halt the session
- [ ] Session end triggers break timer automatically; break end triggers SETUP automatically
- [ ] Closing and reopening the app correctly resolves offline casts up to bucket capacity
- [ ] Offline session progress is calculated from real elapsed time, not cast count
- [ ] Bucket capacity matches rod tier values from the Formulas table
- [ ] Performance: catch resolution (weighted draw + event emission) completes in < 1 ms

## Open Questions

| Question | Owner | Target Resolution |
| ---- | ---- | ---- |
| Should the session-halt toast notification be dismissable or auto-fade? | Designer | Decide during UI prototype; current spec: auto-fade after 3 seconds |
| Do sessions persist across game updates (versioning)? If a balance patch changes cast_interval, do in-flight sessions resolve at old or new values? | Programmer | Resolve before first public build |
