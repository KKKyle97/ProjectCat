# Cat & Hook — Systems Index

*Derived from: [game-concept.md](game-concept.md)*
*Last updated: 2026-05-28*

This index tracks every game system, its design status, priority tier, MVP scope, and cross-system dependencies. Update status here when a system GDD changes state. Author per-system GDDs with `/design-system`.

---

## Status Legend

| Status | Meaning |
| ---- | ---- |
| `Not Started` | No GDD written yet |
| `In Design` | GDD in progress |
| `In Review` | GDD written, awaiting `/design-review` |
| `Approved` | GDD passed design review |
| `In Development` | Being implemented |
| `Complete` | Implemented and tested |

---

## Priority Tiers

- **Tier 1 — Foundation**: Must exist before anything else can be built or tested
- **Tier 2 — MVP Core**: Required for the MVP prototype to be meaningful
- **Tier 3 — Vertical Slice**: Required for a shippable demo; post-MVP
- **Tier 4 — Full Vision**: Content/polish layer; deferred until Tier 1–3 are stable

---

## Systems

### Tier 1 — Foundation

#### S-01 · Widget Window System
| Field | Value |
| ---- | ---- |
| **Status** | `Approved` |
| **GDD** | [design/gdd/systems/widget-window.md](systems/widget-window.md) |
| **MVP Scope** | Yes |
| **Description** | Transparent, borderless, always-on-top Godot 4 window that hosts all game visuals. Handles window dragging, DPI scaling, multi-monitor placement, and minimize/restore state. |
| **Depends On** | *(none — platform foundation)* |
| **Required By** | All systems (renders inside this window) |
| **Key Open Questions** | Does Godot 4 transparent window work on Windows 11 with snap layouts? Click-through regions for non-UI areas? |
| **Prototype** | `/prototype widget-window` — validate before writing GDD |

#### S-02 · Fishing Loop
| Field | Value |
| ---- | ---- |
| **Status** | `Approved` |
| **GDD** | [design/gdd/systems/fishing-loop.md](systems/fishing-loop.md) |
| **MVP Scope** | Yes |
| **Description** | The autonomous catch cycle. Cat casts on a timer, waits, and catches a fish drawn from the area's weighted table. No player input required. Outputs fish to bucket; pauses when bucket is full. |
| **Depends On** | S-01 (renders in widget), S-04 (rod stats modify cast speed + catch rate), S-05 (bait modifies catch weight table), S-07 (area determines which catch table is active) |
| **Required By** | S-03 (album receives catch events), S-06 (market receives bucket contents), S-08 (save persists bucket state) |
| **Key Rules** | Catch weight rule (×4 bait boost, renormalized); full-bucket pause (no penalty, resumes on first sell) |

