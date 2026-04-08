# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Canary**, an open-source MMORPG server emulator (based on OpenTibiaBR) written in C++ with extensive Lua scripting support. It implements the Tibia client protocol (version 1332).

- Server version: 3.1.2
- Upstream: https://github.com/opentibiabr/canary

## Build Commands

Prerequisites: CMake 3.22+, Ninja, vcpkg (with `VCPKG_ROOT` set), Visual Studio (Windows) or GCC/Clang (Linux).

```bash
# Linux Release
cmake --preset linux-release
cmake --build linux-release

# Linux Debug (with ASAN)
cmake --preset linux-debug
cmake --build linux-debug

# Linux with tests
cmake --preset linux-test
cmake --build linux-test

# Windows Release
cmake --preset windows-release
cmake --build --preset windows-release

# Quick rebuild helper
./recompile.sh /path/to/vcpkg linux-release
```

Presets are defined in `CMakePresets.json`. Dependencies are managed via `vcpkg.json`.

## Running the Server

```bash
./start.sh [path_to_binary]
```

The script creates `logs/`, copies `config.lua` if missing, and starts the binary with graceful shutdown on `q`. Edit `config.lua` for server name, ports, DB connection, rates, etc.

## Tests

Framework: **Boost::ut** (header-only, macro-free). Tests live in `tests/unit/` and `tests/integration/`.

```bash
# Run all tests
ctest --verbose

# Unit tests only
ctest -R unit --verbose

# Integration tests only
ctest -R integration --verbose

# Run binary directly
./linux-test/tests/unit/canary_ut
./linux-test/tests/integration/canary_it
```

Integration tests require a real database (no mocks). See `tests/README.md` for fixture/DI patterns.

## Architecture

### Entry Point & DI
- `src/main.cpp` — bootstraps Boost.DI container
- `src/canary_server.hpp/cpp` — `CanaryServer` class orchestrates initialization
- `src/lib/di/` — dependency injection bindings
- `src/pch.hpp` — precompiled header (include all heavy headers here)

### Core Subsystems

| Directory | Responsibility |
|---|---|
| `src/creatures/` | Players, NPCs, monsters, combat, AI |
| `src/game/` | Core game loop, scheduling, zones, bank |
| `src/items/` | Item system, containers, weapons, decay |
| `src/map/` | World map, houses, pathfinding |
| `src/lua/` | Lua VM integration, callbacks, script loader |
| `src/server/network/` | ASIO networking, Tibia protocol implementation |
| `src/database/` | MySQL/MariaDB abstraction layer |
| `src/io/` | File I/O and Lua I/O bindings |
| `src/kv/` | In-memory key-value store |
| `src/lib/` | Logging (spdlog), threading, metrics (OpenTelemetry), messaging |
| `src/security/` | RSA encryption for login |
| `src/config/` | `config.lua` parsing and typed access |

### Lua Scripting
The server exposes C++ functionality to Lua via bindings in `src/lua/functions/`. Game content lives in:
- `data/` — core scripts, events, NPC lib, items, XML definitions
- `data-otservbr-global/` — OTServBR community content package

Lua hooks into events, creature callbacks, item interactions, and module systems.

### Database
MySQL/MariaDB. Schema: `schema.sql` (fresh install) or `otserv.sql` (full dump with default data). Default credentials in `config.lua`: host `localhost`, user/db `otserver`.

### Networking
- Login server: port 7171
- Game server: port 7172
- Uses ASIO for async I/O; custom Tibia binary protocol with RSA + XTEA encryption

### Metrics
Optional OpenTelemetry export via Prometheus or OStream exporters. Config in `config.lua` under metrics section. Grafana dashboards in `metrics/`.

## Custom Additions

### Belt Slot (`CONST_SLOT_BELT = 12`)

A new equipment slot added after `CONST_SLOT_STORE_INBOX = 11`. It is the last slot (`CONST_SLOT_LAST = CONST_SLOT_BELT`).

