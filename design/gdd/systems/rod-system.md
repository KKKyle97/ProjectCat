# S-04 · Rod System

> **Status**: Approved
> **Author**: Design session 2026-05-29
> **Last Updated**: 2026-05-29
> **Implements Pillar**: Pillar 4 (Gear is the Progression)

## Overview

The Rod System defines the five fishing rods available to the player, each representing a tier of progression. Every rod has two stats: `cast_interval` (how quickly the cat fishes) and `bucket_capacity` (how many fish it can hold before the cat pauses). Rods are purchased sequentially at the Cat Market using coins; only the next tier is available to buy at any time. The equipped rod's stats are read by the Fishing Loop at session start and on any rod change. Rods are the primary mechanical progression axis — upgrading a rod is the most impactful single action a player can take, directly expanding both the pace of income and the length of time the game can run unattended.

## Player Fantasy

Buying a new rod should feel like a small occasion — the cat gets a better tool, the fishing spot feels more alive, and the player knows the next check-in will be more productive. The upgrade isn't a gate that was blocking progress; it's a reward for the coins earned through patience. Each rod has a distinct name and visual character so the player can point to their current rod and feel ownership: *"I'm using the Bamboo Stalker now, working toward the Carbon Whip."* The progression is transparent — the player can always see exactly what the next rod costs and what it will improve — so the upgrade arc feels like a plan, not a grind.

## Detailed Design

### Core Rules

1. There are **5 rod tiers**. Every player starts with Tier 1 (Stick & String) equipped at no cost.
2. Each rod has exactly two gameplay stats: `cast_interval` (seconds between catches) and `bucket_capacity` (max fish in bucket before pausing). Values are fixed per tier — not random, not modifiable by any other system.
3. Each rod has a **minimum area tier** it is required to unlock. Area access is checked by the Area Progression system against the player's `equipped_tier`.
4. Rods are purchased **sequentially** — T2 before T3, T3 before T4, etc. Skipping tiers is not possible. Sequential enforcement is UI-layer only — no data-layer validation is required for a single-player local game.
5. Only the **next unowned tier** is shown as purchasable in the Cat Market. All tiers are visible (for transparency), with owned tiers marked and future tiers shown greyed with cost.
6. On purchase, `equipped_tier` updates immediately. The Fishing Loop reads the new stats at the start of the next session — any active session must be halted first (S-02 Rule 7 confirmation prompt).
7. There is no downgrade path. Rod tiers are permanent once purchased.
8. Each rod has a **name** and a **flavour description** shown in the market UI.

### Rod Data Table

| Tier | Name | `cast_interval` | `bucket_capacity` | Unlocks Through | Cost | Flavour |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| T1 | Stick & String | 150 s | 25 | Area 2 | Free | *A trusty twig and some fishing line. The cat doesn't mind.* |
| T2 | Bamboo Stalker | 108 s | 37 | Area 3 | 250c | *Light, flexible, reliable. The cat sits up a little straighter.* |
| T3 | River Runner | 78 s | 56 | Area 5 | 700c | *Built for moving water. Opens up new spots the cat's been eyeing.* |
| T4 | Deep Seeker | 56 s | 84 | Area 6 | 1,800c | *Weighted for depth. Whatever's down there, this reaches it.* |
| T5 | Carbon Whip | 40 s | 126 | Area 7 | 5,000c | *Whisper-thin, impossibly strong. The cat barely moves. The fish do all the work.* |

### Area Access Gates (Rod Requirement)

| Area | Min Rod Tier | Rationale |
| ---- | ---- | ---- |
| Area 1 (Backyard Pond) | T1 | Starting area — no gate |
| Area 2 | T1 | Early content; T1 covers first two areas |
| Area 3 | T2 | First upgrade unlocks first expansion |
| Area 4 | T3 | Mid-game gate |
| Area 5 | T3 | T3 unlocks two areas — rewards the mid-game investment |
| Area 6 | T4 | Late-game gate |
| Area 7 (Deep) | T5 | Endgame gate — the final frontier |

### States and Transitions

The Rod System is stateless beyond the stored `equipped_tier` and `owned_tiers[]` array.

| State | Description |
| ---- | ---- |
| **IDLE** | Default state. `equipped_tier` and `owned_tiers[]` set and exposed to other systems. |
| **PURCHASE_PENDING** | Player has confirmed purchase in Cat Market; coin deduction in progress. Resolves instantly — `equipped_tier` and `owned_tiers[]` updated. Returns to IDLE. |

### Interactions with Other Systems

