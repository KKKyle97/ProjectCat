# Game Concept: Cat & Hook

*Created: 2026-05-28*
*Status: Approved*

---

## Elevator Pitch

> A window-level desktop idle game where your cat fishes autonomously while you work. Set up the right rod and bait, leave your cat at the water's edge, and come back to a bucket full of discoveries — collecting every fish species across every area is the goal, and your cats are purely along for the ride.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Idle / Incremental + Collectible |
| **Platform** | PC (Windows first, Mac later) |
| **Target Audience** | Casual-to-midcore PC users who want a low-pressure companion while working |
| **Player Count** | Single-player |
| **Session Length** | 2–5 minute check-ins throughout the day; passive accumulation in between |
| **Monetization** | Premium (buy once) |
| **Estimated Scope** | Medium (4–8 months) |
| **Comparable Titles** | Neko Atsume, Desktop Goose, Stardew Valley (fishing feel) |

---

## Core Fantasy

Your cat is being productive while you're being productive.

It's sitting at the water's edge with a tiny rod, doing its job, while you do yours. Every time you glance over, something new is in the bucket. You're not managing the cat — you're just present for its life. Over time you learn which bait lures the Mountain Trout, which rod reaches the deep spots, and you set your cat up with exactly what it needs before you head back to your own work. The satisfaction is in knowing, planning, and returning to find you were right.

---

## Unique Hook

It's like Neko Atsume — AND ALSO the rarity isn't luck. Every fish in the album is reachable through knowledge: learn the right area, set the right bait, upgrade the right gear. No RNG walls. Completion is a question of *when*, not *if*.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Submission** (relaxation, comfort zone) | 1 | Background presence, no pressure, no fail states, ambient audio |
| **Fellowship** (companionship) | 2 | Named cats with distinct idle personalities, animations that react to good catches |
| **Discovery** (exploration, secrets) | 3 | Fish album fills gradually; each new area reveals new species |
| **Expression** (self-expression) | 4 | Cat cosmetics, rod skins, widget background customization |
| **Sensation** (sensory pleasure) | 5 | Satisfying catch animation, cozy visual style, soft audio feedback |
| **Challenge** (mastery) | N/A | Not a skill game — mastery is knowledge-based, not input-based |
| **Narrative** (story arc) | N/A | No plot; world-building is incidental through fish album lore entries |
| **Fantasy** (role-playing) | N/A | Player is themselves, not a character |

### Key Dynamics (Emergent player behaviors)

- Players will learn fish preferences and pre-configure bait + area before leaving their desk
- Players will prioritize selling common fish to fund bait for rare targets
- Players will collect specific cats for aesthetic reasons and attach personality to them
- Players will check the album before each session to decide what to hunt
- Players will delay selling fish they've never seen before, just to look at them

### Core Mechanics (Systems we build)

1. **Autonomous fishing loop** — Cat casts, waits, and catches on a timer. No input required. Catch rate and fish type influenced by equipped rod tier and active bait. **Catch weight rule**: each area has a weighted catch table (e.g., Common fish 60%, Uncommon 30%, Rare 10% base). Equipping a matching bait multiplies that fish family's weight by ×4; weights are renormalized after the boost is applied so total probability sums to 100%. Result: a Rare fish boosted from 10 → 40 weight, with Common 60 and Uncommon 30, normalizes to Rare ≈31%, Common ≈46%, Uncommon ≈23% — making targeted species the dominant catch while still allowing incidental others. **Full-bucket rule**: when the bucket reaches capacity the cat stops casting and sits idle. No catch is lost, no penalty accrues. The moment the player sells any fish the cat resumes casting immediately.
2. **Fish album** — Encyclopedic collection of all species. Each fish has a name, area, preferred bait, size record, and lore blurb. Completing an area's album page unlocks a reward. **Bait-hint rule**: every album entry has two states — *Undiscovered* (shows silhouette, area name, and preferred bait as a visible clue) and *Discovered* (full entry with name, sprite, size record, and lore blurb unlocked on first catch). Bait preference is always visible, even before a fish is caught, so players can make knowledge-based decisions from day one.
3. **Bait and rod system** — Rods affect cast speed, catch rate, and bucket capacity. Bait types attract specific fish families. Selecting the right combination is the player's primary decision.
4. **Cat Market** — Sell accumulated fish for coins. Daily rotating bonus prices on specific species. Coins fund rod upgrades, bait, cosmetics, and new cats.
5. **Cat collection** — Multiple cats available to unlock, each purely cosmetic with distinct idle animations and visual personality. Selecting which cat fishes is the player's expressive choice, not a strategic one.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Player chooses area, rod, and bait each session — small but meaningful setup decisions | Supporting |
| **Competence** (mastery, skill growth) | Mastery = learning fish preferences. Album completion is proof of knowledge | Core |
| **Relatedness** (connection, belonging) | Named cat with expressive animations creates a genuine sense of companionship | Core |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — Filling the fish album is the primary long-term goal. Album pages, area completion, and cat collection all feed this.
- [x] **Explorers** (discovery, understanding systems) — Discovering which bait catches which fish, unlocking new areas, reading fish lore entries.
- [ ] **Socializers** — Single-player only; no social layer in this scope.
- [ ] **Killers/Competitors** — No competition, no leaderboards, intentionally excluded.

