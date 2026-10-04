# Data Model

## Reagent
`id`, `name`, `category`, `rarity`, `base_price`, `tags`.

## Recipe
`id`, `name`, `ingredients`, `result_id`, `discovery_hint`, `value`.

## Order
`id`, `client_id`, `requested_recipe`, `quantity`, `reward`, `deadline`, `reputation_delta`.

## Game Save
`version`, `gold`, `reputation`, `day`, `inventory`, `known_recipes`, `active_orders`, `unlocked_locations`, `settings`.
