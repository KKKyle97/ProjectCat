# S-05 · Bait System

> **Status**: Approved
> **Author**: Design session 2026-05-29
> **Last Updated**: 2026-05-31
> **Implements Pillar**: Pillar 2 (Collection is Knowledge, Not Luck) · Pillar 4 (Gear is the Progression)

## Overview

The Bait System manages the player's consumable bait inventory and applies it as a catch-weight modifier during active fishing sessions. At any time, the player has one active bait slot: a single bait type with a running uses count. Bait is purchased in stacks — each purchase adds ×10 uses to the running total for that type (or replaces the active type if a different bait is selected). Each cast during an active session consumes one use and applies a ×4 family-targeted multiplier to all fish in the named family on the catch table, boosting their share of the weighted draw before renormalization. When uses reach zero the multiplier silently reverts to ×1.0 from the following cast; the session does not halt.

Bait is available to purchase from the Cat Market from the player's very first session — no rod tier gate. Different bait types unlock as the player advances through area tiers: the earliest baits target common freshwater families; later area tiers introduce more specialized types matched to rarer fish. The MVP ships with 3 bait types covering 3 distinct fish families. At full vision there are 30+ types spanning all areas. Selecting the right bait for the fish family you're targeting is the player's primary knowledge-based decision — it is how Pillar 2 ("Collection is Knowledge, Not Luck") is expressed mechanically.

## Player Fantasy

Equipping bait should feel like briefing your cat before a mission. The player has checked the album, seen that the Spotted Gudgeon prefers Mayfly Bait, and now they're stocking the bucket with exactly the right thing before they go back to work. It's a small act of care — one decision that says "I know what you need." When they return and the bucket is full of Spotted Gudgeons, the payoff isn't luck. It's knowledge.

The bait purchase itself should feel light and deliberate, never anxious. Coin costs are low enough that running out of bait doesn't feel like a setback — it's just a signal to check in, buy more, and re-equip. The depletion moment ("bait ran out") should read as a gentle nudge, not a punishment. The player should feel like a well-prepared angler who occasionally needs to restock, not like a manager tracking a resource.

For new players, bait is the gateway to the knowledge system: the album shows the hint, the bait exists in the shop, and the first targeted catch is the "aha" moment that explains the whole game. For experienced players, bait selection is the pre-session ritual that gives every session a purpose.

## Detailed Design

### Core Rules

1. The Bait System maintains a single active bait slot: `active_bait_id` (string or null) and `uses_remaining` (int ≥ 0). When `uses_remaining = 0` or `active_bait_id = null`, the slot is empty and no modifier is applied.
2. Bait is purchased in stacks. Each purchase adds exactly `stack_size` (default 10) uses. If the purchased bait type matches the currently active type, uses are added to the running total (no cap). If a different bait type is purchased and `uses_remaining > 0`, a confirmation prompt informs the player that existing uses will be discarded; on confirmation, the active bait changes and `uses_remaining = stack_size`. If `uses_remaining = 0`, the new bait auto-equips with no prompt.
3. One use is consumed per completed cast (the `consume_use` event emitted by the Fishing Loop on each CASTING → CATCHING transition, as defined in S-02). Consumption is triggered only while bait is active; it is not triggered during BREAK, SETUP, or PAUSED states with no cast in flight.
4. `uses_remaining` has no upper cap.
5. When `uses_remaining` reaches 0 after a cast, `active_bait_id` is set to null and the slot enters the NO_BAIT state. The Fishing Loop reads `uses_remaining = 0` and applies no multiplier from the next cast onward. The session is not halted. A depletion notification appears in the compact widget (see UI Requirements).
6. The player may unequip bait at any time via the widget or market panel. If an active session is in progress (CASTING or PAUSED), the S-02 session halt confirmation fires first; if confirmed, the session halts then bait is unequipped; if dismissed, bait remains equipped and the session continues.
7. If the active bait's `bait_family` is not represented in the current area's catch table, bait is still consumed per cast but has no effect on catch probabilities. This is a knowledge failure, not a system error. No system correction or warning is provided.
8. Available bait types in the Cat Market are gated by area tier. A bait type becomes purchasable once the player's `unlocked_area_tier` (from S-07) meets or exceeds the bait's `area_tier_unlock` value. Bait types for higher tiers are visible in the market but greyed with a lock indicator showing the unlock condition.
9. Bait is equip-on-purchase: buying bait immediately makes it the active bait (or adds uses, if same type). There is no separate "equip" action after purchase.

