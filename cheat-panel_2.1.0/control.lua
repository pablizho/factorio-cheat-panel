-- control.lua  -  Cheat Panel v2.1 (Factorio 2.1)
local mod_gui = require("__core__.lualib.mod-gui")

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

-- Depth-first search for a named element inside a GUI subtree.
local function find_in(parent, target_name)
  for _, child in pairs(parent.children) do
    if child.name == target_name then return child end
    local found = find_in(child, target_name)
    if found then return found end
  end
end

local function field_number(scroll, field_name, default)
  local f = find_in(scroll, field_name)
  return tonumber(f and f.text or "") or default
end

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

local function create_buttons_for_all()
  for _, player in pairs(game.players) do create_button(player) end
end

local function add_section_header(parent, caption)
  local label = parent.add{type = "label", caption = caption}
  label.style.font = "heading-2"
  label.style.top_margin = 6
  label.style.bottom_margin = 4
end

local function add_section(parent, caption, name)
  add_section_header(parent, caption)
  return parent.add{
    type = "frame",
    name = name,
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }
end

local function add_cheat_button(parent, name, caption, tooltip)
  local btn = parent.add{
    type = "button",
    name = name,
    caption = caption,
    tooltip = tooltip or "",
    style = "rounded_button"
  }
  btn.style.horizontally_stretchable = true
  return btn
end

-- Row: label + number field + apply + reset
local function add_modifier_row(parent, label_text, field_name, default_val, modifier_key)
  local flow = parent.add{type = "flow", direction = "horizontal"}
  flow.style.vertical_align = "center"
  flow.style.top_margin = 2

  flow.add{type = "label", caption = label_text}.style.minimal_width = 200

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
    tags = {modifier_key = modifier_key, field = field_name}
  }.style.width = 36

  flow.add{
    type = "button",
    name = "reset_" .. field_name,
    caption = "↺",
    tooltip = "Сброс к 0",
    tags = {modifier_key = modifier_key, reset = true}
  }.style.width = 36
end

-- Grid of one-click give buttons; items missing in this game version are skipped.
local function add_item_grid(parent, name, items)
  local grid = parent.add{type = "table", name = name, column_count = 10}
  for _, data in pairs(items) do
    local item_name, count = data[1], data[2]
    if prototypes.item[item_name] then
      grid.add{
        type = "sprite-button",
        name = "cheat_quick_" .. item_name,
        sprite = "item/" .. item_name,
        tooltip = {"", prototypes.item[item_name].localised_name, " x" .. count},
        number = count,
        style = "slot_button",
        tags = {item_name = item_name, item_count = count}
      }
    end
  end
end

------------------------------------------------------------
-- MAIN WINDOW
------------------------------------------------------------
local QUICK_ITEMS = {
  {"iron-plate", 1000}, {"copper-plate", 1000}, {"steel-plate", 500},
  {"electronic-circuit", 500}, {"advanced-circuit", 200}, {"processing-unit", 100},
  {"iron-gear-wheel", 500}, {"coal", 1000}, {"stone", 1000}, {"wood", 500},
  {"plastic-bar", 500}, {"sulfur", 200}, {"battery", 200}, {"explosives", 200},
  {"rocket-fuel", 100}, {"nuclear-fuel", 50}, {"uranium-235", 50}, {"uranium-238", 100},
  {"solar-panel", 100}, {"accumulator", 100}, {"construction-robot", 50}, {"logistic-robot", 50},
  {"roboport", 10}, {"rail", 500}, {"locomotive", 5}, {"cargo-wagon", 5},
  {"medium-electric-pole", 200}, {"substation", 50}, {"small-lamp", 100}, {"rocket-part", 10},
  {"power-armor-mk2", 1}, {"fission-reactor-equipment", 2},
  {"exoskeleton-equipment", 4}, {"personal-roboport-mk2-equipment", 4},
  {"energy-shield-mk2-equipment", 4}, {"battery-mk2-equipment", 4},
  {"stone-wall", 500}, {"gun-turret", 50}, {"laser-turret", 50}, {"radar", 20},
}

