# Plan: Diablo 2-Inspired MySQL Item System Migration

## Context

The server currently loads all item definitions from `data/items/items.xml` (~75,870 lines) into a `std::vector<ItemType>` at startup. The goal is to migrate this to MySQL tables, enabling a Diablo 2-style item system with dynamic rarity, per-item rolled abilities, unidentified item mechanics, and a monster-level-based dynamic drop system.

**Key invariant:** The client only receives item IDs over the network and renders items using its own `appearances.dat`. Removing items.xml has zero impact on client-side rendering. RME (Remere's Map Editor) uses its own copy of items.xml — the server has no reference to it.

**Architecture preserved:** The in-memory `std::vector<ItemType> Items::items` vector stays intact. Only its data source changes (XML → MySQL). All 200+ call sites using `Item::items[id]` remain untouched.

---

## Phase 1: Database Schema (Migration 45.lua)

### `item_rarity`
```sql
CREATE TABLE `item_rarity` (
    `id`              TINYINT UNSIGNED  NOT NULL,
    `name`            VARCHAR(32)       NOT NULL,
    `code`            VARCHAR(32)       NOT NULL,
    `abilities_count` TINYINT UNSIGNED  NOT NULL DEFAULT 1,
    `min_increase`    FLOAT             NOT NULL DEFAULT 1.0,
    `max_increase`    FLOAT             NOT NULL DEFAULT 1.0,
    `color_name`      VARCHAR(32)       NOT NULL DEFAULT 'white',
    `is_identified`   TINYINT(1)        NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`), UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB;
