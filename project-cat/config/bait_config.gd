class_name BaitConfig
extends RefCounted
## Authored data and tuning knobs for the S-05 Bait System.
##
## Per-bait authored values (id, name, family, cost, area unlock, flavour) live here.
## The bait_multiplier and stack_size are global tuning knobs — adjust here for balance.
## All balance values are intentionally left at design-intent defaults and will be
## tuned during the post-mechanics balance pass.
##
## Tuning Knobs (see design/gdd/systems/bait-system.md):
##   bait_multiplier: target-family weight boost. Too high → bait dominates.
##   stack_size:      uses per purchase. Too high → restocking feels trivial.

## Weight multiplier applied to the active bait's target family.
const BAIT_MULTIPLIER: float = 4.0

## Uses added per stack purchase.
const STACK_SIZE: int = 10

## Uses-remaining threshold at which the low-bait UI warning triggers.
const LOW_BAIT_WARNING_THRESHOLD: int = 3

## Master bait data table. Each entry is the single source of truth for a bait type.
## Fields: id, name, bait_family, cost_per_stack, area_tier_unlock, flavour.
const BAIT_DATA: Array[Dictionary] = [
	{
		"id": "worm_bait",
		"name": "Worm Bait",
		"bait_family": "cyprinidae",
		"cost_per_stack": 25,
		"area_tier_unlock": 1,
		"flavour": "A classic earthworm, irresistible to any fish that's ever seen a riverbed.",
	},
	{
		"id": "mayfly_bait",
		"name": "Mayfly Bait",
		"bait_family": "percidae",
		"cost_per_stack": 35,
		"area_tier_unlock": 1,
		"flavour": "Lifelike and delicate. Perch can't resist it. Your cat is very patient.",
	},
	{
		"id": "spinner_bait",
		"name": "Spinner Bait",
		"bait_family": "salmonidae",
		"cost_per_stack": 45,
		"area_tier_unlock": 2,
		"flavour": "A tiny glinting lure. Trout and salmon lose all composure at the sight of it.",
	},
]
