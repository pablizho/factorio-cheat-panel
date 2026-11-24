# Factorio Cheat Panel

**A scrollable in-game cheat and debug GUI for Factorio 2.1. Ctrl+F9.**

![Lua](https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white)
![Factorio](https://img.shields.io/badge/Factorio-2.1-FFA500?style=flat-square)
![MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

~950 lines of Lua · 8 sections · 60+ actions · depends on `base` only

---

## Why it exists

Factorio's cheats live behind `/c` console commands. You have to remember that clearing pollution is `game.surfaces[1].clear_pollution()` and that unlocking everything is `game.player.force.research_all_technologies()`, and one typo either does nothing or does something you did not want.

This mod puts all of it behind a window. Every button's tooltip is **the actual API call it performs**, so the panel doubles as a browsable index of the Factorio Lua API — you learn the commands by hovering over the buttons that run them.

## What it does

Eight sections in one scrollable, draggable window:

- **Items** — a native item picker with an amount field, plus 47 one-click quick-give buttons (40 items and 7 fluid barrels) with sprite icons and stack counts.
- **Core cheats** — cheat mode (free and instant crafting), god mode, restore character.
- **Research** — research everything, reset all technologies, enable all recipes, finish current research.
- **Map** — chart or unchart the whole surface, always-day, freeze daytime, remove cliffs, remove decoratives.
- **Teleport & speed** — jump to X/Y or to spawn, set game speed (clamped at 0.01).
- **Enemies** — kill all, kill nearby, kill units only, peaceful mode, toggle expansion, set evolution factor (clamped 0–1).
- **Pollution** — clear on this surface, clear and disable everywhere, re-enable.
- **Force modifiers** — ten of them (mining speed, crafting speed, lab speed, running speed, build/reach/resource-reach distance, inventory slots, trash slots, item drop distance), each with an apply and a reset button.
- **Resources** — spawn an 11×11 ore patch under the player, refill the resource under the cursor.

## Engineering notes

**The window function is its own toggle.** `create_main_window(player)` opens with:

```lua
if player.gui.screen.cheat_panel_frame then
  player.gui.screen.cheat_panel_frame.destroy()
  return
end
```

so the hotkey and the toolbar button share one function for open *and* close, with no state variable to keep in sync.

**Ten force modifiers, one code path.** `add_modifier_row` bakes the target into the widget's tags:

```lua
tags = { modifier_key = "manual_mining_speed_modifier", target = "force" }
```

and the click handler does `player.force[tags.modifier_key] = val`. Adding an eleventh modifier is one line in the builder and zero lines in the handler. The same trick handles all 47 quick-give buttons in four lines via `tags.item_name` / `tags.item_count`.

**Every quick-give button is wrapped in `pcall`.** An item prototype that does not exist in the player's Factorio version or mod set is silently skipped instead of crashing GUI construction. Same for `cheat_fill_inventory`, which walks `pairs(prototypes.item)` and counts only the inserts that actually succeeded.

**Ore patches look natural.** `cheat_spawn_ore` walks an 11×11 grid and computes richness with distance falloff plus jitter:

```lua
local dist = math.max(math.abs(dx), math.abs(dy))   -- Chebyshev
local a = math.floor(amount * (1 - dist / (size + 2)) * (0.75 + math.random() * 0.5))
```

It also checks `not tile.collides_with("water-tile")` and clears pre-existing resources before `create_entity`, so you don't get ore floating in a lake.

**Correct 2.1 API.** `prototypes.item` rather than the removed `game.item_prototypes`; per-surface `set_evolution_factor`; `choose-elem-button` with `elem_filters` for the ore picker; `player.insert` return values used for accurate "gave you N" feedback.

## Install

Download the release zip and unpack into your mods folder so that `cheat-panel_2.1.0/` sits directly inside it:

- Windows — `%APPDATA%\Factorio\mods\`
- Linux — `~/.factorio/mods/`

Then **Mods → enable "Cheat Panel" → restart**. Open with `Ctrl+F9` or the ⚠️ button on the toolbar.

Cloning the repository directly does not work — the mod folder is one level down, so copy `cheat-panel_2.1.0/` out of the repo root.

## Known issues

- **No permission check.** In multiplayer *any* player, not just an admin, can reset all technologies, change game speed, set evolution or wipe pollution on every surface. A single `if not player.admin then return end` is missing, and the mod is described as multiplayer-friendly. Fix this before using it on a public server.
- `info.json` still has the template placeholder in the author field.
- The `find_in` recursive GUI search helper is defined four separate times, verbatim, inside different branches of the click handler instead of once at file scope.
- `cheat_give_item` reads its widget by hardcoded index while everything else uses `find_in` — two incompatible lookup strategies in one file.
- The click handler is a flat ~35-branch `if`/`return` chain rather than a dispatch table.
- No `script.on_init` and no persistent state, so the toolbar button is not guaranteed to appear for players who already exist when the mod is added to a running save.
- `changelog.txt` is not in Factorio's required format, so the in-game changelog is empty.
- No `locale/` folder — every string is a hardcoded Russian literal in `control.lua`, which caps the audience on the mod portal.
- `cheat_pickup_items` calls `player.insert` then `item.destroy()` without checking the return value: with a full inventory the items are deleted rather than picked up.
- Typo in a shipped element name: `cheat_unhart_all` (should be `unchart`).
- Modifier reset always writes `0` rather than the prototype default.

---

<details>
<summary><b>🇷🇺 По-русски</b></summary>

<br>

**Панель читов и отладки для Factorio 2.1 в одном прокручиваемом окне. Ctrl+F9.**

### Зачем

Читы в Factorio живут за консольными командами `/c`. Нужно помнить, что очистка загрязнения — это `game.surfaces[1].clear_pollution()`, а разблокировка всего — `force.research_all_technologies()`, и одна опечатка либо не делает ничего, либо делает не то.

Мод убирает это за окно. **Тултип каждой кнопки — это сам вызов API**, который она выполняет, поэтому панель заодно работает как справочник по Lua API: команды запоминаются, пока наводишь мышь.

### Что внутри

Восемь секций: выдача предметов (пикер + 47 кнопок быстрой выдачи), базовые читы, исследования и рецепты, карта и поверхность, телепорт и скорость игры, враги и эволюция, загрязнение, десять модификаторов силы, генерация руды.

### Интересные места

- **Функция окна — сама себе переключатель**: первым делом проверяет, существует ли фрейм, и уничтожает его. Хоткей и кнопка на панели используют одну функцию и на открытие, и на закрытие, без переменной состояния.
- **Десять модификаторов — один обработчик.** Ключ модификатора зашит в `tags` кнопки, обработчик делает `player.force[tags.modifier_key] = val`. Добавить одиннадцатый — одна строка в билдере и ноль строк в обработчике. Тем же приёмом 47 кнопок выдачи предметов обслуживаются четырьмя строками.
- **Каждая кнопка выдачи обёрнута в `pcall`** — предмет, которого нет в текущей версии или наборе модов, просто пропускается, а не роняет построение интерфейса.
- **Руда генерируется с затуханием от центра**: расстояние по Чебышёву, множитель `(1 - dist / (size + 2))` и случайный разброс, плюс проверка на воду и очистка старых ресурсов. Получается похоже на природное месторождение, а не на квадрат.

### Известные проблемы

**Нет проверки прав.** В мультиплеере любой игрок, не только админ, может сбросить все технологии, изменить скорость игры или эволюцию. Не хватает одной строки `if not player.admin then return end` — это стоит починить до использования на публичном сервере.

Ещё: в `info.json` осталась заглушка автора, `find_in` продублирован четыре раза, `changelog.txt` не в формате Factorio (внутриигровой список изменений пустой), нет папки `locale/` — все строки захардкожены по-русски, опечатка в имени элемента `cheat_unhart_all`.

</details>