-- Seed: (1,Normal,normal,1,1.0,1.0,white,0), (2,Magic,magic,1,1.1,1.3,blue,1), (3,Rare,rare,1,1.3,1.5,yellow,1)
```

### `item_habilities`
```sql
CREATE TABLE `item_habilities` (
    `id`          SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type`        ENUM('attack','defense','support') NOT NULL,
    `effect`      VARCHAR(64) NOT NULL,
    `name`        VARCHAR(64) NOT NULL,
    `effect_type` ENUM('fixed','percent') NOT NULL DEFAULT 'fixed',
    `min_value`   FLOAT NOT NULL DEFAULT 0,
    `max_value`   FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`), UNIQUE KEY `effect` (`effect`)
) ENGINE=InnoDB;
-- Seeded with all 21 abilities:
-- (1,'attack','ADD_COLD_DAMAGE','Shivering','percent',1,10)
-- (2,'attack','ADD_FIRE_DAMAGE','Flaming','percent',1,10)
-- (3,'attack','ADD_LIGHTNING_DAMAGE','Shocking','percent',1,10)
-- (4,'attack','ADD_POISON_DAMAGE','Toxic','percent',1,10)
-- (5,'attack','ADD_HOLY_DAMAGE','Holy','percent',1,10)
-- (6,'attack','ADD_DARKNESS_DAMAGE','Cursed','percent',1,10)
-- (7,'attack','ADD_PHYSICAL_DAMAGE','Savage','percent',1,10)
-- (8,'defense','ADD_PHYSICAL_DEFENSE','Diamond','fixed',1,15)
-- (9,'defense','ADD_FIRE_RESISTENCE','Ruby','percent',1,10)
-- (10,'defense','ADD_COLD_RESISTENCE','Sapphire','percent',1,10)
-- (11,'defense','ADD_LIGHTNING_RESISTENCE','Amber','percent',1,10)
-- (12,'defense','ADD_POISON_RESISTENCE','Jade','percent',1,10)
-- (13,'defense','ADD_HOLY_RESISTENCE','Topaz','percent',1,10)
-- (14,'defense','ADD_DARKNESS_RESISTENCE','Sacred','percent',1,10)
-- (15,'support','ADD_DROP_CHANCE','Fortuitous','fixed',1,5)
-- (16,'support','ADD_MAX_LIFE','Tiger','percent',1,5)
-- (17,'support','ADD_LIFE_STEAL','Vampire','percent',1,5)
-- (18,'support','ADD_MANA_STEAL','Wraith','percent',1,5)
-- (19,'support','ADD_ATTACK_SPEED','Swiftness','percent',1,10)
-- (20,'support','ADD_MOVEMENT_SPEED','Haste','fixed',10,20)
-- (21,'support','ADD_MAX_MANA','Snake','percent',1,5)
```

### `item_types` (replaces items.xml)

All existing `ItemType` fields as columns. Array fields (absorbPercent[14], skills[15], stats[6], etc.) stored as **JSON columns** to avoid a very wide table. Parsed once at startup.

Key columns beyond existing ItemType fields:
- `min_monster_level SMALLINT UNSIGNED` — minimum monster level to drop this item
- `max_monster_level SMALLINT UNSIGNED` — maximum monster level to drop this item
- `base_drop_chance FLOAT` — base drop probability (0.0–1.0)
- `script_path VARCHAR(255)` — path to associated Lua script (was embedded in XML)

JSON columns (parsed once at startup, no per-request cost):
- `absorb_percent` — int array[14] mapped to COMBAT_COUNT indices
- `field_absorb_percent` — int array[14]
- `reflect_percent` — int array[14]
- `reflect_flat` — int array[14]
- `specialized_magic_level` — int array[14]
- `stats` — int array[6] for STAT_LAST+1
- `stats_percent` — int array[6]
- `skills_ability` — int array[15] for SKILL_LAST+1
- `condition_immunities`, `condition_suppressions` — bitmask arrays
- `imbuement_types` — map of imbuement type → tier

### `item_habilities_item_type`
```sql
CREATE TABLE `item_habilities_item_type` (
    `id`               INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `item_hability_id` SMALLINT UNSIGNED NOT NULL,
    `id_item_type`     SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `hability_item` (`item_hability_id`, `id_item_type`),
    KEY `item_type_idx` (`id_item_type`),
    FOREIGN KEY (`item_hability_id`) REFERENCES `item_habilities` (`id`),
    FOREIGN KEY (`id_item_type`) REFERENCES `item_types` (`id`)
) ENGINE=InnoDB;
```

### `item_hability_item_rarity`
```sql
CREATE TABLE `item_hability_item_rarity` (
    `id`               INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `item_hability_id` SMALLINT UNSIGNED NOT NULL,
    `rarity_id`        TINYINT UNSIGNED  NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `hability_rarity` (`item_hability_id`, `rarity_id`),
    FOREIGN KEY (`item_hability_id`) REFERENCES `item_habilities` (`id`),
    FOREIGN KEY (`rarity_id`) REFERENCES `item_rarity` (`id`)
) ENGINE=InnoDB;
```

### Player column
```sql
ALTER TABLE `players` ADD `drop_chance_bonus` FLOAT NOT NULL DEFAULT 0.0;
```

**Migration file:** `data-otservbr-global/migrations/45.lua`

---

## Phase 2: One-Time XML → MySQL Migration

Write `tools/migrate_items_xml.py` (Python script):
1. Parses `data/items/items.xml` with ElementTree
2. Maps every XML attribute to the correct `item_types` column (mirrors `ItemParse::initParse` logic)
3. Packs array fields (absorbPercent, skills, stats, etc.) as JSON arrays
4. Does `INSERT INTO item_types ... ON DUPLICATE KEY UPDATE`
5. Does **not** delete `items.xml` — kept for RME compatibility

Runtime: ~60 seconds for ~10,000 items.

**Verification:** `SELECT COUNT(*), SUM(attack), SUM(armor) FROM item_types` should match totals computed from the XML.

---

## Phase 3: C++ Changes

### 3.1 New ItemAttribute_t values
File: `src/enums/item_attribute.hpp` — add after value 35:

```
ITEM_RARITY       = 36   // uint8_t — maps to item_rarity.id
ITEM_IDENTIFIED   = 37   // bool
HABILITY_1_ID     = 38   // uint16_t — ability id (attack slot)
HABILITY_1_VALUE  = 39   // int32_t  — rolled value
HABILITY_2_ID     = 40   // defense slot id
HABILITY_2_VALUE  = 41   // defense slot value
HABILITY_3_ID     = 42   // support slot id
HABILITY_3_VALUE  = 43   // support slot value
```

Uses the existing BLOB serialization pipeline — no new binary format needed. Mirrors how imbuement slots are stored today.

### 3.2 New structs
New file: `src/items/item_rarity.hpp`

```cpp
struct ItemRarity {
    uint8_t  id = 0;
    std::string name, code, colorName;
    uint8_t  abilitiesCount = 1;
    float    minIncrease = 1.0f, maxIncrease = 1.0f;
    bool     isIdentified = false;
};

