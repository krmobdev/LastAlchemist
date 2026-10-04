extends Control

const Inventory = preload("res://scripts/systems/inventory/inventory_system.gd")
const Recipes = preload("res://scripts/systems/recipes/recipe_book.gd")
const Orders = preload("res://scripts/systems/orders/order_system.gd")
const Save = preload("res://scripts/systems/save/save_manager.gd")
const Economy = preload("res://scripts/systems/economy/economy_system.gd")
const Upgrade = preload("res://scripts/systems/world/upgrade_system.gd")
const Shop = preload("res://scripts/systems/shop/shop_system.gd")
const World = preload("res://scripts/systems/world/world_system.gd")
const WorldEvents = preload("res://scripts/systems/world/event_system.gd")
const Dialogue = preload("res://scripts/systems/characters/dialogue_system.gd")
const Characters = preload("res://scripts/systems/characters/character_database.gd")
const Story = preload("res://scripts/systems/story/story_system.gd")
const Feedback = preload("res://scripts/systems/polish/feedback_system.gd")
const Audio = preload("res://scripts/systems/polish/audio_system.gd")

var inventory: InventorySystem
var recipes: RecipeBook
var orders: OrderSystem
var save_manager: SaveManager
var economy: EconomySystem
var upgrades: UpgradeSystem
var shop: ShopSystem
var world: WorldSystem
var world_events: WorldEventSystem
var dialogue: DialogueSystem
var characters: CharacterDatabase
var story: StorySystem
var feedback: FeedbackSystem
var audio: AudioSystem
var order_index := 0
var order_database: Array[Dictionary] = []
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
    "flower": {"name": "Звёздный цветок", "icon": "res://assets/items/flower.svg"},
    "lavender": {"name": "Лавандовый пучок", "icon": ""},
    "ember_root": {"name": "Корень угольника", "icon": ""},
    "frost_leaf": {"name": "Морозный лист", "icon": ""},
    "sun_dust": {"name": "Солнечная пыль", "icon": ""},
    "night_berry": {"name": "Ночная ягода", "icon": ""},
    "moonstone": {"name": "Лунный камень", "icon": ""},
    "thorn": {"name": "Колючая лоза", "icon": ""},
    "ash": {"name": "Серый пепел", "icon": ""}
}

func _ready() -> void:
    inventory = Inventory.new()
    recipes = Recipes.new()
    orders = Orders.new()
    save_manager = Save.new()
    economy = Economy.new()
    upgrades = Upgrade.new()
    shop = Shop.new()
    world = World.new()
    world_events = WorldEvents.new()
    dialogue = Dialogue.new()
    characters = Characters.new()
    story = Story.new()
    feedback = Feedback.new()
    audio = Audio.new()
    story.milestone_reached.connect(_on_milestone_reached)
    story.act_changed.connect(_on_act_changed)
    world.gathered.connect(_on_gathered)
    var order_file := FileAccess.open("res://data/orders/orders.json", FileAccess.READ)
    if order_file:
        var order_data = JSON.parse_string(order_file.get_as_text())
        if order_data is Dictionary:
            order_database.assign(order_data.get("orders", []))
    inventory.changed.connect(_refresh_inventory)
    recipes.discovered.connect(_on_recipe_discovered)
    orders.completed.connect(_on_order_completed)
    orders.order_changed.connect(_on_order_changed)
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
    b.pressed.connect(func(): feedback.click())
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
    box.modulate.a = 0.0
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(box, "modulate:a", 1.0, 0.18)
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
    gold = economy.gold
    gold_label = _make_label(top, "🪙  %d" % gold, 20)
    gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reputation_label = _make_label(top, "★  %d" % orders.reputation, 20)
    var people_btn := _make_button(top, "👥 NPC", 48)
    people_btn.pressed.connect(show_characters)
    var world_btn := _make_button(top, "🗺 Мир", 48)
    world_btn.pressed.connect(show_world)
    var shop_btn := _make_button(top, "🛒 Магазин", 48)
    shop_btn.pressed.connect(show_shop)
    var story_btn := _make_button(top, "📜 Сюжет", 48)
    story_btn.pressed.connect(show_story)
    var menu := _make_button(top, "Меню", 48)
    menu.pressed.connect(show_menu)

    var order_panel := PanelContainer.new()
    order_panel.add_theme_stylebox_override("panel", _panel_style(Color("382a29")))
    box.add_child(order_panel)
    var order_box := VBoxContainer.new()
    order_panel.add_child(order_box)
    _make_label(order_box, "📜 ЗАКАЗ", 19)
    _make_label(order_box, "Клиент: %s\nНужно: %s\nНаграда: %d золотых" % [_order_client_name(), _order_recipe_name(), int(orders.active.get("reward", 0))], 16)
    var deliver := _make_button(order_box, "Сдать зелье", 52)
    deliver.pressed.connect(_deliver_order)
    var next := _make_button(order_box, "Следующий заказ", 46)
    next.pressed.connect(func():
        orders.next_order()
        show_lab())

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
        if not str(data["icon"]).is_empty():
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
        feedback.failure()
        audio.play_brew_failure()
        message_label.text = "💨 Реакция нестабильна. Получилась неизвестная смесь."
    else:
        recipes.discover(recipe_id)
        story.check_progress(orders.reputation, world, recipes.known)
        last_potion = recipe_id
        feedback.success()
        audio.play_brew_success()
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