### MVP Bait Data Table

| ID | Name | `bait_family` | `cost_per_stack` | `area_tier_unlock` | Flavour |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `worm_bait` | Worm Bait | `Cyprinidae` | 25c | Area 1 | *A classic earthworm, irresistible to any fish that's ever seen a riverbed.* |
| `mayfly_bait` | Mayfly Bait | `Percidae` | 35c | Area 1 | *Lifelike and delicate. Perch can't resist it. Your cat is very patient.* |
| `spinner_bait` | Spinner Bait | `Salmonidae` | 45c | Area 2 | *A tiny glinting lure. Trout and salmon lose all composure at the sight of it.* |

Full-vision bait types follow the same schema. Each new area tier introduces 3–5 new bait types targeting the families exclusive to that area. Bait `id` and `bait_family` strings are the data contract between this system and S-02; names and flavour are display-only.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
| ---- | ---- | ---- | ---- |
| **NO_BAIT** | First launch; depletion (`uses_remaining → 0`); player unequips bait | Player purchases any bait type → ACTIVE | Slot shows empty. `bait_multiplier` = ×1.0 (no effect). No consumption events handled. |
| **ACTIVE** | Bait purchased (same type: uses added; different type: old uses discarded on confirmation, new bait set) | Depletion (`uses_remaining → 0`) → NO_BAIT; player unequips → NO_BAIT; player swaps to different type → ACTIVE (new type) | `bait_multiplier` = ×4.0 applied to `bait_family` in catch table. `uses_remaining` decrements on each `consume_use` event. |

### Interactions with Other Systems

| System | Data In | Data Out | Owner | Contract Status |
| ---- | ---- | ---- | ---- | ---- |
| S-06 Cat Market | *(none)* | `bait_data[]`: array of `{id, name, family, cost_per_stack, uses_remaining, area_tier_unlock, flavour, is_active}` for shop display; `active_bait_id`, `uses_remaining` for equip UI | Bait System owns data; Market reads for UI | ⚠️ Provisional — S-06 not yet designed |
| S-06 Cat Market (purchase) | `purchase_confirmed {bait_id}` signal + coin deducted | `active_bait_id` and `uses_remaining` updated | Market owns coin deduction; Bait System owns slot state | ⚠️ Provisional — S-06 not yet designed |
| S-02 Fishing Loop | `consume_use` signal (emitted per completed cast while bait family is set) | `bait_family` (StringName), `bait_multiplier` (float) injected via `set_active_bait(family, multiplier)`; `clear_bait()` called by Bait System on depletion | **BaitSystem owns `uses_remaining`.** FishingLoop emits `consume_use` as a notification; BaitSystem decrements its counter and calls `FishingLoop.clear_bait()` when uses hit 0. FishingLoop does not track use count internally. | ✅ Confirmed — S-02 GDD Approved, `fishing_loop.gd` updated |
| S-07 Area Progression | `unlocked_area_tier` (int) | *(none — read-only gate check)* | Area Progression owns unlock state; Bait System reads to filter purchasable types | ⚠️ Provisional — S-07 not yet designed |
| S-08 Save System | `active_bait_id` (string or null), `uses_remaining` (int) on load | Same fields written on: bait equip, bait unequip, depletion, app close | Save System owns file; Bait System provides state snapshot | S-08 not yet designed |

## Formulas

> Bait multiplier math is defined in S-02 (Fishing Loop) as Step 2 of catch weight resolution. This system owns the *input values* (`bait_family`, `bait_multiplier`); S-02 owns the *formula*. Do not redefine the formula here — reference it and provide worked examples for validation.

