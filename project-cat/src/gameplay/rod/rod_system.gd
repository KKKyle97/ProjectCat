class_name RodSystem
extends Node
## S-04 Rod System — manages rod tier state and exposes stats to other systems.
##
## Owns: equipped_tier (int 1–5), owned_tiers[] (bool[5]).
## Stats (cast_interval, bucket_capacity) are derived on-the-fly from FishingConfig
## formulas — no duplication here.
##
## Purchase flow (S-06 Cat Market integration, not yet built):
##   1. Market validates coin balance via can_purchase_next(coin_balance).
##   2. Market deducts the cost from the player's coin balance.
##   3. Market calls purchase_next() — this node updates state and emits rod_purchased.
##   4. LevelBackyardPond listens to rod_purchased and calls
##      FishingLoop.halt_for_equipment_change() + set_rod_stats().
##
## Implements: design/gdd/systems/rod-system.md

## Emitted after a successful purchase. new_tier is the newly equipped tier (2–5).
signal rod_purchased(new_tier: int)

## Current rod tier the cat is fishing with. Range 1–5.
var equipped_tier: int = 1

## Ownership flags per tier (index 0 = T1, always true at start).
var owned_tiers: Array[bool] = [true, false, false, false, false]


func _ready() -> void:
	add_to_group("rod_system")


# --- Stats API (S-02 FishingLoop reads these) ------------------------------------

## Cast interval in seconds for the currently equipped rod tier.
func get_cast_interval() -> float:
	return FishingConfig.cast_interval(equipped_tier)


## Bucket capacity (fish count) for the currently equipped rod tier.
func get_bucket_capacity() -> int:
	return FishingConfig.bucket_capacity(equipped_tier)


# --- Market API (S-06 Cat Market reads these) ------------------------------------

## Full data array for all rod tiers, one Dictionary per tier. Index 0 = T1.
## Each entry: {tier, name, flavour, cost, cast_interval, bucket_capacity, owned}.
func get_all_rod_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in RodConfig.TIER_COUNT:
		var tier := i + 1
		out.append({
			"tier":           tier,
			"name":           RodConfig.NAMES[i],
			"flavour":        RodConfig.FLAVOURS[i],
			"cost":           RodConfig.COSTS[i],
			"cast_interval":  FishingConfig.cast_interval(tier),
			"bucket_capacity": FishingConfig.bucket_capacity(tier),
			"owned":          owned_tiers[i],
		})
	return out


## The next tier available for purchase, or 0 if the player already owns T5.
func get_next_purchasable_tier() -> int:
	if equipped_tier >= RodConfig.TIER_COUNT:
		return 0
	return equipped_tier + 1


## True if coin_balance is enough to buy the next rod tier.
func can_purchase_next(coin_balance: int) -> bool:
	var next := get_next_purchasable_tier()
	if next == 0:
		return false
	return coin_balance >= RodConfig.COSTS[next - 1]


## Completes a rod purchase. Call this AFTER the Market has already deducted the
## coin cost — this node does not touch the economy. Returns false if no valid
## next tier exists (at T5 or called out of sequence).
func purchase_next() -> bool:
	var next := get_next_purchasable_tier()
	if next == 0:
		return false
	owned_tiers[next - 1] = true
	equipped_tier = next
	rod_purchased.emit(equipped_tier)
	return true


# --- Save / Load hooks (S-08 Save System, not yet built) -------------------------

## Snapshot of rod state for serialisation. Passed to SaveSystem on write.
func save_state() -> Dictionary:
	return {
		"equipped_tier": equipped_tier,
		"owned_tiers":   owned_tiers.duplicate(),
	}


## Restores rod state from a save snapshot. Clamps tier and fills gaps defensively.
func load_state(data: Dictionary) -> void:
	var tier: int = int(data.get("equipped_tier", 1))
	equipped_tier = clampi(tier, 1, RodConfig.TIER_COUNT)
	var saved: Array = data.get("owned_tiers", [])
	for i in RodConfig.TIER_COUNT:
		owned_tiers[i] = bool(saved[i]) if i < saved.size() else (i + 1 <= equipped_tier)
	owned_tiers[0] = true  # T1 is always owned regardless of save data
