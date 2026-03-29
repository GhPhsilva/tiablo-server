-- Migration 46: Epic Items System — items.xml-driven refactor
-- Run this script manually against your MySQL/MariaDB database.

-- ─────────────────────────────────────────────────────────────────────────────
-- Drop tables no longer needed (epic items now defined in items.xml)
-- ─────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS `epic_items_modifiers_epic_item_types`;
DROP TABLE IF EXISTS `epic_items`;
DROP TABLE IF EXISTS `epic_item_types`;

-- ─────────────────────────────────────────────────────────────────────────────
-- epic_items_rarity: replace drop_chance / modifiers_count
--                    with min_modifiers / max_modifiers
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE `epic_items_rarity`
    DROP COLUMN `drop_chance`,
    DROP COLUMN `modifiers_count`,
    ADD COLUMN  `min_modifiers` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ADD COLUMN  `max_modifiers` TINYINT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `epic_items_rarity` SET `min_modifiers` = 0, `max_modifiers` = 0 WHERE `code` = 'normal';
UPDATE `epic_items_rarity` SET `min_modifiers` = 1, `max_modifiers` = 3 WHERE `code` = 'magic';
UPDATE `epic_items_rarity` SET `min_modifiers` = 2, `max_modifiers` = 5 WHERE `code` = 'rare';

-- ─────────────────────────────────────────────────────────────────────────────
-- epic_items_modifiers: replace name / min_value / max_value
--                       with per-rarity values, label, description, applied_to_type
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE `epic_items_modifiers`
    DROP COLUMN `name`,
    DROP COLUMN `min_value`,
    DROP COLUMN `max_value`,
    ADD COLUMN  `label`           VARCHAR(32)  NOT NULL DEFAULT '',
    ADD COLUMN  `description`     VARCHAR(255) NOT NULL DEFAULT '',
    ADD COLUMN  `min_magic_value` FLOAT        NOT NULL DEFAULT 0,
    ADD COLUMN  `max_magic_value` FLOAT        NOT NULL DEFAULT 0,
    ADD COLUMN  `min_rare_value`  FLOAT        NOT NULL DEFAULT 0,
    ADD COLUMN  `max_rare_value`  FLOAT        NOT NULL DEFAULT 0,
    ADD COLUMN  `applied_to_type` VARCHAR(255) NOT NULL DEFAULT '';

-- ─────────────────────────────────────────────────────────────────────────────
-- Seed modifier data
-- ─────────────────────────────────────────────────────────────────────────────

-- Attack modifiers — weapons only
UPDATE `epic_items_modifiers` SET
    `label` = 'Shivering', `description` = 'Adds %d%% cold damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_COLD_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Flaming', `description` = 'Adds %d%% fire damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_FIRE_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Shocking', `description` = 'Adds %d%% lightning damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_LIGHTNING_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Toxic', `description` = 'Adds %d%% poison damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_POISON_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Holy', `description` = 'Adds %d%% holy damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_HOLY_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Cursed', `description` = 'Adds %d%% death damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_DARKNESS_DAMAGE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Savage', `description` = 'Adds %d%% physical damage to attacks',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition'
WHERE `effect` = 'ADD_PHYSICAL_DAMAGE';

-- Defense modifiers — armor pieces only
UPDATE `epic_items_modifiers` SET
    `label` = 'Diamond', `description` = 'Adds %d physical defense',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 15,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_PHYSICAL_DEFENSE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Ruby', `description` = 'Adds %d%% fire resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_FIRE_RESISTENCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Sapphire', `description` = 'Adds %d%% cold resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_COLD_RESISTENCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Amber', `description` = 'Adds %d%% lightning resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_LIGHTNING_RESISTENCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Jade', `description` = 'Adds %d%% poison resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_POISON_RESISTENCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Topaz', `description` = 'Adds %d%% holy resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_HOLY_RESISTENCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Sacred', `description` = 'Adds %d%% death resistance',
    `min_magic_value` = 1, `max_magic_value` = 5,
    `min_rare_value`  = 5, `max_rare_value`  = 10,
    `applied_to_type` = 'armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_DARKNESS_RESISTENCE';

-- Support modifiers — all item types
UPDATE `epic_items_modifiers` SET
    `label` = 'Fortuitous', `description` = 'Increases loot drop chance by %d%%',
    `min_magic_value` = 1, `max_magic_value` = 3,
    `min_rare_value`  = 3, `max_rare_value`  = 5,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_DROP_CHANCE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Tiger', `description` = 'Increases max health by %d%%',
    `min_magic_value` = 1, `max_magic_value` = 3,
    `min_rare_value`  = 3, `max_rare_value`  = 5,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_MAX_LIFE';

UPDATE `epic_items_modifiers` SET
    `label` = 'Vampire', `description` = 'Steals %d%% life on hit',
    `min_magic_value` = 1, `max_magic_value` = 3,
    `min_rare_value`  = 3, `max_rare_value`  = 5,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_LIFE_STEAL';

UPDATE `epic_items_modifiers` SET
    `label` = 'Wraith', `description` = 'Steals %d%% mana on hit',
    `min_magic_value` = 1, `max_magic_value` = 3,
    `min_rare_value`  = 3, `max_rare_value`  = 5,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_MANA_STEAL';

UPDATE `epic_items_modifiers` SET
    `label` = 'Swiftness', `description` = 'Increases attack speed by %d%%',
    `min_magic_value` = 1,  `max_magic_value` = 5,
    `min_rare_value`  = 5,  `max_rare_value`  = 10,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_ATTACK_SPEED';

UPDATE `epic_items_modifiers` SET
    `label` = 'Haste', `description` = 'Increases movement speed by %d',
    `min_magic_value` = 5,  `max_magic_value` = 10,
    `min_rare_value`  = 10, `max_rare_value`  = 20,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_MOVEMENT_SPEED';

UPDATE `epic_items_modifiers` SET
    `label` = 'Snake', `description` = 'Increases max mana by %d%%',
    `min_magic_value` = 1, `max_magic_value` = 3,
    `min_rare_value`  = 3, `max_rare_value`  = 5,
    `applied_to_type` = 'sword,axe,club,distance,wand,ammunition,armors,helmets,legs,boots,gloves,shields,amulets and necklaces,rings,belts,quivers,spellbook'
WHERE `effect` = 'ADD_MAX_MANA';