### Bait Multiplier Application (reference: S-02 Catch Weight Resolution, Step 2)

```
For each species s in catch table:
  if family(s) == active_bait_family:
    adjusted_weight[s] *= bait_multiplier    (default ×4.0)
```

`bait_multiplier` = 4.0 for all MVP bait types. Differentiation between bait types is via `bait_family` target, not multiplier magnitude.

### Worked Examples

> **Illustrative table** (not final game data — final fish roster is owned by S-03/S-07).
> All percentages are calculated from the S-02 formula constants currently in `fishing_config.gd`
> (M_min[Common]=1.00, M_max[Common]=0.85, M_min[Uncommon]=0.80, M_max[Uncommon]=1.20,
> M_min[Rare]=0.40, M_max[Rare]=2.00, bait_multiplier=4.0). Recalculate if constants change.
> **The rare ceiling (~38.5% in Case E) is a balance tuning knob** — increasing `M_max[Rare]`
> in `fishing_config.gd` raises it. Target ceiling will be set during post-mechanics balance pass.

Area: Backyard Pond. Hypothetical table: Carp (Cyprinidae, Common, w=60) · Roach (Cyprinidae, Common, w=20) · Perch (Percidae, Uncommon, w=30) · Gudgeon (Percidae, Uncommon, w=20) · Golden Dace (Salmonidae, Rare, w=10)

| Case | Active Bait | Session Progress p | Carp % | Roach % | Perch % | Gudgeon % | Golden Dace % |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| A | None | 0.0 | 48.4% | 16.1% | 19.4% | 12.9% | **3.2%** |
| B | Worm (Cyprinidae ×4) | 0.0 | 65.9% | 22.0% | 6.6% | 4.4% | **1.1%** |
| C | Mayfly (Percidae ×4) | 0.0 | 24.6% | 8.2% | 39.3% | 26.2% | **1.6%** |
| D | Spinner (Salmonidae ×4) | 0.0 | 44.1% | 14.7% | 17.6% | 11.8% | **11.8%** |
| E | Spinner (Salmonidae ×4) | 1.0 | 24.5% | 8.2% | 17.3% | 11.5% | **38.5%** |

Case E (correct bait + full session) is the current ceiling at ~38.5% for the targeted Rare species, tunable upward via `M_max[Rare]`. Session progress multiplier (Step 1) is applied before the bait multiplier (Step 2) per the S-02 catch weight resolution order.

*Note: Case B (Worm Bait) suppresses Golden Dace to 1.1% — wrong bait actively harms rare odds. Bait selection is a meaningful commitment.*

### Cost Scaling Across Area Tiers

Bait cost is authored per bait type. Scaling principle: each area tier's base bait cost is approximately 1.5× the previous tier, rounded to nearest 5c.

| Area Tier | Cost range per stack | Rationale |
| ---- | ---- | ---- |
| Area 1 | 25–35c | Affordable from first session; no barrier to the knowledge system |
| Area 2 | 45–55c | Aligns with the T2 rod unlock pace |
| Area 3 | 70–90c | Mid-game investment; 2–3 market visits to stock up |
| Area 4 | 100–130c | Late-game; reliable income established by this tier |
| Areas 5–7 | 150–200c | Endgame; rarity of targets justifies premium cost |

### Uses-per-Session Estimate

```
casts_per_session = floor(session_duration_sec / cast_interval_sec)
uses_per_session = casts_per_session     (one use per cast)
sessions_per_stack = floor(stack_size / casts_per_session)
```

| Session Duration | Rod T1 (150 s/cast) | Rod T3 (78 s/cast) | Rod T5 (40 s/cast) |
| ---- | ---- | ---- | ---- |
| 25 min (1,500 s) | 10 casts → **1 stack** | 19 casts → **~2 stacks** | 37 casts → **~4 stacks** |
| 60 min (3,600 s) | 24 casts → **~2.5 stacks** | 46 casts → **~5 stacks** | 90 casts → **9 stacks** |

