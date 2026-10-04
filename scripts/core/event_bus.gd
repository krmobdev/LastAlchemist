class_name EventBus
extends Node

signal game_state_changed
signal inventory_changed
signal recipe_discovered(recipe_id: String)
signal order_completed(order_id: String, reward: int)
signal notification_requested(message: String)
