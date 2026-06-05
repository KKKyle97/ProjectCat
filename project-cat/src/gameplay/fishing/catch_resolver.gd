class_name CatchResolver
extends RefCounted
## Pure catch-resolution math for the S-02 Fishing Loop.
##
## Stateless, node-free, and deterministic given an RNG — this is the testable
## core of the fishing loop, kept separate from the FishingLoop node so the math
## can be validated in isolation (see tests/fishing/sim_catch_resolver.gd).
##
## Implements "Catch Weight Resolution" and "Fish Size" from
## design/gdd/systems/fishing-loop.md.
##
## A catch table is an [code]Array[Dictionary][/code]; each entry must contain:
## [code]id[/code] (StringName), [code]base_weight[/code] (float),
## [code]rarity_tier[/code] (int, [enum FishingConfig.RarityTier]),
## [code]family[/code] (StringName). Size rolls additionally need
## [code]base_size_cm[/code] and [code]size_variance_cm[/code].

## Computes each species' adjusted (pre-normalization) catch weight.
## Step 1: base_weight * progress_multiplier(tier, p).
## Step 2: * bait_multiplier for species in the active bait family.
## Returns a Dictionary mapping species id -> weight.
static func compute_weights(
	catch_table: Array,
	p: float,
	bait_family: StringName,
	bait_multiplier: float,
) -> Dictionary:
	var weights: Dictionary = {}
	for entry in catch_table:
		var w: float = float(entry["base_weight"]) \
			* FishingConfig.progress_multiplier(int(entry["rarity_tier"]), p)
		if bait_family != &"" and StringName(entry["family"]) == bait_family:
			w *= bait_multiplier
		weights[entry["id"]] = w
	return weights


## Normalized catch probability per species (sums to 1.0). Returns an empty
## Dictionary if total weight is non-positive.
static func compute_distribution(
	catch_table: Array,
	p: float,
	bait_family: StringName,
	bait_multiplier: float,
) -> Dictionary:
	var weights: Dictionary = compute_weights(catch_table, p, bait_family, bait_multiplier)
	var total: float = 0.0
	for id in weights:
		total += weights[id]
	var dist: Dictionary = {}
	if total <= 0.0:
		return dist
	for id in weights:
		dist[id] = weights[id] / total
	return dist


## Performs one weighted random draw and returns the chosen species id.
## [param rng] is injected so callers (and tests) control the seed.
static func pick(
	catch_table: Array,
	p: float,
	bait_family: StringName,
	bait_multiplier: float,
	rng: RandomNumberGenerator,
) -> StringName:
	var weights: Dictionary = compute_weights(catch_table, p, bait_family, bait_multiplier)
	var total: float = 0.0
	for id in weights:
		total += weights[id]
	if total <= 0.0:
		return &""
	var roll: float = rng.randf() * total
	var accum: float = 0.0
	for entry in catch_table:
		accum += weights[entry["id"]]
		if roll <= accum:
			return StringName(entry["id"])
	return StringName(catch_table[catch_table.size() - 1]["id"])  # float-rounding fallback


## Rolls a cosmetic catch size (cm) for a species, clamped to the GDD bounds:
## [code]clamp(base + variance * randfn(0, 0.5), base - variance*1.5, base + variance*3.0)[/code].
static func roll_size(species: Dictionary, rng: RandomNumberGenerator) -> float:
	var base_size: float = float(species["base_size_cm"])
	var variance: float = float(species["size_variance_cm"])
	var sample: float = rng.randfn(0.0, FishingConfig.SIZE_STDDEV_FACTOR)
	var size: float = base_size + variance * sample
	return clampf(
		size,
		base_size - variance * FishingConfig.SIZE_CLAMP_LOW,
		base_size + variance * FishingConfig.SIZE_CLAMP_HIGH,
	)
