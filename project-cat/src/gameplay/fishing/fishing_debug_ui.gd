class_name FishingDebugUI
extends Control
## Visual validation interface for S-02 Fishing Loop.
##
## Builds its own UI in code — no scene editor needed.  Shows live state,
## session progress, timers, bucket level, a catch log, and dev controls
## (Start Session, Sell All) so the fishing loop can be exercised and
## validated on screen before any final art exists.
##
## Wires to the FishingLoop sibling node via the "fishing_loop" group.

# --- State display colours -------------------------------------------------------

var _state_bg_colors: Dictionary  # FishingLoop.State -> Color (init in _ready)
var _state_labels: Dictionary     # FishingLoop.State -> String

var _rarity_colors: Dictionary    # FishingConfig.RarityTier -> Color
var _rarity_flash_colors: Dictionary

const _LOG_MAX := 10

# --- Node references (built in code) --------------------------------------------

var _loop: FishingLoop
var _catch_table: Array

var _scene_bg: ColorRect
var _state_label: Label
var _progress_bar: ProgressBar
var _pct_label: Label
var _time_label: Label
var _bucket_label: Label
var _last_catch_label: Label
var _setup_controls: Control
var _session_slider: HSlider
var _session_val: Label
var _break_slider: HSlider
var _break_val: Label
var _start_btn: Button
var _sell_btn: Button
var _log_vbox: VBoxContainer


func _ready() -> void:
	_init_color_tables()
	_catch_table = FishCatalog.load_area("res://data/areas/backyard_pond.json")
	_build_ui()
	# FishingLoop._ready() runs before ours (it's an earlier sibling in the scene),
	# so the group is already populated when we reach this point.
	_loop = get_tree().get_first_node_in_group("fishing_loop") as FishingLoop
	if not _loop:
		push_error("FishingDebugUI: FishingLoop not found in group 'fishing_loop'")
		return
	_loop.set_catch_table(_catch_table)
	_loop.set_rod_stats(
		FishingConfig.cast_interval(1),
		FishingConfig.bucket_capacity(1),
	)
	_loop.state_changed.connect(_on_state_changed)
	_loop.fish_caught.connect(_on_fish_caught)
	_loop.bucket_changed.connect(_on_bucket_changed)
	_on_state_changed(_loop.get_state())
	_on_bucket_changed(_loop.get_bucket_count(), _loop.get_bucket_capacity())


func _init_color_tables() -> void:
	_state_bg_colors = {
		FishingLoop.State.SETUP:    Color(0.15, 0.18, 0.24),
		FishingLoop.State.CASTING:  Color(0.08, 0.22, 0.35),
		FishingLoop.State.CATCHING: Color(0.08, 0.22, 0.35),
		FishingLoop.State.PAUSED:   Color(0.28, 0.12, 0.08),
		FishingLoop.State.BREAK:    Color(0.18, 0.12, 0.28),
	}
	_state_labels = {
		FishingLoop.State.SETUP:    "SETUP",
		FishingLoop.State.CASTING:  "CASTING",
		FishingLoop.State.CATCHING: "CASTING",
		FishingLoop.State.PAUSED:   "BUCKET FULL",
		FishingLoop.State.BREAK:    "BREAK  😴",
	}
	_rarity_colors = {
		FishingConfig.RarityTier.COMMON:   Color(0.75, 0.75, 0.75),
		FishingConfig.RarityTier.UNCOMMON: Color(0.45, 0.78, 1.00),
		FishingConfig.RarityTier.RARE:     Color(1.00, 0.85, 0.20),
	}
	_rarity_flash_colors = {
		FishingConfig.RarityTier.COMMON:   Color(0.10, 0.30, 0.15),
		FishingConfig.RarityTier.UNCOMMON: Color(0.10, 0.28, 0.50),
		FishingConfig.RarityTier.RARE:     Color(0.45, 0.35, 0.05),
	}


# --- Live update ----------------------------------------------------------------

func _process(_delta: float) -> void:
	if not _loop:
		return
	var state := _loop.get_state()
	match state:
		FishingLoop.State.CASTING, FishingLoop.State.PAUSED, FishingLoop.State.CATCHING:
			var p := _loop.get_session_progress()
			_progress_bar.value = p
			_pct_label.text = "%d%%" % int(p * 100)
			_time_label.text = "⏱  %s left" % _fmt_time(_loop.get_session_time_remaining())
		FishingLoop.State.BREAK:
			var remaining := _loop.get_break_time_remaining()
			var total := _loop.get_break_duration()
			_progress_bar.value = 1.0 - clampf(remaining / maxf(total, 0.001), 0.0, 1.0)
			_pct_label.text = ""
			_time_label.text = "Break: %s" % _fmt_time(remaining)
		FishingLoop.State.SETUP:
			pass


