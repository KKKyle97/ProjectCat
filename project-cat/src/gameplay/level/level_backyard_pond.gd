class_name LevelBackyardPond
extends Node2D
## S-02 presentation layer — Backyard Pond.
##
## Owns the visual side of the fishing loop: drives the cat [AnimatedSprite2D]
## through all five animation states (IDLE / CAST / TUG / CATCH / SLEEP) and
## keeps the [Line2D] fishing line pinned from the rod tip to the bobber.
##
## The node owns a [FishingLoop] child (added in the scene). [WidgetWindow]
## instances this scene into its Frame area and no longer creates a temporary
## FishingLoop of its own.
##
## ── Sprite sheet requirements ──────────────────────────────────────────────
## Assign a SpriteFrames resource to $Cat/CatSprite in the Godot editor once
## the cat sprite sheet (IDLE / CAST / TUG / CATCH / SLEEP) is imported and
## sliced. Animation names must match the ANIM_* constants below.
##   • IDLE  — loop = true   (cat sits, tail swaying)
##   • CAST  — loop = false  (single cast swing, then idles)
##   • TUG   — loop = false  (fish on the line!)
##   • CATCH — loop = false  (reel in + fish flick)
##   • SLEEP — loop = true   (zzz breathing cycle)
## ──────────────────────────────────────────────────────────────────────────
##
## Implements the visual half of: design/gdd/systems/fishing-loop.md

# ---------------------------------------------------------------------------
# Animation name constants — must match the SpriteFrames resource exactly.
# ---------------------------------------------------------------------------
const ANIM_IDLE  := &"idle"
const ANIM_CAST  := &"cast"
const ANIM_TUG   := &"tug"
const ANIM_CATCH := &"catch"
const ANIM_SLEEP := &"sleep"

# ---------------------------------------------------------------------------
# Inspector knobs — tune after placing sprites in the editor.
# ---------------------------------------------------------------------------

## Local-space position (relative to this node's origin) where the bobber
## rests once the line is cast into the water. Adjust after placing the cat.
@export var bobber_water_pos: Vector2 = Vector2(200, 300)

## Colour of the Line2D fishing line.
@export var line_color: Color = Color(0.55, 0.40, 0.25, 1.0)

## Width of the fishing line in pixels.
@export var line_width: float = 2.0

## Vertical bob amplitude (pixels) of the float while it waits in the water.
@export var bobber_bob_amplitude: float = 3.0

## Bob speed in radians/second (~one full bob every 2π / this value seconds).
@export var bobber_bob_speed: float = 2.0

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var _cat_sprite: AnimatedSprite2D = $Cat/CatSprite
@onready var _rod_tip: Marker2D           = $Cat/RodTip
@onready var _fishing_line: Line2D        = $FishingLine
@onready var _bobber: AnimatedSprite2D    = $FishingLine/Bobber
@onready var _loop: FishingLoop           = $FishingLoop
@onready var _rod: RodSystem              = $RodSystem

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## True while the TUG → CATCH anim chain is running. Used to swallow the
## immediate CATCHING → CASTING state pulse the loop emits in the same frame.
var _in_catch_seq: bool = false

## Accumulated time driving the bobber's idle bob (seconds). Only advances while
## the float is in the water (line visible).
var _bob_time: float = 0.0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Wire the loop to the backyard data and the equipped rod's current stats.
	var catch_table := FishCatalog.load_area("res://data/areas/backyard_pond.json")
	_loop.set_catch_table(catch_table)
	_loop.set_rod_stats(_rod.get_cast_interval(), _rod.get_bucket_capacity())

	# Connect signals.
	_loop.state_changed.connect(_on_state_changed)
	_cat_sprite.animation_finished.connect(_on_animation_finished)
	_rod.rod_purchased.connect(_on_rod_purchased)

	# Translucent status HUD layered over the pond (read-only; bound to the loop).
	_setup_hud(catch_table)

	# Initialise the Line2D with two zero-points so set_point_position works.
	_fishing_line.clear_points()
	_fishing_line.add_point(Vector2.ZERO)
	_fishing_line.add_point(Vector2.ZERO)
	_fishing_line.default_color = line_color
	_fishing_line.width = line_width

	_set_line_visible(false)
	_play(ANIM_IDLE)

	# Prototype convenience: auto-start the session so the cat begins fishing
	# as soon as the widget launches. Remove or gate behind a UI button later.
	_loop.start_session()


func _process(delta: float) -> void:
	if not _fishing_line.visible:
		return
	# Gentle vertical bob so the float looks alive while waiting for a bite.
	_bob_time += delta
	var bob := sin(_bob_time * bobber_bob_speed) * bobber_bob_amplitude
	var bobber_pos := bobber_water_pos + Vector2(0.0, bob)
	# Pin line point 0 to the rod tip every frame (cat may animate/move).
	_fishing_line.set_point_position(0, to_local(_rod_tip.global_position))
	# Pin line point 1 and the bobber sprite to the (bobbing) water position.
	_fishing_line.set_point_position(1, bobber_pos)
	_bobber.global_position = global_position + bobber_pos


