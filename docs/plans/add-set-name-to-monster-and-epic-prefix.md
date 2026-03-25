# Plan: Add setName to Monster + Apply Prefix in Epic System

## Context
The `Monster` class is missing `setName()` (NPC and Player both have it). The epic monster system already loads prefixes from the DB into `EpicMonster.prefixes`, but never uses them because `monster:setName()` didn't exist. This plan adds the C++ method and wires up the prefix in the Lua system.

---

## C++ Changes

### 1. Add `setName()` to Monster class
**File:** `src/creatures/monsters/monster.hpp`

After `getName()` (~line 48), add:
```cpp
void setName(const std::string &newName) {
    mType->name = newName;
}
```

### 2. Declare Lua binding
**File:** `src/lua/functions/creatures/monster/monster_functions.hpp`

Add static declaration and register the method alongside `luaMonsterGetName`:
```cpp
static int luaMonsterSetName(lua_State* L);
// ...
registerMethod(L, "Monster", "setName", MonsterFunctions::luaMonsterSetName);
```

### 3. Implement Lua binding
**File:** `src/lua/functions/creatures/monster/monster_functions.cpp`

After `luaMonsterGetName`, add (mirrors `NpcFunctions::luaNpcSetName`):
```cpp
int MonsterFunctions::luaMonsterSetName(lua_State* L) {
    // monster:setName(name)
    const auto monster = getUserdataShared<Monster>(L, 1);
    if (!monster) {
        reportErrorFunc(getErrorDesc(LUA_ERROR_MONSTER_NOT_FOUND));
        lua_pushnil(L);
        return 1;
    }
    monster->setName(getString(L, 2));
    pushBoolean(L, true);
    return 1;
}
```

---

## Lua Change

### 4. Apply prefix in `applyEpic()`
**File:** `data/libs/systems/epic_monsters.lua`

At the **end of `applyEpic()`** (before `return true`), add:
```lua
-- ── Prefix ────────────────────────────────────────────────────────────
if #EpicMonster.prefixes > 0 then
    local prefix = EpicMonster.prefixes[math.random(#EpicMonster.prefixes)]
    monster:setName(prefix .. " " .. monster:getName())
end
```

This picks a random enabled prefix from the DB and sets the monster's name to `"<Prefix> <OriginalName>"` (e.g. `"Cursed Demon"`).

---

## Recompile (Windows)
Reference: `docs\Compiling-on-Windows-(CMake).md`

1. Open **Visual Studio**
2. "Get started" → **Open a local folder** → select server root
3. Wait for CMake cache to generate
4. **Build → Build All**

---

## Verification
```lua
-- Admin command: /em Demon
-- Expected: monster appears as "Cursed Demon" (or any random prefix)
local monster = Monster(uid)
print(monster:getName())  -- e.g. "Forsaken Rat"
```
