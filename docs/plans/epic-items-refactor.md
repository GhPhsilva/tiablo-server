# Epic Items System Refactor — items.xml-driven

## Context

The current system stores epic item definitions in MySQL (`epic_items` table) and drives drops through a custom `EpicItems.onDropLoot()` callback gated by a global `epicItemMode` config. The new system:

- **Moves item definitions to `items.xml`**: each unidentified epic variant (e.g., "unidentified magic mace") is its own item ID with an `epic` attribute containing `rarity` and `epicname` sub-attributes
- **Drops via standard loot tables**: monster XML loot tables include the unidentified epic item IDs directly — no custom drop callback
- **Rarity baked into the item**: no more rarity-rolling at identify time; the item IS already "magic" or "rare" by its ID; modifiers/stat scale are still randomized within tier bounds

---

## Database Changes

### New migration: `data-otservbr-global/migrations/46.lua`

**DROP tables:**
- `epic_items_modifiers_epic_item_types` (junction — replaced by `applied_to_type` CSV)
- `epic_items` (replaced by items.xml)
- `epic_item_types` (no longer needed)

**ALTER `epic_items_rarity`:**
- DROP: `drop_chance`, `modifiers_count`
- ADD: `min_modifiers TINYINT UNSIGNED NOT NULL DEFAULT 0`
- ADD: `max_modifiers TINYINT UNSIGNED NOT NULL DEFAULT 0`
- Update seed: magic→(min_modifiers=1, max_modifiers=3), rare→(min_modifiers=2, max_modifiers=5)

**ALTER `epic_items_modifiers`:**
- DROP: `name`, `min_value`, `max_value`
- ADD: `label VARCHAR(32) NOT NULL DEFAULT ''` — short display name shown in look text (e.g., "Flaming", "Diamond")
- ADD: `description VARCHAR(255) NOT NULL DEFAULT ''` — full look text (e.g., "Adds 7% fire damage to attacks")
- ADD: `min_magic_value FLOAT NOT NULL DEFAULT 0`
- ADD: `max_magic_value FLOAT NOT NULL DEFAULT 0`
- ADD: `min_rare_value FLOAT NOT NULL DEFAULT 0`
- ADD: `max_rare_value FLOAT NOT NULL DEFAULT 0`
- ADD: `applied_to_type VARCHAR(255) NOT NULL DEFAULT ''` — comma-separated, e.g., `"club,sword,axe"`

Update seed rows for all 21 modifiers with new columns.

---

## C++ Changes (requires recompile)

### `src/items/items_definitions.hpp`
Add to `ItemParseAttributes_t` enum (before closing brace, after `ITEM_PARSE_SCRIPT`):
```cpp
ITEM_PARSE_EPIC,
```

### `src/items/items.hpp` — ItemType struct
Add after the existing bool fields (~line 372):
```cpp
bool epicItem = false;
std::string epicRarity;  // "magic" | "rare" | ""
std::string epicName;    // base name used in modifier-prefixed naming (e.g., "mace")
```

### `src/items/functions/item/item_parse.hpp`
1. Add to `ItemParseAttributesMap`:
   ```cpp
   { "epic", ITEM_PARSE_EPIC },
   ```
2. Add static method declaration to class `ItemParse`:
   ```cpp
   static void parseEpic(const std::string &tmpStrValue, pugi::xml_node attributeNode, ItemType &itemType);
   ```

### `src/items/functions/item/item_parse.cpp`
1. Add call in `initParse()` after `parseUnscriptedItems` (~line 80):
   ```cpp
   ItemParse::parseEpic(tmpStrValue, attributeNode, itemType);
   ```
2. Implement `parseEpic()` following `parseDummyRate()` pattern:
   - Check `tmpStrValue == "epic"`
   - Set `itemType.epicItem = true`
   - Iterate child `<attribute>` nodes, read `key` and `value`
   - `"rarity"` → `itemType.epicRarity`
   - `"epicname"` → `itemType.epicName`

### `src/lua/functions/items/item_type_functions.hpp` + `.cpp`
Add 4 Lua bindings (expose to ItemType metatable):
- `isEpic()` → `itemType->epicItem`
- `getEpicRarity()` → `itemType->epicRarity`
- `getEpicName()` → `itemType->epicName`
- `getPrimaryType()` → `itemType->m_primaryType` (currently unexposed)