| System | Data In | Data Out | Owner |
| ---- | ---- | ---- | ---- |
| S-06 Cat Market | *(none)* | `rod_data[all_tiers]` (name, cost, stats, flavour, owned status) for shop display; `next_purchasable_tier` | Rod System owns data; Market reads for UI |
| S-06 Cat Market (purchase) | Purchase confirmed + coin deducted signal | `equipped_tier` and `owned_tiers[]` updated | Market owns coin deduction; Rod System owns tier state |
| S-02 Fishing Loop | *(none)* | `cast_interval` (float, seconds — rounded to nearest whole second before use), `bucket_capacity` (int) for current `equipped_tier` | Rod System owns values; Fishing Loop reads on session start |
| S-07 Area Progression | *(none)* | `equipped_tier` (int) for area access gate check | Rod System owns tier; Area Progression reads to validate unlock eligibility |
| S-08 Save System | `equipped_tier` (int), `owned_tiers[]` (bool array) on load | Same fields written on purchase and app close | Save System owns file; Rod System provides state snapshot |

## Formulas

Rod stat values are derived from formulas defined in S-02 (Fishing Loop). This system owns the data; S-02 owns the formulas. Do not redefine the formulas here — reference them.

### Cast Interval

Defined in S-02 Formulas: `cast_interval(rod_tier) = 150 × 0.72 ^ (rod_tier − 1)`

| Tier | cast_interval (s) | Improvement vs previous |
| ---- | ---- | ---- |
| T1 | 150 | — (baseline) |
| T2 | 108 | −28% (42 s faster) |
| T3 | 78 | −28% (30 s faster) |
| T4 | 56 | −28% (22 s faster) |
| T5 | 40 | −29% (16 s faster) |

Each tier is approximately 28% faster than the previous — consistent improvement that doesn't feel diminishing. `cast_interval` values are rounded to the nearest whole second before being stored and passed to the Fishing Loop (e.g. 77.76 → 78, 40.31 → 40).

### Bucket Capacity

Defined in S-02 Formulas: `bucket_capacity(rod_tier) = floor(25 × 1.50 ^ (rod_tier − 1))`

| Tier | bucket_capacity | Fill time at tier cast rate |
| ---- | ---- | ---- |
| T1 | 25 fish | ~62 min |
| T2 | 37 fish | ~67 min |
| T3 | 56 fish | ~73 min |
| T4 | 84 fish | ~78 min |
| T5 | 126 fish | ~84 min |

Fill time stays deliberately stable (~60–85 min) across all tiers. Upgrading never makes the game more demanding; it makes it more productive within the same check-in rhythm.

### Purchase Cost Scaling

Costs are authored values (not formula-derived), anchored to the economy reference in game-concept.md:

| Tier | Cost | Cumulative investment | Approx. hours to afford (T1 passive income ~120c/hr) |
| ---- | ---- | ---- | ---- |
| T1 | Free | 0c | 0 |
| T2 | 250c | 250c | ~2 hrs |
| T3 | 700c | 950c | ~8 hrs cumulative |
| T4 | 1,800c | 2,750c | ~23 hrs cumulative |
| T5 | 5,000c | 7,750c | ~65 hrs cumulative |

These are rough estimates — actual income grows as the player upgrades rods and reaches higher-value areas. The intent is: T2 feels accessible in the first day; T5 is a multi-week achievement.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
| ---- | ---- | ---- |
| Player tries to purchase T3 without owning T2 | T3 purchase button is disabled and hidden; only the next unowned tier is purchasable | Sequential rule enforced at UI level |
| Insufficient coins at moment of purchase deduction | Purchase fails; "Not enough coins" message shown; no state changes | Coin balance may change between tap and deduction — validate at deduction time |
| Player purchases a rod while a session is active | S-02 confirmation prompt fires first ("End session?"); if cancelled, rod purchase is also cancelled; if confirmed, session halts then rod purchase completes | Rod purchase and session halt are coupled — rod system waits for session confirmation |
| App closes mid-purchase (between coin deduction and tier update) | Neither change is committed; `owned_tiers[]` and coin balance revert to pre-purchase state on reload | Atomic write: both changes succeed together or neither is written |
| Player reaches T5 (max tier) | Shop shows all rods as owned; no purchasable rod visible; no "next upgrade" prompt | Terminal state — no further rod progression |
| Area was unlocked at T2 minimum; player somehow has T1 (impossible in normal flow) | Area remains accessible — gate is checked at unlock time only, not continuously | Access is one-way; downgrade is architecturally impossible anyway |

## Dependencies

| System | Direction | Nature | Status |
| ---- | ---- | ---- | ---- |
| S-06 Cat Market | Rod System depends on S-06 | Market owns purchase UI and coin deduction; Rod System provides `rod_data[all_tiers]` and receives purchase confirmation signal | ⚠️ Provisional — S-06 not yet designed |
| S-02 Fishing Loop | S-02 depends on Rod System | Rod System provides `cast_interval` and `bucket_capacity` for the current `equipped_tier`; read by Fishing Loop on each session start | ✅ Confirmed — S-02 GDD Approved |
| S-07 Area Progression | S-07 depends on Rod System | Rod System provides `equipped_tier` (int); Area Progression reads it as one of the three area unlock gate conditions | ⚠️ Provisional — S-07 not yet designed |
| S-08 Save System | Bidirectional | Save System persists `equipped_tier` (int) and `owned_tiers[]` (bool[5]); reads on load, writes on purchase confirmation | S-08 not yet designed |

