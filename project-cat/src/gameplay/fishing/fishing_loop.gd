class_name FishingLoop
extends Node
## S-02 Fishing Loop — the autonomous, Pomodoro-style catch cycle.
##
## The player sets a session timer (5-60 min) and a break timer (1-30 min); the
## cat then fishes hands-free for the session, casting on the rod's interval and
## drawing each fish from a weighted table whose rare/uncommon weights climb as the
## session advances. When the session ends the cat breaks, then a new session
## auto-starts with the same settings. Whatever was caught stays in the bucket.
##
## This node owns timing, state, and the bucket. All catch math is delegated to the
## stateless [CatchResolver]; all tuning comes from [FishingConfig]. It depends on
## no other system directly — rod stats, bait, and the catch table are injected via
## setters, and outputs are broadcast through signals (no UI references), per the
## gameplay-code rules.
##
## Implements: design/gdd/systems/fishing-loop.md
##
## DESIGN NOTE (flagged for the designer): the GDD's prose (Overview, Rule 9, Core
## Loop) says a new session *auto-starts* when the break ends; the States table
## instead lists BREAK -> SETUP. This implementation follows the prose (auto-start),
## which is stated three times. See report / open question.

## Lifecycle states. Mirrors the GDD "States and Transitions" table.
## (OFFLINE_RESOLVE is handled by [method resolve_offline], not a live state.)
enum State { SETUP, CASTING, CATCHING, PAUSED, BREAK }

signal state_changed(new_state: State)
## One fish was caught and added to the bucket.
signal fish_caught(species_id: StringName, size_cm: float)
## Bucket contents changed (catch or removal). Carries current count and capacity.
signal bucket_changed(count: int, capacity: int)
signal session_started()
signal session_ended()
signal break_started()
signal break_ended()
## One cast completed while bait was active. BaitSystem listens to decrement its
## own uses_remaining counter and call clear_bait() on depletion.
signal consume_use()

# --- Injected configuration (defaults = Rod Tier 1, no bait) ---
var _cast_interval: float = FishingConfig.cast_interval(1)
var _bucket_capacity: int = FishingConfig.bucket_capacity(1)
var _catch_table: Array = []
var _bait_family: StringName = &""
var _bait_multiplier: float = 1.0
# uses_remaining is owned by BaitSystem — FishingLoop does not track it.

# --- Player settings (seconds) ---
var _session_duration: float = FishingConfig.DEFAULT_SESSION_MINUTES * 60.0
var _break_duration: float = FishingConfig.DEFAULT_BREAK_MINUTES * 60.0

# --- Runtime state ---
var _state: State = State.SETUP
var _session_elapsed: float = 0.0
var _break_elapsed: float = 0.0
var _cast_elapsed: float = 0.0
var _bucket: Array = []  ## Array of { species_id: StringName, size_cm: float }
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("fishing_loop")
	_rng.randomize()
	set_process(false)  # No ticking until a session starts.


func _process(delta: float) -> void:
	match _state:
		State.CASTING:
			_tick_casting(delta)
		State.PAUSED:
			_tick_paused(delta)
		State.BREAK:
			_tick_break(delta)
		_:
			pass


# --- Public configuration API ---------------------------------------------------

## Sets the catch table (see [CatchResolver] for the expected entry shape).
func set_catch_table(table: Array) -> void:
	_catch_table = table


## Injects the equipped rod's stats. Owned by S-04; read here on session start.
func set_rod_stats(cast_interval_sec: float, bucket_capacity_fish: int) -> void:
	_cast_interval = maxf(0.01, cast_interval_sec)
	_bucket_capacity = maxi(1, bucket_capacity_fish)
	bucket_changed.emit(_bucket.size(), _bucket_capacity)


## Activates a bait family with a weight multiplier. Owned by S-05 BaitSystem.
## BaitSystem tracks uses_remaining and calls clear_bait() on depletion.
func set_active_bait(family: StringName, multiplier: float) -> void:
	_bait_family = family
	_bait_multiplier = multiplier


func clear_bait() -> void:
	_bait_family = &""
	_bait_multiplier = 1.0


## Clamps and stores the session length (minutes). Persists as the loop default.
func set_session_minutes(minutes: int) -> void:
	var m: int = clampi(minutes, FishingConfig.SESSION_MIN_MINUTES, FishingConfig.SESSION_MAX_MINUTES)
	_session_duration = m * 60.0


## Clamps and stores the break length (minutes). Persists as the loop default.
func set_break_minutes(minutes: int) -> void:
	var m: int = clampi(minutes, FishingConfig.BREAK_MIN_MINUTES, FishingConfig.BREAK_MAX_MINUTES)
	_break_duration = m * 60.0