Design intent: a T1 player buying one stack (25c) gets exactly one full 25-minute session of targeted fishing. Bait spending scales naturally with rod tier — T5 players need more stacks per session, but their income comfortably supports it.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
| ---- | ---- | ---- |
| Player purchases the same bait type currently active | `uses_remaining += stack_size`. No confirmation prompt. No state change. | Same-type purchase is always additive; no decision required. Rule 2. |
| Player purchases a different bait type while `uses_remaining > 0` | Confirmation prompt: "Switch to [Bait B]? Your [N] remaining [Bait A] uses will be lost." On confirm: `active_bait_id = new_id`, `uses_remaining = stack_size`. On dismiss: no change. | Prevents accidental loss of uses. Rule 2. |
| Player purchases a different bait type while `uses_remaining = 0` | New bait auto-equips with `uses_remaining = stack_size`. No confirmation prompt. | No uses to lose; no confirmation needed. Rule 2. |
| Bait depletes mid-session (last use consumed on a cast) | Current cast resolves with the bait multiplier applied. `uses_remaining → 0`, `active_bait_id → null`. Session continues. Next cast uses no multiplier. Depletion notification shown in compact widget. | Depletion is not player-initiated; session never halts on depletion. Locked by S-02 edge case. |
| Player is in Area 1 with Spinner Bait (Salmonidae) and no Salmonidae fish exist in Area 1's catch table | Bait is consumed per cast. Catch probabilities are unaffected — no species belong to the targeted family so no weights change. No system warning. Player wastes uses. | Knowledge failure, not a system error. Rule 7. |
| Player tries to purchase a bait type locked behind a higher area tier | Purchase button is disabled and greyed in the market. Lock icon shown with area unlock condition. No purchase proceeds. | Rule 8. Area Progression owns the gate; Bait System reads it. |
| Player unequips bait during an active session (CASTING or PAUSED) | S-02 session halt confirmation fires first. If confirmed: session halts, then bait is unequipped (`active_bait_id → null`, `uses_remaining → 0`, slot becomes NO_BAIT — remaining uses are discarded). If dismissed: session continues with bait active. | Remaining uses are discarded on unequip; there is no re-equip recovery path. Session halt owns the interruption; bait unequip is the follow-through. Rule 6. |
| Player unequips bait during SETUP or BREAK | Bait unequipped immediately. No confirmation prompt. No session interaction. | No active session to halt. |
| App closes with active bait and `uses_remaining > 0` | `active_bait_id` and `uses_remaining` persisted to save file by S-08 on app close. On reload, bait is restored to the same state. | Save/restore parity. |
| Offline session resolves more casts than `uses_remaining` | Fishing Loop offline resolution deducts uses one per cast until `uses_remaining = 0`, then resolves remaining offline casts with no multiplier. The catch distribution splits accordingly. | S-02 owns offline resolution and must read `uses_remaining`, decrement it per offline cast, and cap at 0. Bait System's responsibility ends at providing the correct `uses_remaining` at load time. |
| Player starts a session with `uses_remaining = 0` (NO_BAIT state) | Session starts normally. No bait multiplier applied. No warning, no block. | NO_BAIT is a valid fishing setup — bait is optional. Pillar 5: never punish the player for a valid choice. |
| `bait_multiplier` config value is changed by a balance patch | New value takes effect at the next session start. Any in-progress session completes using the value read at session start. | Config is the source of truth; sessions read config at start and hold the value for their duration. |

## Dependencies

| System | Direction | Nature | Status |
| ---- | ---- | ---- | ---- |
| S-06 Cat Market | Bait System depends on S-06 | Market owns purchase UI and coin deduction. Bait System provides `bait_data[]` for display and receives `purchase_confirmed {bait_id}` signal. Coin deduction happens in S-06; Bait System updates slot state only after confirmation. | ⚠️ Provisional — S-06 not yet designed |
| S-02 Fishing Loop | S-02 depends on Bait System | Bait System exposes `bait_family` (string), `bait_multiplier` (float, ×4.0), and `uses_remaining` (int). Fishing Loop reads these on each catch resolution (Step 2 of weight calculation). Fishing Loop emits `consume_use` event on each cast while bait is ACTIVE; Bait System decrements `uses_remaining` in response. | ✅ Confirmed — S-02 GDD Approved |
| S-07 Area Progression | Bait System depends on S-07 | Area Progression exposes `unlocked_area_tier` (int). Bait System reads this to determine which bait types are purchasable in the market (gate check). Read-only — Bait System never writes to S-07. | ⚠️ Provisional — S-07 not yet designed |
| S-08 Save System | Bidirectional | Save System reads `active_bait_id` (string or null) and `uses_remaining` (int) on load, restoring the bait slot to its pre-close state. Bait System writes these fields on: bait equip, bait unequip, depletion, and app close. | S-08 not yet designed |

