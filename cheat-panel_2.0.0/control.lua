-- control.lua  —  Cheat Panel v2 (полный, с прокруткой)
local mod_gui = require("__core__.lualib.mod-gui")

------------------------------------------------------------
-- КНОПКА В ВЕРХНЕЙ ПАНЕЛИ
------------------------------------------------------------
local function create_button(player)
  local flow = mod_gui.get_button_flow(player)
  if not flow.cheat_panel_button then
    flow.add{
      type = "sprite-button",
      name = "cheat_panel_button",
      sprite = "utility/warning_icon",
      tooltip = "Cheat Panel [Ctrl+F9]",
      style = mod_gui.button_style
    }
  end
end

------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
------------------------------------------------------------

-- Добавляет заголовок секции
local function add_section_header(parent, caption)
  local label = parent.add{type = "label", caption = caption}
  label.style.font = "heading-2"
  label.style.top_margin = 6
  label.style.bottom_margin = 4
end

-- Добавляет кнопку-чит
local function add_cheat_button(parent, name, caption, tooltip, style)
  local btn = parent.add{
    type = "button",
    name = name,
    caption = caption,
    tooltip = tooltip or "",
    style = style or "rounded_button"
  }
  btn.style.horizontally_stretchable = true
  return btn
end

-- Добавляет слайдер-строку (label + textfield + apply + reset)
local function add_modifier_row(parent, label_text, field_name, default_val, tags)
  local flow = parent.add{type = "flow", direction = "horizontal"}
  flow.style.vertical_align = "center"
  flow.style.top_margin = 2

  local lbl = flow.add{type = "label", caption = label_text}
  lbl.style.minimal_width = 200

  flow.add{
    type = "textfield",
    name = field_name,
    text = tostring(default_val),
    numeric = true,
    allow_decimal = true
  }.style.width = 90

  flow.add{
    type = "button",
    name = "apply_" .. field_name,
    caption = "✔",
    tooltip = "Применить",
    tags = tags
  }.style.width = 36

  flow.add{
    type = "button",
    name = "reset_" .. field_name,
    caption = "↺",
    tooltip = "Сброс к 0",
    tags = {modifier_key = tags.modifier_key, target = tags.target, reset = true}
  }.style.width = 36
end

