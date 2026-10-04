# Last Alchemist — Architecture

## 1. Principles
- Mobile-first, portrait 9:16.
- Systems are independent and communicate through signals/events.
- Game rules live in scripts/data, not UI scenes.
- Data-driven content: recipes, reagents, clients and orders are Resources/JSON-like data.
- Save data is versioned from day one.
- MVP first; content and polish are layered afterward.

## 2. Modules

### Core
GameManager, GameState, SceneRouter, EventBus, SaveManager, SettingsManager.

### Alchemy
Reagent compatibility, reaction graph, recipe discovery, brewing simulation, quality/result calculation.

### Inventory
Reagents, quantities, storage limits, item categories, sorting/filtering.

### Recipes
Known/unknown recipes, recipe unlocks, ingredients, required equipment, discovered effects.

### Orders
Client generation, order requirements, deadlines, rewards, reputation, validation.

### Economy
Gold, shop prices, buying/selling, laboratory upgrades and balancing.

### World
Village hub, locations, unlock conditions, travel and simple events.

### Characters
Player, clients, NPC data, portraits, dialogue hooks.

### UI
Main menu, laboratory, cauldron, inventory, recipes, orders, shop, map, settings, modal notifications.

### Save/Data
Serializable game state, schema version, migration path, autosave/checkpoints.

## 3. Dependency direction
UI -> systems -> core/data.
UI must never implement game rules.
Alchemy can read Inventory and Data, then emit results/events.
Orders consume crafted results and award Economy/Reputation.
SaveManager observes state changes and persists them.

## 4. Proposed structure
```text
LastAlchemist/
  assets/
    textures/
    ui/
    characters/
    items/
    world/
    audio/
  data/
    recipes/
    reagents/
    orders/
    characters/
    config/
  scenes/
    main/
    lab/
    ui/
    world/
    characters/
  scripts/
    core/
    systems/
      alchemy/
      inventory/
      recipes/
      orders/
      economy/
      world/
      characters/
      save/
    ui/
  docs/
```

## 5. MVP vertical slice
1. Main menu
2. Enter laboratory
3. Inventory with 6–8 reagents
4. Select two reagents
5. Brew in cauldron
6. Resolve one reaction
7. Discover/save a recipe
8. Receive one client order
9. Craft requested potion
10. Deliver order and receive gold
11. Save/load

Everything else waits until this loop is stable.