# ---------------------------------------------------------------------------
# FishingLoop → animation
# ---------------------------------------------------------------------------

func _on_state_changed(state: FishingLoop.State) -> void:
	# While the TUG → CATCH chain plays, ignore the CASTING / PAUSED pulse that
	# FishingLoop emits immediately after CATCHING in the same frame.
	if _in_catch_seq and state in [FishingLoop.State.CASTING, FishingLoop.State.PAUSED]:
		return

	match state:
		FishingLoop.State.SETUP:
			_in_catch_seq = false
			_set_line_visible(false)
			_play(ANIM_IDLE)

		FishingLoop.State.CASTING:
			# Pull the line back, then play the cast swing. The line drops into
			# the water once the CAST animation finishes (→ _on_animation_finished).
			_set_line_visible(false)
			_play(ANIM_CAST)

		FishingLoop.State.CATCHING:
			# Fish on the line! Start the TUG → CATCH chain.
			_in_catch_seq = true
			_play(ANIM_TUG)

		FishingLoop.State.PAUSED:
			# Bucket full — cat waits, still holding the rod with the line in.
			_set_line_visible(true)
			_hold_rod()

		FishingLoop.State.BREAK:
			# Session over — cancel any running catch sequence and sleep.
			_in_catch_seq = false
			_set_line_visible(false)
			_play(ANIM_SLEEP)


func _on_animation_finished() -> void:
	match _cat_sprite.animation:
		ANIM_CAST:
			# Cast complete: drop the line into the water. The cat keeps holding
			# the rod (final cast pose) while waiting for a bite.
			_set_line_visible(true)
			_hold_rod()

		ANIM_TUG:
			# Tug complete: reel in the fish.
			_play(ANIM_CATCH)

		ANIM_CATCH:
			# Catch complete: end the sequence and re-cast.
			_in_catch_seq = false
			match _loop.get_state():
				FishingLoop.State.CASTING:
					# Re-cast: pull line back, swing again.
					_set_line_visible(false)
					_play(ANIM_CAST)
				FishingLoop.State.PAUSED:
					# Bucket filled on this catch — hold the rod with line in.
					_set_line_visible(true)
					_hold_rod()
				FishingLoop.State.BREAK:
					_set_line_visible(false)
					_play(ANIM_SLEEP)
				_:
					_play(ANIM_IDLE)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Plays [param anim] on the cat sprite. No-op (with a warning) if the
## SpriteFrames resource is not yet assigned or the animation name is missing —
## safe to call before the sprite sheet is imported in the editor.
func _play(anim: StringName) -> void:
	if _cat_sprite.sprite_frames == null:
		return  # Sprite sheet not yet assigned — silent during early prototyping.
	if not _cat_sprite.sprite_frames.has_animation(anim):
		push_warning("LevelBackyardPond: animation '%s' missing from SpriteFrames." % anim)
		return
	if _cat_sprite.animation == anim and _cat_sprite.is_playing():
		return  # Already playing the right looping animation — don't restart it.
	if _cat_sprite.animation == anim:
		# Same animation but stopped/paused (e.g. parked on the last CAST frame by
		# _hold_rod). Rewind so play() swings from the start instead of resuming
		# at the end and firing animation_finished immediately.
		_cat_sprite.frame = 0
	_cat_sprite.play(anim)


## Parks the cat on the final CAST frame — the rod-extended, line-out pose — so
## it visibly holds the rod while waiting for a bite. There is no dedicated
## "waiting" animation yet; the last cast frame doubles as the hold pose.
## No-op (safe) before the SpriteFrames resource is assigned.
func _hold_rod() -> void:
	if _cat_sprite.sprite_frames == null:
		return
	if not _cat_sprite.sprite_frames.has_animation(ANIM_CAST):
		push_warning("LevelBackyardPond: animation '%s' missing from SpriteFrames." % ANIM_CAST)
		return
	var last: int = _cat_sprite.sprite_frames.get_frame_count(ANIM_CAST) - 1
	if last < 0:
		return
	_cat_sprite.animation = ANIM_CAST
	_cat_sprite.frame = last
	_cat_sprite.pause()


func _set_line_visible(on: bool) -> void:
	_fishing_line.visible = on
	_bobber.visible = on


## Creates the status HUD on its own CanvasLayer so it renders in screen space
## over the pond (unaffected by this Node2D's transform) and binds it to the loop.
func _setup_hud(catch_table: Array) -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	add_child(layer)
	var hud := FishingHUD.new()
	layer.add_child(hud)
	hud.bind(_loop, catch_table)


## Called when the player buys a new rod tier via the Cat Market (S-06).
## Halts the active session (current cast completes and is banked), then injects
## the new stats so the next start_session() call picks them up automatically.
func _on_rod_purchased(_new_tier: int) -> void:
	_loop.halt_for_equipment_change()
	_loop.set_rod_stats(_rod.get_cast_interval(), _rod.get_bucket_capacity())
