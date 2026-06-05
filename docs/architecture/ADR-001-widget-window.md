# ADR-001 · Widget Window Implementation

- **Status**: Accepted
- **Date**: 2026-05-29
- **Implements**: [S-01 Widget Window](../../design/gdd/systems/widget-window.md)
- **Engine**: Godot 4.6.3 (Compatibility / OpenGL renderer)

## Context

S-01 requires a borderless, transparent, always-on-top desktop widget the player
can drag anywhere, with a compact fishing view that expands downward into a panel.
The widget hosts every other system's visuals and must be cheap to render since it
runs continuously alongside the player's real work.

## Decisions

1. **Compatibility (OpenGL) renderer**, not Forward+. The widget is pure 2D and
   must be light on integrated GPUs; Compatibility also supports per-pixel window
   transparency on Windows. Changed in `project.godot`.

2. **Window flags are set in both `project.godot` and code.** `_configure_window()`
   re-asserts `transparent_bg`, `always_on_top`, `borderless`, and `unresizable` at
   runtime as a backstop against platform launch quirks. The project settings make
   the flags correct from the first frame; the code guarantees they hold.

3. **Drag via `_unhandled_input`.** Window dragging lives in `_unhandled_input` so
   that input already consumed by UI controls (market/album buttons) never starts a
   drag — directly satisfying the GDD rule that buttons must not trigger drag.
   Absolute desktop coordinates (`DisplayServer.mouse_get_position()`) drive the
   move to avoid relative-motion drift while the window itself is moving.

4. **Click-through = rounded-rect passthrough polygon**, not true per-pixel alpha.
   `DisplayServer.window_set_mouse_passthrough()` restricts input to the widget's
   rounded silhouette so the transparent corners pass clicks through. Pixel-perfect
   alpha passthrough remains an open GDD question (prototype-owned) and is
   intentionally approximated by the frame outline for now.

5. **All geometry/timing constants in `config/window_config.gd`** (`WindowConfig`).
   No magic numbers in the scene or controller, per coding standards and the GDD.

6. **Interim position persistence via `ConfigFile`** at `user://window_state.cfg`.
   The S-08 Save System will own this once it exists; this satisfies the
   "position survives restart" and off-screen-reset criteria today without blocking
   on a system that is not yet designed.

## Consequences

- Off-screen recovery, multi-monitor reset, drag, and expand/collapse are testable
  now against the S-01 acceptance criteria.
- **Deferred / not yet verified**: HiDPI logical-pixel scaling (150% → 540×720),
  system-tray hide/show (HIDDEN state), single-instance lock, Alt+Tab exclusion,
  and pixel-perfect click-through. These are tracked as S-01 open questions.