#### S-03 · Fish Album
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/fish-album.md` |
| **MVP Scope** | Yes |
| **Description** | Encyclopedic collection tracking every fish species. Each entry has two states: Undiscovered (silhouette + area + bait hint visible) and Discovered (full entry on first catch). Tracks personal size record per species. Area completion gates rewards. |
| **Depends On** | S-02 (catch events trigger discovery), S-07 (area unlock state determines visible entries) |
| **Required By** | S-06 (market may reference album for pricing hints), S-07 (album % drives area unlock gate), S-08 (save persists album state) |
| **Key Rules** | Bait hint always visible even before first catch; size record is cosmetic-only; 70% completion = area unlock eligible; 100% completion = completion reward |

---

### Tier 2 — MVP Core

#### S-04 · Rod System
| Field | Value |
| ---- | ---- |
| **Status** | `Approved` |
| **GDD** | [design/gdd/systems/rod-system.md](systems/rod-system.md) |
| **MVP Scope** | Yes |
| **Description** | Five rod tiers each improving cast speed, catch rate, and bucket capacity. Purchased at the Cat Market with coins. Rod tier also gates access to deeper water in later areas. |
| **Depends On** | S-06 (market handles purchase flow and coin deduction) |
| **Required By** | S-02 (fishing loop reads rod stats), S-08 (save persists equipped rod) |
| **Key Open Questions** | Exact stat values per tier (must be defined in this GDD). Does rod tier directly gate areas, or only indirectly via efficiency? |
| **Economy Anchor** | Tier 2 = 250c, Tier 3 = 700c, Tier 4 = 1,800c, Tier 5 = 5,000c (from game-concept.md) |

#### S-05 · Bait System
| Field | Value |
| ---- | ---- |
| **Status** | `Approved` |
| **GDD** | [design/gdd/systems/bait-system.md](systems/bait-system.md) |
| **MVP Scope** | Yes |
| **Description** | Consumable stacks (×10 uses per stack) that boost a specific fish family's catch weight by ×4 (renormalized). Different bait types available per area tier. Purchased at the Cat Market. |
| **Depends On** | S-06 (market handles purchase), S-07 (area tier determines available bait types) |
| **Required By** | S-02 (fishing loop applies bait modifier to catch table), S-08 (save persists active bait + remaining uses) |
| **Key Open Questions** | What constitutes one bait "use"? (per cast recommended — define in GDD). How does the player know they are out of bait? Early-game sequencing: can player buy bait before Rod Tier 2? |

#### S-06 · Cat Market
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/cat-market.md` |
| **MVP Scope** | Yes |
| **Description** | Panel where the player sells fish from the bucket for coins, and spends coins on rods, bait, cats, and cosmetics. Coin balance is the central economy currency. Daily bonus price rotation is post-MVP. |
| **Depends On** | S-02 (bucket contents available to sell), S-08 (save persists coin balance) |
| **Required By** | S-04 (rod purchases), S-05 (bait purchases), S-09 (cat purchases), S-10 (cosmetic purchases) |
| **Key Rules** | Economy reference values in game-concept.md. Daily rotation deferred to Vertical Slice. |

#### S-08 · Save System
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/save-system.md` |
| **MVP Scope** | Yes |
| **Description** | Local file save of all persistent state: album discoveries, coin balance, equipped rod/bait, active area, bucket contents, cat roster, size records. Needs backup mechanism given the emotional weight of album progress loss. |
| **Depends On** | *(reads from all systems; writes to local disk)* |
| **Required By** | All systems (provides persisted state on load) |
| **Key Risks** | Save file corruption or deletion would devastate this player type. Design a silent backup (e.g., rolling `.bak` file). Define what happens on corrupt load. |

---

### Tier 3 — Vertical Slice

#### S-07 · Area Progression
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/area-progression.md` |
| **MVP Scope** | No (one area in MVP; system structure needed in Tier 2 but content deferred) |
| **Description** | Manages available fishing areas. Each area has a unique catch table, background, and ambient audio. Unlock gate: previous area ≥70% album complete AND coin cost paid. 7 areas total at full vision. |
| **Depends On** | S-03 (album % tracked per area), S-06 (coin balance for gate cost) |
| **Required By** | S-02 (active area determines catch table), S-05 (area tier determines available bait), S-08 (save persists unlocked areas) |
| **Coin Gates** | Area 2 = 300c, Area 3 = 800c, Area 4 = 2,000c; Areas 5–7 follow ~2.5× scaling (define in GDD) |