- **Enum**: `CONST_SLOT_BELT = 12` in `src/creatures/creatures_definitions.hpp`
- **Bit flag**: `SLOTP_BELT = 1 << 12` in `src/items/items_definitions.hpp`
- **Item type**: `ITEM_TYPE_BELT` — set via `<attribute key="type" value="belt"/>` in XML
- **Slot type**: set via `<attribute key="slotType" value="belt"/>` in XML
- **Included in `armorSlots[]`** — belt abilities (armor, absorbPercent, etc.) are applied in combat
- **No DB migration required** — `player_items` stores slots as dynamic rows; `sid=12` is simply a new row.
- **Plan**: `docs/plans/server-belt-slot.md`

## Extended Opcodes (Server → Client Communication)

Extended opcodes allow the server to send custom data to OTClient via byte `0x32`. They only work when the client has `GameExtendedOpcode` enabled (set in `data/modules/game_features/features.lua`).

### Sending from Server

Use `Player.sendExtendedOpcode(opcode, buffer)` defined in `data/libs/functions/player.lua:55`:

```lua
player:sendExtendedOpcode(100, "O" .. jsonString)
```

**Critical:** this function silently returns `false` if `player:isUsingOtClient()` is false (i.e., `player:getClient().os < CLIENTOS_OTCLIENT_LINUX` which is 10). OTClientV8 reports `os=20` (`CLIENTOS_OTCLIENTV8_LINUX`), which passes the check. Always verify with a log when debugging:

```lua
print("os=" .. player:getClient().os .. " isOtClient=" .. tostring(player:isUsingOtClient()))
```

### Buffer Format Convention

The first character of the buffer is a status prefix used by the client's JSON opcode system:
- `"O"` — single complete message (most common)
- `"S"` / `"P"` / `"E"` — start / part / end of chunked messages

Always prefix with `"O"` for single-packet JSON payloads:

```lua
player:sendExtendedOpcode(Waypoints.OPCODE, "O" .. json)
```

### Receiving on Server (Client → Server)

Register a `CreatureEvent` with `onExtendedOpcode`:

```lua
local handler = CreatureEvent("MyOpcode")
function handler.onExtendedOpcode(player, opcode, buffer)
    if opcode ~= MY_OPCODE then return end
    local action = buffer:match('"action"%s*:%s*"([^"]+)"')
    -- handle action
end
handler:register()
```

Register the event for the player on login:

```lua
player:registerEvent("MyOpcode")
```

### Timing: Do NOT send on login

Sending extended opcodes directly in `onLogin` causes them to arrive **before the client has re-initialized its modules** (the "All modules and scripts were reloaded" message). The opcode will be dropped.

**Correct pattern:** client requests data after `onGameStart` fires:
- Client: on `onGameStart`, send `{"action":"request"}` via `sendExtendedOpcode`
- Server: handle `action == "request"`, then send the data

```lua
-- server: waypoints_opcode.lua
if action == "request" then
    Waypoints.sendToPlayer(player)
    return
end
```

### JSON Escaping

Always escape strings before inserting into JSON manually:

```lua
local function jsonEscape(s)
    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '')
end
```

### Waypoints System Reference

Implementation files:
- `data/libs/systems/waypoints.lua` — `Waypoints.sendToPlayer`, `Waypoints.unlock`, `Waypoints.teleport`
- `data/scripts/creaturescripts/player/waypoints_opcode.lua` — receives client opcodes (request, teleport)
- `data/scripts/migrations/waypoints_migration.lua` — creates `waypoints` + `player_waypoints` tables
- `data/scripts/migrations/20260407000001_waypoints_add_category_image.lua` — adds `category` + `image` columns
- `data/scripts/actions/objects/waypoint.lua` — item 8836 unlocks a waypoint (`uid` = waypoint id)

DB schema:
```sql
waypoints: id, name, x, y, z, description, category VARCHAR(50), image VARCHAR(255)
player_waypoints: player_id, waypoint_id
```

## Critical Hit System

### Critical Hit Chance (Weapon Skill Based)

Critical hit chance is derived from the player's active weapon skill, not from `SKILL_CRITICAL_HIT_CHANCE` (which is never trained). The formula is applied in `src/creatures/combat/combat.cpp` → `Combat::applyExtensions()`.

**Formula**: `weaponCritChance = min(skillLevel * 25, 5000)` (internal unit: 10000 = 100%)