static func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	if s >= 60:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%ds" % s


# --- Signal handlers ------------------------------------------------------------

func _on_state_changed(new_state: FishingLoop.State) -> void:
	_state_label.text = _state_labels.get(new_state, "???")
	_scene_bg.color = _state_bg_colors.get(new_state, Color(0.12, 0.12, 0.12))

	var in_setup := new_state == FishingLoop.State.SETUP
	var in_break := new_state == FishingLoop.State.BREAK
	var is_paused := new_state == FishingLoop.State.PAUSED

	_setup_controls.visible = in_setup or in_break
	_start_btn.visible = in_setup or in_break
	_start_btn.text = "▶  Start Session" if in_setup else "▶  Start Next Session"
	_sell_btn.visible = is_paused

	if in_setup:
		_progress_bar.value = 0.0
		_pct_label.text = "0%"
		_time_label.text = "Set your session length"


func _on_fish_caught(species_id: StringName, size_cm: float) -> void:
	var species := _find_species(species_id)
	var rarity: int = FishingConfig.RarityTier.COMMON
	var display_name := String(species_id)
	if not species.is_empty():
		rarity = int(species["rarity_tier"])
		display_name = String(species.get("display_name", species_id))

	var color: Color = _rarity_colors.get(rarity, Color.WHITE)
	var star := ""
	match rarity:
		FishingConfig.RarityTier.RARE:     star = "  ⭐"
		FishingConfig.RarityTier.UNCOMMON: star = "  ·"

	var text := "%s  %.1f cm%s" % [display_name, size_cm, star]
	_last_catch_label.text = text
	_last_catch_label.add_theme_color_override("font_color", color)

	_flash_scene(_rarity_flash_colors.get(rarity, Color(0.10, 0.28, 0.15)))
	_add_log_entry(text, color)


func _on_bucket_changed(count: int, capacity: int) -> void:
	_bucket_label.text = "🪣  %d / %d" % [count, capacity]
	if count >= capacity:
		_bucket_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	else:
		_bucket_label.remove_theme_color_override("font_color")


func _flash_scene(flash_color: Color) -> void:
	var orig := _state_bg_colors.get(_loop.get_state(), _scene_bg.color) as Color
	_scene_bg.color = flash_color
	var tw := create_tween()
	tw.tween_property(_scene_bg, "color", orig, 0.45)


func _add_log_entry(text: String, color: Color) -> void:
	while _log_vbox.get_child_count() >= _LOG_MAX:
		_log_vbox.get_child(0).queue_free()
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", color)
	_log_vbox.add_child(lbl)


func _find_species(species_id: StringName) -> Dictionary:
	for entry in _catch_table:
		if StringName(entry["id"]) == species_id:
			return entry
	return {}


# --- Button handlers ------------------------------------------------------------

func _on_start_pressed() -> void:
	if _loop:
		_loop.set_session_minutes(int(_session_slider.value))
		_loop.set_break_minutes(int(_break_slider.value))
		_loop.start_session()


func _on_sell_pressed() -> void:
	if _loop:
		var count := _loop.get_bucket_count()
		_loop.remove_fish(count)
		_add_log_entry("— Sold %d fish —" % count, Color(0.55, 0.9, 0.55))


# --- UI construction (all in code) ----------------------------------------------

func _build_ui() -> void:
	# Fill the parent control (Frame minus its bottom button strip).
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Outer VBox: scene area on top, info strip below, log at the bottom.
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	_build_scene_area(root_vbox)
	_build_info_strip(root_vbox)
	_build_catch_log(root_vbox)
	_build_close_button()


func _build_scene_area(parent: Control) -> void:
	# Top zone: coloured background + state text + cat emoji.
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, 185)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(area)

	_scene_bg = ColorRect.new()
	_scene_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_bg.color = Color(0.15, 0.18, 0.24)
	area.add_child(_scene_bg)

	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 10)
	area.add_child(inner)

	var cat_lbl := Label.new()
	cat_lbl.text = "🐱"
	cat_lbl.add_theme_font_size_override("font_size", 52)
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(cat_lbl)

	_state_label = Label.new()
	_state_label.text = "SETUP"
	_state_label.add_theme_font_size_override("font_size", 18)
	_state_label.add_theme_color_override("font_color", Color.WHITE)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_state_label)