struct ItemHability {
    uint16_t id = 0;
    std::string type;    // "attack" | "defense" | "support"
    std::string effect;  // "ADD_FIRE_DAMAGE" etc.
    std::string name;
    std::string effectType; // "fixed" | "percent"
    float minValue = 0, maxValue = 0;
};
```

Add to `Items` class (`src/items/items.hpp`):
```cpp
std::unordered_map<uint8_t,  ItemRarity>              rarities;
std::unordered_map<uint16_t, ItemHability>            habilities;
std::unordered_map<uint16_t, std::vector<uint16_t>>  itemHabilityMap; // itemTypeId → habilityIds
```

### 3.3 `Items::loadFromDatabase()`
File: `src/items/items.cpp` — new method:

```cpp
bool Items::loadFromDatabase() {
    loadRaritiesFromDatabase();    // SELECT * FROM item_rarity
    loadHabilitiesFromDatabase();  // SELECT * FROM item_habilities
    loadItemHabilityMappings();    // SELECT * FROM item_habilities_item_type

    DBResult_ptr result = g_database().storeQuery(
        "SELECT * FROM `item_types` ORDER BY `id` ASC");
    if (!result) return false;
    do {
        uint16_t id = result->getNumber<uint16_t>("id");
        if (id >= items.size()) items.resize(id + 1);
        populateItemTypeFromResult(items[id], result);
    } while (result->next());

    buildInventoryList();
    return true;
}
```

**Two-stage load preserved:** `loadFromProtobuf()` still runs first (visual flags from `appearances.dat`), then `loadFromDatabase()` overlays game-logic fields. Same pattern as current XML loading.

### 3.4 Config flag for safe rollout
File: `src/config/configmanager.hpp` — add `USE_DB_ITEMS` bool (default `false`).

File: `src/canary_server.cpp` line ~355:
```cpp
if (g_configManager().getBoolean(USE_DB_ITEMS)) {
    modulesLoadHelper(Item::items.loadFromDatabase(), "item_types DB table");
} else {
    modulesLoadHelper(Item::items.loadFromXml(), "items.xml");
}
```
Remove this flag once validated.

### 3.5 Equip/unequip ability application
File: `src/lua/creature/movement.cpp` — `MoveEvent::EquipItem` and `MoveEvent::DeEquipItem`

After the existing abilities block:
```cpp
// Dynamic habilities (rarity system)
uint8_t rarity = item->hasAttribute(ITEM_RARITY)
    ? item->getAttribute<uint8_t>(ITEM_RARITY) : 1;
bool identified = item->hasAttribute(ITEM_IDENTIFIED)
    ? item->getAttribute<bool>(ITEM_IDENTIFIED) : true;

if (rarity > 1 && !identified) return; // unidentified → no bonus