### `src/config/config_enums.hpp`
Remove `EPIC_ITEM_MODE` enum value.

### `src/config/configmanager.cpp`
Remove the line:
```cpp
loadStringConfig(L, EPIC_ITEM_MODE, "epicItemMode", "normal");
```

### `src/enums/item_attribute.hpp`
Mark `EPIC_ITEM_ID = 36` as deprecated with a comment (keep value to avoid serialization break).

---

## items.xml New Entries

Add one entry per epic item per rarity tier. Example (using new IDs above current max):
```xml
<!-- Unidentified Magic Mace -->
<item id="NEWID1" article="a" name="unidentified magic mace">
    <attribute key="primarytype" value="club"/>
    <attribute key="weaponType" value="club"/>
    <attribute key="attack" value="16"/>
    <attribute key="defense" value="11"/>
    <attribute key="weight" value="3800"/>
    <attribute key="epic" value="true">
        <attribute key="rarity" value="magic"/>
        <attribute key="epicname" value="mace"/>
    </attribute>
    <attribute key="script" value="moveevent;weapon">
        <attribute key="weaponType" value="club"/>
        <attribute key="slot" value="hand"/>
    </attribute>
</item>
```

**Critical:** The `primarytype` value (e.g., `"club"`) must match the values used in `applied_to_type` in `epic_items_modifiers` exactly.

---

## Lua Changes

### `data/libs/systems/epic_items.lua` — Full rewrite

**New table structure:**
```lua
EpicItems = {
    rarities       = {},   -- [id]   = {id, name, code, min_increase, max_increase, color_name, min_modifiers, max_modifiers}
    raritiesByCode = {},   -- ["magic"] = rarity row
    modifiers      = {},   -- [id]   = {id, type, effect, effect_type, label, description,
                           --           min_magic_value, max_magic_value, min_rare_value, max_rare_value, applied_to_type}
}
```

**Keep:** `shuffleTable()` helper.

**Add:** `splitCSV(str)` helper — splits comma-separated string, trims whitespace.

**`EpicItems.init()`:** Load only rarities + modifiers (no epic_items/types tables). Build `raritiesByCode` index. Use counter vars for log (not `#table` on sparse tables).

**`EpicItems.identify(item, player)`** — new signature (no `epicRow`):
1. `local itemType = item:getType()`
2. `local rarity = EpicItems.raritiesByCode[itemType:getEpicRarity()]`
3. Base stats: `itemType:getAttack()`, `itemType:getDefense()`, `itemType:getArmor()`
4. Filter `EpicItems.modifiers` by checking `applied_to_type` CSV contains `itemType:getPrimaryType()`
5. Roll count: `math.random(rarity.min_modifiers, rarity.max_modifiers)`
6. Shuffle eligible mods, pick up to count (no type restriction — multiple mods of same type allowed)
7. Per-mod value range: use `min_magic_value/max_magic_value` for magic, `min_rare_value/max_rare_value` for rare; scale by `mult`
8. Name: strip `"unidentified "` prefix from item's current name (e.g., `"unidentified magic mace"` → `"magic mace"`)
9. Set: `ITEM_ATTRIBUTE_EPIC_ITEM_RARITY`, `ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED=1`, `ITEM_ATTRIBUTE_NAME`
10. Set stats: `ITEM_ATTRIBUTE_ATTACK`, `ITEM_ATTRIBUTE_DEFENSE`, `ITEM_ATTRIBUTE_ARMOR`
11. Set modifier attrs: `EPIC_MODIFIER_1_ID/VALUE` ... `EPIC_MODIFIER_3_ID/VALUE`
12. Build `ITEM_ATTRIBUTE_DESCRIPTION`: `"[Magic Epic Item]\n<mod.description>\n..."`
13. Set `ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX`
14. Return rarity

**Remove entirely:** `EpicItems.items`, `EpicItems.byLevel`, `EpicItems.typeModifiers`, `EpicItems.rollDrop()`, `EpicItems.createUnidentified()`, `EpicItems.onDropLoot()`, local `rollRarity()`.

