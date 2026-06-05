class_name RodConfig
extends RefCounted
## Authored data for the S-04 Rod System.
##
## Owns all per-tier constants that are NOT formula-derived: names, flavour text,
## purchase costs, and area access requirements. Formula-derived stats
## (cast_interval, bucket_capacity) are computed by FishingConfig and read via
## RodSystem — do not duplicate them here.
##
## Tuning knobs (costs) are defined in the "Tuning Knobs" table of
## design/gdd/systems/rod-system.md. Change costs here only; formula constants
## live in fishing_config.gd.

## Total number of rod tiers.
const TIER_COUNT: int = 5

## Display name per tier (index 0 = Tier 1).
const NAMES: Array[String] = [
	"Stick & String",
	"Bamboo Stalker",
	"River Runner",
	"Deep Seeker",
	"Carbon Whip",
]

## Flavour text shown in the Cat Market (index 0 = Tier 1).
const FLAVOURS: Array[String] = [
	"A trusty twig and some fishing line. The cat doesn't mind.",
	"Light, flexible, reliable. The cat sits up a little straighter.",
	"Built for moving water. Opens up new spots the cat's been eyeing.",
	"Weighted for depth. Whatever's down there, this reaches it.",
	"Whisper-thin, impossibly strong. The cat barely moves. The fish do all the work.",
]

## Purchase cost in coins per tier (index 0 = Tier 1). T1 is always free (0).
const COSTS: Array[int] = [0, 250, 700, 1800, 5000]

## Minimum rod tier required to access each area (index 0 = Area 1).
## Read by S-07 Area Progression when evaluating unlock eligibility.
const MIN_ROD_FOR_AREA: Array[int] = [1, 1, 2, 3, 3, 4, 5]