| Skill level | Crit chance |
|---|---|
| 10 | 2.5% |
| 100 | 25.0% |
| 200 | 50.0% (cap) |

**Weapon → skill mapping** (via `player->getWeaponSkill(item)`):
- Sword/Axe/Club → respective melee skill
- Bow/Crossbow/Spear/Throwing knife (`WEAPON_DISTANCE`/`WEAPON_MISSILE`) → `SKILL_DISTANCE`
- Wand (`WEAPON_WAND`) → `getMagicLevel()`
- No weapon → `SKILL_FIST`

Item bonuses from `SKILL_CRITICAL_HIT_CHANCE` (via `varSkills`) stack on top.

### Critical Hit Damage

**Base damage**: stored in `skill_critical_hit_damage` DB column (default `5000` = 50%). The base is no longer hardcoded — it lives in the database.

- Migration `20260408000001_crit_damage_base_to_db.lua` sets all existing players to `5000` and changes the column DEFAULT to `5000` so new characters start with it automatically.
- `combat.cpp` → `applyExtensions()`: `bonus = player->getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE)` — no hardcoded addition.

**Stack**: item bonuses (`criticalhitdamage` attribute in XML, internal unit 10000 = 100%) add on top via `varSkills`, which is included in `getSkillLevel()`.

**Multiplier formula**: `1.0 + getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE) / 10000`
- No extra items (DB = 5000): `×1.5` (+50%)
- DB 5000 + item 2500: `×1.75` (+75%)
- DB 5000 + item 3500: `×1.85` (+85%)

### Protocol & Client Display

`AddPlayerSkills` (`src/server/network/protocol/protocolgame.cpp`) sends `getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE)` directly (the base is already in the skill level). `sendSkills()` is called on item equip/de-equip so the display updates automatically.

Client (`data/modules/game_skills/skills.lua` → `onSkillChange`) formats both as `"X.XX%"` by dividing the internal value by 100.

## Life Leech System

### Life Leech Chance (Weapon Skill Based)

Life leech chance is derived from the player's active weapon skill. The formula is applied in `src/game/game.cpp` → `Game::applyLifeLeech()`, before the chance roll.

**Formula**: `weaponLeechBonus = min(skillLevel, 250)` (internal scale: 0–1000, 0.1% per unit)

| Skill level | Life leech chance |
|---|---|
| 10 | 1.0% |
| 50 | 5.0% |
| 100 | 10.0% |
| 200 | 20.0% |
| 250 | 25.0% (cap) |

**Weapon → skill mapping** (via `player->getWeaponSkill(item)`):
- Sword/Axe/Club → respective melee skill
- Bow/Crossbow/Spear/Throwing knife (`WEAPON_DISTANCE`/`WEAPON_MISSILE`) → `SKILL_DISTANCE`
- Wand (`WEAPON_WAND`) → **no bonus** (returns 0; wands do not contribute to life leech)
- No weapon → `SKILL_FIST`

Item bonuses from `SKILL_LIFE_LEECH_CHANCE` (via `varSkills`, e.g. imbuements) stack on top.

### Life Leech Scales

| Skill | DB/item scale | Internal roll scale | DB column |
|---|---|---|---|
| `SKILL_LIFE_LEECH_CHANCE` (9) | 0–100 | 0–1000 (×10) | `skill_life_leech_chance` |
| `SKILL_LIFE_LEECH_AMOUNT` (10) | 0–10000 | 0–10000 | `skill_life_leech_amount` |

The chance roll is `normal_random(0, 1000) >= lifeChance`. Item/wheel values are multiplied by 10 when combining. Weapon bonus is added directly (already in 0–1000 scale). Amount uses 10000 = 100% of damage healed.

### Protocol & Client Display

`AddPlayerSkills` (`src/server/network/protocol/protocolgame.cpp`) computes `effectiveLifeLeechChanceDisplay` (base × 10 + weapon skill bonus) and sends it.

Client (`data/modules/game_skills/skills.lua` → `onSkillChange`) formats:
- `Skill.LifeLeechChance` (9): `string.format("%.2f%%", level / 10)` — divide by 10 (internal scale 0–1000)
- `Skill.LifeLeechAmount` (10): `string.format("%.2f%%", level / 100)` — divide by 100 (scale 0–10000)