**Note for downstream GDD authors:**
- S-06 (Cat Market) must support a `purchase_confirmed {bait_id}` signal that triggers Bait System slot update. Coin deduction and purchase validation are S-06's responsibility; Bait System only acts on the confirmed signal.
- S-07 (Area Progression) must expose `unlocked_area_tier` (int, 1–7). The Bait System compares this against each bait type's `area_tier_unlock` value to determine purchasability.
- S-02 (Fishing Loop) offline resolution must read `uses_remaining` at resolution start and decrement it once per resolved offline cast, stopping at 0. Bait System does not perform offline resolution itself.

## Tuning Knobs

All bait system values live in `res://config/bait_config.gd`.

| Parameter | Default | Safe Range | Too High | Too Low |
| ---- | ---- | ---- | ---- | ---- |
| `bait_multiplier` | 4.0 | 2.0–8.0 | Bait dominates catch table; targeted species nearly certain; other species rarely caught; reduces incidental discovery | Bait barely shifts probabilities; knowledge-based targeting feels unrewarding; players stop buying bait |
| `stack_size` (uses per purchase) | 10 | 5–20 | One purchase lasts many sessions; restocking friction eliminated; bait economy shrinks | Player must restock every session; bait spending feels like a chore; Pillar 5 pressure risk |
| Worm Bait `cost_per_stack` | 25c | 15–50c | Tier 1 bait inaccessible early; knowledge loop delayed for new players | Bait trivially cheap; no economic weight to the bait decision |
| Mayfly Bait `cost_per_stack` | 35c | 20–65c | — | — |
| Spinner Bait `cost_per_stack` | 45c | 30–80c | Mid-game bait too expensive relative to income; players skip targeted fishing | Feels too cheap for a premium bait; no sense of bait tier progression |

**Coupled parameters:**
- `bait_multiplier` interacts directly with `M_max[Rare]` (S-02, `fishing_config.gd`). Increasing `bait_multiplier` raises Case D/E rare ceilings — `M_max[Rare]` may need a compensating reduction. Re-verify all worked examples in Formulas after changing either value.
- `stack_size` and `cost_per_stack` must be tuned together. Reducing `stack_size` without reducing `cost_per_stack` increases per-use cost and makes bait feel punishing.
- Bait costs should stay below 20 minutes of passive income at the tier's rod rate. Reference: T1 rod earns ~120c/hr (game-concept.md); 25c Worm Bait = ~12 min of T1 income.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
| ---- | ---- | ---- | ---- |
| Bait ACTIVE (bait equipped) | Small bait icon with uses count shown in compact widget near bucket | *(none)* | Must-have |
| Uses count ticking down | Uses number updates on each cast; no animation unless nearing depletion | *(none)* | Must-have |
| Uses low warning (≤3 uses remaining) | Uses count changes colour (amber) | *(none)* | Should-have |
| Bait depleted (`uses_remaining → 0`) | Icon fades out; "Bait empty" text briefly flashes in widget | Soft chime or pop (distinct from catch sounds) | Must-have |
| Bait purchased / equipped | Icon animates in with a small bounce; uses count updates | Light purchase sound (same as rod purchase — reuse asset) | Should-have |
| NO_BAIT state | Bait slot shows empty with a subtle dashed border | *(none)* | Must-have |

## UI Requirements