for (uint8_t slot = 0; slot < 3; ++slot) {
    auto idAttr  = ItemAttribute_t(uint8_t(HABILITY_1_ID)    + slot * 2);
    auto valAttr = ItemAttribute_t(uint8_t(HABILITY_1_VALUE) + slot * 2);
    if (!item->hasAttribute(idAttr)) continue;
    applyHabilityToPlayer(player,
        item->getAttribute<uint16_t>(idAttr),
        item->getAttribute<int32_t>(valAttr),
        /*equip=*/equipping);
}
```

New static helper `applyHabilityToPlayer(player, habilityId, value, equip)` switches on effect string and calls the appropriate setter. For `ADD_DROP_CHANCE`: `player->addDropChanceBonus(±value/100.f)`.

### 3.6 Unidentified item name override
When a magic/rare item is created/dropped unidentified:
```cpp
item->setAttribute(ITEM_ATTRIBUTE_NAME, "unidentified " + it.name);
```
On identification: `item->removeAttribute(ITEM_ATTRIBUTE_NAME)`.
Reuses the existing NAME attribute override that already works in `Item::getName()`.

### 3.7 Unidentified item stacking
File: `src/items/item.cpp` — override `isStackable()`:
```cpp
bool Item::isStackable() const {
    bool unidentified = hasAttribute(ITEM_IDENTIFIED) &&
                        !getAttribute<bool>(ITEM_IDENTIFIED);
    if (unidentified && getAttribute<uint8_t>(ITEM_RARITY) > 1) {
        return true; // unidentified magic/rare items stack
    }
    return items[id].stackable;
}
```
Stack merge requires same base `id` and same `ITEM_RARITY` — enforced in `Container::addItem`.

### 3.8 Player drop chance bonus
File: `src/creatures/players/player.hpp`:
```cpp
float dropChanceBonus = 0.f;
float getDropChanceBonus() const { return dropChanceBonus; }
void  addDropChanceBonus(float delta) { dropChanceBonus += delta; }
```

File: `src/io/iologindata.cpp` — save/load `drop_chance_bonus` column.

### 3.9 Ability → C++ field mapping

| New Ability | Existing C++ mechanism |
|---|---|
| ADD_COLD/FIRE/LIGHTNING/POISON/HOLY/DARKNESS_DAMAGE | `elementDamage + elementType` (existing per-item COMBAT_* type) |
| ADD_PHYSICAL_DAMAGE | `attack` bonus on item instance |
| ADD_PHYSICAL_DEFENSE | `armor` bonus on item instance |
| ADD_FIRE/COLD/LIGHTNING/POISON/HOLY/DARKNESS_RESISTENCE | `abilities->absorbPercent[combatTypeIndex]` |
| ADD_MAX_LIFE / ADD_MAX_MANA | `abilities->statsPercent[STAT_MAXHITPOINTS / MANAPOINTS]` |
| ADD_LIFE_STEAL / ADD_MANA_STEAL | `abilities->lifeleechamount / manaleechamount` |
| ADD_MOVEMENT_SPEED | `abilities->speed` |
| ADD_ATTACK_SPEED | `STAT_ATTACKSPEED` or `player->setAttackSpeed()` |
| **ADD_DROP_CHANCE** | **NEW** — `Player::dropChanceBonus` (cached, updated on equip/unequip) |

Only `ADD_DROP_CHANCE` requires a new player stat. All others route through existing C++ setters in `applyHabilityToPlayer()`.

---

## Phase 4: Lua Changes

### 4.1 Monster level field
- `src/creatures/monsters/monsters.hpp` — add `uint16_t level = 1` to `MonsterType::Info`
- `src/lua/functions/creatures/monster/monster_type_functions.cpp` — add `setLevel`/`getLevel` bindings
- Monster Lua files: add `monster.level = N` incrementally (defaults to 1)

### 4.2 Rarity system — new file
New file: `data/libs/functions/item_rarity.lua`

```lua
-- Loaded once at server startup
HABILITY_CACHE = {}  -- [itemTypeId][rarityId] = { list of hability rows }
RARITY_CACHE   = {}  -- [rarityId] = rarity row

function initHabilityCache()
    -- Query DB once, populate in-memory tables
    -- No DB queries during loot events
end
addEvent(initHabilityCache, 0)

-- Rarity probability table (configurable)
local rarityChances = {
    { id = 3, baseChance = 0.01, levelScale = 0.002 }, -- Rare
    { id = 2, baseChance = 0.08, levelScale = 0.005 }, -- Magic
    { id = 1, baseChance = 1.00, levelScale = 0.000 }, -- Normal (always)
}

function rollRarity(monsterLevel, dropBonus)
    local roll = math.random()
    for _, entry in ipairs(rarityChances) do
        local chance = (entry.baseChance + entry.levelScale * monsterLevel)
                       * (1 + dropBonus)
        if roll < chance then return entry.id end
    end
    return 1
end

function isRarityEligible(iType)
    return iType:getSlotPosition() > 0  -- only equippable items
end

function assignRarityToItem(item, itemId, rarityId)
    item:setAttribute(ITEM_ATTRIBUTE_RARITY, rarityId)
    item:setAttribute(ITEM_ATTRIBUTE_IDENTIFIED, rarityId == 1 and 1 or 0)
    if rarityId == 1 then return end

    -- Set unidentified name
    item:setAttribute(ITEM_ATTRIBUTE_NAME, "unidentified " .. ItemType(itemId):getName())
    item:setAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX,
        " (" .. RARITY_CACHE[rarityId].name .. ")")

    -- Roll abilities (max 1 per type: attack, defense, support)
    local abilities = HABILITY_CACHE[itemId] and HABILITY_CACHE[itemId][rarityId] or {}
    local rarity = RARITY_CACHE[rarityId]
    local usedTypes = {}

    shuffleTable(abilities)
    local slot = 1
    for _, ability in ipairs(abilities) do
        if slot > 3 then break end
        if not usedTypes[ability.type] then
            local multiplier = rarity.min_increase +
                math.random() * (rarity.max_increase - rarity.min_increase)
            local value = math.floor(
                (ability.min_value + math.random() *
                (ability.max_value - ability.min_value)) * multiplier)

            local idAttr  = ITEM_ATTRIBUTE_HABILITY_1_ID    + (slot - 1) * 2
            local valAttr = ITEM_ATTRIBUTE_HABILITY_1_VALUE + (slot - 1) * 2
            item:setAttribute(idAttr, ability.id)
            item:setAttribute(valAttr, value)
            usedTypes[ability.type] = true
            slot = slot + 1
        end
    end
