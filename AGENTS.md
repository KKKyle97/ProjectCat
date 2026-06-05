# ProjectCat Agent Guide

## Project Overview

- This workspace contains **Cat & Hook**, a Godot 4.6.3 desktop-widget game.
- The runnable Godot project is in `project-cat/`.
- Use the Compatibility/OpenGL renderer and preserve the transparent, borderless,
  always-on-top widget behavior unless a design change explicitly requires otherwise.
- Treat `design/gdd/` as the gameplay and product source of truth.
- Treat accepted records in `docs/architecture/` as the implementation source of
  truth. If a GDD and an ADR conflict, stop and surface the conflict before changing
  behavior.

## Repository Map

- `project-cat/project.godot`: Godot project entry point.
- `project-cat/scenes/`: reusable and level scenes.
- `project-cat/src/`: runtime GDScript organized by system.
- `project-cat/config/`: typed tuning constants and formulas.
- `project-cat/data/`: data-driven game content.
- `project-cat/tests/`: headless validation scripts.
- `project-cat/tools/`: development-only scripts and visual test harnesses.
- `design/gdd/`: game concept and system specifications.
- `docs/architecture/`: accepted architecture decisions.
- `.agents/skills/`: reusable project workflows.

## Working Process

1. Read the relevant GDD, accepted ADRs, scene, and scripts before editing.
2. Keep changes scoped to the requested system and preserve existing behavior outside
   that scope.
3. Surface unclear or contradictory design requirements instead of silently choosing
   a new interpretation.
4. Update the relevant GDD or ADR when an approved change alters behavior or
   architecture.
5. Run the narrowest relevant validation, then inspect output for errors and warnings.

## Godot Standards

- Follow the official Godot 4.6 GDScript style guide.
- Use tabs for indentation and UTF-8/LF files.
- Use `snake_case` for files, functions, and variables.
- Use `PascalCase` for classes, enum names, and node names.
- Use `CONSTANT_CASE` for constants and enum members.
- Name signals in past tense, such as `fish_caught` or `state_changed`.
- Prefix private variables and methods with `_`.
- Prefer static typing. Use `:=` when the type is obvious from the assignment and an
  explicit type when it is ambiguous.
- Add `class_name` only for reusable project-wide types that benefit from being in
  Godot's global class registry.
- Order scripts according to Godot conventions: class declaration and documentation,
  signals, enums, constants, properties, lifecycle callbacks, public methods, then
  private methods.
- Use `##` documentation comments for public classes, signals, and APIs. Use regular
  comments only to explain intent or non-obvious constraints.

## Architecture Rules

- Prefer small, self-contained scenes and nodes composed together over deep
  inheritance.
- Keep gameplay/domain logic separate from UI and presentation.
- Communicate across systems with signals and injected dependencies; avoid hard-coded
  scene-tree paths and unrelated global dependencies.
- Keep deterministic math and rules in node-free or stateless classes where practical
  so they can be tested headlessly.
- Put balancing values, timing values, and formulas in `project-cat/config/`; avoid
  magic numbers in gameplay and scene-controller scripts.
- Put content in `project-cat/data/` when designers should be able to change it
  without editing gameplay code.
- Make time-based behavior frame-rate independent using `delta`, timers, or elapsed
  time as appropriate.
- Use `StringName` for stable identifiers and signal/group names when appropriate.
- Handle expected failure cases explicitly; do not silently swallow invalid data or
  impossible states.

## Scenes And Assets

- Use the repository `generate-character` skill whenever the user says **generate
  character** or asks for a new Cat & Hook cat character, variant, sprite, reference,
  or animation.
- Keep scene ownership clear: a scene should configure its own internal nodes, while
  external dependencies are injected by its parent or composition root.
- Use exported properties for editor-authored scene configuration where appropriate.
- Preserve existing node names and paths when changing them would break scene or
  script references.
- Do not manually edit generated `.godot/`, `.import`, or `.uid` data. Preserve
  checked-in import metadata unless an intentional asset change regenerates it.
- Do not modify `templates_4.6.3.tpz`; it is a large engine template archive, not
  project source.

## Verification

Run commands from `project-cat/`. Use the installed Godot 4.6 console executable in
place of `<godot>` when `godot` is not available on `PATH`.

```powershell
# Parse/load the project and exit.
<godot> --headless --path . --editor --quit

# Existing fishing-loop validation.
<godot> --headless --path . --script res://tests/fishing/sim_catch_resolver.gd

# Run the game for manual verification.
<godot> --path .
```

- Add or update a headless validation script for deterministic gameplay-rule changes.
- For scene, UI, transparency, input, animation, or rendering changes, also verify the
  behavior in a windowed Godot run.
- Treat new parser errors, runtime errors, and unexpected warnings as failures.
- Report which checks ran and which could not run.

## Definition Of Done

- The implementation matches the relevant GDD and accepted ADRs.
- The change follows Godot style and the architecture rules above.
- Relevant validation passes, including windowed checks for visual or input changes.
- Documentation and data are updated when behavior or tuning contracts change.
- Generated files and unrelated systems remain untouched.
