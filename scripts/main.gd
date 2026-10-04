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
    "lavender": {"name": "Лавандовый пучок", "icon": "res://assets/items/lavender.svg"},
    "ember_root": {"name": "Корень угольника", "icon": "res://assets/items/ember_root.svg"},
    "frost_leaf": {"name": "Морозный лист", "icon": "res://assets/items/frost_leaf.svg"},
    "sun_dust": {"name": "Солнечная пыль", "icon": "res://assets/items/sun_dust.svg"},
    "night_berry": {"name": "Ночная ягода", "icon": "res://assets/items/night_berry.svg"},
    "moonstone": {"name": "Лунный камень", "icon": "res://assets/items/moonstone.svg"},
    "thorn": {"name": "Колючая лоза", "icon": "res://assets/items/thorn.svg"},
    "ash": {"name": "Серый пепел", "icon": "res://assets/items/ash.svg"}
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
    label.add_theme_color_override("font_color", Color("eadfc8"))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _button_style(bg: Color, border: Color, radius := 14, shadow := 8) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = border
    s.shadow_color = Color(0, 0, 0, 0.38)
    s.shadow_size = shadow
    s.content_margin_left = 14
    s.content_margin_right = 14
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s

func _make_button(parent: Control, text: String, min_height: int = 64) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, min_height)
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color("f2e8d2"))
    b.add_theme_color_override("font_hover_color", Color("fff4d1"))
    b.add_theme_color_override("font_pressed_color", Color("fff7df"))
    b.add_theme_stylebox_override("normal", _button_style(Color("261c20"), Color("6b4a3b")))
    b.add_theme_stylebox_override("hover", _button_style(Color("35242a"), Color("b17a45")))
    b.add_theme_stylebox_override("pressed", _button_style(Color("4a2b2d"), Color("d69a52"), 14, 4))
    b.add_theme_stylebox_override("disabled", _button_style(Color("1c171a"), Color("3a3030")))
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
    s.border_color = Color("6f503d")
    s.shadow_color = Color(0, 0, 0, 0.42)
    s.shadow_size = 10
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 16
    s.content_margin_bottom = 16
    return s

func _section_label(parent: Control, text: String) -> Label:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    parent.add_child(row)
    var mark := ColorRect.new()
    mark.color = Color("c98a48")
    mark.custom_minimum_size = Vector2(4, 24)
    row.add_child(mark)
    var label := _make_label(row, text.to_upper(), 15)
    label.add_theme_color_override("font_color", Color("d5a766"))
    return label

func _card(parent: Control, color := Color("20171b")) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(color))
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    return box

func _base(title: String) -> VBoxContainer:
    _clear()
    var bg := TextureRect.new()
    bg.texture = load("res://assets/ui/lab_backdrop.svg")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.04, 0.025, 0.04, 0.16)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 12)
    scroll.add_child(box)
    box.modulate.a = 0.0
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(box, "modulate:a", 1.0, 0.22)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 10)
    box.add_child(header)
    var title_label := _make_label(header, title, 26)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_color_override("font_color", Color("f0d39a"))
    var rune := _make_label(header, "✦", 22)
    rune.add_theme_color_override("font_color", Color("c98a48"))
    return box