## Tuning Knobs

Cost values are owned by this system in `res://config/rod_config.gd`. Formula constants (`I_base`, `decay_rate`, `B_base`, `growth_rate`) are owned by S-02 in `res://config/fishing_config.gd` — listed here for reference only.

| Parameter | Default | Safe Range | Too High | Too Low |
| ---- | ---- | ---- | ---- | ---- |
| T2 cost | 250c | 150–400c | Early progression blocked; new players churn | T2 trivially fast; no sense of earned upgrade |
| T3 cost | 700c | 500–1,200c | Mid-game wall | Players rush past T3 before exploring Areas 1–2 |
| T4 cost | 1,800c | 1,200–3,000c | Late-game grind | Late progression too fast; T5 endgame feels cheap |
| T5 cost | 5,000c | 3,500–8,000c | Many players never reach it | Endgame achievement feels unearned |
| `I_base` *(S-02 owned)* | 150 s | 120–180 s | Slow T1 early game | T1 too fast; bucket fills before onboarding |
| `decay_rate` *(S-02 owned)* | 0.72 | 0.65–0.80 | Flat per-tier improvement | T5 dominates; mid-tier rods feel negligible |
| `B_base` *(S-02 owned)* | 25 fish | 20–35 | Infrequent check-in; game feels too passive | Bucket fills too fast; too demanding for idle play |
| `growth_rate` *(S-02 owned)* | 1.50 | 1.30–1.75 | Game becomes trivially passive at high tiers | Bucket barely grows; check-in rhythm never improves |

**Coupled costs**: Rod costs and area unlock coin gates (defined in S-07) must be tuned together. Recommended stagger: make the rod upgrade affordable ~200c *before* the matching area gate, so the player buys the rod first, fishes one session with the upgraded gear, then pays the gate. Example: T3=700c, Area 3 gate=900c (total ~1,600c needed, earned at T2 rate ~160c/hr ≈ 10 hrs). This creates a two-step unlock rhythm rather than a single large spend. If both costs land at the same moment, the gate feels like a wall; the stagger makes it feel like a sequence.

## Visual/Audio Requirements

| Element | Requirement | Priority |
| ---- | ---- | ---- |
| Rod sprite in fishing scene | Each tier has a visually distinct rod sprite rendered in the cat's paw — more ornate/longer as tier increases | Must-have |
| Purchase animation | Brief sparkle/glow on rod sprite when new tier purchased; cat looks at it approvingly | Should-have |
| Rod icon in shop | Small illustrated icon per tier; owned tiers shown with a tick; current tier highlighted | Must-have |
| Audio on purchase | Satisfying "upgrade" chime — distinct from catch sounds | Should-have |

## UI Requirements

| Element | Location | Notes |
| ---- | ---- | ---- |
| Rod shop section | Cat Market panel, dedicated tab or section | Shows all 5 tiers; owned ticked; next purchasable highlighted with cost; future tiers greyed |
| Current rod indicator | Compact window — small icon near cat or bottom bar | Shows equipped rod name; tapping opens market to rod section |
| Cost display | Next rod entry in shop | Shows exact coin cost; greyed if player cannot afford |
| Stat comparison | On hover/tap of next rod | Shows current vs. next: "Cast: 150s → 108s · Bucket: 25 → 37" |

## Acceptance Criteria

- [ ] Player starts with T1 (Stick & String) equipped; T2 is visible in the shop at 250c
- [ ] Purchasing T2 deducts exactly 250c from coin balance and sets `equipped_tier = 2`
- [ ] T3 is not purchasable until T2 is owned; its button is disabled/hidden
- [ ] Fishing Loop reads updated `cast_interval` and `bucket_capacity` at next session start after upgrade
- [ ] Area Progression correctly reads `equipped_tier` as one of the three gate conditions for each area
- [ ] Full `rod_data` array (name, flavour, stats, cost, owned bool) is correctly exposed to Cat Market for all 5 tiers
- [ ] `equipped_tier` and `owned_tiers[]` survive app close and reopen unchanged
- [ ] Purchase with insufficient coins shows error; coin balance and `equipped_tier` unchanged
- [ ] Mid-purchase crash (simulated) leaves both coin balance and `owned_tiers[]` in pre-purchase state on reload
- [ ] At T5, no further purchase is shown or available
- [ ] Rod sprite in fishing scene updates to match `equipped_tier` immediately on purchase (during SETUP/BREAK) — not deferred to next session start

## Open Questions

| Question | Owner | Target Resolution |
| ---- | ---- | ---- |
| Should the stat comparison on the shop show the cast interval change as a time value (42s faster) or a percentage (28% faster)? | Designer | Decide during UI prototype — time feels more concrete for this audience |
| Should purchasing a rod automatically equip it, or should there be a separate "equip" action? | Designer | Current spec: auto-equip on purchase. Only relevant if a future cosmetic rod tier is added (unlikely given pillars). |
