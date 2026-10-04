extends Control

const Inventory = preload("res://scripts/systems/inventory/inventory_system.gd")
const Recipes = preload("res://scripts/systems/recipes/recipe_book.gd")
const Orders = preload("res://scripts/systems/orders/order_system.gd")
const Save = preload("res://scripts/systems/save/save_manager.gd")

var inventory: InventorySystem
var recipes: RecipeBook
var orders: OrderSystem
var save_manager: SaveManager
var gold := 100
var last_potion := ""
var selected: Array[String] = []
var content: Control
var gold_label: Label
var reputation_label: Label
var message_label: Label
var inventory_labels: Dictionary = {}

const ITEMS := {
    "herb": {"name": "Лунная трава", "icon": "res://assets/items/herb.svg"},
    "mushroom": {"name": "Красный гриб", "icon": "res://assets/items/mushroom.svg"},
    "crystal": {"name": "Синий кристалл", "icon": "res://assets/items/crystal.svg"},
    "flower": {"name": "Звёздный цветок", "icon": "res://assets/items/flower.svg"}
}

func _ready() -> void:
    inventory = Inventory.new()
    recipes = Recipes.new()
    orders = Orders.new()
    save_manager = Save.new()
    inventory.changed.connect(_refresh_inventory)
    recipes.discovered.connect(_on_recipe_discovered)
    orders.completed.connect(_on_order_completed)
    show_menu()

func _clear() -> void:
    for child in get_children():
        child.queue_free()
    content = null

func _make_label(parent: Control, text: String, size: int = 18) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _make_button(parent: Control, text: String, min_height: int = 64) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, min_height)
    b.add_theme_font_size_override("font_size", 18)
    parent.add_child(b)
    return b

func _panel_style(color: Color, radius := 18) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = Color("6e5532")
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 14
    s.content_margin_bottom = 14
    return s

func _base(title: String) -> VBoxContainer:
    _clear()
    var bg := TextureRect.new()
    bg.texture = load("res://assets/ui/lab_backdrop.svg")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    margin.add_child(box)
    _make_label(box, title, 30)
    return box

func show_menu() -> void:
    var box := _base("LAST ALCHEMIST")
    _make_label(box, "Последний алхимик", 20)
    _make_label(box, "Создавай. Исследуй. Торгуй.", 16)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(spacer)
    var start := _make_button(box, "🧪  ВОЙТИ В ЛАБОРАТОРИЮ", 78)
    start.pressed.connect(show_lab)
    var load_btn := _make_button(box, "Продолжить", 60)
    load_btn.pressed.connect(_load_game)
    var info := _make_label(box, "MVP • алхимия • заказы • рецепты • сохранение", 14)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_lab() -> void:
    var box := _base("ЛАБОРАТОРИЯ")

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 12)
    box.add_child(top)
    gold_label = _make_label(top, "🪙  %d" % gold, 20)
    gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reputation_label = _make_label(top, "★  %d" % orders.reputation, 20)
    var menu := _make_button(top, "Меню", 48)
    menu.pressed.connect(show_menu)

    var order_panel := PanelContainer.new()
    order_panel.add_theme_stylebox_override("panel", _panel_style(Color("382a29")))
    box.add_child(order_panel)
    var order_box := VBoxContainer.new()
    order_panel.add_child(order_box)
    _make_label(order_box, "📜 ЗАКАЗ", 19)
    _make_label(order_box, "Клиент: Элиза\nНужно: Зелье восстановления\nНаграда: 120 золотых", 16)
    var deliver := _make_button(order_box, "Сдать зелье", 52)
    deliver.pressed.connect(_deliver_order)

    _make_label(box, "ИНГРЕДИЕНТЫ — выбери два", 19)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    box.add_child(grid)
    for id in ITEMS:
        var data: Dictionary = ITEMS[id]
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 88)
        b.text = "%s\n%d" % [data["name"], int(inventory.items.get(id, 0))]
        b.icon = load(data["icon"])
        b.expand_icon = true
        b.icon_max_width = 48
        b.add_theme_font_size_override("font_size", 15)
        b.pressed.connect(func(): _select_reagent(id))
        grid.add_child(b)
        inventory_labels[id] = b

    var brew := _make_button(box, "🔥  ВАРИТЬ", 68)
    brew.pressed.connect(_brew)
    message_label = _make_label(box, "Выбрано: —\nПодсказка: попробуй траву + цветок.", 16)
    message_label.add_theme_color_override("font_color", Color("e7d6ad"))

    var lower := HBoxContainer.new()
    lower.add_theme_constant_override("separation", 10)
    box.add_child(lower)
    var recipes_btn := _make_button(lower, "📖 Рецепты", 52)
    recipes_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    recipes_btn.pressed.connect(_show_recipes)
    var save_btn := _make_button(lower, "💾 Сохранить", 52)
    save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    save_btn.pressed.connect(_save_game)