### Testing Notes

- Life leech heals the attacker — if HP is already at max, no change is visible.
- Use `UPDATE players SET skill_life_leech_chance = 100, skill_life_leech_amount = 10000 WHERE name = '...'` to test at 100% chance and 100% amount, then reconnect.
- Reduce HP via Lua (`player:addHealth(-5000)`) before attacking to see the heal.
- Shows `CONST_ME_MAGIC_RED` effect on attacker when it procs.

## Mana Leech System

### Mana Leech Chance (Weapon Skill Based)

Mana leech chance is derived from the player's active weapon skill. The formula is applied in `src/game/game.cpp` → `Game::applyManaLeech()`, before the chance roll.

**Formula**: `weaponLeechBonus = min(skillLevel, 250)` (internal scale: 0–1000, 0.1% per unit)

| Skill level | Mana leech chance |
|---|---|
| 10 | 1.0% |
| 50 | 5.0% |
| 100 | 10.0% |
| 200 | 20.0% |
| 250 | 25.0% (cap) |

**Weapon → skill mapping**:
- Wand (`WEAPON_WAND`) → `getMagicLevel()` — only wands contribute
- All other weapons (melee, distance, no weapon) → **no bonus**

Item bonuses from `SKILL_MANA_LEECH_CHANCE` (via `varSkills`, e.g. imbuements) stack on top.

### Mana Leech Scales

| Skill | DB/item scale | Internal roll scale | DB column |
|---|---|---|---|
| `SKILL_MANA_LEECH_CHANCE` (11) | 0–100 | 0–1000 (×10) | `skill_mana_leech_chance` |
| `SKILL_MANA_LEECH_AMOUNT` (12) | 0–10000 | 0–10000 | `skill_mana_leech_amount` |

The chance roll is `normal_random(0, 1000) >= manaChance`. Same scaling as life leech.

### Protocol & Client Display

`AddPlayerSkills` (`src/server/network/protocol/protocolgame.cpp`) computes `effectiveManaLeechChanceDisplay` (base × 10 + weapon/magic level bonus) and sends it. Wands use magic level for display.

Client (`data/modules/game_skills/skills.lua` → `onSkillChange`) formats:
- `Skill.ManaLeechChance` (11): `string.format("%.2f%%", level / 10)` — divide by 10
- `Skill.ManaLeechAmount` (12): `string.format("%.2f%%", level / 100)` — divide by 100

### Testing Notes

- Mana leech restores attacker mana — visible even at full HP.
- Use `UPDATE players SET skill_mana_leech_chance = 100, skill_mana_leech_amount = 10000 WHERE name = '...'` then reconnect.
- Shows `CONST_ME_MAGIC_BLUE` effect on attacker when it procs.

## Weapon Skill Calculation Pitfall

### `getWeapon()` vs `getWeapon(true)` for Distance Weapons

`Player::getWeapon()` (ignoreAmmo=false) for bows/crossbows returns the **ammo item** (arrow/bolt) from the quiver, not the bow itself. Without a quiver it returns `nullptr`. This means:

- `getWeaponSkill(ammoItem)` → hits `default` case → returns `0`
- `getWeaponSkill(nullptr)` → returns `SKILL_FIST`

**Rule**: always use `getWeapon(true)` (ignoreAmmo=true) when the goal is to determine the **weapon type/skill** for crit or leech calculations. Use `getWeapon()` only for actual damage calculations where the ammo item is needed.

Affected locations (all use `getWeapon(true)`):
- `src/creatures/combat/combat.cpp` → `applyExtensions()` — crit chance weapon skill
- `src/game/game.cpp` → `applyLifeLeech()` — life leech chance weapon skill
- `src/game/game.cpp` → `applyManaLeech()` — mana leech chance weapon skill
- `src/server/network/protocol/protocolgame.cpp` → `AddPlayerSkills()` — crit, life leech, mana leech display (three calls)

## Code Style

Formatting is enforced via `.clang-format` (4-space indent, C++17 style). Run `clang-format` before committing. Lua style via `.luarc.json`.
