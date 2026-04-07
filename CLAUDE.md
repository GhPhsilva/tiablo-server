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

## Code Style

Formatting is enforced via `.clang-format` (4-space indent, C++17 style). Run `clang-format` before committing. Lua style via `.luarc.json`.