### Flow State Design

- **Onboarding curve**: Tutorial cat catches its first fish in 30 seconds. Bait system introduced at first album gap ("You're missing the Spotted Gudgeon — try Mayfly Bait"). Natural discovery, no tutorial walls.
- **Difficulty scaling**: Not applicable — this isn't a skill game. "Difficulty" is album completion percentage; the curve is geographic (new areas = new fish to learn).
- **Feedback clarity**: Catch animations celebrate every fish. Rare catches get a bigger animation beat. Album progress is always visible. Coin delta shown on market sell.
- **Recovery from failure**: There is no failure. Being away = fish accumulated. The game is always in the player's favour.

---

## Core Loop

### Moment-to-Moment (30 seconds)

The cat sits at the water's edge. It casts automatically. The line bobs. The cat's ear flicks. A tug — the cat pulls back, a small fish arcs through the air and lands in the bucket with a soft *plop*. The cat shakes its paw and casts again. This plays on repeat, visible in the corner of the player's screen, whether they watch or not.

### Short-Term (5–15 minutes)

The player glances over and sees the bucket is getting full. They open the panel: eight Carp, two Roach, and one fish they don't recognise — a Spined Loach, a new album entry. They open the album page, read the blurb, note it prefers Worm Bait. They sell everything except the Loach (they want to look at it a bit longer), pocket the coins, swap the active bait to Worm, and click away.

### Session-Level (30–120 minutes)

