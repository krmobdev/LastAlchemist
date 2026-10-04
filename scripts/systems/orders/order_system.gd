class_name OrderSystem
extends RefCounted

signal completed(reward: int)

var active := {"id": "healing", "name": "Зелье восстановления", "reward": 120}
var reputation := 0

func fulfill(recipe_id: String) -> Dictionary:
    if recipe_id != active["id"]:
        return {"success": false, "message": "Клиент просил другое зелье."}
    reputation += 1
    var reward: int = active["reward"]
    completed.emit(reward)
    return {"success": true, "reward": reward, "message": "Заказ выполнен!"}
