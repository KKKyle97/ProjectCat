# S-01 · Widget Window System

> **Status**: Approved
> **Author**: Design session 2026-05-28
> **Last Updated**: 2026-05-28
> **Implements Pillar**: Pillar 1 (The Cat Does the Work) · Pillar 5 (Check-In is Rewarding, Never Punishing)

## Overview

The Widget Window System manages the desktop presence of Cat & Hook. It renders as a medium-sized (~360×480px), transparent, borderless, always-on-top panel — no title bar, no minimize/maximize buttons, no taskbar entry by default. The player can drag it anywhere on screen, and all non-UI areas of the window are click-through (mouse events pass through to whatever is beneath). The game renders inside this panel continuously whether the player is looking at it or not. It is the host container for all other systems' visuals and is the first thing designed and the last thing that can change.

## Player Fantasy

The window should feel like a postcard pinned to a corner of the desk — present without demanding. When the player first places it, they should feel like they've found the right spot for a small, living thing. When they glance at it mid-work, it should feel like looking up from a book to check on a pet sleeping in the corner: no urgency, just warmth. The window never asks for attention. It earns glances. Its visual boundaries are soft (rounded corners, faded edges into transparency) so it doesn't feel like a rectangular intrusion — it feels like it was always there.

## Detailed Design

### Core Rules

1. Default window size is **360×480 px** (logical pixels at 100% DPI). When a panel is open, the window expands vertically to **360×800 px**; it returns to 360×480 px when the panel is closed.
2. The window is **borderless, transparent-background, and always-on-top**. It has no OS title bar, no minimize/maximize/close buttons, and no taskbar entry.
3. **Click-through** uses pixel-alpha detection: any pixel with alpha = 0 passes mouse events to the desktop beneath. Opaque pixels (game scene, UI elements) receive mouse events normally.
4. **Dragging**: Left-click-and-hold on any non-interactive opaque area (water, background, cat sprite) moves the window. UI buttons and interactive elements receive their own click events and do not trigger drag.
5. **Window position** persists across sessions via the Save System. On load, if the saved position places the window entirely off-screen, it resets to default (bottom-right corner, 20 px inset from screen edge).
6. **DPI scaling**: uses Godot 4's `display/window/dpi/allow_hidpi = true`. All layout values are logical pixels; the engine scales automatically. At 150% DPI the widget renders at 540×720 physical pixels.
7. **Multi-monitor**: position is saved in absolute screen coordinates. On load, the engine checks if the window rect intersects any connected display; if not, it resets to the primary monitor's default position.
8. **System tray icon**: a system tray entry provides right-click options — *Hide/Show*, *Reset Position*, and *Quit*. When hidden, the game process continues running (fishing loop accumulates catches). The window becomes visible again via the tray or by relaunching the executable.
9. **Panel expand direction**: the window always expands downward. If expanding down would go off-screen, the panel content scrolls internally rather than repositioning the window.
10. The window renders **continuously** — there is no pause when the window is covered by other applications or when the player is not focused on it.
11. **HIDDEN state rendering**: when in HIDDEN state, Godot's rendering loop is paused (via `set_process(false)` or equivalent); game simulation logic (fishing timer, bucket accumulation) continues at full speed via a separate process tick. This eliminates unnecessary GPU load on laptops while preserving idle functionality.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
| ---- | ---- | ---- | ---- |
| **COMPACT** | App start; panel closed | Player clicks market/album/settings button | Fishing animation plays. Window 360×480. Non-UI pixels click-through. |
| **PANEL_OPEN** | Player clicks market, album, or settings button | Player clicks close/back in panel | Window expands to 360×800. Panel renders below fishing view. Fishing continues behind panel. |
| **DRAGGING** | Left-mouse-down on draggable area (any state) | Mouse button released | Window follows cursor delta. Click-through disabled during drag. |
| **HIDDEN** | Player selects Hide from system tray | Player selects Show from tray or relaunches exe | Window invisible. Game loop continues. Catches accumulate normally. |

### Interactions with Other Systems

| System | Data In | Data Out | Owner |
| ---- | ---- | ---- | ---- |
| S-08 Save System | Window position (x, y) on load | Window position (x, y) on drag end and app close | Save System owns read/write; Widget Window reads on init |
| S-02 Fishing Loop | *(none — widget is display host)* | Renders fishing animation in upper zone of compact window | Fishing Loop owns animation state; Widget Window provides render surface |
| S-09 Cat Collection | Active cat sprite + animation state | *(none)* | Cat Collection owns which sprite; Widget Window renders it |
| S-11 Cosmetics | Active background asset | *(none)* | Cosmetics owns asset selection; Widget Window renders it |
| S-03, S-06 (panel systems) | Panel open/close signal | Triggers PANEL_OPEN state; renders panel in lower zone | Widget Window owns state machine; each panel system owns its UI content |

## Formulas

This system has no game-balance math. Its formulas are layout calculations.

### Window Expand

```
expanded_height = compact_height + panel_height
```

| Variable | Value | Notes |
| ---- | ---- | ---- |
| compact_height | 480 px | Fixed compact state height |
| panel_height | 320 px | Fixed panel zone height; content scrolls internally if needed |
| expanded_height | 800 px | Maximum window height |

Expand/collapse is a **linear tween over 120 ms**. Fast enough to feel snappy; slow enough to communicate the transition.

### Off-Screen Reset Position

```
default_x = screen_width - compact_width - 20
default_y = screen_height - compact_height - 20
```

