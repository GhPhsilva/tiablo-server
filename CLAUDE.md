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

## Code Style

Formatting is enforced via `.clang-format` (4-space indent, C++17 style). Run `clang-format` before committing. Lua style via `.luarc.json`.
