class_name ReactionEngine
extends RefCounted

func brew(reagent_a: String, reagent_b: String) -> Dictionary:
    # MVP placeholder. Rules will move to data-driven reaction definitions.
    if reagent_a.is_empty() or reagent_b.is_empty():
        return {"success": false, "reason": "missing_reagent"}
    return {
        "success": true,
        "result_id": "unknown_potion",
        "discovered": true
    }
