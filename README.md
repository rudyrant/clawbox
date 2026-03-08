# Clawbox

Clawbox is a small 2D sandbox prototype built in Godot 4. You can move, jump, break blocks, place blocks from your hotbar, collect dropped items, and continue from an auto-saved world.

## Features
- Procedurally generated tile world (grass, dirt, stone)
- Block mining and placement
- Inventory + hotbar UI
- Mobile touch controls (left movement pad, right jump/mine/place, bag toggle)
- Automatic save/load to `user://savegame.json`

## Local setup and run
1. Install **Godot 4.2.x** (project exports are configured for 4.2.2).
2. Clone this repo and `cd` into it.
3. Open the folder in Godot and let it import assets (`project.godot`).
4. Run the main scene `scenes/main.tscn` (or press Play).

Optional CLI run (if `godot4` is on your `PATH`):

```bash
godot4 --path .
```

## GitHub Actions Android build
The workflow is defined at `.github/workflows/android.yml` and is triggered by:
- Pushes to `main`
- Manual runs from **Actions -> Android Export -> Run workflow**

Build job summary:
1. Checks out the repo.
2. Installs Java 17 (Temurin).
3. Installs Android SDK components.
4. Generates a debug keystore at `~/.android/debug.keystore`.
5. Runs `firebelley/godot-export@v5.2.1` with Godot **4.2.2** and export templates.
6. Uploads build output as the **Android Build** artifact.

To download the APK/AAB from a run:
1. Open the workflow run in GitHub Actions.
2. Download the **Android Build** artifact from the run summary.