func _select_reagent(id: String) -> void:
    if selected.size() >= 2:
        selected.clear()
    selected.append(id)
    if selected.size() == 2:
        message_label.text = "Выбрано: %s + %s\nНажми ВАРИТЬ." % [ITEMS[selected[0]]["name"], ITEMS[selected[1]]["name"]]
    else:
        message_label.text = "Выбрано: %s\nВыбери второй ингредиент." % ITEMS[id]["name"]

func _brew() -> void:
    if selected.size() != 2:
        message_label.text = "Сначала выбери два ингредиента."
        return
    var a := selected[0]
    var b := selected[1]
    if not inventory.consume({a: 1, b: 1}):
        message_label.text = "Недостаточно ингредиентов."
        selected.clear()
        return
    var recipe_id := recipes.find_reaction(a, b)
    if recipe_id.is_empty():
        last_potion = "unknown"
        message_label.text = "💨 Реакция нестабильна. Получилась неизвестная смесь."
    else:
        recipes.discover(recipe_id)
        last_potion = recipe_id
        message_label.text = "✨ Успех! Открыт рецепт: %s" % recipes.recipes[recipe_id]["name"]
    selected.clear()

func _deliver_order() -> void:
    if last_potion.is_empty() or last_potion == "unknown":
        message_label.text = "У тебя нет подходящего зелья. Сначала свари его."
        return
    var result := orders.fulfill(last_potion)
    if result["success"]:
        last_potion = ""
        message_label.text = "🎉 %s +%d золота" % [result["message"], result["reward"]]
    else:
        message_label.text = result["message"]

func _on_recipe_discovered(_id: String) -> void:
    pass

func _on_order_completed(reward: int) -> void:
    gold += reward
    _refresh_header()

func _refresh_header() -> void:
    if is_instance_valid(gold_label):
        gold_label.text = "🪙  %d" % gold
    if is_instance_valid(reputation_label):
        reputation_label.text = "★  %d" % orders.reputation

func _refresh_inventory(_items: Dictionary) -> void:
    for id in inventory_labels:
        if is_instance_valid(inventory_labels[id]):
            inventory_labels[id].text = "%s\n%d" % [ITEMS[id]["name"], int(inventory.items.get(id, 0))]

func _show_recipes() -> void:
    var box := _base("📖 КНИГА РЕЦЕПТОВ")
    for id in recipes.recipes:
        var r: Dictionary = recipes.recipes[id]
        var known := recipes.known.has(id)
        var text := ("✓  " + r["name"]) if known else "?  Неизвестный рецепт"
        _make_label(box, text, 19)
    var back := _make_button(box, "← Вернуться в лабораторию", 60)
    back.pressed.connect(show_lab)

func _save_game() -> void:
    var state := {
        "gold": gold,
        "reputation": orders.reputation,
        "inventory": inventory.items,
        "known_recipes": recipes.known
    }
    var ok := save_manager.save_game(state)
    message_label.text = "💾 Игра сохранена." if ok else "Ошибка сохранения."

func _load_game() -> void:
    var state := save_manager.load_game()
    if state.is_empty():
        show_lab()
        return
    gold = int(state.get("gold", 100))
    orders.reputation = int(state.get("reputation", 0))
    inventory.items = state.get("inventory", inventory.items)
    recipes.known = state.get("known_recipes", {})
    show_lab()
