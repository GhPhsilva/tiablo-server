# Plan: Remove Imbuements System from Tiablo

## Context

Tiablo is a custom MMORPG server (Canary/OpenTibiaBR) that intentionally does not include the imbuements feature. The goal is a complete removal from both the server (C++/Lua) and the client (Lua/OTUI only — C++ binary is pre-compiled and cannot be modified). This prevents any imbuement UI from appearing and removes all related server processing, stat calculations, and item XML attributes.

---

## Scope

### Server — C++ files involved (~31 files)

| Component | Files | Role |
|---|---|---|
| Core System | `src/creatures/players/imbuements/imbuements.hpp/cpp` | Imbuement class, XML loader, singleton |
| Lua Bindings | `src/lua/functions/items/imbuement_functions.hpp/cpp` | Lua API |
| Item System | `src/items/items.hpp`, `item.hpp`, `item.cpp`, `items_definitions.hpp` | Slot fields, methods, serialization |
| XML Parser | `src/items/functions/item/item_parse.hpp/cpp` | Parsing `imbuementslot` attribute |
| Player | `src/creatures/players/player.hpp/cpp` | Apply/clear, decay, stat bonuses |
| Network | `src/server/network/protocol/protocolgame.hpp/cpp` | Protocol opcodes, window packets |
| Game | `src/game/game.hpp/cpp` | Dispatch, decay event loop |
| Combat | `src/creatures/combat/combat.cpp` | Elemental damage from imbuements |
| Movement | `src/lua/creature/movement.cpp` | Equip/unequip stat updates |
| Reload | `src/game/functions/game_reload.hpp/cpp` | `/reload imbuements` support |
| Utilities | `src/utils/tools.hpp/cpp`, `src/config/configmanager.cpp` | Type names, config flags |
| Lua misc | `src/lua/scripts/scripts.cpp`, `events.hpp`, `lua_definitions.hpp` | Includes, enum value |
| Scheduling | `src/game/scheduling/task.hpp` | Traceable context name |
| Startup | `src/canary_server.cpp` | `g_imbuements().loadFromXml()` |

### Server — Data files

- `data/XML/imbuements.xml` (430 lines — all imbuement definitions)
- `data/items/items.xml` — **463 items** with `imbuementslot` attributes
- `data-otservbr-global/scripts/actions/object/imbuement_shrine.lua`
- `data-otservbr-global/npc/imbuement_assistant.lua`
- `data/scripts/talkactions/god/reload.lua` (remove one line)
- `data/scripts/eventcallbacks/player/on_trade_accept.lua` (remove two lines)
- `config.lua` (remove two config entries)

### Client — Lua/OTUI only (C++ binary is pre-compiled, cannot be modified)

- `data/modules/game_imbuing/` (entire directory)
- `data/images/game/imbuing/` (entire directory)
- `data/modules/game_bot/default_configs/vBot_4.7/cavebot/imbuing.lua`
- `data/modules/game_interface/interface.otmod` (remove one dependency line)
- `data/modules/game_bot/bot.lua`, `executor.lua`, `functions/callbacks.lua` (remove signal handlers)
- `data/modules/game_bot/default_configs/vBot_4.7/vBot/supplies.lua/otui` (remove imbues config)

---

## Risk Assessment

### Server
- **Database**: No migration needed. Imbuements are stored as custom item attributes in binary item serialization (keys "500"–"502"). The `case ATTR_IMBUEMENT_SLOT:` branch must be converted to skip-and-discard (not deleted) so existing characters load cleanly without errors.
- **Network Protocol**: The pre-compiled client may send imbuement opcodes (open window, apply, clear, tracker). The server must silently absorb these as no-ops — never disconnect. Since the shrine/NPC scripts are deleted, the window is never triggered, but residual packets must still be handled gracefully.
- **`criticalChance` config**: Do NOT remove — used by skill system cap (`SKILL_CRITICAL_HIT_CHANCE`), not imbuements.
- **`isTradeable` logic**: After removing the imbuement block in `getDescriptions()`, items correctly always show "Tradeable: yes" — no extra action needed.
- **`npc.cpp`**: `hasImbuements()` check in shop logic must become just the tier check.

