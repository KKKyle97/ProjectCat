class_name WidgetWindow
extends Control
## S-01 Widget Window controller.
##
## Owns the desktop-presence behaviour of the Cat & Hook widget: a borderless,
## transparent, always-on-top OS window the player can drag anywhere on screen,
## with a compact fishing view that expands downward into a panel for the
## market/album. All other systems render inside this window; this script never
## reaches into them — it only exposes state via the [signal state_changed] signal.
##
## Implements: design/gdd/systems/widget-window.md
## Pillars: 1 (The Cat Does the Work), 5 (Check-In is Rewarding, Never Punishing)
##
## Geometry, timing, and persistence constants live in
## [WindowConfig] (res://config/window_config.gd) — no literals here.

## Widget lifecycle states. Mirrors the "States and Transitions" table in the GDD.
## (HIDDEN is reserved for the system-tray hide/show feature, not yet wired up.)
enum State { COMPACT, PANEL_OPEN, DRAGGING, HIDDEN }

## Emitted whenever the widget transitions between states. Downstream systems may
## observe this to drive animation/host behaviour; this system pushes, never pulls.
signal state_changed(new_state: State)

@onready var _market_button: Button = $Frame/MarketButton
@onready var _album_button: Button = $Frame/AlbumButton
@onready var _panel_zone: Control = $PanelZone

var _state: State = State.COMPACT
## State to restore to when a drag ends (COMPACT or PANEL_OPEN).
var _state_before_drag: State = State.COMPACT
## Offset from the window's top-left to the cursor at drag start, in absolute
## desktop pixels. Keeps the grab point fixed under the cursor while dragging.
var _drag_offset: Vector2i = Vector2i.ZERO
var _resize_tween: Tween


func _ready() -> void:
	_configure_window()
	_load_window_position()
	_update_passthrough()

	_market_button.pressed.connect(_toggle_panel)
	_album_button.pressed.connect(_toggle_panel)
	_panel_zone.visible = false

	_set_state(State.COMPACT)
	_setup_level()


func _setup_level() -> void:
	# Instance the real level scene. It owns its own FishingLoop child, which
	# registers itself in the "fishing_loop" group so FishingDebugUI can still
	# find it if re-enabled for debugging.
	var level_scene: PackedScene = load("res://scenes/levels/level_backyard_pond.tscn")
	var level := level_scene.instantiate()
	# Add behind the title label and Market/Album buttons (move_child index 0).
	$Frame.add_child(level)
	$Frame.move_child(level, 0)


## Applies the OS-level window flags at runtime as a backstop to the matching
## project.godot settings (the two together guard against platform quirks where a
## flag fails to apply on launch).
func _configure_window() -> void:
	var w := get_window()
	w.transparent_bg = true
	w.always_on_top = true
	w.borderless = true
	w.unresizable = true
	w.size = Vector2i(WindowConfig.COMPACT_WIDTH, WindowConfig.COMPACT_HEIGHT)


# --- State machine --------------------------------------------------------------

func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	_state = new_state
	state_changed.emit(_state)


## Returns the current widget state. Read-only accessor for other systems/tests.
func get_state() -> State:
	return _state


# --- Panel expand / collapse ----------------------------------------------------

func _toggle_panel() -> void:
	if _state == State.PANEL_OPEN:
		_collapse_panel()
	elif _state == State.COMPACT:
		_expand_panel()
	# Ignored while DRAGGING or HIDDEN.


func _expand_panel() -> void:
	_panel_zone.visible = true
	_tween_window_height(WindowConfig.EXPANDED_HEIGHT)
	_set_state(State.PANEL_OPEN)


func _collapse_panel() -> void:
	_tween_window_height(WindowConfig.COMPACT_HEIGHT)
	_set_state(State.COMPACT)
	# Hide the panel only once the window has finished shrinking back over it.
	await _resize_tween.finished
	if _state == State.COMPACT:
		_panel_zone.visible = false


## Tweens the OS window height to [param target_height] over the configured
## duration, then refreshes the click-through silhouette to the new size.
func _tween_window_height(target_height: int) -> void:
	if _resize_tween and _resize_tween.is_running():
		_resize_tween.kill()
	var w := get_window()
	var target := Vector2i(WindowConfig.COMPACT_WIDTH, target_height)
	_resize_tween = create_tween()
	_resize_tween.tween_method(_set_window_size, w.size, target, WindowConfig.EXPAND_TWEEN_DURATION)
	_resize_tween.tween_callback(_update_passthrough)