# --- Session control ------------------------------------------------------------

## Starts (or auto-restarts) a fishing session with the current settings.
func start_session() -> void:
	_session_elapsed = 0.0
	_cast_elapsed = 0.0
	_break_elapsed = 0.0
	set_process(true)
	_set_state(State.CASTING)
	session_started.emit()


## Halts the active session for an equipment change (rod/bait/area). Per the GDD,
## a cast in progress completes and is banked, then the loop returns to SETUP with
## progress reset. The 2-second confirmation prompt itself is a UI concern; call
## this only once the change is confirmed. No-op outside CASTING/PAUSED.
func halt_for_equipment_change() -> void:
	if _state == State.CASTING and _bucket.size() < _bucket_capacity:
		_resolve_catch()  # current cast completes
	if _state == State.CASTING or _state == State.PAUSED:
		_enter_setup()


# --- Bucket access (for S-06 Cat Market) ----------------------------------------

## Read-only snapshot of the bucket contents.
func get_bucket() -> Array:
	return _bucket.duplicate()


func get_bucket_count() -> int:
	return _bucket.size()


func get_bucket_capacity() -> int:
	return _bucket_capacity


## Removes [param amount] fish from the front of the bucket (e.g. on sell). If the
## loop was PAUSED on a full bucket, removing any fish resumes casting.
func remove_fish(amount: int) -> void:
	var n: int = clampi(amount, 0, _bucket.size())
	if n == 0:
		return
	_bucket = _bucket.slice(n)
	bucket_changed.emit(_bucket.size(), _bucket_capacity)
	if _state == State.PAUSED and _bucket.size() < _bucket_capacity:
		_set_state(State.CASTING)


# --- State queries --------------------------------------------------------------

func get_state() -> State:
	return _state


## Current session progress, 0.0 (start) .. 1.0 (end). Drives catch weights.
func get_session_progress() -> float:
	if _session_duration <= 0.0:
		return 0.0
	return clampf(_session_elapsed / _session_duration, 0.0, 1.0)


func get_session_duration() -> float:
	return _session_duration


func get_break_duration() -> float:
	return _break_duration


func get_session_time_remaining() -> float:
	return maxf(0.0, _session_duration - _session_elapsed)


func get_break_time_remaining() -> float:
	return maxf(0.0, _break_duration - _break_elapsed)


# --- Real-time ticking ----------------------------------------------------------

func _tick_casting(delta: float) -> void:
	_session_elapsed += delta
	if _session_elapsed >= _session_duration:
		# Session timer expired: the in-flight cast still completes (Rule 8).
		if _bucket.size() < _bucket_capacity:
			_resolve_catch()
		_begin_break()
		return

	_cast_elapsed += delta
	while _state == State.CASTING \
			and _cast_elapsed >= _cast_interval \
			and _bucket.size() < _bucket_capacity:
		_cast_elapsed -= _cast_interval
		_resolve_catch()

	if _state == State.CASTING and _bucket.size() >= _bucket_capacity:
		_set_state(State.PAUSED)  # full bucket: pause, but session timer keeps running


func _tick_paused(delta: float) -> void:
	# No casting while full; the session clock continues (Rule per Edge Cases).
	_session_elapsed += delta
	if _session_elapsed >= _session_duration:
		_begin_break()


func _tick_break(delta: float) -> void:
	_break_elapsed += delta
	if _break_elapsed >= _break_duration:
		break_ended.emit()
		start_session()  # auto-start next session (see DESIGN NOTE)


# --- Internal transitions -------------------------------------------------------

func _begin_break() -> void:
	session_ended.emit()
	_break_elapsed = 0.0
	_set_state(State.BREAK)
	break_started.emit()


func _enter_setup() -> void:
	_session_elapsed = 0.0
	_cast_elapsed = 0.0
	set_process(false)
	_set_state(State.SETUP)


## Resolves a single catch at the current session progress: draws a species, rolls
## its size, banks it, consumes bait, and emits the catch/bucket signals.
func _resolve_catch() -> void:
	if _catch_table.is_empty():
		return
	var p: float = get_session_progress()
	var species_id: StringName = CatchResolver.pick(
		_catch_table, p, _bait_family, _bait_multiplier, _rng
	)
	if species_id == &"":
		return
	var species: Dictionary = _find_species(species_id)
	var size_cm: float = CatchResolver.roll_size(species, _rng) if not species.is_empty() else 0.0

	_bucket.append({ "species_id": species_id, "size_cm": size_cm })
	_consume_bait_use()

	# Pulse CATCHING for presentation, then settle back to the running state.
	_set_state(State.CATCHING)
	fish_caught.emit(species_id, size_cm)
	bucket_changed.emit(_bucket.size(), _bucket_capacity)
	_set_state(State.CASTING if _bucket.size() < _bucket_capacity else State.PAUSED)


