# ADR-002 · Fishing Loop Implementation

- **Status**: Accepted
- **Date**: 2026-05-29
- **Implements**: [S-02 Fishing Loop](../../design/gdd/systems/fishing-loop.md)
- **Engine**: Godot 4.6.3

## Context

S-02 is the autonomous, Pomodoro-style catch cycle that drives all progression:
player-set session/break timers, weighted catch tables whose rare weights climb
with session progress, a bucket that pauses when full, and offline resolution of
time spent away. It must be frame-rate independent, data-driven, and testable in
isolation from presentation and from the (not-yet-built) rod/bait/area/save systems.

## Decisions

1. **Catch math is a pure, stateless class** (`CatchResolver`), separate from the
   `FishingLoop` node. It takes an injected `RandomNumberGenerator`, so every result
   is deterministic and verifiable. This is what let us assert the GDD's four worked
   examples to 4 decimal places (`tests/fishing/sim_catch_resolver.gd`, 28/28 pass).

2. **`FishingLoop` is a self-contained `Node` with no outward dependencies.** Rod
   stats, bait, and the catch table are pushed in via setters; results go out via
   signals (`fish_caught`, `bucket_changed`, state/session/break signals). It never
   references UI or other systems — satisfying the gameplay-code rules and letting
   S-04/S-05/S-06/S-08 wire in later without changes here.

3. **All tuning in `config/fishing_config.gd`** (`FishingConfig`), including the
   rod stat *formulas* (`cast_interval`, `bucket_capacity`) which S-02 owns and S-04
   will consume. No magic numbers in the loop.

4. **Offline resolution is a stepwise simulation** (`resolve_offline`) that advances
   cast/session/break clocks in lockstep through session ends, breaks, and
   auto-restarts. Because the bucket can't be sold while away, it naturally fills at
   most once and discards excess casts — matching Rule 10. Verified: a 1-hour
   absence caps the bucket at capacity.

5. **Content is data-driven via JSON** (`data/areas/backyard_pond.json` +
   `FishCatalog`). The MVP roster is explicitly placeholder; final fish content is
   owned by S-03 / S-07.

## Design discrepancy surfaced (needs designer ruling)

The GDD is internally inconsistent on the end-of-break transition:
- **Prose** (Overview, Rule 9, Core Loop — stated 3×): a new session **auto-starts**
  when the break timer expires, using the same settings.
- **States table**: `BREAK → SETUP`.

We implemented the **auto-start** reading (CASTING resumes after break), since the
prose states it three times and it fits the "cat does the work" pillar. If the
designer intends the player to re-confirm settings each cycle (→ SETUP), this is a
one-line change in `_tick_break` / `_step_offline_break`. Flagged for resolution.

## Consequences

- Catch distribution, size rolls, weighted draw, and offline resolution are all
  verified against the GDD today, ahead of any UI.
- **Not yet built (presentation / integration)**: SETUP sliders + Start button,
  the 2-second equipment-change confirmation prompt (logic hook `halt_for_equipment_change`
  exists; the prompt/timeout is UI), catch/break/cast animations, and the
  session-progress indicator. These are the S-01↔S-02 wiring step and need art.