func _set_window_size(size: Vector2i) -> void:
	get_window().size = size


# --- Dragging -------------------------------------------------------------------
# Drag is handled in _unhandled_input so that clicks consumed by UI controls
# (the market/album buttons) never start a window drag — satisfying the GDD rule
# "UI buttons receive their own click events and do not trigger drag."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag()
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _state == State.DRAGGING:
		get_window().position = DisplayServer.mouse_get_position() - _drag_offset


func _begin_drag() -> void:
	if _state == State.DRAGGING or _state == State.HIDDEN:
		return
	_state_before_drag = _state
	_drag_offset = DisplayServer.mouse_get_position() - get_window().position
	# Disable click-through while dragging so the window never slips out from
	# under the cursor when it passes over a transparent region.
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
	_set_state(State.DRAGGING)


func _end_drag() -> void:
	if _state != State.DRAGGING:
		return
	_set_state(_state_before_drag)
	_update_passthrough()
	_save_window_position()


# --- Click-through silhouette ---------------------------------------------------

## Restricts mouse input to the rounded-rect silhouette of the widget; clicks on
## the transparent corners pass through to the desktop beneath. Pixel-perfect
## alpha passthrough (for gaps inside the art) remains a GDD open question and is
## intentionally approximated here by the frame outline.
func _update_passthrough() -> void:
	var poly := _rounded_rect_polygon(get_window().size, WindowConfig.CORNER_RADIUS)
	DisplayServer.window_set_mouse_passthrough(poly)


## Builds a clockwise rounded-rectangle polygon in window-local pixel coordinates.
func _rounded_rect_polygon(size: Vector2i, radius: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var w := float(size.x)
	var h := float(size.y)
	var r := float(clampi(radius, 0, mini(size.x, size.y) / 2))
	var segments := 4  # per corner; 4 keeps the polygon cheap while staying round
	var centers := [
		Vector2(w - r, r),      # top-right
		Vector2(w - r, h - r),  # bottom-right
		Vector2(r, h - r),      # bottom-left
		Vector2(r, r),          # top-left
	]
	var start_angles := [-PI / 2.0, 0.0, PI / 2.0, PI]
	for i in 4:
		var center: Vector2 = centers[i]
		var a0: float = start_angles[i]
		for s in segments + 1:
			var a := a0 + (PI / 2.0) * (float(s) / float(segments))
			pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


# --- Position persistence -------------------------------------------------------
# Interim ownership. The S-08 Save System will subsume window position once it
# exists; until then a small ConfigFile satisfies the "position survives restart"
# acceptance criterion.

func _load_window_position() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(WindowConfig.WINDOW_STATE_PATH) != OK:
		_reset_to_default_position()
		return
	var pos := Vector2i(
		int(cfg.get_value("window", "x", 0)),
		int(cfg.get_value("window", "y", 0)),
	)
	get_window().position = pos
	if not _is_window_on_any_screen():
		_reset_to_default_position()


func _save_window_position() -> void:
	var cfg := ConfigFile.new()
	var pos := get_window().position
	cfg.set_value("window", "x", pos.x)
	cfg.set_value("window", "y", pos.y)
	cfg.save(WindowConfig.WINDOW_STATE_PATH)


## True if any part of the window rect overlaps a connected display. Used on load
## to recover from a saved position that is now off all monitors.
func _is_window_on_any_screen() -> bool:
	var win_rect := Rect2i(get_window().position, get_window().size)
	for screen in DisplayServer.get_screen_count():
		var screen_rect := Rect2i(
			DisplayServer.screen_get_position(screen),
			DisplayServer.screen_get_size(screen),
		)
		if win_rect.intersects(screen_rect):
			return true
	return false


## Parks the window at the bottom-right of the primary display, inset per the GDD
## off-screen reset formula.
func _reset_to_default_position() -> void:
	var usable := DisplayServer.screen_get_usable_rect(0)
	var x := usable.position.x + usable.size.x - WindowConfig.COMPACT_WIDTH - WindowConfig.DEFAULT_INSET
	var y := usable.position.y + usable.size.y - WindowConfig.COMPACT_HEIGHT - WindowConfig.DEFAULT_INSET
	get_window().position = Vector2i(x, y)


# --- Shutdown -------------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_save_window_position()
