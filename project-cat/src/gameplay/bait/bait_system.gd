class_name BaitSystem
extends Node
## S-05 Bait System — manages the active bait slot and exposes modifiers to FishingLoop.
##
## Owns: active_bait_id (String/""), uses_remaining (int).
## FishingLoop owns the cast cycle and emits consume_use() per cast; this node
## listens, decrements uses_remaining, and calls FishingLoop.clear_bait() on depletion.
##
## Purchase flow (S-06 Cat Market integration, not yet built):
##   1. Market validates coin balance.
##   2. Market deducts the cost.
##   3. Market calls purchase(bait_id) — this node updates slot and injects into loop.
##
## Implements: design/gdd/systems/bait-system.md

## Emitted when the active bait changes or uses_remaining updates (UI refresh hook).
signal bait_changed(bait_id: String, uses_remaining: int)

## Emitted when the slot depletes to 0. UI shows the depletion notification.
signal bait_depleted()

## Current active bait ID, or "" when the slot is empty (NO_BAIT state).
var active_bait_id: String = ""

## Remaining uses for the active bait. 0 when slot is empty.
var uses_remaining: int = 0

## Reference to FishingLoop — set in _ready() via group lookup.
var _loop: FishingLoop = null


func _ready() -> void:
	add_to_group("bait_system")
	_connect_loop()


# --- Loop connection -------------------------------------------------------------

func _connect_loop() -> void:
	var nodes := get_tree().get_nodes_in_group("fishing_loop")
	if nodes.is_empty():
		push_warning("BaitSystem: no FishingLoop found in 'fishing_loop' group.")
		return
	_loop = nodes[0] as FishingLoop
	_loop.consume_use.connect(_on_consume_use)


# --- Purchase API (S-06 Cat Market calls these) ----------------------------------

## Purchases one stack of the given bait_id. Handles same-type and cross-type cases.
## Returns false if bait_id is unknown. Coin deduction is the Market's responsibility.
func purchase(bait_id: String) -> bool:
	var entry := _find_entry(bait_id)
	if entry.is_empty():
		push_warning("BaitSystem.purchase: unknown bait_id '%s'." % bait_id)
		return false

	if active_bait_id == bait_id:
		# Same type: stack on top of current uses (Rule 2 — no cap, no prompt).
		uses_remaining += BaitConfig.STACK_SIZE
	else:
		# Different type: caller (Market) must have already shown the confirmation
		# prompt if uses_remaining > 0. This node just updates state.
		active_bait_id = bait_id
		uses_remaining = BaitConfig.STACK_SIZE

	_inject_into_loop()
	bait_changed.emit(active_bait_id, uses_remaining)
	return true


## Unequips the active bait immediately. Remaining uses are discarded (Rule 6).
## Caller is responsible for triggering the S-02 session halt first if needed.
func unequip() -> void:
	active_bait_id = ""
	uses_remaining = 0
	if _loop:
		_loop.clear_bait()
	bait_changed.emit("", 0)


# --- Stats API (Market UI reads these) ------------------------------------------

## Full data array for all bait types, decorated with live slot state.
## Each entry: {id, name, bait_family, cost_per_stack, area_tier_unlock, flavour,
##              is_active, uses_remaining, is_purchasable}.
## area_tier: pass the player's current unlocked_area_tier (from S-07 once built).
func get_all_bait_data(unlocked_area_tier: int = 1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in BaitConfig.BAIT_DATA:
		var d := entry.duplicate()
		d["is_active"]      = (d["id"] == active_bait_id)
		d["uses_remaining"] = uses_remaining if d["is_active"] else 0
		d["is_purchasable"] = unlocked_area_tier >= int(d["area_tier_unlock"])
		out.append(d)
	return out


# --- Save / Load hooks (S-08 Save System, not yet built) -------------------------

func save_state() -> Dictionary:
	return {
		"active_bait_id":  active_bait_id,
		"uses_remaining":  uses_remaining,
	}


func load_state(data: Dictionary) -> void:
	active_bait_id  = str(data.get("active_bait_id", ""))
	uses_remaining  = int(data.get("uses_remaining", 0))
	if active_bait_id != "" and uses_remaining > 0:
		_inject_into_loop()
	else:
		active_bait_id = ""
		uses_remaining = 0


# --- FishingLoop signal handler --------------------------------------------------

func _on_consume_use() -> void:
	if uses_remaining <= 0:
		return
	uses_remaining -= 1
	bait_changed.emit(active_bait_id, uses_remaining)
	if uses_remaining == 0:
		_deplete()


# --- Helpers --------------------------------------------------------------------

func _deplete() -> void:
	active_bait_id = ""
	if _loop:
		_loop.clear_bait()
	bait_depleted.emit()
	bait_changed.emit("", 0)


func _inject_into_loop() -> void:
	if not _loop:
		return
	var entry := _find_entry(active_bait_id)
	if entry.is_empty():
		return
	_loop.set_active_bait(StringName(entry["bait_family"]), BaitConfig.BAIT_MULTIPLIER)


func _find_entry(bait_id: String) -> Dictionary:
	for entry in BaitConfig.BAIT_DATA:
		if entry["id"] == bait_id:
			return entry
	return {}
