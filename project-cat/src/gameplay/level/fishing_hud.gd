class_name FishingHUD
extends Control
## Translucent status overlay for the Backyard Pond scene.
##
## Read-only HUD layered over the real pond art (it does NOT drive or configure
## the loop — the level owns that). Shows the live fishing state, session
## progress + time remaining, bucket fill, and a fading "last catch" readout so
## the player can tell what the cat is doing at a glance.
##
## Built entirely in code (no scene file) and bound by the level via [method bind].
## Mouse input is ignored throughout so it never blocks dragging the widget or
## clicking the Market / Album buttons beneath it.

# --- State display ---------------------------------------------------------------

var _state_labels: Dictionary    # FishingLoop.State -> String
var _rarity_colors: Dictionary   # FishingConfig.RarityTier -> Color

# --- Bindings --------------------------------------------------------------------

var _loop: FishingLoop
var _catch_table: Array = []

# --- Widgets (built in code) -----------------------------------------------------

var _state_label: Label
var _bucket_label: Label
var _progress_bar: ProgressBar
var _pct_label: Label
var _time_label: Label
var _catch_label: Label
var _catch_tween: Tween


func _ready() -> void:
	_init_tables()
	_build_ui()
	# Don't poll until bound.
	set_process(false)


## Wires the HUD to a running [FishingLoop] and the area's catch table (for fish
## display names + rarity colours). Call once from the level after the loop exists.
func bind(loop: FishingLoop, catch_table: Array) -> void:
	_loop = loop
	_catch_table = catch_table
	if not _loop:
		push_error("FishingHUD.bind: loop is null")
		return
	_loop.state_changed.connect(_on_state_changed)
	_loop.fish_caught.connect(_on_fish_caught)
	_loop.bucket_changed.connect(_on_bucket_changed)
	_on_state_changed(_loop.get_state())
	_on_bucket_changed(_loop.get_bucket_count(), _loop.get_bucket_capacity())
	set_process(true)


func _init_tables() -> void:
	_state_labels = {
		FishingLoop.State.SETUP:    "Setup",
		FishingLoop.State.CASTING:  "Fishing…",
		FishingLoop.State.CATCHING: "Fish on!",
		FishingLoop.State.PAUSED:   "Bucket full",
		FishingLoop.State.BREAK:    "Break (zzz)",
	}
	_rarity_colors = {
		FishingConfig.RarityTier.COMMON:   Color(0.85, 0.85, 0.85),
		FishingConfig.RarityTier.UNCOMMON: Color(0.45, 0.78, 1.00),
		FishingConfig.RarityTier.RARE:     Color(1.00, 0.85, 0.20),
	}


# --- Live polling ----------------------------------------------------------------

func _process(_delta: float) -> void:
	match _loop.get_state():
		FishingLoop.State.CASTING, FishingLoop.State.CATCHING, FishingLoop.State.PAUSED:
			var p := _loop.get_session_progress()
			_progress_bar.value = p
			_pct_label.text = "%d%%" % int(p * 100.0)
			_time_label.text = "%s left" % _fmt_time(_loop.get_session_time_remaining())
		FishingLoop.State.BREAK:
			var remaining := _loop.get_break_time_remaining()
			var total := maxf(_loop.get_break_duration(), 0.001)
			_progress_bar.value = 1.0 - clampf(remaining / total, 0.0, 1.0)
			_pct_label.text = ""
			_time_label.text = "Break: %s" % _fmt_time(remaining)
		FishingLoop.State.SETUP:
			pass


static func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	if s >= 60:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%ds" % s


# --- Signal handlers -------------------------------------------------------------

func _on_state_changed(new_state: FishingLoop.State) -> void:
	_state_label.text = _state_labels.get(new_state, "?")
	if new_state == FishingLoop.State.SETUP:
		_progress_bar.value = 0.0
		_pct_label.text = "0%"
		_time_label.text = "Ready"


func _on_bucket_changed(count: int, capacity: int) -> void:
	_bucket_label.text = "Bucket %d/%d" % [count, capacity]
	_bucket_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.55, 0.35) if count >= capacity else Color.WHITE
	)


func _on_fish_caught(species_id: StringName, size_cm: float) -> void:
	var species := _find_species(species_id)
	var rarity: int = FishingConfig.RarityTier.COMMON
	var display_name := String(species_id)
	if not species.is_empty():
		rarity = int(species["rarity_tier"])
		display_name = String(species.get("display_name", species_id))

	var star := ""
	match rarity:
		FishingConfig.RarityTier.RARE:     star = "  ★"
		FishingConfig.RarityTier.UNCOMMON: star = "  ·"

	_catch_label.text = "Caught %s  %.1f cm%s" % [display_name, size_cm, star]
	_catch_label.add_theme_color_override("font_color", _rarity_colors.get(rarity, Color.WHITE))

	# Pop in, hold, then fade out.
	if _catch_tween and _catch_tween.is_running():
		_catch_tween.kill()
	_catch_label.modulate.a = 1.0
	_catch_tween = create_tween()
	_catch_tween.tween_interval(2.5)
	_catch_tween.tween_property(_catch_label, "modulate:a", 0.0, 1.0)


func _find_species(species_id: StringName) -> Dictionary:
	for entry in _catch_table:
		if StringName(entry["id"]) == species_id:
			return entry
	return {}


# --- UI construction -------------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_status_panel()
	_build_catch_toast()


## Translucent status bar pinned below the widget title (which sits at y≈16-40).
func _build_status_panel() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.offset_left = 10.0
	panel.offset_right = -10.0
	panel.offset_top = 46.0
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.62)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Row 1: state (left) + bucket (right)
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	_state_label = _mk_label("Setup", 15, HORIZONTAL_ALIGNMENT_LEFT)
	_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_state_label)

	_bucket_label = _mk_label("Bucket 0/0", 13, HORIZONTAL_ALIGNMENT_RIGHT)
	top_row.add_child(_bucket_label)

	# Row 2: session progress bar + percent
	var prog_row := HBoxContainer.new()
	prog_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_row.add_theme_constant_override("separation", 6)
	vbox.add_child(prog_row)

	_progress_bar = ProgressBar.new()
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_row.add_child(_progress_bar)

	_pct_label = _mk_label("0%", 11, HORIZONTAL_ALIGNMENT_RIGHT)
	_pct_label.custom_minimum_size = Vector2(34, 0)
	prog_row.add_child(_pct_label)

	# Row 3: session time remaining
	_time_label = _mk_label("Ready", 12, HORIZONTAL_ALIGNMENT_LEFT)
	vbox.add_child(_time_label)


## Fading "last catch" readout, pinned low (above the Market/Album button strip).
func _build_catch_toast() -> void:
	_catch_label = _mk_label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	_catch_label.anchor_left = 0.0
	_catch_label.anchor_right = 1.0
	_catch_label.anchor_top = 0.0
	_catch_label.offset_left = 10.0
	_catch_label.offset_right = -10.0
	_catch_label.offset_top = 392.0
	_catch_label.offset_bottom = 420.0
	_catch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_catch_label.modulate.a = 0.0
	# Outline so it reads over both grass and water.
	_catch_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_catch_label.add_theme_constant_override("outline_size", 4)
	add_child(_catch_label)


func _mk_label(text: String, size: int, align: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = align
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	# Subtle outline keeps text legible over the bright pond art.
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("outline_size", 3)
	return lbl