------------------------------------------------------------
-- СОЗДАНИЕ ГЛАВНОГО ОКНА
------------------------------------------------------------
local function create_main_window(player)
  if player.gui.screen.cheat_panel_frame then
    player.gui.screen.cheat_panel_frame.destroy()
    return
  end

  -- Главный фрейм
  local frame = player.gui.screen.add{
    type = "frame",
    name = "cheat_panel_frame",
    direction = "vertical"
  }
  frame.auto_center = true
  frame.style.maximal_height = 750
  frame.style.minimal_width = 520

  -- Заголовок с кнопкой закрытия
  local titlebar = frame.add{type = "flow", direction = "horizontal"}
  titlebar.style.horizontal_spacing = 8
  titlebar.style.bottom_margin = 4
  titlebar.add{type = "label", caption = "🛠  Cheat Panel", style = "frame_title"}
  local filler = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  filler.drag_target = frame
  titlebar.add{
    type = "sprite-button",
    name = "cheat_close_panel",
    sprite = "utility/close",
    style = "close_button"
  }

  -- СКРОЛЛИРУЕМАЯ ПАНЕЛЬ — решает проблему обрезки!
  local scroll = frame.add{
    type = "scroll-pane",
    name = "cheat_scroll",
    direction = "vertical",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space"
  }
  scroll.style.maximal_height = 680
  scroll.style.minimal_width = 490

  local content = scroll

  -- ==========================================================
  -- 📦 РАЗДЕЛ 1: ВЫДАЧА ПРЕДМЕТОВ (любой предмет)
  -- ==========================================================
  add_section_header(content, "📦 Выдача предметов")

  local item_frame = content.add{
    type = "frame",
    name = "item_frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  -- Строка: выбор предмета + количество + кнопка
  local row1 = item_frame.add{type = "flow", direction = "horizontal"}
  row1.style.vertical_align = "center"

  row1.add{type = "label", caption = "Предмет:"}
  row1.add{
    type = "choose-elem-button",
    name = "cheat_item_picker",
    elem_type = "item",
    tooltip = "Кликните и выберите ЛЮБОЙ предмет"
  }

  row1.add{type = "label", caption = "  Кол-во:"}
  local amt = row1.add{
    type = "textfield",
    name = "cheat_item_amount",
    text = "1000",
    numeric = true,
    allow_decimal = false,
    allow_negative = false
  }
  amt.style.width = 100

  row1.add{
    type = "button",
    name = "cheat_give_item",
    caption = "Выдать",
    style = "confirm_button"
  }

  -- Быстрые кнопки
  local quick_label = item_frame.add{type = "label", caption = "Быстрая выдача (клик = в инвентарь):"}
  quick_label.style.top_margin = 6

  local quick_table = item_frame.add{
    type = "table",
    name = "quick_table",
    column_count = 10
  }

  local quick_items = {
    {"iron-plate", 1000}, {"copper-plate", 1000}, {"steel-plate", 500},
    {"electronic-circuit", 500}, {"advanced-circuit", 200}, {"processing-unit", 100},
    {"iron-gear-wheel", 500}, {"coal", 1000}, {"stone", 1000}, {"wood", 500},
    {"plastic-bar", 500}, {"sulfur", 200}, {"battery", 200}, {"explosives", 200},
    {"rocket-fuel", 100}, {"nuclear-fuel", 50}, {"uranium-235", 50}, {"uranium-238", 100},
    {"solar-panel", 100}, {"accumulator", 100}, {"construction-robot", 50}, {"logistic-robot", 50},
    {"roboport", 10}, {"rail", 500}, {"locomotive", 5}, {"cargo-wagon", 5},
    {"red-wire", 200}, {"green-wire", 200}, {"small-lamp", 100}, {"rocket-part", 10},
    {"power-armor-mk2", 1}, {"fusion-reactor-equipment", 2},
    {"exoskeleton-equipment", 4}, {"personal-roboport-mk2-equipment", 4},
    {"energy-shield-mk2-equipment", 4}, {"battery-mk2-equipment", 4},
    {"stone-wall", 500}, {"gun-turret", 50}, {"laser-turret", 50}, {"radar", 20},
  }

  for _, item_data in pairs(quick_items) do
    local ok = pcall(function()
      quick_table.add{
        type = "sprite-button",
        name = "cheat_quick_" .. item_data[1],
        sprite = "item/" .. item_data[1],
        tooltip = item_data[1] .. " x" .. item_data[2],
        number = item_data[2],
        style = "slot_button",
        tags = {item_name = item_data[1], item_count = item_data[2]}
      }
    end)
    -- если предмет не существует в текущей версии — просто пропускаем
  end

  -- Бочки с жидкостями
  local barrel_label = item_frame.add{type = "label", caption = "Бочки с жидкостями:"}
  barrel_label.style.top_margin = 6

  local barrel_table = item_frame.add{
    type = "table",
    name = "barrel_table",
    column_count = 10
  }

  local barrels = {
    {"crude-oil-barrel", 100}, {"petroleum-gas-barrel", 100},
    {"light-oil-barrel", 100}, {"heavy-oil-barrel", 100},
    {"lubricant-barrel", 100}, {"sulfuric-acid-barrel", 100},
    {"water-barrel", 100},
  }

  for _, item_data in pairs(barrels) do
    pcall(function()
      barrel_table.add{
        type = "sprite-button",
        name = "cheat_quick_" .. item_data[1],
        sprite = "item/" .. item_data[1],
        tooltip = item_data[1] .. " x" .. item_data[2],
        number = item_data[2],
        style = "slot_button",
        tags = {item_name = item_data[1], item_count = item_data[2]}
      }
    end)
  end

  -- ==========================================================
  -- ⚡ РАЗДЕЛ 2: ОСНОВНЫЕ ЧИТЫ
  -- ==========================================================
  add_section_header(content, "⚡ Основные читы")

  local cheat_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_cheat_button(cheat_frame, "cheat_mode_toggle",
    "🎮 Cheat Mode (бесплатный крафт)",
    "game.player.cheat_mode — бесплатный и мгновенный крафт всего")

  add_cheat_button(cheat_frame, "cheat_god_mode",
    "👼 God Mode (бессмертие + полёт)",
    "Убирает персонажа — вы летаете и неуязвимы")

  add_cheat_button(cheat_frame, "cheat_undo_god_mode",
    "🧍 Вернуть персонажа (отменить God Mode)",
    "Создаёт нового персонажа на спавне")

  add_cheat_button(cheat_frame, "cheat_research_all",
    "🔬 Исследовать ВСЕ технологии",
    "force.research_all_technologies()")

  add_cheat_button(cheat_frame, "cheat_unresearch_all",
    "🔬 Сбросить ВСЕ технологии",
    "force.reset_technologies() — сбрасывает технологии, бонусы, статистику")

  add_cheat_button(cheat_frame, "cheat_enable_all_recipes",
    "📋 Включить все рецепты",
    "Принудительно включает все рецепты крафта")

  add_cheat_button(cheat_frame, "cheat_finish_research",
    "⏩ Завершить текущее исследование",
    "Мгновенно завершает текущий ресёрч")

  -- ==========================================================
  -- 🗺 РАЗДЕЛ 3: КАРТА И МИР
  -- ==========================================================
  add_section_header(content, "🗺 Карта и мир")

  local map_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_cheat_button(map_frame, "cheat_chart_all",
    "🗺 Открыть всю карту",
    "force.chart_all(surface)")

  add_cheat_button(map_frame, "cheat_unhart_all",
    "🗺 Скрыть карту (unchart)",
    "force.unchart_chunk — скрывает всю карту")

  add_cheat_button(map_frame, "cheat_always_day",
    "☀️ Всегда день (вкл/выкл)",
    "surface.always_day = true/false")

  add_cheat_button(map_frame, "cheat_freeze_time",
    "⏸ Заморозить время суток (вкл/выкл)",
    "surface.freeze_daytime = true/false")

  add_cheat_button(map_frame, "cheat_remove_cliffs",
    "🪨 Удалить все скалы",
    "Удаляет все cliff на текущей поверхности")

  add_cheat_button(map_frame, "cheat_remove_decoratives",
    "🌿 Удалить декорации",
    "surface.destroy_decoratives — удаляет траву, камешки и т.д.")

  -- Телепортация
  local tp_flow = map_frame.add{type = "flow", direction = "horizontal"}
  tp_flow.style.vertical_align = "center"
  tp_flow.style.top_margin = 4

  tp_flow.add{type = "label", caption = "Телепорт X:"}
  tp_flow.add{type = "textfield", name = "cheat_tp_x", text = "0", numeric = true, allow_decimal = true, allow_negative = true}.style.width = 80
  tp_flow.add{type = "label", caption = " Y:"}
  tp_flow.add{type = "textfield", name = "cheat_tp_y", text = "0", numeric = true, allow_decimal = true, allow_negative = true}.style.width = 80
  tp_flow.add{type = "button", name = "cheat_teleport", caption = "Телепорт", style = "confirm_button"}

  add_cheat_button(map_frame, "cheat_tp_spawn",
    "🏠 Телепорт на спавн (0, 0)", "Телепорт к началу карты")

  -- Скорость игры
  local speed_flow = map_frame.add{type = "flow", direction = "horizontal"}
  speed_flow.style.vertical_align = "center"
  speed_flow.style.top_margin = 4

  speed_flow.add{type = "label", caption = "Скорость игры:"}
  speed_flow.add{
    type = "textfield",
    name = "cheat_game_speed_val",
    text = "1",
    numeric = true,
    allow_decimal = true
  }.style.width = 80
  speed_flow.add{
    type = "button",
    name = "cheat_set_game_speed",
    caption = "Установить",
    tooltip = "game.speed (1=норма, 2=x2, 0.5=x0.5)"
  }

  -- ==========================================================
  -- 🐛 РАЗДЕЛ 4: ВРАГИ / БИТТЕРЫ
  -- ==========================================================
  add_section_header(content, "🐛 Враги")

  local enemy_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_cheat_button(enemy_frame, "cheat_kill_all_enemies",
    "💀 Убить ВСЕХ врагов на поверхности",
    "Удаляет все entity с force=enemy")

  add_cheat_button(enemy_frame, "cheat_kill_nearby_enemies",
    "💀 Убить врагов рядом (радиус 250)",
    "Удаляет врагов в радиусе 250 тайлов")

  add_cheat_button(enemy_frame, "cheat_kill_units_only",
    "🐜 Убить только юнитов (не базы)",
    "game.forces['enemy'].kill_all_units()")

  add_cheat_button(enemy_frame, "cheat_toggle_peaceful",
    "☮️ Мирный режим (вкл/выкл)",
    "surface.peaceful_mode = true/false")

  add_cheat_button(enemy_frame, "cheat_toggle_expansion",
    "🚫 Расширение биттеров (вкл/выкл)",
    "map_settings.enemy_expansion.enabled")

  -- Эволюция
  local evo_flow = enemy_frame.add{type = "flow", direction = "horizontal"}
  evo_flow.style.vertical_align = "center"
  evo_flow.style.top_margin = 4
  evo_flow.add{type = "label", caption = "Фактор эволюции (0–1):"}
  evo_flow.add{
    type = "textfield",
    name = "cheat_evo_val",
    text = "0",
    numeric = true,
    allow_decimal = true
  }.style.width = 80
  evo_flow.add{type = "button", name = "cheat_set_evolution", caption = "Установить"}

  -- ==========================================================
  -- 🌍 РАЗДЕЛ 5: ЗАГРЯЗНЕНИЕ
  -- ==========================================================
  add_section_header(content, "🌍 Загрязнение")

  local poll_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_cheat_button(poll_frame, "cheat_clear_pollution",
    "🧹 Убрать всё загрязнение",
    "surface.clear_pollution()")

  add_cheat_button(poll_frame, "cheat_disable_pollution",
    "❌ Полностью отключить загрязнение",
    "Очищает загрязнение на ВСЕХ поверхностях и отключает его")

  add_cheat_button(poll_frame, "cheat_enable_pollution",
    "✅ Включить загрязнение обратно",
    "map_settings.pollution.enabled = true")

  -- ==========================================================
  -- 🧰 РАЗДЕЛ 6: ИНВЕНТАРЬ
  -- ==========================================================
  add_section_header(content, "🧰 Инвентарь")

  local inv_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_cheat_button(inv_frame, "cheat_fill_inventory",
    "📥 Заполнить инвентарь (по 100 всего)",
    "Добавляет по 100 штук каждого предмета")

  add_cheat_button(inv_frame, "cheat_clear_inventory",
    "🗑 Очистить инвентарь",
    "Полностью очищает основной инвентарь")

  add_cheat_button(inv_frame, "cheat_pickup_items",
    "🧲 Подобрать предметы с земли (радиус 50)",
    "Собирает все items-on-ground в радиусе 50")

  -- ==========================================================
  -- 🔧 РАЗДЕЛ 7: МОДИФИКАТОРЫ СИЛЫ
  -- ==========================================================
  add_section_header(content, "🔧 Модификаторы (Force)")

  local mod_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  add_modifier_row(mod_frame, "⛏ Скорость добычи", "mod_mining", 1000,
    {modifier_key = "manual_mining_speed_modifier", target = "force"})
  add_modifier_row(mod_frame, "🔨 Скорость крафта", "mod_craft", 1000,
    {modifier_key = "manual_crafting_speed_modifier", target = "force"})
  add_modifier_row(mod_frame, "🔬 Скорость лабораторий", "mod_lab", 100,
    {modifier_key = "laboratory_speed_modifier", target = "force"})
  add_modifier_row(mod_frame, "🏃 Скорость бега", "mod_run", 5,
    {modifier_key = "character_running_speed_modifier", target = "force"})
  add_modifier_row(mod_frame, "📏 Дальность постройки", "mod_build_reach", 1000,
    {modifier_key = "character_build_distance_bonus", target = "force"})
  add_modifier_row(mod_frame, "🤚 Дальность взаимодействия", "mod_reach", 1000,
    {modifier_key = "character_reach_distance_bonus", target = "force"})
  add_modifier_row(mod_frame, "💎 Дальность ресурсов", "mod_res_reach", 1000,
    {modifier_key = "character_resource_reach_distance_bonus", target = "force"})
  add_modifier_row(mod_frame, "📦 Доп. слоты инвентаря", "mod_inv", 200,
    {modifier_key = "character_inventory_slots_bonus", target = "force"})
  add_modifier_row(mod_frame, "🤖 Бонус робот. слотов", "mod_trash", 100,
    {modifier_key = "character_trash_slot_count_bonus", target = "force"})
  add_modifier_row(mod_frame, "📡 Дальность сброса предметов", "mod_drop", 1000,
    {modifier_key = "character_item_drop_distance_bonus", target = "force"})

  -- ==========================================================
  -- 🌐 РАЗДЕЛ 8: РЕСУРСЫ НА КАРТЕ
  -- ==========================================================
  add_section_header(content, "🌐 Спавн ресурсов на карте")

  local spawn_frame = content.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  local spawn_desc = spawn_frame.add{type = "label",
    caption = "Создаёт патч 11×11 ресурсов под игроком:"}
  spawn_desc.style.single_line = false

  local spawn_flow = spawn_frame.add{type = "flow", direction = "horizontal"}
  spawn_flow.style.vertical_align = "center"
  spawn_flow.style.top_margin = 4

  spawn_flow.add{type = "label", caption = "Ресурс:"}
  spawn_flow.add{
    type = "choose-elem-button",
    name = "cheat_ore_picker",
    elem_type = "entity",
    elem_filters = {{filter = "type", type = "resource"}},
    tooltip = "Выберите тип ресурса (iron-ore, copper-ore, и т.д.)"
  }

  spawn_flow.add{type = "label", caption = " Кол-во:"}
  spawn_flow.add{
    type = "textfield",
    name = "cheat_ore_amount",
    text = "3000",
    numeric = true
  }.style.width = 80

  spawn_flow.add{
    type = "button",
    name = "cheat_spawn_ore",
    caption = "Создать патч",
    style = "confirm_button"
  }

  add_cheat_button(spawn_frame, "cheat_refill_resource",
    "♻️ Пополнить ресурс под курсором до 10000",
    "Наведите курсор на ресурс и нажмите")

end

------------------------------------------------------------
-- ОБРАБОТКА КЛИКОВ
------------------------------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  local el = event.element
  local name = el.name

  -- Открыть панель
  if name == "cheat_panel_button" then
    create_main_window(player)
    return
  end

  -- Закрыть панель
  if name == "cheat_close_panel" then
    if player.gui.screen.cheat_panel_frame then
      player.gui.screen.cheat_panel_frame.destroy()
    end
    return
  end

  local root = player.gui.screen.cheat_panel_frame
  if not root then return end
  local scroll = root.cheat_scroll

  -- ========== ВЫДАЧА ПРЕДМЕТОВ ==========

  if name == "cheat_give_item" then
    local picker = scroll.item_frame.children[1].cheat_item_picker
    local amount_tf = scroll.item_frame.children[1].cheat_item_amount
    if picker.elem_value then
      local count = tonumber(amount_tf.text) or 1000
      local inserted = player.insert{name = picker.elem_value, count = count}
      player.print("Выдано: " .. picker.elem_value .. " x" .. inserted)
    else
      player.print("[color=red]Сначала выберите предмет![/color]")
    end
    return
  end

  -- Быстрые кнопки (определяем по тегам)
  if el.tags and el.tags.item_name then
    local inserted = player.insert{name = el.tags.item_name, count = el.tags.item_count}
    player.print("Выдано: " .. el.tags.item_name .. " x" .. inserted)
    return
  end

  -- ========== ОСНОВНЫЕ ЧИТЫ ==========

  if name == "cheat_mode_toggle" then
    player.cheat_mode = not player.cheat_mode
    player.print("Cheat Mode: " .. (player.cheat_mode and "ВКЛ ✅" or "ВЫКЛ ❌"))
    return
  end

  if name == "cheat_god_mode" then
    if player.character then
      player.character.destroy()
      player.print("God Mode: ВКЛ ✅ — вы бессмертны и летаете")
    else
      player.print("[color=yellow]Вы уже в God Mode[/color]")
    end
    return
  end

  if name == "cheat_undo_god_mode" then
    if not player.character then
      player.create_character()
      player.print("Персонаж создан. God Mode ВЫКЛ ❌")
    else
      player.print("[color=yellow]У вас уже есть персонаж[/color]")
    end
    return
  end

  if name == "cheat_research_all" then
    player.force.research_all_technologies()
    player.print("Все технологии исследованы! 🔬")
    return
  end

  if name == "cheat_unresearch_all" then
    player.force.reset()
    player.print("Все технологии и данные force сброшены!")
    return
  end

  if name == "cheat_enable_all_recipes" then
    for _, recipe in pairs(player.force.recipes) do
      recipe.enabled = true
    end
    player.print("Все рецепты включены! 📋")
    return
  end

  if name == "cheat_finish_research" then
    local tech = player.force.current_research
    if tech then
      player.force.research_progress = 1
      player.print("Исследование \"" .. tech.name .. "\" завершено! ⏩")
    else
      player.print("[color=yellow]Нет активного исследования[/color]")
    end
    return
  end

  -- ========== КАРТА И МИР ==========

  if name == "cheat_chart_all" then
    player.force.chart_all(player.surface)
    player.print("Карта полностью открыта! 🗺")
    return
  end

  if name == "cheat_unhart_all" then
    player.force.clear_chart(player.surface)
    player.print("Карта скрыта!")
    return
  end

  if name == "cheat_always_day" then
    player.surface.always_day = not player.surface.always_day
    player.print("Всегда день: " .. (player.surface.always_day and "ВКЛ ☀️" or "ВЫКЛ 🌙"))
    return
  end

  if name == "cheat_freeze_time" then
    player.surface.freeze_daytime = not player.surface.freeze_daytime
    player.print("Заморозка времени: " .. (player.surface.freeze_daytime and "ВКЛ ⏸" or "ВЫКЛ ▶"))
    return
  end

  if name == "cheat_remove_cliffs" then
    local count = 0
    for _, cliff in pairs(player.surface.find_entities_filtered{type = "cliff"}) do
      cliff.destroy()
      count = count + 1
    end
    player.print("Удалено скал: " .. count .. " 🪨")
    return
  end

  if name == "cheat_remove_decoratives" then
    player.surface.destroy_decoratives{}
    player.print("Все декорации удалены! 🌿")
    return
  end

  if name == "cheat_teleport" then
    local x = tonumber(scroll.children[4].children[2].text) or 0 -- может не работать так
    local y = tonumber(scroll.children[4].children[4].text) or 0
    -- Более надёжный поиск через имена элементов:
    local function find_in(parent, target_name)
      for _, child in pairs(parent.children) do
        if child.name == target_name then return child end
        if child.children then
          local found = find_in(child, target_name)
          if found then return found end
        end
      end
    end
    local xf = find_in(scroll, "cheat_tp_x")
    local yf = find_in(scroll, "cheat_tp_y")
    x = tonumber(xf and xf.text or "0") or 0
    y = tonumber(yf and yf.text or "0") or 0
    player.teleport({x, y})
    player.print("Телепорт → [" .. x .. ", " .. y .. "]")
    return
  end

  if name == "cheat_tp_spawn" then
    player.teleport({0, 0})
    player.print("Телепорт на спавн [0, 0] 🏠")
    return
  end

  if name == "cheat_set_game_speed" then
    local function find_in(parent, target_name)
      for _, child in pairs(parent.children) do
        if child.name == target_name then return child end
        if child.children then
          local found = find_in(child, target_name)
          if found then return found end
        end
      end
    end
    local sf = find_in(scroll, "cheat_game_speed_val")
    local speed = tonumber(sf and sf.text or "1") or 1
    if speed < 0.01 then speed = 0.01 end
    game.speed = speed
    player.print("Скорость игры: x" .. speed .. " ⏱")
    return
  end

  -- ========== ВРАГИ ==========

  if name == "cheat_kill_all_enemies" then
    local enemies = player.surface.find_entities_filtered{force = "enemy"}
    for _, e in pairs(enemies) do if e.valid then e.destroy() end end
    player.print("Уничтожено врагов: " .. #enemies .. " 💀")
    return
  end

  if name == "cheat_kill_nearby_enemies" then
    local enemies = player.surface.find_entities_filtered{
      force = "enemy", position = player.position, radius = 250
    }
    for _, e in pairs(enemies) do if e.valid then e.destroy() end end
    player.print("Уничтожено врагов рядом: " .. #enemies .. " 💀")
    return
  end

  if name == "cheat_kill_units_only" then
    game.forces["enemy"].kill_all_units()
    player.print("Все вражеские юниты убиты! 🐜")
    return
  end

  if name == "cheat_toggle_peaceful" then
    player.surface.peaceful_mode = not player.surface.peaceful_mode
    player.print("Мирный режим: " .. (player.surface.peaceful_mode and "ВКЛ ☮️" or "ВЫКЛ ⚔️"))
    return
  end

  if name == "cheat_toggle_expansion" then
    local e = game.map_settings.enemy_expansion
    e.enabled = not e.enabled
    player.print("Расширение биттеров: " .. (e.enabled and "ВКЛ" or "ВЫКЛ 🚫"))
    return
  end

  if name == "cheat_set_evolution" then
    local function find_in(parent, target_name)
      for _, child in pairs(parent.children) do
        if child.name == target_name then return child end
        if child.children then
          local found = find_in(child, target_name)
          if found then return found end
        end
      end
    end
    local ef = find_in(scroll, "cheat_evo_val")
    local val = tonumber(ef and ef.text or "0") or 0
    if val < 0 then val = 0 end
    if val > 1 then val = 1 end
    game.forces["enemy"].evolution_factor = val
    player.print("Фактор эволюции: " .. val)
    return
  end

  -- ========== ЗАГРЯЗНЕНИЕ ==========

  if name == "cheat_clear_pollution" then
    player.surface.clear_pollution()
    player.print("Загрязнение очищено! 🧹")
    return
  end

  if name == "cheat_disable_pollution" then
    for _, surface in pairs(game.surfaces) do
      surface.clear_pollution()
    end
    game.map_settings.pollution.enabled = false
    player.print("Загрязнение ПОЛНОСТЬЮ отключено! ❌")
    return
  end

  if name == "cheat_enable_pollution" then
    game.map_settings.pollution.enabled = true
    player.print("Загрязнение включено! ✅")
    return
  end

  -- ========== ИНВЕНТАРЬ ==========

  if name == "cheat_fill_inventory" then
    local count = 0
    for item_name, _ in pairs(prototypes.item) do
      local ok = pcall(function()
        player.insert{name = item_name, count = 100}
      end)
      if ok then count = count + 1 end
    end
    player.print("Добавлено предметов: " .. count .. " видов по 100 шт 📥")
    return
  end

  if name == "cheat_clear_inventory" then
    local inv = player.get_main_inventory()
    if inv then inv.clear() end
    player.print("Инвентарь очищен! 🗑")
    return
  end

  if name == "cheat_pickup_items" then
    local items = player.surface.find_entities_filtered{
      type = "item-entity",
      position = player.position,
      radius = 50
    }
    for _, item in pairs(items) do
      if item.valid and item.stack then
        player.insert(item.stack)
        item.destroy()
      end
    end
    player.print("Подобрано предметов с земли: " .. #items .. " 🧲")
    return
  end

  -- ========== МОДИФИКАТОРЫ ==========

  if el.tags and el.tags.modifier_key then
    local tags = el.tags

    if tags.reset then
      if tags.target == "force" then
        player.force[tags.modifier_key] = 0
      end
      player.print(tags.modifier_key .. " → 0 (сброс)")
      return
    end

    -- Apply — найти поле рядом
    local function find_in(parent, target_name)
      for _, child in pairs(parent.children) do
        if child.name == target_name then return child end
        if child.children then
          local found = find_in(child, target_name)
          if found then return found end
        end
      end
    end

    -- Имя поля из имени кнопки
    local field_name = string.gsub(el.name, "^apply_", "")
    local field = find_in(scroll, field_name)
    if field then
      local val = tonumber(field.text) or 0
      if tags.target == "force" then
        player.force[tags.modifier_key] = val
      end
      player.print(tags.modifier_key .. " → " .. val .. " ✔")
    end
    return
  end

  -- ========== РЕСУРСЫ НА КАРТЕ ==========

  if name == "cheat_spawn_ore" then
    local function find_in(parent, target_name)
      for _, child in pairs(parent.children) do
        if child.name == target_name then return child end
        if child.children then
          local found = find_in(child, target_name)
          if found then return found end
        end
      end
    end
    local picker = find_in(scroll, "cheat_ore_picker")
    local amount_field = find_in(scroll, "cheat_ore_amount")
    if not picker or not picker.elem_value then
      player.print("[color=red]Выберите тип ресурса![/color]")
      return
    end
    local ore_name = picker.elem_value
    local amount = tonumber(amount_field.text) or 3000
    local pos = player.position
    local surface = player.surface
    local size = 5
    for dx = -size, size do
      for dy = -size, size do
        local p = {x = math.floor(pos.x) + dx, y = math.floor(pos.y) + dy}
        local tile = surface.get_tile(p.x, p.y)
        if tile and tile.valid and not tile.collides_with("water-tile") then
          local dist = math.max(math.abs(dx), math.abs(dy))
          local a = math.floor(amount * (1 - dist / (size + 2)) * (0.75 + math.random() * 0.5))
          if a > 0 then
            local existing = surface.find_entities_filtered{position = p, type = "resource"}
            for _, e in pairs(existing) do e.destroy() end
            surface.create_entity{name = ore_name, position = p, amount = a}
          end
        end
      end
    end
    player.print("Патч " .. ore_name .. " создан под вами! 🌐")
    return
  end

  if name == "cheat_refill_resource" then
    local selected = player.selected
    if selected and selected.valid and selected.type == "resource" then
      selected.amount = 10000
      player.print(selected.name .. " пополнен до 10000! ♻️")
    else
      player.print("[color=red]Наведите курсор на ресурс![/color]")
    end
    return
  end

end)

------------------------------------------------------------
-- ГОРЯЧАЯ КЛАВИША
------------------------------------------------------------
script.on_event("toggle-cheat-panel", function(event)
  local player = game.get_player(event.player_index)
  create_main_window(player)
end)

------------------------------------------------------------
-- ИНИЦИАЛИЗАЦИЯ
------------------------------------------------------------
script.on_event(defines.events.on_player_created, function(event)
  create_button(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  create_button(game.get_player(event.player_index))
end)