# Extended Opcodes (Server ↔ Client)

Extended opcodes send custom data to OTClient via byte `0x32`. Requires `GameExtendedOpcode` in `data/modules/game_features/features.lua`.

## Sending from Server

```lua
player:sendExtendedOpcode(100, "O" .. jsonString)
```

Defined in `data/libs/functions/player.lua:55`. Silently returns `false` if `player:isUsingOtClient()` is false. OTClientV8 reports `os=20` (`CLIENTOS_OTCLIENTV8_LINUX`), which passes.

## Buffer Prefix

- `"O"` — single complete message
- `"S"` / `"P"` / `"E"` — start / part / end of chunked messages

## Receiving on Server

```lua
local handler = CreatureEvent("MyOpcode")
function handler.onExtendedOpcode(player, opcode, buffer)
    if opcode ~= MY_OPCODE then return end
    local action = buffer:match('"action"%s*:%s*"([^"]+)"')
end
handler:register()
-- register in onLogin:
player:registerEvent("MyOpcode")
```

## Timing: Do NOT send on login

Send on `onLogin` arrives before client re-initializes modules — opcode is dropped.

**Correct pattern**: client requests on `onGameStart`:
```lua
if action == "request" then
    MySystem.sendToPlayer(player)
end
```

## JSON Escaping

```lua
local function jsonEscape(s)
    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '')
end
```

## Waypoints System

- `data/libs/systems/waypoints.lua` — `Waypoints.sendToPlayer`, `Waypoints.unlock`, `Waypoints.teleport`
- `data/scripts/creaturescripts/player/waypoints_opcode.lua` — handles request/teleport opcodes
- `data/scripts/migrations/waypoints_migration.lua` — creates `waypoints` + `player_waypoints` tables
- `data/scripts/migrations/20260407000001_waypoints_add_category_image.lua` — adds `category` + `image` columns
- `data/scripts/actions/objects/waypoint.lua` — item 8836 unlocks waypoint by `uid`

DB schema: `waypoints(id, name, x, y, z, description, category, image)`, `player_waypoints(player_id, waypoint_id)`