### Client
- **Pre-compiled binary**: The C++ engine fires signals like `onImbuementWindow`. If `game_imbuing` module is removed, the signal fires into nothing — OtClientV8 handles missing handlers gracefully. Safe.
- **Bot integration**: `bot.lua`, `executor.lua`, `callbacks.lua` reference `onImbuementWindow` — must be cleaned up to avoid Lua errors at runtime.
- **Protocol handlers**: `game_protocol/protocol.lua` inspection packet handler already discards imbuement data safely. No changes needed there.

---

## Implementation Plan

### Phase 1 — Delete Core C++ Imbuement Files

Delete entirely:
- `src/creatures/players/imbuements/imbuements.hpp`
- `src/creatures/players/imbuements/imbuements.cpp`
- `src/lua/functions/items/imbuement_functions.hpp`
- `src/lua/functions/items/imbuement_functions.cpp`

### Phase 2 — CMake Build System

- `src/creatures/CMakeLists.txt` — remove `players/imbuements/imbuements.cpp`
- `src/lua/functions/items/CMakeLists.txt` — remove `imbuement_functions.cpp`

### Phase 3 — Remove Enum/Constant Definitions

**`src/items/items_definitions.hpp`**:
- Delete `enum ImbuementTypes_t : int64_t { ... }` block
- Delete `struct ImbuementInfo { ... }` block
- Delete `ITEM_PARSE_IMBUEMENT` from `enum ItemParseAttributes_t`
- **Keep** `ATTR_IMBUEMENT_SLOT = 35` (needed for Phase 5 skip-and-discard serialization)

**`src/utils/const.hpp`**:
- Delete `EVENT_IMBUEMENT_INTERVAL = 1000`
- Delete `IMBUEMENT_MAX_TIER = 3`

**`src/config/config_enums.hpp`**:
- Delete `TOGGLE_IMBUEMENT_NON_AGGRESSIVE_FIGHT_ONLY`
- Delete `TOGGLE_IMBUEMENT_SHRINE_STORAGE`

### Phase 4 — Update `ItemType` Class

**`src/items/items.hpp`**:
- Delete `setImbuementType()` method
- Delete `imbuementTypes` map field
- Delete `imbuementSlot` field

### Phase 5 — Update `Item` Class

**`src/items/item.hpp`**:
- Remove `class Imbuement;` forward declaration
- Remove `parseImbuementDescription()` declaration
- Remove `getImbuementSlot()`, `getImbuementInfo()`, `addImbuement()`, `decayImbuementTime()`, `clearImbuement()`, `hasImbuementType()`, `hasImbuementCategoryId()`, `hasImbuements()` methods
- Remove `setImbuement()` private declaration

**`src/items/item.cpp`**:
- Remove `#include "creatures/players/imbuements/imbuements.hpp"` and `#define ITEM_IMBUEMENT_SLOT 500`
- Delete `getImbuementInfo()`, `setImbuement()`, `addImbuement()`, `hasImbuementCategoryId()` function bodies
- **Convert** `case ATTR_IMBUEMENT_SLOT:` to skip-and-discard — read int32 and discard, do NOT delete the case:
  ```cpp
  case ATTR_IMBUEMENT_SLOT: {
      int32_t unused;
      if (!propStream.read<int32_t>(unused)) {
          return ATTR_READ_ERROR;
      }
      // Imbuement slots removed; discard legacy value
      break;
  }
  ```
- Delete the write block: `if (hasAttribute(ItemAttribute_t::IMBUEMENT_SLOT)) { ... }`
- Delete imbuement slot description blocks in `getDescriptions()` (the `it.imbuementSlot > 0` block and the per-item block)
- Delete `parseImbuementDescription()` function and its call site
- Fix `isStaticDescription()`: replace `!hasImbuements() && !isStoreItem() && !hasOwner()` with `!isStoreItem() && !hasOwner()`

