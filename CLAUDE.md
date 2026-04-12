# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Canary** — open-source MMORPG server emulator (OpenTibiaBR based), C++ + Lua, Tibia protocol 1332.
Server version 3.1.2. Upstream: https://github.com/opentibiabr/canary

## Build Commands

```bash
cmake --preset linux-release && cmake --build linux-release
cmake --preset linux-debug  && cmake --build linux-debug
cmake --preset linux-test   && cmake --build linux-test
cmake --preset windows-release && cmake --build --preset windows-release
./recompile.sh /path/to/vcpkg linux-release   # quick rebuild
```

Presets: `CMakePresets.json`. Dependencies: `vcpkg.json` (requires `VCPKG_ROOT`).

## Running & Tests

```bash
./start.sh [binary]           # creates logs/, copies config.lua, graceful shutdown on q
ctest --verbose               # all tests
ctest -R unit --verbose       # unit only
ctest -R integration --verbose # integration (requires real DB, no mocks)
```

## Architecture

| Directory | Responsibility |
|---|---|
| `src/creatures/` | Players, NPCs, monsters, combat, AI |
| `src/game/` | Core game loop, scheduling, zones, bank |
| `src/items/` | Item system, containers, weapons, decay |
| `src/map/` | World map, houses, pathfinding |
| `src/lua/` | Lua VM, callbacks, script loader |
| `src/server/network/` | ASIO networking, Tibia protocol |
| `src/database/` | MySQL/MariaDB abstraction |
| `src/config/` | `config.lua` parsing |
| `data/` | Lua scripts, NPC lib, items, XML definitions |
| `data-otservbr-global/` | OTServBR community content |

Entry: `src/main.cpp` → Boost.DI container → `src/canary_server.hpp`. Precompiled header: `src/pch.hpp`.
DB: `schema.sql` (fresh) or `otserv.sql` (full dump). Ports: login 7171, game 7172.

## Custom Additions

### Belt Slot (`CONST_SLOT_BELT = 12`)
- Enum: `src/creatures/creatures_definitions.hpp`
- Bit flag: `SLOTP_BELT = 1 << 12` in `src/items/items_definitions.hpp`
- XML: `<attribute key="type" value="belt"/>` / `<attribute key="slotType" value="belt"/>`
- Included in `armorSlots[]` — belt stats applied in combat
- No DB migration — `player_items` uses dynamic rows (`sid=12`)
- Plan: `docs/plans/server-belt-slot.md`

## Related Projects

| Project | CLAUDE.md |
|---|---|
| OTClientV8 (client) | `C:\Users\Pedro\Documents\tiablo\client\CLAUDE.md` |

## System Documentation

Detailed docs for custom game systems:

| System | Doc |
|---|---|
| Extended Opcodes (server↔client, waypoints) | `docs/systems/extended-opcodes.md` |
| Critical Hit (chance + damage) | `docs/systems/critical-hit.md` |
| Life Leech & Mana Leech | `docs/systems/leech.md` |
| Bonus Attack Speed (opcode 101) | `docs/systems/attack-speed.md` |

**Key pitfall**: always use `getWeapon(true)` (ignoreAmmo) for crit/leech/display — see `docs/systems/leech.md`.

## Code Style

`.clang-format` (4-space indent, C++17). Run `clang-format` before committing. Lua: `.luarc.json`.

## MCP Tools: code-review-graph

**IMPORTANT: ALWAYS use code-review-graph MCP tools BEFORE Grep/Glob/Read.**

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — risk-scored analysis |
| `get_review_context` | Source snippets for review — token-efficient |
| `get_impact_radius` | Blast radius of a change |
| `get_affected_flows` | Which execution paths are impacted |
| `query_graph` | Trace callers, callees, imports, tests |
| `semantic_search_nodes` | Find functions/classes by name or keyword |
| `get_architecture_overview` | High-level codebase structure |
| `refactor_tool` | Plan renames, find dead code |

Workflow: graph auto-updates on file changes. Use `detect_changes` for review → `get_affected_flows` for impact → `query_graph pattern="tests_for"` for coverage.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