end
```

### 4.3 `generateLootRoll` extension
File: `data/libs/functions/monstertype.lua`

After the existing loot loop, before `return result`:
```lua
local monsterLevel = self:getLevel() or 1
for itemId, item in pairs(result) do
    local iType = ItemType(itemId)
    if isRarityEligible(iType) then
        result[itemId].rarity = rollRarity(monsterLevel, config.dropBonus or 0)
    end
end
```

### 4.4 Apply rarity in drop callback
File: `data/scripts/eventcallbacks/monster/ondroploot__base.lua`

After `corpse:addLoot(lootTable)`:
```lua
for itemId, item in pairs(lootTable) do
    if item.rarity and item.rarity > 1 then
        local dropped = corpse:getItemByType(itemId)
        if dropped then
            assignRarityToItem(dropped, itemId, item.rarity)
        end
    end
end
```

### 4.5 ADD_DROP_CHANCE in loot factor
File: `data/libs/functions/player.lua` — extend `calculateLootFactor`:
```lua
local dropBonus = self:getDropChanceBonus()  -- new C++ binding
if dropBonus > 0 then
    factor = factor * (1 + dropBonus)
end
return { factor = factor, dropBonus = dropBonus }
```

### 4.6 Identify rune action
New file: `data/scripts/actions/identify_rune.lua`

```lua
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or not target:isItem() then return false end
    local rarity = target:getAttribute(ITEM_ATTRIBUTE_RARITY) or 0
    if rarity <= 1 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "This item does not need identification.")
        return true
    end
    if target:getAttribute(ITEM_ATTRIBUTE_IDENTIFIED) == 1 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "This item is already identified.")
        return true
    end
    -- Reveal the item
    target:removeAttribute(ITEM_ATTRIBUTE_NAME)
    target:setAttribute(ITEM_ATTRIBUTE_IDENTIFIED, 1)
    -- If equipped, apply habilities immediately
    -- (handle via moveEvent re-trigger or direct Lua application)
    player:sendTextMessage(MESSAGE_INFO_DESCR,
        "You have identified the " .. target:getName() .. ".")
    item:remove(1)
    return true
