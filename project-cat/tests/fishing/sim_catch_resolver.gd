extends SceneTree
## Headless validation for S-02 Fishing Loop math + offline resolution.
##
## Run:
##   Godot_..._console.exe --headless --path E:\ProjectCat\project-cat \
##     --script res://tests/fishing/sim_catch_resolver.gd
##
## Verifies the implementation against the published "Worked Examples" and
## acceptance criteria in design/gdd/systems/fishing-loop.md. Exits non-zero on
## failure so it can gate CI later.

var _passed: int = 0
var _failed: int = 0

# The exact area table from the GDD worked-examples section.
var _table: Array = [
	{ "id": &"catfish",    "base_weight": 60.0, "rarity_tier": FishingConfig.RarityTier.COMMON,   "family": &"ictaluridae", "base_size_cm": 30.0, "size_variance_cm": 6.0 },
	{ "id": &"perch",      "base_weight": 30.0, "rarity_tier": FishingConfig.RarityTier.UNCOMMON, "family": &"percidae",    "base_size_cm": 22.0, "size_variance_cm": 4.0 },
	{ "id": &"golden_koi", "base_weight": 10.0, "rarity_tier": FishingConfig.RarityTier.RARE,     "family": &"cyprinidae",  "base_size_cm": 45.0, "size_variance_cm": 12.0 },
]


func _init() -> void:
	print("=== S-02 Fishing Loop validation ===")
	_test_progress_multiplier()
	_test_worked_examples()
	_test_monte_carlo()
	_test_size_roll()
	_test_offline_fills_one_bucket()
	_test_catalog_load()

	print("-------------------------------------")
	print("PASSED: %d   FAILED: %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s  %s" % [label, detail])


func _approx(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


func _test_progress_multiplier() -> void:
	print("progress_multiplier endpoints:")
	var rt := FishingConfig.RarityTier
	_check("Common p=0 -> 1.00", _approx(FishingConfig.progress_multiplier(rt.COMMON, 0.0), 1.00, 1e-6))
	_check("Common p=1 -> 0.85", _approx(FishingConfig.progress_multiplier(rt.COMMON, 1.0), 0.85, 1e-6))
	_check("Uncommon p=1 -> 1.20", _approx(FishingConfig.progress_multiplier(rt.UNCOMMON, 1.0), 1.20, 1e-6))
	_check("Rare p=0 -> 0.40", _approx(FishingConfig.progress_multiplier(rt.RARE, 0.0), 0.40, 1e-6))
	_check("Rare p=1 -> 2.00", _approx(FishingConfig.progress_multiplier(rt.RARE, 1.0), 2.00, 1e-6))
	_check("Rare p=0.5 -> 1.20", _approx(FishingConfig.progress_multiplier(rt.RARE, 0.5), 1.20, 1e-6))


func _test_worked_examples() -> void:
	print("worked-example distributions (GDD Formulas table):")
	# Case A: start, no bait
	_assert_dist("A start/no-bait", 0.0, &"", {&"catfish": 0.6818, &"perch": 0.2727, &"golden_koi": 0.0455})
	# Case B: end, no bait
	_assert_dist("B end/no-bait", 1.0, &"", {&"catfish": 0.4766, &"perch": 0.3364, &"golden_koi": 0.1869})
	# Case C: start, bait x4 on the Rare's family
	_assert_dist("C start/bait", 0.0, &"cyprinidae", {&"catfish": 0.6000, &"perch": 0.2400, &"golden_koi": 0.1600})
	# Case D: end, bait x4
	_assert_dist("D end/bait", 1.0, &"cyprinidae", {&"catfish": 0.3054, &"perch": 0.2156, &"golden_koi": 0.4790})


func _assert_dist(label: String, p: float, bait_family: StringName, expected: Dictionary) -> void:
	var mult: float = FishingConfig.DEFAULT_BAIT_MULTIPLIER if bait_family != &"" else 1.0
	var dist: Dictionary = CatchResolver.compute_distribution(_table, p, bait_family, mult)
	for id in expected:
		_check("%s %s" % [label, id], _approx(dist.get(id, -1.0), expected[id], 0.0005),
			"got %.4f expected %.4f" % [dist.get(id, -1.0), expected[id]])


func _test_monte_carlo() -> void:
	print("Monte Carlo pick() vs distribution (Case D, 200k draws):")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var n := 200000
	var counts := { &"catfish": 0, &"perch": 0, &"golden_koi": 0 }
	for i in n:
		var id: StringName = CatchResolver.pick(_table, 1.0, &"cyprinidae", FishingConfig.DEFAULT_BAIT_MULTIPLIER, rng)
		counts[id] += 1
	var koi_freq := float(counts[&"golden_koi"]) / float(n)
	var catfish_freq := float(counts[&"catfish"]) / float(n)
	_check("koi empirical ~0.479 (+/-0.005)", _approx(koi_freq, 0.4790, 0.005), "got %.4f" % koi_freq)
	_check("catfish empirical ~0.305 (+/-0.005)", _approx(catfish_freq, 0.3054, 0.005), "got %.4f" % catfish_freq)


func _test_size_roll() -> void:
	print("roll_size bounds + mean (100k samples, koi base 45 +/- variance 12):")
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var species: Dictionary = _table[2]  # golden_koi
	var lo := 45.0 - 12.0 * FishingConfig.SIZE_CLAMP_LOW   # 27
	var hi := 45.0 + 12.0 * FishingConfig.SIZE_CLAMP_HIGH  # 81
	var sum := 0.0
	var within := true
	var n := 100000
	for i in n:
		var s := CatchResolver.roll_size(species, rng)
		sum += s
		if s < lo - 0.001 or s > hi + 0.001:
			within = false
	_check("all sizes within clamp [%.0f, %.0f]" % [lo, hi], within)
	_check("mean size ~45 (+/-0.3)", _approx(sum / float(n), 45.0, 0.3), "got %.3f" % (sum / float(n)))


func _test_offline_fills_one_bucket() -> void:
	print("offline resolution fills exactly one bucket and stops:")
	var loop := FishingLoop.new()
	loop.set_catch_table(_table)
	loop.set_rod_stats(2.0, 5)        # cast every 2s, capacity 5
	loop.set_session_minutes(5)       # 300s sessions
	loop.set_break_minutes(1)         # 60s breaks
	loop.start_session()
	loop.resolve_offline(3600.0)      # away for one hour
	_check("bucket capped at capacity (5)", loop.get_bucket_count() == 5,
		"got %d" % loop.get_bucket_count())
	loop.free()


func _test_catalog_load() -> void:
	print("FishCatalog loads MVP area data:")
	var table: Array = FishCatalog.load_area("res://data/areas/backyard_pond.json")
	_check("loaded 6 fish", table.size() == 6, "got %d" % table.size())
	if table.is_empty():
		return
	var koi: Dictionary = {}
	for e in table:
		if e["id"] == &"golden_koi":
			koi = e
	_check("golden_koi present", not koi.is_empty())
	if not koi.is_empty():
		_check("golden_koi mapped to RARE tier",
			int(koi["rarity_tier"]) == FishingConfig.RarityTier.RARE)
		_check("golden_koi family = cyprinidae", StringName(koi["family"]) == &"cyprinidae")
	# Table is usable by the resolver without error.
	var dist: Dictionary = CatchResolver.compute_distribution(table, 0.5, &"cyprinidae", FishingConfig.DEFAULT_BAIT_MULTIPLIER)
	var total := 0.0
	for id in dist:
		total += dist[id]
	_check("loaded-table distribution sums to 1.0", _approx(total, 1.0, 1e-6), "got %.6f" % total)
