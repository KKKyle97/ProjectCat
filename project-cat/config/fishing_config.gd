class_name FishingConfig
extends RefCounted
## Tuning constants and shared formulas for the S-02 Fishing Loop.
##
## Implements the "Formulas" and "Tuning Knobs" tables of
## design/gdd/systems/fishing-loop.md. Per the GDD: "All values live in
## res://config/fishing_config.gd. No magic numbers in scene files." The
## relationships between these values are locked; the constants are tuning knobs.
##
## S-02 owns these formulas; the S-04 Rod System owns the per-tier rod *data* and
## reads [method cast_interval] / [method bucket_capacity] from here.

## Rarity tiers used by catch-weight resolution. Drives the session-progress
## multiplier each species receives.
enum RarityTier { COMMON, UNCOMMON, RARE }

# --- Session-progress multipliers (M_min at p=0.0, M_max at p=1.0) ---
# progress_multiplier(tier, p) = M_MIN[tier] + p * (M_MAX[tier] - M_MIN[tier])

## Multiplier applied to each tier's base weight at session start (p = 0.0).
const M_MIN: Dictionary = {
	RarityTier.COMMON: 1.00,
	RarityTier.UNCOMMON: 0.80,
	RarityTier.RARE: 0.40,
}
## Multiplier applied to each tier's base weight at session end (p = 1.0).
const M_MAX: Dictionary = {
	RarityTier.COMMON: 0.85,
	RarityTier.UNCOMMON: 1.20,
	RarityTier.RARE: 2.00,
}

# --- Rod stat formulas (S-02 owned; consumed by S-04) ---
const I_BASE: float = 6.0      ## Base cast interval at T1, seconds.
const DECAY_RATE: float = 0.72   ## Per-tier cast-interval multiplier (lower = steeper).
const B_BASE: int = 25           ## Base bucket capacity at T1, fish.
const GROWTH_RATE: float = 1.50  ## Per-tier bucket-capacity multiplier.

# --- Session / break bounds (minutes) ---
const SESSION_MIN_MINUTES: int = 5
const SESSION_MAX_MINUTES: int = 60
const BREAK_MIN_MINUTES: int = 1
const BREAK_MAX_MINUTES: int = 30
const DEFAULT_SESSION_MINUTES: int = 5  ## First-launch default (Pomodoro).
const DEFAULT_BREAK_MINUTES: int = 5

# --- Bait ---
const DEFAULT_BAIT_MULTIPLIER: float = 4.0  ## Matching-family weight boost.

# --- Fish size (cosmetic) ---
## normal_sample stddev in: size = base + variance * randfn(0, STDDEV_FACTOR).
const SIZE_STDDEV_FACTOR: float = 0.5
const SIZE_CLAMP_LOW: float = 1.5   ## Lower clamp: base - variance * 1.5.
const SIZE_CLAMP_HIGH: float = 3.0  ## Upper clamp: base + variance * 3.0 (record ceiling).


## Cast interval (seconds) for a rod tier, rounded to the nearest whole second.
## [codeblock]
## FishingConfig.cast_interval(1)  # 150
## FishingConfig.cast_interval(3)  # 78
## [/codeblock]
static func cast_interval(rod_tier: int) -> float:
	return roundf(I_BASE * pow(DECAY_RATE, rod_tier - 1))


## Bucket capacity (fish) for a rod tier.
## [codeblock]
## FishingConfig.bucket_capacity(1)  # 25
## FishingConfig.bucket_capacity(5)  # 126
## [/codeblock]
static func bucket_capacity(rod_tier: int) -> int:
	return int(floor(B_BASE * pow(GROWTH_RATE, rod_tier - 1)))


## Session-progress weight multiplier for a rarity tier at progress [param p]
## (0.0 = session start, 1.0 = session end). Linear interpolation between the
## tier's M_MIN and M_MAX.
static func progress_multiplier(tier: int, p: float) -> float:
	var lo: float = M_MIN[tier]
	var hi: float = M_MAX[tier]
	return lo + clampf(p, 0.0, 1.0) * (hi - lo)
