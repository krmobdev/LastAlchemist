class_name EconomySystem
extends RefCounted

signal gold_changed(value: int)
signal inventory_changed

var gold: int = 100

func can_afford(price: int) -> bool:
    return gold >= price

func spend(price: int) -> bool:
    if price < 0 or not can_afford(price):
        return false
    gold -= price
    gold_changed.emit(gold)
    return true

func earn(amount: int) -> void:
    if amount <= 0:
        return
    gold += amount
    gold_changed.emit(gold)