Once or twice a day the player opens the full panel properly. They check album progress — Mountain Stream is 80% complete, only the Golden Dace left. They upgrade the rod to Tier 3 (unlocks a larger bucket), buy a stack of Spinner Bait (Golden Dace's preference), switch to Mountain Stream, and equip their newest cat (a fluffy Maine Coon they unlocked yesterday). They close the panel and go back to work.

### Long-Term Progression

- **Areas**: Unlock 6–8 distinct fishing zones across the game, each with a unique fish roster and visual environment in the widget. **Unlock condition**: each area beyond the first requires (a) the previous area's album is ≥70% complete AND (b) a coin cost paid at the market. The 70% threshold prevents a single rare fish from blocking progress indefinitely; the coin cost makes progression feel earned. Suggested coin gates: Area 2 = 300c, Area 3 = 800c, Area 4 = 2,000c (scales roughly 2.5×).
- **Album**: Two distinct completion milestones per area — (a) reaching the ≥70% threshold + coin gate unlocks the *next fishing area*; (b) reaching 100% completion earns a *completion reward* (new cat or cosmetic item). These are separate outcomes, not the same trigger.
- **Equipment**: Rod tiers 1–5 unlock faster catches, deeper water access, and bigger buckets; bait types expand as new areas open
- **Cats**: 15–20 collectible cats, unlocked via album milestones and coin purchase; purely cosmetic, purely expressive
- **Endgame**: Full album completion unlocks a final visual reward and a "completion" panel — the entire collection displayed together

### Retention Hooks

- **Curiosity**: New area silhouette visible before unlock; unknown fish species show as silhouettes in the album with bait preference visible as a clue
- **Investment**: Album progress, named cat, cosmetic choices — the widget feels *theirs*
- **Mastery**: Bait knowledge accumulates; experienced players set up perfectly-targeted fishing sessions
- **Daily variance**: Cat Market rotates bonus prices daily, creating a light reason to check in

---

## Game Pillars

### Pillar 1: The Cat Does the Work

The game progresses without the player present. No mechanic should require active input to function.

*Design test*: If we're debating a fishing minigame vs. fully automatic catches, this pillar says automatic. Always.

### Pillar 2: Collection is Knowledge, Not Luck

Every fish in the album is reachable through correct area selection and bait choice. Pure RNG walls are forbidden.

*Design test*: If a fish can only be caught by luck regardless of what the player sets up, redesign it to have a knowable preference.

### Pillar 3: The Cat is a Companion, Not a Tool

Cats are purely cosmetic. They carry no stat bonuses, fishing advantages, or mechanical differentiation.

*Design test*: If we're tempted to add a "Lucky Cat" that boosts rare fish rates, this pillar says no — give it a charming animation instead.

### Pillar 4: Gear is the Progression

Rod tier and bait selection are the sole mechanical levers. Upgrading these is how the player expands their capabilities.

*Design test*: If a new feature doesn't connect to rod or bait, it needs justification before it enters scope.

### Pillar 5: Check-In is Rewarding, Never Punishing

Every time the player glances at the widget, something good has happened. The game never creates anxiety about being away.

*Design test*: If a mechanic would make a player feel bad for not checking in (fish spoiling, cat getting sad, bucket overflow penalties), cut it.

### Anti-Pillars (What This Game Is NOT)

- **NOT a skill game**: No fishing minigame, no timing mechanics, no reflexes required. This would drive away the exact player we're building for.
- **NOT a pressure game**: No decay, no hunger meters, no cat welfare systems. The companion format only works if presence is a choice, not an obligation.
- **NOT a pay-to-win model**: No stat-boosting purchases. Cosmetics only in any monetisation consideration.
- **NOT a social game**: No multiplayer, no trading, no leaderboards in this scope. The intimacy of a solo companion would be diluted.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Neko Atsume** | Cat collection as pure expression; no-pressure check-in loop | Adds active progression (album, upgrades) and a knowledge system | Proves the "cats you love but don't manage" design works commercially |
| **Desktop Goose** | Window-level desktop presence as a format | Warm and cozy, not chaotic; the cat cooperates rather than disrupts | Proves desktop companions can be a primary platform, not a gimmick |
| **Stardew Valley (fishing)** | Emotional satisfaction of catching a new species for the first time | No minigame skill requirement; satisfaction is pure collection, not execution | Validates the emotional weight of fish-as-collectibles |

**Non-game inspirations**: Studio Ghibli backgrounds (visual warmth, detailed natural environments in small spaces); café lo-fi playlists (ambient audio tone); nature documentary narration tone for fish album lore entries.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 20–38 |
| **Gaming experience** | Casual to mid-core; comfortable with PC games, not interested in high-skill genres |
| **Time availability** | Works at a computer; has a second monitor or window space; plays in scattered 2–5 minute glances throughout the day |
| **Platform preference** | PC (desktop), always-on computing environment |
| **Current games they play** | Stardew Valley, Neko Atsume, A Short Hike, various idle/clicker games |
| **What they're looking for** | A low-stakes companion that gives them something pleasant to glance at; the feeling of gentle progress without demanding attention |
| **What would turn them away** | Minigames requiring focused input, any mechanic that punishes being away, visual noise or loud audio |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4** — native support for transparent borderless always-on-top windows; lightweight runtime; excellent 2D animation tooling; free and open source |
| **Key Technical Challenges** | Transparent/click-through window implementation on Windows; always-on-top window management; reliable local save state; bucket overflow edge cases |
| **Art Style** | 2D illustrated / soft pixel — warm palette, hand-drawn feel, readable at small widget size |
| **Art Pipeline Complexity** | Medium — custom 2D sprites with multiple animation states per cat; per-area backgrounds; 60–80 fish sprites at full scope |
| **Audio Needs** | Moderate — ambient loop per area (water, wind, environment); soft catch SFX; light UI sounds; no adaptive audio system needed |
| **Networking** | None |
| **Content Volume** | MVP: 1 area, 15 fish, 1 cat, 2 rod tiers, 3 baits. Full vision: 7 areas, 75 fish, 18 cats, 5 rod tiers, 30+ cosmetics |
| **Procedural Systems** | None — all fish, areas, and cats are hand-authored |

---

## Economy Reference (Placeholder Values)

These are rough design-intent numbers for pacing. Exact values are tuning knobs; the ratios matter more than the absolutes. Design target: a new player should be able to afford Rod Tier 2 after approximately 2–3 hours of passive accumulation with occasional check-ins.

| Item | Sell / Cost | Notes |
| ---- | ---- | ---- |
| Common fish | 3–8c sell | Majority of early catches |
| Uncommon fish | 15–30c sell | ~30% of catches without bait |
| Rare fish | 50–100c sell | ~10% base rate; targeted with bait |
| Rod Tier 2 | 250c | First meaningful upgrade |
| Rod Tier 3 | 700c | Unlocks Area 3 depth |
| Rod Tier 4 | 1,800c | Late-game pacing |
| Rod Tier 5 | 5,000c | Endgame; unlocks max bucket + deep zones |
| Bait stack (×10 uses) | 25–60c buy | Scales with area tier |
| Cosmetic items | 100–500c buy | No gameplay effect |
| Cat unlock (coin-purchased) | 600–2,000c buy | Trophy price; purely cosmetic |

**Fish size record**: size is a trophy attribute tracked per species in the album — the personal best length in cm. Larger catches of the same species silently replace the record. No mechanical effect on coins or catch rate; it is a pure collector's stat displayed in the album entry. A subtle catch-size animation variant (bigger splash) fires when a new record is set.

---

## System Dependencies

| System | Depends On | Required By |
| ---- | ---- | ---- |
| **Fishing Loop** | Rod & Bait data, Area/catch-table data | Album, Market, all other systems |
| **Fish Album** | Fishing Loop (catch events), Area unlock state | Market (prices), Area unlock gate |
| **Bait & Rod System** | Market (purchase), Coin balance | Fishing Loop (modifiers) |
| **Cat Market** | Fishing Loop (bucket contents), Coin balance | Rod & Bait System, Cat Collection, Cosmetics |
| **Cat Collection** | Market (purchase), Album milestones (unlock triggers) | None (cosmetic output only) |
| **Area Progression** | Album completion %, Coin balance | Fishing Loop (available areas), Catch tables |

---

## Risks and Open Questions

### Design Risks
- Album completion may feel anticlimactic if the final fish is just "wait longer with the right bait" — needs a satisfying reveal moment for each species discovered
- Cat personality may feel thin without narrative investment — expressive idle animations must do heavy lifting

### Technical Risks
- Transparent always-on-top window behaviour is OS-dependent; Godot 4 supports it but edge cases (multiple monitors, DPI scaling, Windows 11 snap layouts) need early prototyping
- Local save file could be corrupted or deleted — album progress loss would be devastating for this player type; needs backup mechanism

### Market Risks
- Desktop companion games have a history of novelty wearing off quickly; long-term retention depends entirely on content depth (area count, fish count, cat count)
- Discovery is tricky — the game is invisible to someone who hasn't seen it running. Streaming/YouTube demonstration is the primary marketing surface

### Scope Risks
- Art volume is the primary timeline risk — 70+ fish sprites + 18 cats × multiple animation states is significant for a solo developer
- Bait + fish pairing data must be authored carefully to avoid dead-end album states where no available bait catches a needed fish

### Open Questions

- Does the widget format sustain interest past the first week, or does it become wallpaper? — Answer with a 2-week prototype test with 5–10 players
- What is the right bucket capacity vs. check-in frequency balance? — Prototype test: bucket fills in 30 minutes (forces check-in) vs. 4 hours (fully passive)
- Do players want to name their cats, or does it add friction at onboarding? — A/B test in prototype

---

## MVP Definition

**Core hypothesis**: Players find it satisfying to glance at a fishing cat widget and feel rewarded by what was caught, without ever needing to actively play.

**Required for MVP**:
1. Borderless always-on-top widget window with one background (Backyard Pond)
2. One cat with 4 animation states: idle, cast, tug, catch
3. 15 fish species with distinct sprites; 3 bait types that influence catch distribution
4. Rod Tier 1 and 2 with visible upgrade path
5. Fish album UI showing collected/uncollected species
6. Cat Market sell screen with coin tracking
7. Local save file

**Explicitly NOT in MVP**:
- Multiple fishing areas (validate the single loop first)
- Cat collection and cosmetics (scope after core loop is validated)
- Daily market rotation (add once retention is confirmed)
- Audio (placeholder or silent for MVP test)

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 area, 15 fish, 1 cat, 2 rod tiers, 3 baits | Core loop, album, market, save | 4–6 weeks |
| **Vertical Slice** | 2 areas, 30 fish, 4 cats, 3 rod tiers, 8 baits | + Cat cosmetics, audio, daily market | 10–14 weeks |
| **Alpha** | 5 areas, 55 fish, 12 cats, 5 rod tiers | All features, rough art | 5–6 months |
| **Full Vision** | 7 areas, 75 fish, 18 cats, full cosmetics | Polished, achievement layer, final album reward | 7–9 months |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine godot 4`)
- [ ] Create game pillars document (`/design-review` to validate)
- [ ] Decompose concept into systems (`/map-systems`)
- [ ] Prototype the widget window format in Godot 4 — transparent always-on-top window with a cat sprite and idle animation (`/prototype widget-window`)
- [ ] Prototype the core fishing loop — auto-cast timer, bait influence on catch table, bucket fill (`/prototype fishing-loop`)
- [ ] Validate both prototypes with 2-week playtest (`/playtest-report`)
- [ ] Plan first sprint (`/sprint-plan new`)
