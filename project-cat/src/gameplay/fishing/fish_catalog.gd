class_name FishCatalog
extends RefCounted
## Loads area fish data (JSON) into a catch table the [CatchResolver] understands.
##
## Keeps content data-driven per the gameplay-code rule "ALL gameplay values MUST
## come from external config/data files, NEVER hardcoded." Maps the human-friendly
## rarity strings in the data file to [enum FishingConfig.RarityTier] integers.
##
## Final ownership of fish content moves to S-03 Fish Album / S-07 Area Progression;
## this loader is the interim bridge so S-02 can run against real data today.

const _RARITY_BY_NAME: Dictionary = {
	"common": FishingConfig.RarityTier.COMMON,
	"uncommon": FishingConfig.RarityTier.UNCOMMON,
	"rare": FishingConfig.RarityTier.RARE,
}


## Loads an area JSON file and returns its catch table as an
## [code]Array[Dictionary][/code] with normalized keys (id/family as StringName,
## rarity_tier as int). Returns an empty array on failure and pushes an error.
static func load_area(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("FishCatalog: area file not found: %s" % path)
		return []

	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("fish"):
		push_error("FishCatalog: malformed area file: %s" % path)
		return []

	var table: Array = []
	for raw in parsed["fish"]:
		var rarity_name: String = String(raw.get("rarity", "common")).to_lower()
		if not _RARITY_BY_NAME.has(rarity_name):
			push_error("FishCatalog: unknown rarity '%s' in %s" % [rarity_name, path])
			continue
		table.append({
			"id": StringName(raw["id"]),
			"display_name": String(raw.get("display_name", raw["id"])),
			"rarity_tier": _RARITY_BY_NAME[rarity_name],
			"family": StringName(raw.get("family", "")),
			"base_weight": float(raw["base_weight"]),
			"base_size_cm": float(raw.get("base_size_cm", 1.0)),
			"size_variance_cm": float(raw.get("size_variance_cm", 0.0)),
		})
	return table
