class_name UpgradeSystem
extends RefCounted

signal upgraded(upgrade_id: String)

var owned: Dictionary = {}
var capacity_bonus := 0
var quality_bonus := 0.0

func purchase(upgrade: Dictionary, economy: EconomySystem) -> bool:
    var id := str(upgrade.get("id", ""))
    if id.is_empty() or owned.has(id):
        return false
    var price := int(upgrade.get("price", 0))
    if not economy.spend(price):
        return false
    owned[id] = true
    capacity_bonus += int(upgrade.get("capacity", 0))
    quality_bonus += float(upgrade.get("quality_bonus", 0.0))
    upgraded.emit(id)
    return true