func _order_client_name() -> String:
    var id := str(orders.active.get("client", ""))
    var file := FileAccess.open("res://data/characters/characters.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data is Dictionary:
            for c in data.get("characters", []):
                if str(c.get("id", "")) == id:
                    return str(c.get("name", id))
    return id

func _order_recipe_name() -> String:
    var id := str(orders.active.get("recipe", ""))
    if recipes.recipes.has(id):
        return str(recipes.recipes[id].get("name", id))
    return id

func _on_order_changed(_order: Dictionary) -> void:
    last_potion = ""

func _on_recipe_discovered(_id: String) -> void:
    pass

func _on_order_completed(reward: int) -> void:
    economy.earn(reward)
    gold = economy.gold
    story.check_progress(orders.reputation, world, recipes.known)
    _refresh_header()

func _refresh_header() -> void:
    if is_instance_valid(gold_label):
        gold_label.text = "🪙  %d" % gold
    if is_instance_valid(reputation_label):
        reputation_label.text = "★  %d" % orders.reputation

func _refresh_inventory(_items: Dictionary) -> void:
    for id in inventory_labels:
        if is_instance_valid(inventory_labels[id]):
            inventory_labels[id].text = "%s\n%d" % [ITEMS.get(id, {"name": id})["name"], int(inventory.items.get(id, 0))]





func show_story() -> void:
    var box := _base("📜 ИСТОРИЯ")
    var act := story.get_current_act()
    _make_label(box, "Акт: %s" % str(act.get("name", "Искра")), 24)
    _make_label(box, str(act.get("goal", "")), 17)
    _make_label(box, "Пройденные этапы", 19)
    if story.reached.is_empty():
        _make_label(box, "Пока нет завершённых этапов.", 15)
    else:
        for id in story.reached:
            var data: Dictionary = story.milestones.get(id, {})
            _make_label(box, "✓ %s\n%s" % [str(data.get("title", id)), str(data.get("text", ""))], 15)
    var back := _make_button(box, "← В лабораторию", 60)
    back.pressed.connect(show_lab)

func _on_milestone_reached(id: String, data: Dictionary) -> void:
    if is_instance_valid(message_label):
        message_label.text = "📜 %s\n%s" % [str(data.get("title", id)), str(data.get("text", ""))]

func _on_act_changed(act: Dictionary) -> void:
    if is_instance_valid(message_label):
        message_label.text = "✨ Новый акт: %s\n%s" % [str(act.get("name", "")), str(act.get("goal", ""))]

func show_characters() -> void:
    var box := _base("👥 ЖИТЕЛИ СТАРОЙ ДОЛИНЫ")
    _make_label(box, "Познакомься с жителями. Их истории будут открываться по мере развития лаборатории.", 15)
    for id in characters.characters:
        var character: Dictionary = characters.characters[id]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        box.add_child(row)
        var portrait := TextureRect.new()
        portrait.texture = load("res://assets/characters/%s.svg" % id)
        portrait.custom_minimum_size = Vector2(72, 72)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(portrait)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        _make_label(info, str(character.get("name", id)), 19)
        _make_label(info, str(character.get("role", "")), 14)
        var talk := _make_button(info, "Поговорить", 44)
        talk.pressed.connect(func(): show_dialogue(id, 0))
    var back := _make_button(box, "← В лабораторию", 60)
    back.pressed.connect(show_lab)

func show_dialogue(character_id: String, line_index: int) -> void:
    var lines: Array = dialogue.get_lines(character_id)
    var character: Dictionary = characters.get_character(character_id)
    var box := _base(str(character.get("name", character_id)))
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/characters/%s.svg" % character_id)
    portrait.custom_minimum_size = Vector2(150, 150)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    box.add_child(portrait)
    if line_index < lines.size():
        var line: Dictionary = lines[line_index]
        _make_label(box, str(line.get("text", "")), 21)
        var next := _make_button(box, "Дальше →", 60)
        next.pressed.connect(func():
            if line_index + 1 < lines.size():
                show_dialogue(character_id, line_index + 1)
            else:
                show_characters())
    else:
        var close := _make_button(box, "Закрыть", 60)
        close.pressed.connect(show_characters)

func show_world() -> void:
    var box := _base("🗺 МИР — СТАРАЯ ДОЛИНА")
    _make_label(box, "Репутация: %d  •  Текущая локация: %s" % [orders.reputation, _world_location_name()], 17)
    for id in world.locations:
        var loc: Dictionary = world.locations[id]
        var unlocked := world.unlocked.has(id)
        var req := int(loc.get("unlock_reputation", 0))
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", _panel_style(Color("302824")))
        box.add_child(row)
        var inner := VBoxContainer.new()
        row.add_child(inner)
        _make_label(inner, ("✓ " if unlocked else "🔒 ") + str(loc.get("name", id)), 19)
        _make_label(inner, str(loc.get("description", "")), 14)
        var action := _make_button(inner, "Посетить" if unlocked else "Открыть • репутация %d" % req, 48)
        if unlocked:
            action.pressed.connect(func(): world.travel(id); show_world())
        else:
            action.disabled = not world.can_unlock(id, orders.reputation)
            action.pressed.connect(func():
                if world.unlock(id, orders.reputation):
                    show_world())
    var gather := _make_button(box, "🌿 Собрать ингредиент", 64)
    gather.pressed.connect(func():
        var result := world.gather()
        if result.is_empty():
            return
        inventory.add_item(str(result["item"]), int(result["amount"]))
        var event := world_events.event_for(world.current_location)
        if not event.is_empty():
            inventory.add_item(str(event.get("reward", "")), int(event.get("amount", 1)))
        show_world())
    var back := _make_button(box, "← В лабораторию", 60)
    back.pressed.connect(show_lab)

func _world_location_name() -> String:
    if world.locations.has(world.current_location):
        return str(world.locations[world.current_location].get("name", world.current_location))
    return world.current_location

func _on_gathered(_item_id: String, _amount: int) -> void:
    pass

func show_shop() -> void:
    var box := _base("🛒 МАГАЗИН И ЛАБОРАТОРИЯ")
    _make_label(box, "Ингредиенты", 21)
    for id in ["herb", "mushroom", "crystal", "flower", "lavender", "ember_root"]:
        var row := HBoxContainer.new()
        box.add_child(row)
        var label := _make_label(row, "%s  •  %d зол." % [ITEMS.get(id, {"name": id})["name"], shop.prices.get(id, 0)], 16)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var buy := _make_button(row, "Купить", 48)
        buy.pressed.connect(func():
            if shop.buy(id, economy, inventory):
                gold = economy.gold
                show_shop()
            else:
                message_label = _make_label(box, "Недостаточно золота или товара нет.", 14)
        )
    _make_label(box, "Улучшения", 21)
    for upgrade in shop.upgrades:
        if upgrades.owned.has(str(upgrade["id"])):
            continue
        var ub := _make_button(box, "🔧 %s — %d зол." % [upgrade["name"], upgrade["price"]], 58)
        ub.pressed.connect(func():
            if upgrades.purchase(upgrade, economy):
                gold = economy.gold
                show_shop()
        )
    var back := _make_button(box, "← В лабораторию", 60)
    back.pressed.connect(show_lab)

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
        "known_recipes": recipes.known,
        "world_unlocked": world.unlocked,
        "world_current_location": world.current_location,
        "upgrades_owned": upgrades.owned,
        "upgrade_capacity_bonus": upgrades.capacity_bonus,
        "upgrade_quality_bonus": upgrades.quality_bonus,
        "order_index": orders.order_index,
        "story_reached": story.reached,
        "story_current_act": story.current_act
    }
    var ok := save_manager.save_game(state)
    message_label.text = "💾 Игра сохранена." if ok else "Ошибка сохранения."

func _load_game() -> void:
    var state := save_manager.load_game()
    if state.is_empty():
        show_lab()
        return
    gold = int(state.get("gold", 100))
    economy.gold = gold
    orders.reputation = int(state.get("reputation", 0))
    inventory.items = state.get("inventory", inventory.items)
    recipes.known = state.get("known_recipes", {})
    world.unlocked = state.get("world_unlocked", {"village": true})
    world.current_location = str(state.get("world_current_location", "village"))
    upgrades.owned = state.get("upgrades_owned", {})
    upgrades.capacity_bonus = int(state.get("upgrade_capacity_bonus", 0))
    upgrades.quality_bonus = float(state.get("upgrade_quality_bonus", 0.0))
    orders.order_index = int(state.get("order_index", 0))
    if not orders.orders.is_empty():
        orders.active = orders.orders[orders.order_index % orders.orders.size()]
    story.reached = state.get("story_reached", {})
    story.current_act = int(state.get("story_current_act", 0))
    story.check_progress(orders.reputation, world, recipes.known)
    show_lab()