end
```

---

## Phase 5: RME Compatibility

- `items.xml` stays on disk, unchanged
- Add `Items::exportToXml(path)` C++ method — regenerates `items.xml` from the in-memory `items` vector
- Add GM command `/exportitemsxml` → calls `Items::exportToXml()`
- Workflow for content creators: edit item data in DB → run `/exportitemsxml` → copy output file to RME installation

---

## Implementation Order

| Step | What | Files |
|---|---|---|
| 1 | Schema: write + test migration 45.lua | `data-otservbr-global/migrations/45.lua` |
| 2 | Python migrator: import all items, verify counts | `tools/migrate_items_xml.py` |
| 3 | C++ enums + structs: ItemAttribute values 36–43, ItemRarity/ItemHability | `src/enums/item_attribute.hpp`, `src/items/item_rarity.hpp`, `src/items/items.hpp` |
| 4 | `loadFromDatabase()`: implement behind `USE_DB_ITEMS` flag, validate parity with XML | `src/items/items.cpp`, `src/canary_server.cpp` |
| 5 | Equip/unequip abilities: `applyHabilityToPlayer()` + `Player::dropChanceBonus` | `src/lua/creature/movement.cpp`, `src/creatures/players/player.hpp/cpp`, `src/io/iologindata.cpp` |
| 6 | Unidentified behavior: name override, stacking, description | `src/items/item.cpp` |
| 7 | Monster level: C++ field + Lua bindings | `src/creatures/monsters/monsters.hpp`, monster_type_functions.cpp |
| 8 | Drop system: `item_rarity.lua`, `generateLootRoll` extension, `ondroploot__base.lua` | Lua files |
| 9 | ADD_DROP_CHANCE wiring: Lua `calculateLootFactor` integration | `data/libs/functions/player.lua` |
| 10 | Identify rune action script | `data/scripts/actions/identify_rune.lua` |
| 11 | XML export: `Items::exportToXml()` + GM command | `src/items/items.cpp` |
| 12 | Cleanup: remove `USE_DB_ITEMS` flag | `src/config/configmanager.hpp`, `src/canary_server.cpp` |

---

## Critical Files Summary

| File | Change |
|---|---|
| `src/items/items.hpp` | Add `ItemRarity`, `ItemHability` structs; new maps to `Items` class |
| `src/items/items.cpp` | New `loadFromDatabase()`, sub-loaders, `populateItemTypeFromResult()` |
| `src/items/item_rarity.hpp` | NEW — `ItemRarity` and `ItemHability` struct definitions |
| `src/enums/item_attribute.hpp` | Add values 36–43 |
| `src/lua/creature/movement.cpp` | Extend `EquipItem`/`DeEquipItem` with dynamic hability application |
| `src/creatures/players/player.hpp` | Add `dropChanceBonus` field + accessors |
| `src/creatures/players/player.cpp` | Load `dropChanceBonus` on login |
| `src/io/iologindata.cpp` | Save/load `drop_chance_bonus` column |
| `src/canary_server.cpp` | Add `USE_DB_ITEMS` config switch (temporary) |
| `src/creatures/monsters/monsters.hpp` | Add `level` to `MonsterType::Info` |
| `src/lua/functions/creatures/monster/monster_type_functions.cpp` | `setLevel`/`getLevel` Lua bindings |
| `data/libs/functions/monstertype.lua` | Rarity post-processing in `generateLootRoll` |
| `data/libs/functions/item_rarity.lua` | NEW — cache init, `rollRarity`, `assignRarityToItem` |
| `data/scripts/eventcallbacks/monster/ondroploot__base.lua` | Apply rarity to dropped equippable items |
| `data/scripts/actions/identify_rune.lua` | NEW — identify rune action |
| `data-otservbr-global/migrations/45.lua` | NEW — full schema migration |
| `tools/migrate_items_xml.py` | NEW — one-time XML→MySQL importer |

---

## Verification Plan

| Test | Expected Result |
|---|---|
| Server startup with `USE_DB_ITEMS=true` | Starts cleanly, `items.size()` matches XML load |
| Spot-check 50 items (name, attack, armor, absorbPercent) | Exact match between XML and DB loads |
| Existing player login | No stat changes, no broken items, imbuements work |
| Kill monster 500× | Drop rates statistically close to pre-migration values |
| Rarity distribution at monster.level=1 | ~8% magic, ~1% rare for equippable items |
| Pick up unidentified magic sword | Displays "unidentified iron sword", stacks with others of same type |
| Equip unidentified item | No stat bonus applied |
| Use identify rune | Abilities revealed and applied, item unstacks |
| ADD_DROP_CHANCE equipped | Loot factor increases proportionally |
| `/exportitemsxml` | Valid XML, opens in RME without errors |

---

## Design Notes

**Why JSON columns for arrays?**
`absorbPercent` has 14 elements, `skills` has 15. A fully normalized schema would require 14+ rows per item + a JOIN at startup. JSON columns = one row per item, parsed once at startup. Zero per-request overhead.

**Why store habilities as attribute pairs (HABILITY_N_ID + HABILITY_N_VALUE)?**
The existing `player_items.attributes` BLOB handles all item instance state atomically. Adding a separate `player_item_habilities` table would require a JOIN on every player load. This mirrors how imbuement slots are stored today (`ITEM_IMBUEMENT_SLOT + N`).

**Max 1 ability per type (attack/defense/support)**
Enforced in `assignRarityToItem` via `usedTypes` tracking. This matches the requirements and keeps the system balanced.

**Backward compatibility**
Existing player items have no `ITEM_RARITY` attribute → treated as rarity 1 (Normal) and identified = true → no behavior change for existing characters.

**ADD_DROP_CHANCE as cached player stat**
Loot events happen frequently. Computing drop bonus by iterating equipped slots at loot time would be expensive. Caching it as a player stat (updated on equip/unequip, same pattern as `varStats`) keeps loot event cost O(1).
