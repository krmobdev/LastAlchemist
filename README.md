# Last Alchemist

Mobile-first alchemy management RPG. Build potions, discover reactions, serve clients, explore the valley and uncover the lost alchemical school.

## Current vertical slice

- Laboratory and brewing loop
- 12 reagents with custom SVG art
- 12 recipes
- Recipe discovery
- 5 NPCs with portraits and dialogue
- Client orders, rewards and reputation
- Shop and laboratory upgrades
- World map with 4 locations
- Locked locations and exploration events
- Story progression through the first act
- Save/load state (versioned)
- Haptic feedback adapter
- UI transition animations
- Automated content-reference validation

## Architecture

```text
Main UI
  ├─ InventorySystem
  ├─ RecipeBook / ReactionEngine
  ├─ OrderSystem
  ├─ EconomySystem
  ├─ ShopSystem
  ├─ UpgradeSystem
  ├─ WorldSystem / WorldEventSystem
  ├─ CharacterDatabase / DialogueSystem
  ├─ StorySystem
  ├─ SaveManager
  └─ FeedbackSystem / AudioSystem

Data
  ├─ reagents.json
  ├─ recipes.json
  ├─ orders.json
  ├─ characters.json
  ├─ dialogue.json
  ├─ locations.json
  ├─ events.json
  ├─ story.json
  └─ shop.json
```

The game is intentionally data-driven: adding content should normally require editing data rather than rewriting gameplay systems.

## Validation

Run:

```bash
python tools_validate_content.py
./tools_validate_project.sh
```

The current Termux environment contains the Android SDK/build tooling, but not a Godot runtime. Godot execution tests and Android export remain release-gate tasks.