**`src/enums/item_attribute.hpp`**:
- Remove `IMBUEMENT_SLOT = 25` from `ItemAttribute_t` enum

**`src/items/functions/item/attribute.hpp`**:
- Remove `case ItemAttribute_t::IMBUEMENT_SLOT:` from integer attribute switch

### Phase 6 — Update `Player` Class

**`src/creatures/players/player.hpp`**:
- Remove `#include "imbuements/imbuements.hpp"` and forward declaration
- Remove `hasImbuingItem()`, `setImbuingItem()`, `onApplyImbuement()`, `onClearImbuement()`, `openImbuementWindow()`, `sendImbuementResult()`, `closeImbuementWindow()`
- Remove `addItemImbuementStats()`, `removeItemImbuementStats()`, `updateImbuementTrackerStats()`, `updateDamageReductionFromItemImbuement()`
- Remove `sendInventoryImbuements()`, `updateInventoryImbuement()`
- Remove `imbuementTrackerWindowOpen` and `imbuingItem` fields

**`src/creatures/players/player.cpp`**:
- Remove `setImbuingItem()`, `updateInventoryImbuement()`, `onApplyImbuement()`, `onClearImbuement()`, `openImbuementWindow()`, `addItemImbuementStats()`, `removeItemImbuementStats()`, `updateImbuementTrackerStats()`, `updateDamageReductionFromItemImbuement()` function bodies
- Remove imbuement decay loop and imbuement tracker update calls
- Remove imbuement absorption in damage reduction path
- Remove `hasImbuements()` guard in `getForgeItemFromId()`

### Phase 7 — Update XML Parser

**`src/items/functions/item/item_parse.hpp`**:
- Remove `ImbuementsTypeMap` constant (references deleted enum)
- Remove `{ "imbuementslot", ITEM_PARSE_IMBUEMENT }` entry
- Remove `parseImbuement()` declaration

**`src/items/functions/item/item_parse.cpp`**:
- Remove `ItemParse::parseImbuement()` call from `initParse()`
- Delete `void ItemParse::parseImbuement(...)` function body

### Phase 8 — Update Tools

**`src/utils/tools.hpp`**: Remove `getImbuementType()` declaration

**`src/utils/tools.cpp`**: Remove `ImbuementTypeNames` map and `getImbuementType()` function

### Phase 9 — Update Combat

**`src/creatures/combat/combat.hpp`**: Remove `applyImbuementElementalDamage()` declaration

**`src/creatures/combat/combat.cpp`**:
- Delete `applyImbuementElementalDamage()` function
- Remove the call to it (~line 587)

### Phase 10 — Update Movement Callbacks

**`src/lua/creature/movement.cpp`**:
- Remove imbuement stat loops in equip handler (`addItemImbuementStats` loop, ~lines 546–551)
- Remove imbuement stat loops in unequip handler (`removeItemImbuementStats` loop, ~lines 644–649)

### Phase 11 — Update Game

**`src/game/game.hpp`**: Remove `playerApplyImbuement()`, `playerClearImbuement()`, `playerCloseImbuementWindow()`, `playerRequestInventoryImbuements()`, `checkImbuements()`

**`src/game/game.cpp`**:
- Remove `cycleEvent(EVENT_IMBUEMENT_INTERVAL, ...)` registration (~line 351)
- Remove `hasImbuingItem()` guard in `playerMoveThing()` (~line 1133)
- Delete `playerApplyImbuement()`, `playerClearImbuement()`, `playerCloseImbuementWindow()`, `checkImbuements()`, `playerRequestInventoryImbuements()` function bodies

### Phase 12 — Update Reload System

**`src/game/functions/game_reload.hpp`**: Remove `RELOAD_TYPE_IMBUEMENTS` and `reloadImbuements()`

**`src/game/functions/game_reload.cpp`**:
- Remove imbuements include
- Remove `case Reload_t::RELOAD_TYPE_IMBUEMENTS:` branch
- Delete `reloadImbuements()` function