func _consume_bait_use() -> void:
	if _bait_family == &"":
		return
	consume_use.emit()  # BaitSystem decrements its counter and calls clear_bait() on depletion.


func _find_species(species_id: StringName) -> Dictionary:
	for entry in _catch_table:
		if StringName(entry["id"]) == species_id:
			return entry
	return {}


func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	_state = new_state
	state_changed.emit(_state)


# --- Offline resolution (Rule 10) -----------------------------------------------

## Advances the loop by [param real_elapsed] seconds of wall-clock time spent away,
## stepping through casts, session ends, breaks, and auto-restarts exactly as if the
## game had run. Casts beyond bucket capacity are naturally discarded (the cat
## stopped when the bucket was full). Call after restoring saved state on launch.
func resolve_offline(real_elapsed: float) -> void:
	var remaining: float = real_elapsed
	var guard: int = 0
	const GUARD_LIMIT := 10_000_000
	while remaining > 0.0001 and guard < GUARD_LIMIT:
		guard += 1
		match _state:
			State.CASTING, State.CATCHING:
				remaining = _step_offline_casting(remaining)
			State.PAUSED:
				remaining = _step_offline_paused(remaining)
			State.BREAK:
				remaining = _step_offline_break(remaining)
			_:
				return  # SETUP: nothing accrues while idle
	if guard >= GUARD_LIMIT:
		push_warning("FishingLoop.resolve_offline hit the iteration guard.")


func _step_offline_casting(remaining: float) -> float:
	var to_session_end: float = _session_duration - _session_elapsed
	if _bucket.size() >= _bucket_capacity:
		# Bucket full: only the session clock advances.
		var step: float = minf(remaining, to_session_end)
		_session_elapsed += step
		if _session_elapsed >= _session_duration:
			_begin_break()
		return remaining - step

	var to_cast: float = _cast_interval - _cast_elapsed
	var step: float = minf(remaining, minf(to_session_end, to_cast))
	_session_elapsed += step
	_cast_elapsed += step
	if _session_elapsed >= _session_duration:
		if _bucket.size() < _bucket_capacity:
			_resolve_catch()
		_begin_break()
	elif _cast_elapsed >= _cast_interval:
		_cast_elapsed -= _cast_interval
		_resolve_catch()
	return remaining - step


func _step_offline_paused(remaining: float) -> float:
	var to_session_end: float = _session_duration - _session_elapsed
	var step: float = minf(remaining, to_session_end)
	_session_elapsed += step
	if _session_elapsed >= _session_duration:
		_begin_break()
	return remaining - step


func _step_offline_break(remaining: float) -> float:
	var to_break_end: float = _break_duration - _break_elapsed
	var step: float = minf(remaining, to_break_end)
	_break_elapsed += step
	if _break_elapsed >= _break_duration:
		break_ended.emit()
		start_session()
	return remaining - step


# --- Save / load (for S-08 Save System) -----------------------------------------

## Serializable snapshot of all persistent loop state.
func get_save_state() -> Dictionary:
	return {
		"state": _state,
		"session_duration": _session_duration,
		"break_duration": _break_duration,
		"session_elapsed": _session_elapsed,
		"break_elapsed": _break_elapsed,
		"cast_elapsed": _cast_elapsed,
		"bucket": _bucket.duplicate(true),
	}


## Restores state produced by [method get_save_state]. Resumes ticking unless the
## restored state is SETUP. Call [method resolve_offline] afterwards to account for
## time spent away.
func apply_save_state(data: Dictionary) -> void:
	_session_duration = float(data.get("session_duration", _session_duration))
	_break_duration = float(data.get("break_duration", _break_duration))
	_session_elapsed = float(data.get("session_elapsed", 0.0))
	_break_elapsed = float(data.get("break_elapsed", 0.0))
	_cast_elapsed = float(data.get("cast_elapsed", 0.0))
	_bucket = (data.get("bucket", []) as Array).duplicate(true)
	_state = data.get("state", State.SETUP)
	set_process(_state != State.SETUP)
	bucket_changed.emit(_bucket.size(), _bucket_capacity)
	state_changed.emit(_state)