local BARRELS = {
  {"crude-oil-barrel", 100}, {"petroleum-gas-barrel", 100},
  {"light-oil-barrel", 100}, {"heavy-oil-barrel", 100},
  {"lubricant-barrel", 100}, {"sulfuric-acid-barrel", 100},
  {"water-barrel", 100},
}

local function create_main_window(player)
  if player.gui.screen.cheat_panel_frame then
    player.gui.screen.cheat_panel_frame.destroy()
    return
  end

  local frame = player.gui.screen.add{
    type = "frame",
    name = "cheat_panel_frame",
    direction = "vertical"
  }
  frame.auto_center = true
  frame.style.maximal_height = 750
  frame.style.minimal_width = 520

  local titlebar = frame.add{type = "flow", direction = "horizontal"}
  titlebar.style.horizontal_spacing = 8
  titlebar.style.bottom_margin = 4
  titlebar.drag_target = frame
  titlebar.add{type = "label", caption = "🛠  Cheat Panel", style = "frame_title", ignored_by_interaction = true}
  local filler = titlebar.add{type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true}
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  titlebar.add{
    type = "sprite-button",
    name = "cheat_close_panel",
    sprite = "utility/close",
    style = "close_button"
  }

  local scroll = frame.add{
    type = "scroll-pane",
    name = "cheat_scroll",
    direction = "vertical",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space"
  }
  scroll.style.maximal_height = 680
  scroll.style.minimal_width = 490

  -- 📦 ITEMS
  local item_frame = add_section(scroll, "📦 Выдача предметов", "item_frame")

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
  row1.add{
    type = "textfield",
    name = "cheat_item_amount",
    text = "1000",
    numeric = true,
    allow_decimal = false,
    allow_negative = false
  }.style.width = 100
  row1.add{type = "button", name = "cheat_give_item", caption = "Выдать", style = "confirm_button"}

  item_frame.add{type = "label", caption = "Быстрая выдача (клик = в инвентарь):"}.style.top_margin = 6
  add_item_grid(item_frame, "quick_table", QUICK_ITEMS)

  item_frame.add{type = "label", caption = "Бочки с жидкостями:"}.style.top_margin = 6
  add_item_grid(item_frame, "barrel_table", BARRELS)

  -- ⚡ CORE CHEATS
  local cheat_frame = add_section(scroll, "⚡ Основные читы")
  add_cheat_button(cheat_frame, "cheat_mode_toggle",
    "🎮 Cheat Mode (бесплатный крафт)",
    "player.cheat_mode: бесплатный и мгновенный крафт всего")
  add_cheat_button(cheat_frame, "cheat_god_mode",
    "👼 God Mode (бессмертие + полёт)",
    "player.set_controller{type = god}: убирает персонажа, вы летаете и неуязвимы")
  add_cheat_button(cheat_frame, "cheat_undo_god_mode",
    "🧍 Вернуть персонажа (отменить God Mode)",
    "player.create_character(): создаёт нового персонажа")
  add_cheat_button(cheat_frame, "cheat_research_all",
    "🔬 Исследовать ВСЕ технологии",
    "force.research_all_technologies()")
  add_cheat_button(cheat_frame, "cheat_unresearch_all",
    "🔬 Сбросить ВСЕ технологии",
    "force.reset(): сбрасывает технологии, бонусы, статистику")
  add_cheat_button(cheat_frame, "cheat_enable_all_recipes",
    "📋 Включить все рецепты",
    "recipe.enabled = true для всех рецептов")
  add_cheat_button(cheat_frame, "cheat_finish_research",
    "⏩ Завершить текущее исследование",
    "force.research_progress = 1")

  -- 🗺 MAP
  local map_frame = add_section(scroll, "🗺 Карта и мир")
  add_cheat_button(map_frame, "cheat_chart_all", "🗺 Открыть всю карту", "force.chart_all(surface)")
  add_cheat_button(map_frame, "cheat_unhart_all", "🗺 Скрыть карту (unchart)", "force.clear_chart(surface)")
  add_cheat_button(map_frame, "cheat_always_day", "☀️ Всегда день (вкл/выкл)", "surface.always_day = true/false")
  add_cheat_button(map_frame, "cheat_freeze_time", "⏸ Заморозить время суток (вкл/выкл)", "surface.freeze_daytime = true/false")
  add_cheat_button(map_frame, "cheat_remove_cliffs", "🪨 Удалить все скалы", "Удаляет все cliff на текущей поверхности")
  add_cheat_button(map_frame, "cheat_remove_decoratives", "🌿 Удалить декорации",
    "surface.destroy_decoratives{}: удаляет траву, камешки и т.д.")

  local tp_flow = map_frame.add{type = "flow", direction = "horizontal"}
  tp_flow.style.vertical_align = "center"
  tp_flow.style.top_margin = 4
  tp_flow.add{type = "label", caption = "Телепорт X:"}
  tp_flow.add{type = "textfield", name = "cheat_tp_x", text = "0", numeric = true, allow_decimal = true, allow_negative = true}.style.width = 80
  tp_flow.add{type = "label", caption = " Y:"}
  tp_flow.add{type = "textfield", name = "cheat_tp_y", text = "0", numeric = true, allow_decimal = true, allow_negative = true}.style.width = 80
  tp_flow.add{type = "button", name = "cheat_teleport", caption = "Телепорт", style = "confirm_button"}

  add_cheat_button(map_frame, "cheat_tp_spawn", "🏠 Телепорт на спавн (0, 0)", "Телепорт к началу карты")

  local speed_flow = map_frame.add{type = "flow", direction = "horizontal"}
  speed_flow.style.vertical_align = "center"
  speed_flow.style.top_margin = 4
  speed_flow.add{type = "label", caption = "Скорость игры:"}
  speed_flow.add{type = "textfield", name = "cheat_game_speed_val", text = "1", numeric = true, allow_decimal = true}.style.width = 80
  speed_flow.add{type = "button", name = "cheat_set_game_speed", caption = "Установить",
    tooltip = "game.speed (1 = норма, 2 = x2, 0.5 = x0.5)"}

  -- 🐛 ENEMIES
  local enemy_frame = add_section(scroll, "🐛 Враги")
  add_cheat_button(enemy_frame, "cheat_kill_all_enemies", "💀 Убить ВСЕХ врагов на поверхности", "Удаляет все entity с force = enemy")
  add_cheat_button(enemy_frame, "cheat_kill_nearby_enemies", "💀 Убить врагов рядом (радиус 250)", "Удаляет врагов в радиусе 250 тайлов")
  add_cheat_button(enemy_frame, "cheat_kill_units_only", "🐜 Убить только юнитов (не базы)", "game.forces.enemy.kill_all_units()")
  add_cheat_button(enemy_frame, "cheat_toggle_peaceful", "☮️ Мирный режим (вкл/выкл)", "surface.peaceful_mode = true/false")
  add_cheat_button(enemy_frame, "cheat_toggle_expansion", "🚫 Расширение биттеров (вкл/выкл)", "map_settings.enemy_expansion.enabled")

  local evo_flow = enemy_frame.add{type = "flow", direction = "horizontal"}
  evo_flow.style.vertical_align = "center"
  evo_flow.style.top_margin = 4
  evo_flow.add{type = "label", caption = "Фактор эволюции (0..1):"}
  evo_flow.add{type = "textfield", name = "cheat_evo_val", text = "0", numeric = true, allow_decimal = true}.style.width = 80
  evo_flow.add{type = "button", name = "cheat_set_evolution", caption = "Установить",
    tooltip = "game.forces.enemy.set_evolution_factor(value, surface)"}

  -- 🌍 POLLUTION
  local poll_frame = add_section(scroll, "🌍 Загрязнение")
  add_cheat_button(poll_frame, "cheat_clear_pollution", "🧹 Убрать всё загрязнение", "surface.clear_pollution()")
  add_cheat_button(poll_frame, "cheat_disable_pollution", "❌ Полностью отключить загрязнение",
    "Очищает загрязнение на ВСЕХ поверхностях и отключает его")
  add_cheat_button(poll_frame, "cheat_enable_pollution", "✅ Включить загрязнение обратно", "map_settings.pollution.enabled = true")

  -- 🧰 INVENTORY
  local inv_frame = add_section(scroll, "🧰 Инвентарь")
  add_cheat_button(inv_frame, "cheat_fill_inventory", "📥 Заполнить инвентарь (по 100 всего)", "Добавляет по 100 штук каждого предмета")
  add_cheat_button(inv_frame, "cheat_clear_inventory", "🗑 Очистить инвентарь", "Полностью очищает основной инвентарь")
  add_cheat_button(inv_frame, "cheat_pickup_items", "🧲 Подобрать предметы с земли (радиус 50)", "Собирает все item-entity в радиусе 50")

  -- 🔧 FORCE MODIFIERS
  local mod_frame = add_section(scroll, "🔧 Модификаторы (Force)")
  add_modifier_row(mod_frame, "⛏ Скорость добычи", "mod_mining", 1000, "manual_mining_speed_modifier")
  add_modifier_row(mod_frame, "🔨 Скорость крафта", "mod_craft", 1000, "manual_crafting_speed_modifier")
  add_modifier_row(mod_frame, "🔬 Скорость лабораторий", "mod_lab", 100, "laboratory_speed_modifier")
  add_modifier_row(mod_frame, "🏃 Скорость бега", "mod_run", 5, "character_running_speed_modifier")
  add_modifier_row(mod_frame, "📏 Дальность постройки", "mod_build_reach", 1000, "character_build_distance_bonus")
  add_modifier_row(mod_frame, "🤚 Дальность взаимодействия", "mod_reach", 1000, "character_reach_distance_bonus")
  add_modifier_row(mod_frame, "💎 Дальность ресурсов", "mod_res_reach", 1000, "character_resource_reach_distance_bonus")
  add_modifier_row(mod_frame, "📦 Доп. слоты инвентаря", "mod_inv", 200, "character_inventory_slots_bonus")
  add_modifier_row(mod_frame, "🗑 Слоты для мусора", "mod_trash", 100, "character_trash_slot_count")
  add_modifier_row(mod_frame, "📡 Дальность сброса предметов", "mod_drop", 1000, "character_item_drop_distance_bonus")

  -- 🌐 RESOURCES
  local spawn_frame = add_section(scroll, "🌐 Спавн ресурсов на карте")
  spawn_frame.add{type = "label", caption = "Создаёт патч 11×11 ресурсов под игроком:"}.style.single_line = false

  local spawn_flow = spawn_frame.add{type = "flow", direction = "horizontal"}
  spawn_flow.style.vertical_align = "center"
  spawn_flow.style.top_margin = 4
  spawn_flow.add{type = "label", caption = "Ресурс:"}
  spawn_flow.add{
    type = "choose-elem-button",
    name = "cheat_ore_picker",
    elem_type = "entity",
    elem_filters = {{filter = "type", type = "resource"}},
    tooltip = "Выберите тип ресурса (iron-ore, copper-ore и т.д.)"
  }
  spawn_flow.add{type = "label", caption = " Кол-во:"}
  spawn_flow.add{type = "textfield", name = "cheat_ore_amount", text = "3000", numeric = true}.style.width = 80
  spawn_flow.add{type = "button", name = "cheat_spawn_ore", caption = "Создать патч", style = "confirm_button"}

  add_cheat_button(spawn_frame, "cheat_refill_resource",
    "♻️ Пополнить ресурс под курсором до 10000",
    "Наведите курсор на ресурс и нажмите")