func _build_info_strip(parent: Control) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	parent.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	# Progress row
	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 6)
	vbox.add_child(prog_row)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.custom_minimum_size = Vector2(0, 14)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.show_percentage = false
	prog_row.add_child(_progress_bar)

	_pct_label = Label.new()
	_pct_label.text = "0%"
	_pct_label.custom_minimum_size = Vector2(36, 0)
	_pct_label.add_theme_font_size_override("font_size", 11)
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prog_row.add_child(_pct_label)

	# Time + bucket row
	var time_row := HBoxContainer.new()
	vbox.add_child(time_row)

	_time_label = Label.new()
	_time_label.text = "Set your session length"
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_label.add_theme_font_size_override("font_size", 12)
	time_row.add_child(_time_label)

	_bucket_label = Label.new()
	_bucket_label.text = "🪣  0 / 25"
	_bucket_label.add_theme_font_size_override("font_size", 12)
	_bucket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_row.add_child(_bucket_label)

	# Last catch
	_last_catch_label = Label.new()
	_last_catch_label.text = " "
	_last_catch_label.add_theme_font_size_override("font_size", 12)
	_last_catch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_last_catch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_last_catch_label)

	# Session / break sliders (only in SETUP or BREAK)
	_setup_controls = Control.new()
	_setup_controls.custom_minimum_size = Vector2(0, 52)
	_setup_controls.visible = true
	vbox.add_child(_setup_controls)

	var sliders_vbox := VBoxContainer.new()
	sliders_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	sliders_vbox.add_theme_constant_override("separation", 4)
	_setup_controls.add_child(sliders_vbox)

	_session_slider = _make_slider(sliders_vbox, "Session",
		FishingConfig.SESSION_MIN_MINUTES,
		FishingConfig.SESSION_MAX_MINUTES,
		FishingConfig.DEFAULT_SESSION_MINUTES)
	_session_val = _get_slider_val_label(sliders_vbox)
	_session_val.text = "%dm" % FishingConfig.DEFAULT_SESSION_MINUTES
	_session_slider.value_changed.connect(func(v: float) -> void:
		_session_val.text = "%dm" % int(v))

	_break_slider = _make_slider(sliders_vbox, "Break",
		FishingConfig.BREAK_MIN_MINUTES,
		FishingConfig.BREAK_MAX_MINUTES,
		FishingConfig.DEFAULT_BREAK_MINUTES)
	_break_val = _get_slider_val_label(sliders_vbox)
	_break_val.text = "%dm" % FishingConfig.DEFAULT_BREAK_MINUTES
	_break_slider.value_changed.connect(func(v: float) -> void:
		_break_val.text = "%dm" % int(v))

	# Start button
	_start_btn = Button.new()
	_start_btn.text = "▶  Start Session"
	_start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_btn)

	# Sell All button (only while paused)
	_sell_btn = Button.new()
	_sell_btn.text = "🛒  Sell All Fish"
	_sell_btn.visible = false
	_sell_btn.pressed.connect(_on_sell_pressed)
	vbox.add_child(_sell_btn)


func _make_slider(parent: Control, label: String, lo: float, hi: float, def: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(54, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = 1.0
	slider.value = def
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	# Placeholder for the value label — caller assigns _get_slider_val_label().
	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(34, 0)
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	return slider


# Returns the last Label child added to parent (the value readout from _make_slider).
func _get_slider_val_label(parent: Control) -> Label:
	var last_row := parent.get_child(parent.get_child_count() - 1)
	return last_row.get_child(last_row.get_child_count() - 1) as Label


func _build_catch_log(parent: Control) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	_log_vbox = VBoxContainer.new()
	_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_log_vbox)

	# Seed the log with a hint.
	_add_log_entry("— Catch log —", Color(0.5, 0.5, 0.5))


func _build_close_button() -> void:
	# Dev-only ✕ button pinned to the top-right of this control.
	var btn := Button.new()
	btn.text = "✕"
	btn.flat = true
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -36.0
	btn.offset_right = -4.0
	btn.offset_top = 4.0
	btn.offset_bottom = 32.0
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(func() -> void: get_tree().quit())
	add_child(btn)