#### S-09 · Cat Collection
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/cat-collection.md` |
| **MVP Scope** | No |
| **Description** | 15–20 collectible cats, each purely cosmetic. Distinct idle, cast, tug, and catch animations per cat. Unlocked via album milestones or coin purchase at Cat Market. No stat bonuses — selection is purely expressive. |
| **Depends On** | S-03 (album milestones trigger unlocks), S-06 (coin purchase), S-08 (save persists roster + equipped cat) |
| **Required By** | S-01 (widget renders active cat sprite) |
| **Key Rules** | Pillar 3: cats must never provide mechanical advantage. Any stat proposal must be rejected at design stage. |

#### S-10 · Daily Market Rotation
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/daily-market-rotation.md` |
| **MVP Scope** | No |
| **Description** | Each real-world day, 1–2 fish species receive a bonus sell price multiplier at the Cat Market. Creates a light daily reason to check in without creating pressure. |
| **Depends On** | S-06 (market applies multiplier at sell), S-08 (save/date logic to determine current day's rotation) |
| **Required By** | *(none — optional enhancement to S-06)* |
| **Key Open Questions** | How is rotation seeded — local date RNG or authored calendar? Same bonus for all players on same date or per-player? |

---

### Tier 4 — Full Vision

#### S-11 · Cosmetics System
| Field | Value |
| ---- | ---- |
| **Status** | `Not Started` |
| **GDD** | `design/gdd/systems/cosmetics.md` |
| **MVP Scope** | No |
| **Description** | Visual customisation layer: widget backgrounds, rod skins, cat accessories/outfits. Purchased with coins. No gameplay effect. |
| **Depends On** | S-06 (coin purchase), S-08 (save persists equipped cosmetics) |
| **Required By** | S-01 (widget renders equipped background + accessories) |

---

## Dependency Graph (Summary)

```
S-01 Widget Window
  └── renders ← all systems

S-02 Fishing Loop
  ├── reads rod stats ← S-04
  ├── reads bait modifier ← S-05
  ├── reads active area catch table ← S-07
  ├── sends catch events → S-03
  └── fills bucket → S-06

S-03 Fish Album
  ├── receives catch events ← S-02
  ├── reads area unlock state ← S-07
  ├── sends album % → S-07 (unlock gate)
  └── sends milestone unlocks → S-09

S-04 Rod System
  └── purchased via → S-06

S-05 Bait System
  ├── purchased via → S-06
  └── available types gated by → S-07

S-06 Cat Market
  ├── sells bucket contents ← S-02
  └── funds → S-04, S-05, S-09, S-10, S-11

S-07 Area Progression
  ├── gated by album % ← S-03
  └── gated by coins ← S-06

S-08 Save System
  └── persists state from → all systems

S-09 Cat Collection
  ├── unlocked via milestones ← S-03
  └── purchased via → S-06

S-10 Daily Market Rotation
  └── enhances → S-06

S-11 Cosmetics
  └── purchased via → S-06
```

---

## Recommended Authoring Order

Author system GDDs in this sequence — each GDD can only be written fully once its dependencies are defined:

| Order | System | Reason |
| ---- | ---- | ---- |
| 1 | S-01 Widget Window | Platform foundation; prototype first |
| 2 | S-02 Fishing Loop | Everything depends on it; prototype in parallel |
| 3 | S-04 Rod System | Fishing loop needs rod stat values to be complete |
| 4 | S-05 Bait System | Fishing loop needs bait modifier rules to be complete |
| 5 | S-03 Fish Album | Depends on fishing loop and bait system being defined |
| 6 | S-06 Cat Market | Needs all purchasable systems (rods, bait) defined first |
| 7 | S-08 Save System | Needs all persistent state defined before save schema |
| 8 | S-07 Area Progression | Needs album, market, and fishing loop complete |
| 9 | S-09 Cat Collection | Needs market and album milestones defined |
| 10 | S-10 Daily Market Rotation | Enhances market; write last among core systems |
| 11 | S-11 Cosmetics | Final layer; write when Tier 1–3 are stable |

---

## MVP Checklist

Systems required for MVP (4–6 week target):

- [ ] S-01 Widget Window — prototype validated
- [ ] S-02 Fishing Loop — prototype validated
- [ ] S-04 Rod System — GDD approved
- [ ] S-05 Bait System — GDD approved
- [ ] S-03 Fish Album — GDD approved
- [ ] S-06 Cat Market — GDD approved
- [ ] S-08 Save System — GDD approved