end

------------------------------------------------------------
-- ACTIONS (button name -> function(player, scroll))
------------------------------------------------------------
local function toggle_text(on, yes, no) return on and yes or no end

local actions = {}

actions.cheat_give_item = function(player, scroll)
  local picker = find_in(scroll, "cheat_item_picker")
  if not (picker and picker.elem_value) then
    player.print("[color=red]Сначала выберите предмет![/color]")
    return
  end
  local count = math.max(1, math.floor(field_number(scroll, "cheat_item_amount", 1000)))
  local inserted = player.insert{name = picker.elem_value, count = count}
  player.print("Выдано: " .. picker.elem_value .. " x" .. inserted)
end

actions.cheat_mode_toggle = function(player)
  player.cheat_mode = not player.cheat_mode
  player.print("Cheat Mode: " .. toggle_text(player.cheat_mode, "ВКЛ ✅", "ВЫКЛ ❌"))
end

actions.cheat_god_mode = function(player)
  if player.controller_type == defines.controllers.god then
    player.print("[color=yellow]Вы уже в God Mode[/color]")
    return
  end
  local character = player.character
  player.set_controller{type = defines.controllers.god}
  if character and character.valid then character.destroy() end
  player.print("God Mode: ВКЛ ✅ (вы бессмертны и летаете)")