func _make_bottom_nav(parent: Control) -> void:
    var nav_panel := PanelContainer.new()
    nav_panel.add_theme_stylebox_override("panel", _panel_style(Color("171217"), 16))
    parent.add_child(nav_panel)
    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 6)
    nav_panel.add_child(nav)
    var lab := _make_button(nav, "⚗
Лаб", 58)
    var world_btn := _make_button(nav, "✦
Мир", 58)
    var shop_btn := _make_button(nav, "◈
Торговля", 58)
    var npc_btn := _make_button(nav, "♙
Люди", 58)
    var story_btn := _make_button(nav, "☾
Сюжет", 58)
    for b in [lab, world_btn, shop_btn, npc_btn, story_btn]:
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 12)
    lab.pressed.connect(show_lab)
    world_btn.pressed.connect(show_world)
    shop_btn.pressed.connect(show_shop)
    npc_btn.pressed.connect(show_characters)
    story_btn.pressed.connect(show_story)

func show_menu() -> void:
    var box := _base("ПОСЛЕДНИЙ АЛХИМИК")
    _make_label(box, "Последний алхимик", 20)
    _make_label(box, "Последняя лаборатория на краю Старой Долины.", 16)
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
    gold = economy.gold
    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 8)
    box.add_child(stats)
    var gold_card := _card(stats, Color("21191a"))
    gold_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var g := _make_label(gold_card, "ЗОЛОТО", 11)
    g.add_theme_color_override("font_color", Color("9d8061"))
    gold_label = _make_label(gold_card, "◈ %d" % gold, 21)
    gold_label.add_theme_color_override("font_color", Color("e3b85f"))
    var rep_card := _card(stats, Color("21191a"))
    rep_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var r := _make_label(rep_card, "РЕПУТАЦИЯ", 11)
    r.add_theme_color_override("font_color", Color("9d8061"))
    reputation_label = _make_label(rep_card, "✦ %d" % orders.reputation, 21)
    reputation_label.add_theme_color_override("font_color", Color("cfa56c"))

    var hero := PanelContainer.new()
    hero.add_theme_stylebox_override("panel", _panel_style(Color("21181b"), 22))
    box.add_child(hero)
    var hero_row := HBoxContainer.new()
    hero_row.add_theme_constant_override("separation", 12)
    hero.add_child(hero_row)
    var cauldron := TextureRect.new()
    cauldron.texture = load("res://assets/ui/cauldron_hero.svg")
    cauldron.custom_minimum_size = Vector2(138, 132)
    cauldron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cauldron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero_row.add_child(cauldron)
    var hero_text := VBoxContainer.new()
    hero_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero_row.add_child(hero_text)
    var h1 := _make_label(hero_text, "Твоя последняя надежда", 19)
    h1.add_theme_color_override("font_color", Color("f1d39c"))
    _make_label(hero_text, "Старый котёл ещё помнит великих алхимиков. Осталось заставить его работать.", 13)
    var heat := _make_label(hero_text, "●  КОТЁЛ ГОТОВ", 12)
    heat.add_theme_color_override("font_color", Color("d88a4b"))

    _section_label(box, "Текущий заказ")
    var order_box := _card(box, Color("2a1b1e"))
    var order_head := HBoxContainer.new()
    order_box.add_child(order_head)
    var client_id := str(orders.active.get("client", ""))
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/characters/%s.svg" % client_id)
    portrait.custom_minimum_size = Vector2(62, 62)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    order_head.add_child(portrait)
    var order_info := VBoxContainer.new()
    order_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    order_head.add_child(order_info)
    var client_label := _make_label(order_info, _order_client_name(), 18)
    client_label.add_theme_color_override("font_color", Color("f0d29a"))
    _make_label(order_info, "Заказано: %s" % _order_recipe_name(), 14)
    _make_label(order_info, "Награда: ◈ %d" % int(orders.active.get("reward", 0)), 13)
    var deliver := _make_button(order_box, "СДАТЬ ЗЕЛЬЕ", 52)
    deliver.pressed.connect(_deliver_order)
    var next := _make_button(order_box, "Другой заказ", 42)
    next.pressed.connect(func():
        orders.next_order()
        show_lab())

    _section_label(box, "Ингредиенты — выбери два")
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 9)
    grid.add_theme_constant_override("v_separation", 9)
    box.add_child(grid)
    for id in ITEMS:
        var data: Dictionary = ITEMS[id]
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 86)
        b.text = "%s
× %d" % [data["name"], int(inventory.items.get(id, 0))]
        b.icon = load(data["icon"])
        b.expand_icon = true
        b.icon_max_width = 42
        b.add_theme_font_size_override("font_size", 13)
        b.add_theme_color_override("font_color", Color("e8dbc3"))
        b.add_theme_stylebox_override("normal", _button_style(Color("1c171b"), Color("4d3934"), 14, 5))
        b.add_theme_stylebox_override("hover", _button_style(Color("2d2025"), Color("a56d42"), 14, 7))
        b.add_theme_stylebox_override("pressed", _button_style(Color("4a282a"), Color("d28a4a"), 14, 3))
        b.pressed.connect(func(): _select_reagent(id))
        grid.add_child(b)
        inventory_labels[id] = b

    var brew := _make_button(box, "⚗  ВАРИТЬ ЗЕЛЬЕ", 68)
    brew.add_theme_font_size_override("font_size", 20)
    brew.add_theme_stylebox_override("normal", _button_style(Color("6b3828"), Color("d18b49"), 16, 10))
    brew.add_theme_stylebox_override("hover", _button_style(Color("87462c"), Color("efb15d"), 16, 12))
    brew.pressed.connect(_brew)
    message_label = _make_label(box, "Выбрано: —
Подсказка: попробуй лунную траву + звёздный цветок.", 14)
    message_label.add_theme_color_override("font_color", Color("c9b79d"))
    _make_bottom_nav(box)

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
        var text: String = ("✓  " + str(r["name"])) if known else "?  Неизвестный рецепт"
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