### `data/scripts/actions/items/identify_rune.lua`
- Replace `target:hasAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID)` check with `target:getType():isEpic()`
- Remove epicRow lookup (`EpicItems.items[epicItemId]`)
- Call `EpicItems.identify(target, player)` (no epicRow param)

### `data/scripts/eventcallbacks/monster/ondroploot__base.lua`
- Remove all `epicMode` branching and `EpicItems.onDropLoot()` call
- Always run standard loot generation (factor + gut logic)

### `data/scripts/eventcallbacks/player/on_look.lua`
In the item branch, after `description = description .. thing:getDescription(distance)` (line 17), add:
```lua
local thingType = thing:getType()
if thingType:isEpic() and thing:getAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED) ~= 1 then
    description = description .. "\nThis item is unidentified. Use an identify rune to reveal its true power."
end
```

### `config.lua`
Remove `epicItemMode = "epic"` and its comment block (~line 551-553).

---

## Execution Order

| # | File | Action |
|---|------|--------|
| 1 | `migrations/46.lua` | New migration |
| 2 | `src/items/items_definitions.hpp` | Add `ITEM_PARSE_EPIC` |
| 3 | `src/items/items.hpp` | Add 3 fields to `ItemType` |
| 4 | `src/items/functions/item/item_parse.hpp` | Map entry + method decl |
| 5 | `src/items/functions/item/item_parse.cpp` | `initParse()` call + `parseEpic()` impl |
| 6 | `src/lua/functions/items/item_type_functions.hpp` | 4 method decls |
| 7 | `src/lua/functions/items/item_type_functions.cpp` | 4 Lua binding impls |
| 8 | `src/config/config_enums.hpp` | Remove `EPIC_ITEM_MODE` |
| 9 | `src/config/configmanager.cpp` | Remove epicItemMode load |
| 10 | `src/enums/item_attribute.hpp` | Deprecation comment on `EPIC_ITEM_ID` |
| 11 | **Compile** | Verify no errors |
| 12 | `data/items/items.xml` | Add epic item entries |
| 13 | `data/libs/systems/epic_items.lua` | Full rewrite |
| 14 | `data/scripts/actions/items/identify_rune.lua` | Update checks |
| 15 | `data/scripts/eventcallbacks/monster/ondroploot__base.lua` | Remove epicMode |
| 16 | `data/scripts/eventcallbacks/player/on_look.lua` | Add unidentified hint |
| 17 | `config.lua` | Remove epicItemMode |

**Note:** Steps 8–9 (C++) and step 15 (Lua) must be deployed together — `configKeys.EPIC_ITEM_MODE` is referenced in `ondroploot__base.lua` and removing it from C++ without updating the Lua file causes a load-time error.

---

## Pitfalls to Avoid

1. **`applied_to_type` must match `primarytype` exactly** — if items.xml uses `"club weapons"` but modifiers use `"club"`, filtering yields no eligible modifiers silently. Standardize both sides before seeding.

2. **Name is derived from the XML item name** — after identification, `"unidentified magic mace"` → `"magic mace"` by stripping the `"unidentified "` prefix. No custom name building needed. The `label` column is only used in look description text.

3. **Log counter for sparse tables** — `#EpicItems.rarities` is undefined on integer-keyed sparse tables. Use explicit counters in `init()`.

4. **`m_primaryType` not yet exposed to Lua** — `getPrimaryType()` binding is new; must be registered in the ItemType metatable.

5. **Do NOT delete** `ondroploot__epic.lua` or `on_spawn__epic.lua` — these belong to the `EpicMonster` system (epic monster variants), not the Epic Items drop system.

---

## Verification

1. Run migration 46 — verify all three tables dropped, rarity/modifier tables altered
2. Compile C++ — zero errors/warnings on item_parse and item_type_functions
3. Add a test epic item to items.xml, start server — verify no XML parse errors and `itemType:isEpic()` returns true in Lua console
4. Add the test item to a monster's loot table, kill monster — verify unidentified epic item drops
5. Use identify rune on unidentified item — verify modifier text, scaled stats, description in look
6. Try to equip unidentified item — verify equip blocked (weapon moveevent script must check `item:getType():isEpic() and item:getAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED) ~= 1`)
7. Look at identified item — verify `[Magic Epic Item]` + modifier descriptions in look text