### Phase 13 — Update Network Protocol

**`src/server/network/protocol/protocolgame.hpp`**: Remove all imbuement parse/send method declarations

**`src/server/network/protocol/protocolgame.cpp`**:
- Remove imbuements include
- Delete `handleImbuementDamage()` anonymous namespace function
- Replace the two `handleImbuementDamage(msg, player)` call sites with:
  ```cpp
  msg.addByte(0);  // element damage: none
  msg.addByte(0);  // element type: none
  ```
- Remove imbuement absorb calculation in cyclopedia packet
- **Convert opcodes to silent no-ops** (client is pre-compiled, must never be disconnected):
  - `0x60` inventory imbuements: read and discard 1 byte
  - `0xD5` apply imbuement: read and discard 6 bytes
  - `0xD6` clear imbuement: read and discard 1 byte
  - `0xD7` close imbuement window: empty handler
- Delete `parseApplyImbuement()`, `parseClearImbuement()`, `parseCloseImbuementWindow()`, `addImbuementInfo()`, `openImbuementWindow()`, `sendImbuementResult()`, `closeImbuementWindow()`, `parseInventoryImbuements()`, `sendInventoryImbuements()` function bodies
- Market detail packet: replace `it.imbuementSlot > 0` check with unconditional `msg.add<uint16_t>(0x00)`
- Forge packet: remove `hasImbuements()` guard (~line 5002)

### Phase 14 — Server Startup

**`src/canary_server.cpp`**: Remove `modulesLoadHelper(g_imbuements().loadFromXml(), "XML/imbuements.xml")` (~line 352)

### Phase 15 — Lua Bindings

**`src/lua/functions/items/item_functions.hpp/cpp`**: Remove `luaItemGetImbuement()`, `luaItemGetImbuementSlot()` and their `registerMethod` calls

**`src/lua/functions/items/item_type_functions.hpp/cpp`**: Remove `luaItemTypeGetImbuementSlot()` and its registration

**`src/lua/functions/creatures/player/player_functions.hpp/cpp`**: Remove `luaPlayerOpenImbuementWindow()`, `luaPlayerCloseImbuementWindow()` and their registrations

**`src/lua/scripts/scripts.cpp`**: Remove imbuements include (~line 12)

**`src/lua/creature/events.hpp`**: Remove imbuements include (~line 12)

### Phase 16 — Auxiliary Files

**`src/lua/lua_definitions.hpp`**: Remove `Imbuement` from `LuaData_t` enum

**`src/game/scheduling/task.hpp`**: Remove `"Game::checkImbuements"` from traceable contexts set

**`src/config/configmanager.cpp`**: Remove `loadBoolConfig` calls for `TOGGLE_IMBUEMENT_NON_AGGRESSIVE_FIGHT_ONLY` and `TOGGLE_IMBUEMENT_SHRINE_STORAGE` (~lines 149–150)

**`src/creatures/npc/npc.cpp`**: Replace `item->getTier() > 0 || item->hasImbuements()` with `item->getTier() > 0`

### Phase 17 — Data/Script Files

**Delete entirely:**
- `data-otservbr-global/scripts/actions/object/imbuement_shrine.lua`
- `data-otservbr-global/npc/imbuement_assistant.lua`
- `data/XML/imbuements.xml`

**Edit:**

`data/scripts/talkactions/god/reload.lua`:
- Remove `["imbuements"] = RELOAD_TYPE_IMBUEMENTS`

`data/scripts/eventcallbacks/player/on_trade_accept.lua`:
- Remove `player:closeImbuementWindow()` and `target:closeImbuementWindow()` lines

`config.lua`:
- Remove `toggleImbuementShrineStorage` and `toggleImbuementNonAggressiveFightOnly` lines
- Leave `criticalChance = 10` (used by the skill system, not imbuements)

