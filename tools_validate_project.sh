#!/data/data/com.termux/files/usr/bin/bash
set -eu
required=(project.godot scenes/Main.tscn scripts/main.gd scripts/core/game_manager.gd scripts/core/event_bus.gd scripts/systems/save/save_manager.gd scripts/systems/alchemy/reaction_engine.gd scripts/systems/inventory/inventory_system.gd scripts/systems/recipes/recipe_book.gd scripts/systems/orders/order_system.gd data/recipes/recipes.json data/reagents/reagents.json data/orders/orders.json)
for f in "${required[@]}"; do test -f "$f" || { echo "MISSING: $f"; exit 1; }; done
python - <<'PY'
import json, pathlib
for p in pathlib.Path('data').rglob('*.json'):
    json.loads(p.read_text())
    print('OK JSON', p)
print('Project structure: OK')
PY