| Element | Location | Visibility | Notes |
| ---- | ---- | ---- | ---- |
| Active bait icon + uses count | Compact widget, near bucket fill indicator | Always visible | Shows bait icon and `uses_remaining` as a number; empty state shows dashed slot |
| Bait depletion toast | Compact widget, brief overlay | On depletion only | "Bait ran out — restock in the market"; auto-fades after 3 seconds |
| Bait shop section | Cat Market panel, dedicated section | Always when market is open | Lists all bait types; active bait highlighted with uses count; locked baits greyed with area unlock condition shown |
| Stack purchase button | Per bait entry in market | When bait is purchasable | Shows cost per stack; "+ 10 uses" label when same type is active; changes to "Switch bait" label when different type is active with uses remaining |
| Swap confirmation prompt | Modal over market panel | On cross-type purchase with uses remaining | "Switch to [Bait B]? Your [N] [Bait A] uses will be lost." Confirm / Cancel |
| Unequip button | Active bait entry in market, and widget bait slot long-press | When bait is ACTIVE | Triggers S-02 session halt confirmation if session is active |

## Acceptance Criteria

- [ ] Player starts with no active bait (NO_BAIT state); bait slot shows empty in the widget and market
- [ ] Purchasing Worm Bait (25c) deducts exactly 25c and sets `active_bait_id = "worm_bait"`, `uses_remaining = 10`
- [ ] Purchasing a second stack of Worm Bait while active adds 10 uses (`uses_remaining = 20`); no confirmation prompt shown
- [ ] Purchasing Mayfly Bait while Worm Bait is active with `uses_remaining > 0` shows confirmation prompt; on confirm: `active_bait_id = "mayfly_bait"`, `uses_remaining = 10`; on dismiss: no change
- [ ] Purchasing any bait type while `uses_remaining = 0` auto-equips without a confirmation prompt
- [ ] During an active session, Fishing Loop applies ×4.0 to all Cyprinidae species weights when `active_bait_id = "worm_bait"`; Cyprinidae species collectively represent ≥85% of draws (vs. ≤58% without bait) over 1,000 simulated draws at p=0.0
- [ ] Each completed cast (CASTING → CATCHING transition) decrements `uses_remaining` by exactly 1
- [ ] When `uses_remaining` reaches 0: slot enters NO_BAIT, next cast resolves with no multiplier, depletion notification appears in compact widget, session is not halted
- [ ] Bait depletion mid-session does NOT trigger the S-02 session halt confirmation prompt
- [ ] Equipping or swapping bait during CASTING or PAUSED triggers the S-02 session halt confirmation
- [ ] Unequipping bait during SETUP or BREAK requires no confirmation; slot updates immediately
- [ ] Spinner Bait is not purchasable (greyed, lock indicator shown) until Area 2 is unlocked
- [ ] `active_bait_id` and `uses_remaining` survive app close and reopen unchanged
- [ ] With Spinner Bait active in Area 1 (no Salmonidae in catch table): bait is consumed per cast, catch probabilities are unchanged from the no-bait baseline
- [ ] Full `bait_data[]` array (name, family, cost, uses_remaining, lock state, is_active) is correctly exposed to Cat Market for all bait types

## Open Questions

| Question | Owner | Target Resolution |
| ---- | ---- | ---- |
| Should the bait slot in the compact widget be tappable to open the market directly to the bait section? | Designer / UX | Decide during widget prototype; current assumption: yes, tapping the bait slot shortcuts to the bait section of the market |
| How many bait types should Area 2 introduce? The MVP Spinner Bait (Salmonidae) unlocks at Area 2 — should Areas 2+ each add 3–5 new types or fewer? | Designer | Define when S-07 (Area Progression) GDD is authored |
| Should the "wrong area" scenario (bait with no matching fish) surface any soft hint in the album or market, or remain fully silent as a knowledge test? | Designer | Revisit during playtest; current spec: fully silent |
| Is the `bait_multiplier` uniform (×4.0) for all bait types permanent, or do higher-tier baits get stronger multipliers at full vision? | Designer | Revisit at Vertical Slice; current spec: uniform ×4.0 for all tiers |