end

actions.cheat_undo_god_mode = function(player)
  if player.character then
    player.print("[color=yellow]У вас уже есть персонаж[/color]")
    return
  end
  if player.create_character() then
    player.print("Персонаж создан. God Mode ВЫКЛ ❌")
  else
    player.print("[color=red]Не удалось создать персонажа здесь[/color]")
  end
end

actions.cheat_research_all = function(player)
  player.force.research_all_technologies()
  player.print("Все технологии исследованы! 🔬")
end

actions.cheat_unresearch_all = function(player)
  player.force.reset()
  player.print("Все технологии и данные force сброшены!")
end

actions.cheat_enable_all_recipes = function(player)
  for _, recipe in pairs(player.force.recipes) do recipe.enabled = true end
  player.print("Все рецепты включены! 📋")
end

actions.cheat_finish_research = function(player)
  local tech = player.force.current_research
  if tech then
    player.force.research_progress = 1
    player.print("Исследование \"" .. tech.name .. "\" завершено! ⏩")
  else
    player.print("[color=yellow]Нет активного исследования[/color]")
  end
end

actions.cheat_chart_all = function(player)
  player.force.chart_all(player.surface)
  player.print("Карта полностью открыта! 🗺")
end

actions.cheat_unhart_all = function(player)
  player.force.clear_chart(player.surface)
  player.print("Карта скрыта!")
