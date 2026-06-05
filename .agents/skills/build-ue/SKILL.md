---
name: build-ue
description: "Compile the UE project, run editor setup scripts, and optionally launch the Unreal Editor. Offer this after implementing any C++ feature."
argument-hint: "[launch|compile-only]"
user-invocable: true
allowed-tools: Bash
---

When this skill is invoked:

1. **Determine mode** from the argument:
   - No argument or `launch`: compile → run setup scripts → offer to launch the editor
   - `compile-only`: compile only, skip setup scripts and launch

2. **Run the build** using Unreal Build Tool:
   ```bash
   "E:/UnrealEngine/Engine/Build/BatchFiles/Build.bat" SayCheeseEditor Win64 Development "E:/PetProject/SayCheese.uproject" -waitmutex
   ```
   Stream the output. If the build fails, stop and report the error lines to the user — do not proceed further.

3. **On build success**, if mode is `launch` (or no argument was given):

   a. **Run editor setup scripts** (headless, no UI):
      ```bash
      "E:/PetProject/Tools/editor_setup/run_setup.bat"
      ```
      - This runs every `*_setup.py` in `Tools/editor_setup/` via `UnrealEditor-Cmd.exe`
      - Scripts are idempotent — existing assets are skipped, new ones are created
      - If the batch exits with error, report the failure but still offer to launch the editor
        (setup failure is non-blocking — the user may have the editor open, which causes a lock conflict)

   b. **Offer to launch the editor**:
      - Ask the user: "Setup complete. Launch the Unreal Editor now?"
      - If yes, run:
        ```bash
        start "" "E:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor.exe" "E:/PetProject/SayCheese.uproject"
        ```
      - Confirm the editor process started.

4. **After any C++ feature implementation**, proactively offer:
   > "Want me to compile, run setup, and launch the editor? Run `/build-ue` or I can do it now."

### Adding new setup scripts

When implementing a feature that requires new Blueprint assets:
- Write a Python script at `Tools/editor_setup/<feature>_setup.py`
- Name it so it sorts correctly (alphabetical = execution order): `01_core_setup.py`, `02_player_setup.py`, etc.
- `run_setup.bat` picks up all `*_setup.py` files automatically — no registration needed

### Notes
- `.h` changes that add `UPROPERTY`/`UFUNCTION` or new classes require a full compile — Live Coding won't catch them.
- `.cpp`-only changes can also use Live Coding in a running editor session.
- Build target is `SayCheeseEditor` (project was renamed from PetProject to SayCheese).
- Module include root is explicitly set via `PublicIncludePaths.Add(ModuleDirectory)` in Build.cs — required for subdirectory .cpp files.
- UE5.7 test flags: use `EAutomationTestFlags::EditorContext` NOT `EAutomationTestFlags::ApplicationContextMask` (moved to inline constexpr in 5.7).
- Setup scripts run via `UnrealEditor-Cmd.exe -NullRHI` (headless, no rendering). This **requires the editor to be closed** — if the editor is open, the commandlet will fail to acquire the project lock. In that case, setup failure is non-blocking and the user can run `File → Execute Python Script` manually.