Triggers when the saved position rect does not intersect any connected display rect on load.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
| ---- | ---- | ---- |
| Saved position is off all monitors | Reset to default position (bottom-right, 20 px inset) on load | Prevents invisible window on startup |
| Window partially off-screen | Allowed — player may intentionally park widget at screen edge | Don't auto-correct; trust the player |
| Display resolution changes between sessions | Re-run off-screen check on load; reset only if fully off-screen | Multi-monitor disconnect is the common case |
| Player drags window fully off-screen | Allowed during drag; no boundary enforcement | Consistent with above; trust the player |
| Panel open during drag | DRAGGING state takes priority; panel remains open | Don't force panel close on reposition |
| Panel expand would go off bottom of screen | Panel content scrolls internally; window does not reposition or move | Per Rule 9 — never move the window unexpectedly |
| System tray not supported (some Mac/Linux configs) | Show a small always-visible ✕ button on the widget frame as fallback | Close must always be accessible |
| Game process crashes | Window disappears; no data loss if Save System writes on each state change | Save System owns crash safety |
| Two instances launched | Second instance detects running instance via lock file and exits silently with a brief OS notification | One widget on screen at all times |

## Dependencies

| System | Direction | Nature |
| ---- | ---- | ---- |
| S-08 Save System | Bidirectional | Reads window position on load; writes position on move and app close |
| S-02 Fishing Loop | Widget depends on Fishing Loop | Provides render surface; Fishing Loop drives animation content |
| S-09 Cat Collection | Widget depends on Cat Collection | Receives active cat sprite and animation state to render |
| S-11 Cosmetics | Widget depends on Cosmetics | Receives active background asset to render |
| S-03 Fish Album | Bidirectional | Widget hosts album panel UI; Album signals open/close |
| S-06 Cat Market | Bidirectional | Widget hosts market panel UI; Market signals open/close |

S-01 has no upstream dependencies at MVP scope. At Vertical Slice and beyond, S-09 (Cat Collection) and S-11 (Cosmetics) become soft upstream providers of sprite and background data respectively — S-01 renders their outputs but does not control their state.

## Tuning Knobs

| Parameter | Default | Safe Range | Too High | Too Low |
| ---- | ---- | ---- | ---- | ---- |
| `compact_width` | 360 px | 280–480 px | Too wide; intrudes on work screen | Too narrow; cat + water unreadable |
| `compact_height` | 480 px | 380–600 px | Occupies too much vertical screen | Scene feels cramped |
| `panel_height` | 320 px | 240–440 px | Panel pushes widget very tall | Not enough room for album/market content |
| `expand_tween_duration` | 120 ms | 80–250 ms | Animation feels sluggish | Jarring; no sense of transition |
| `default_inset` | 20 px | 0–40 px | Widget far from corner; unexpected default | Widget flush with screen edge; may clip |

All values are set in a single Godot project constant file (`res://config/window_config.gd`). No magic numbers in scene files.

## Visual/Audio Requirements

| Element | Requirement | Priority |
| ---- | ---- | ---- |
| Window edges | Soft rounded corners (~12 px radius); alpha-feathered outer edge (~8 px fade to transparent) to avoid hard rectangular cut | Must-have |
| Expand/collapse | Smooth tween — no pop-in; the window visually grows downward | Must-have |
| Panel divider | Subtle separator line between fishing zone and panel zone when expanded | Should-have |
| Hidden state | No visual indicator on screen; system tray icon remains | Must-have |
| Audio on open/close | No audio — window state changes are silent to avoid startling the player mid-work | Must-have |

## UI Requirements

| Element | Location | Notes |
| ---- | ---- | ---- |
| Market button | Bottom-left of compact window | Always visible; tapping opens panel |
| Album button | Bottom-right of compact window | Always visible; tapping opens panel |
| Settings / tray hint | Accessible via right-click on cat or tray icon only | Not a persistent UI element — avoids visual noise |
| Close button fallback | Top-right corner, 16×16 px, low opacity unless hovered | Only shown if system tray is unavailable |

## Acceptance Criteria

- [ ] Window launches borderless, transparent-background, and always-on-top on Windows 11
- [ ] Transparent (alpha = 0) pixels pass mouse clicks through to the desktop; opaque pixels do not
- [ ] Left-click-drag on a non-interactive area moves the window; position is preserved on restart
- [ ] Clicking a UI button (market, album) does not trigger drag
- [ ] Widget expands from 360×480 to 360×800 in ≤120 ms when a panel is opened; collapses on close
- [ ] Panel expand does not reposition the window; if bottom goes off-screen, panel scrolls
- [ ] Launching with a saved off-screen position resets to default bottom-right corner
- [ ] Launching on a different monitor config than at last save resets position if window would be fully off-screen
- [ ] Hide via system tray makes window invisible; fishing loop continues accumulating catches
- [ ] Show via system tray restores window at last position
- [ ] Launching a second instance shows a notification and the second process exits
- [ ] At 150% DPI, widget renders at 540×720 px and remains fully functional
- [ ] Performance: window rendering contributes ≤1 ms to frame time on the target hardware (integrated GPU, 1080p)

## Open Questions

| Question | Owner | Target Resolution |
| ---- | ---- | ---- |
| Does Godot 4 pixel-alpha click-through work correctly on Windows 11 with snap layouts active? | Programmer | Resolve via `/prototype widget-window` before implementation |
| Does always-on-top persist correctly when a full-screen application is launched? | Programmer | Test in prototype — may need `WINDOW_FLAG_ALWAYS_ON_TOP` + `WINDOW_MODE_FLOATING` combo |
| Mac port: does NSPanel / Godot 4 transparent window work on macOS without a separate plugin? | Programmer | Defer until Mac platform is targeted |
| Should the widget appear in Alt+Tab? Current spec says no taskbar entry, but Alt+Tab is separate. | Designer | Decide before implementation; recommend: exclude from Alt+Tab to maintain "invisible background" feel |