end

actions.cheat_always_day = function(player)
  local s = player.surface
  s.always_day = not s.always_day
  player.print("Всегда день: " .. toggle_text(s.always_day, "ВКЛ ☀️", "ВЫКЛ 🌙"))
end

actions.cheat_freeze_time = function(player)
  local s = player.surface
  s.freeze_daytime = not s.freeze_daytime
  player.print("Заморозка времени: " .. toggle_text(s.freeze_daytime, "ВКЛ ⏸", "ВЫКЛ ▶"))
end

actions.cheat_remove_cliffs = function(player)
  local cliffs = player.surface.find_entities_filtered{type = "cliff"}
  for _, cliff in pairs(cliffs) do if cliff.valid then cliff.destroy() end end
  player.print("Удалено скал: " .. #cliffs .. " 🪨")
end

actions.cheat_remove_decoratives = function(player)
  player.surface.destroy_decoratives{}
  player.print("Все декорации удалены! 🌿")
end

actions.cheat_teleport = function(player, scroll)
  local x = field_number(scroll, "cheat_tp_x", 0)
  local y = field_number(scroll, "cheat_tp_y", 0)
  if player.teleport({x, y}) then
    player.print("Телепорт → [" .. x .. ", " .. y .. "]")
  else
    player.print("[color=red]Не удалось телепортироваться в эту точку[/color]")
  end
end

actions.cheat_tp_spawn = function(player)
  player.teleport({0, 0})
  player.print("Телепорт на спавн [0, 0] 🏠")
end

actions.cheat_set_game_speed = function(player, scroll)
  local speed = math.max(0.01, field_number(scroll, "cheat_game_speed_val", 1))
  game.speed = speed
  player.print("Скорость игры: x" .. speed .. " ⏱")
end

local function destroy_enemies(player, filter)
  filter.force = "enemy"
  local enemies = player.surface.find_entities_filtered(filter)
  for _, e in pairs(enemies) do if e.valid then e.destroy() end end
  return #enemies
end

actions.cheat_kill_all_enemies = function(player)
  player.print("Уничтожено врагов: " .. destroy_enemies(player, {}) .. " 💀")
end

actions.cheat_kill_nearby_enemies = function(player)
  local n = destroy_enemies(player, {position = player.position, radius = 250})
  player.print("Уничтожено врагов рядом: " .. n .. " 💀")
end

actions.cheat_kill_units_only = function(player)
  game.forces["enemy"].kill_all_units()
  player.print("Все вражеские юниты убиты! 🐜")
end

actions.cheat_toggle_peaceful = function(player)
  local s = player.surface
  s.peaceful_mode = not s.peaceful_mode
  player.print("Мирный режим: " .. toggle_text(s.peaceful_mode, "ВКЛ ☮️", "ВЫКЛ ⚔️"))
end

actions.cheat_toggle_expansion = function(player)
  local e = game.map_settings.enemy_expansion
  e.enabled = not e.enabled
  player.print("Расширение биттеров: " .. toggle_text(e.enabled, "ВКЛ", "ВЫКЛ 🚫"))
end

-- 2.0+: evolution is per surface (LuaForce::evolution_factor was removed).
actions.cheat_set_evolution = function(player, scroll)
  local val = math.min(1, math.max(0, field_number(scroll, "cheat_evo_val", 0)))
  game.forces["enemy"].set_evolution_factor(val, player.surface)
  player.print("Фактор эволюции (" .. player.surface.name .. "): " .. val)
end

actions.cheat_clear_pollution = function(player)
  player.surface.clear_pollution()
  player.print("Загрязнение очищено! 🧹")
end

actions.cheat_disable_pollution = function(player)
  for _, surface in pairs(game.surfaces) do surface.clear_pollution() end
  game.map_settings.pollution.enabled = false
  player.print("Загрязнение ПОЛНОСТЬЮ отключено! ❌")
end

actions.cheat_enable_pollution = function(player)
  game.map_settings.pollution.enabled = true
  player.print("Загрязнение включено! ✅")
end

actions.cheat_fill_inventory = function(player)
  local count = 0
  for item_name, proto in pairs(prototypes.item) do
    if not proto.hidden and player.can_insert{name = item_name, count = 1} then
      if player.insert{name = item_name, count = 100} > 0 then count = count + 1 end
    end
  end
  player.print("Добавлено предметов: " .. count .. " видов по 100 шт 📥")
end

actions.cheat_clear_inventory = function(player)
  local inv = player.get_main_inventory()
  if inv then inv.clear() end
  player.print("Инвентарь очищен! 🗑")
end

actions.cheat_pickup_items = function(player)
  local items = player.surface.find_entities_filtered{
    type = "item-entity", position = player.position, radius = 50
  }
  local picked = 0
  for _, item in pairs(items) do
    if item.valid and item.stack and item.stack.valid_for_read then
      local n = player.insert(item.stack)
      if n >= item.stack.count then item.destroy() elseif n > 0 then item.stack.count = item.stack.count - n end
      if n > 0 then picked = picked + 1 end
    end
  end
  player.print("Подобрано предметов с земли: " .. picked .. " 🧲")
end

actions.cheat_spawn_ore = function(player, scroll)
  local picker = find_in(scroll, "cheat_ore_picker")
  if not (picker and picker.elem_value) then
    player.print("[color=red]Выберите тип ресурса![/color]")
    return
  end
  local ore_name = picker.elem_value
  local amount = field_number(scroll, "cheat_ore_amount", 3000)
  local surface = player.surface
  local cx, cy = math.floor(player.position.x), math.floor(player.position.y)
  local size = 5
  for dx = -size, size do
    for dy = -size, size do
      local p = {x = cx + dx, y = cy + dy}
      local tile = surface.get_tile(p.x, p.y)
      if tile and tile.valid and not tile.collides_with("water_tile") then
        local dist = math.max(math.abs(dx), math.abs(dy))
        local a = math.floor(amount * (1 - dist / (size + 2)) * (0.75 + math.random() * 0.5))
        if a > 0 then
          for _, e in pairs(surface.find_entities_filtered{position = p, type = "resource"}) do e.destroy() end
          surface.create_entity{name = ore_name, position = p, amount = a}
        end
      end
    end
  end
  player.print("Патч " .. ore_name .. " создан под вами! 🌐")
end

actions.cheat_refill_resource = function(player)
  local selected = player.selected
  if selected and selected.valid and selected.type == "resource" then
    selected.amount = 10000
    player.print(selected.name .. " пополнен до 10000! ♻️")
  else
    player.print("[color=red]Наведите курсор на ресурс![/color]")
  end
end

local function apply_modifier(player, scroll, tags)
  if tags.reset then
    player.force[tags.modifier_key] = 0
    player.print(tags.modifier_key .. " → 0 (сброс)")
    return
  end
  local val = field_number(scroll, tags.field, 0)
  player.force[tags.modifier_key] = val
  player.print(tags.modifier_key .. " → " .. val .. " ✔")
end

------------------------------------------------------------
-- EVENTS
------------------------------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
  local el = event.element
  if not (el and el.valid) then return end
  local player = game.get_player(event.player_index)
  local name = el.name

  if name == "cheat_panel_button" then
    create_main_window(player)
    return
  end

  local root = player.gui.screen.cheat_panel_frame
  if not root then return end

  if name == "cheat_close_panel" then
    root.destroy()
    return
  end

  local scroll = root.cheat_scroll
  local tags = el.tags

  if tags.item_name then
    local inserted = player.insert{name = tags.item_name, count = tags.item_count}
    player.print("Выдано: " .. tags.item_name .. " x" .. inserted)
  elseif tags.modifier_key then
    apply_modifier(player, scroll, tags)
  elseif actions[name] then
    actions[name](player, scroll)
  end
end)

script.on_event("toggle-cheat-panel", function(event)
  create_main_window(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_created, function(event)
  create_button(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  create_button(game.get_player(event.player_index))
end)

-- Adding the mod to an existing single-player save fires neither event above.
script.on_init(create_buttons_for_all)
script.on_configuration_changed(create_buttons_for_all)

-- Test hook: lets a scenario or console call every action by name.
remote.add_interface("cheat-panel", {
  open = function(player_index) create_main_window(game.get_player(player_index)) end,
  run = function(player_index, action_name)
    local player = game.get_player(player_index)
    local root = player.gui.screen.cheat_panel_frame
    if not root then create_main_window(player); root = player.gui.screen.cheat_panel_frame end
    actions[action_name](player, root.cheat_scroll)
  end,
  actions = function()
    local list = {}
    for k in pairs(actions) do list[#list + 1] = k end
    table.sort(list)
    return list
  end,
})