`data/items/items.xml`:
- Bulk removal of all `imbuementslot` attribute nodes — 463 items affected. Use a script:
  ```python
  import re
  content = open("data/items/items.xml", encoding="utf-8").read()
  # Multi-line imbuementslot blocks
  content = re.sub(
      r'\s*<attribute key="imbuementslot"[^/]*/>\s*(?:<attribute[^>]*/>\s*)*</attribute>',
      '', content, flags=re.DOTALL
  )
  # Self-closing imbuementslot lines
  content = re.sub(r'\s*<attribute key="imbuementslot"[^/]*/>', '', content)
  open("data/items/items.xml", "w", encoding="utf-8").write(content)
  ```
  Validate XML parses correctly after running.

---

## Client Changes (`C:\Users\Pedro\Documents\tiablo\client`)

### Delete Entirely
- `data/modules/game_imbuing/` (entire directory: `imbuing.lua`, `imbuing.otui`, `imbuing.otmod`)
- `data/images/game/imbuing/` (entire directory)
- `data/modules/game_bot/default_configs/vBot_4.7/cavebot/imbuing.lua`

### Edit

**`data/modules/game_interface/interface.otmod`**:
- Remove `- game_imbuing` from `load-later` dependency list

**`data/modules/game_bot/bot.lua`**:
- Remove `onImbuementWindow = botImbuementWindow` from connect() calls (~lines 493, 561)
- Delete `botImbuementWindow()` function (~lines 750–753)

**`data/modules/game_bot/executor.lua`**:
- Remove `onImbuementWindow = {}` from callbacks table (~line 66)
- Remove `onImbuementWindow` callback handler block (~lines 253–256)

**`data/modules/game_bot/functions/callbacks.lua`**:
- Remove `context.onImbuementWindow()` function (~lines 178–181)

**`data/modules/game_bot/default_configs/vBot_4.7/cavebot/supply_check.lua`**:
- Remove `imbues.enabled` check (~line 97)

**`data/modules/game_bot/default_configs/vBot_4.7/vBot/supplies.lua`**:
- Remove `config.imbues` references (~lines 19, 192, 308–310, 461)

**`data/modules/game_bot/default_configs/vBot_4.7/vBot/supplies.otui`**:
- Remove `imbues` checkbox widget (~lines 166, 173)

### No Changes Needed
- `data/modules/game_protocol/protocol.lua` — inspection packet handler already discards imbuement data safely
- `data/modules/game_market/marketprotocol.lua` — reads version-gated data, safe as-is
- `data/modules/gamelib/market.lua` — `Imbuements = 16` filter is cosmetic only

---

## Compilation Pitfalls

1. After deleting the 4 core files, any TU that `#include`s them fails. Phases 3–16 fix all of these in dependency order.
2. **Do not remove `ATTR_IMBUEMENT_SLOT = 35`** from `items_definitions.hpp` — needed by the skip-and-discard serialization case in `item.cpp`.
3. **`criticalChance` config** — do not touch; it caps `SKILL_CRITICAL_HIT_CHANCE` in the wheel system.
4. After Phase 5 removes `ItemAttribute_t::IMBUEMENT_SLOT`, the `attribute.hpp` switch case must also be removed.
5. Two different enum values exist: `ATTR_IMBUEMENT_SLOT = 35` (serialization tag in `items_definitions.hpp`) and `ItemAttribute_t::IMBUEMENT_SLOT = 25` (runtime attribute in `enums/item_attribute.hpp`). Treat them independently.
6. Run `grep -r "g_imbuements()" src/` after all edits to catch any stragglers.

---

## Verification

1. **Compile**: `cmake --preset windows-release && cmake --build --preset windows-release` — zero errors
2. **Run server**: starts, loads items.xml without imbuements.xml reference, connects to DB
3. **Connect client**: log in, equip items, inspect — no imbuement slots, no imbuement UI, no crash
4. **Item look**: look at a weapon — no "Imbuement Slots:" line
5. **NPC shop**: sell/buy works normally
6. **Reload system**: `/reload items` works, no mention of imbuements
7. **Old character with imbued save data**: loads without errors, no imbuement info shown
8. **Client hot reload** (`Ctrl+Shift+R`): no Lua errors about missing modules
