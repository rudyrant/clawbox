# Clawbox

Clawbox is a small 2D sandbox prototype built in Godot 4. You can move, jump, break blocks, place blocks from your hotbar, collect dropped items, and continue from an auto-saved world.

## Features
- Procedurally generated tile world (grass, dirt, stone)
- Block mining and placement
- Inventory + hotbar UI
- Mobile touch controls (move, jump, mine, place)
- Automatic save/load to `user://savegame.json`

## Run
1. Install **Godot 4.x**.
2. Open this folder as a project in Godot.
3. Run the main scene (`scenes/main.tscn`) or press Play in the editor.

Optional CLI run (if `godot4` is on your PATH):

```bash
godot4 --path .
```
