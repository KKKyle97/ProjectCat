class_name WindowConfig
extends RefCounted
## Central layout, timing, and behaviour constants for the S-01 Widget Window System.
##
## Implements the "Tuning Knobs" table of design/gdd/systems/widget-window.md.
## Per the GDD: "All values are set in a single Godot project constant file
## (res://config/window_config.gd). No magic numbers in scene files." Every other
## script and scene must source window geometry from here rather than literals.
##
## Usage (static access — never instanced):
## [codeblock]
## var w := WindowConfig.COMPACT_WIDTH   # 360
## [/codeblock]

# --- Window geometry (logical pixels @ 100% DPI) ---

## Compact-state window width. GDD safe range: 280–480 px.
const COMPACT_WIDTH: int = 360
## Compact-state window height (fishing view only). GDD safe range: 380–600 px.
const COMPACT_HEIGHT: int = 480
## Height added below the fishing view when a panel (market/album) opens.
## GDD safe range: 240–440 px. Content scrolls internally if it overflows.
const PANEL_HEIGHT: int = 320
## Total window height while a panel is open. Derived, not authored.
const EXPANDED_HEIGHT: int = COMPACT_HEIGHT + PANEL_HEIGHT  # 800

# --- Behaviour / timing ---

## Duration of the expand/collapse height tween, in seconds (GDD: 120 ms).
## Safe range: 0.080–0.250 s.
const EXPAND_TWEEN_DURATION: float = 0.120
## Inset from the screen edge used when resetting an off-screen window to the
## default bottom-right corner. GDD safe range: 0–40 px.
const DEFAULT_INSET: int = 20

# --- Visual ---

## Rounded-corner radius of the widget frame (px). Also drives the click-through
## silhouette so transparent corners pass clicks to the desktop beneath.
const CORNER_RADIUS: int = 12
## Width of the alpha-feathered fade into transparency at the window edge (px).
const EDGE_FEATHER: int = 8

# --- Persistence ---

## Placeholder local store for window position. Ownership of persistence moves to
## the S-08 Save System once it exists; this file is the interim home so the
## "position survives restart" acceptance criterion can be met today.
const WINDOW_STATE_PATH: String = "user://window_state.cfg"
