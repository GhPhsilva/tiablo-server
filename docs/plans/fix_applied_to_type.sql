-- Fix epic_items_modifiers.applied_to_type to match items.xml primarytype values.
-- The original migration used short names (e.g. "club") but items.xml uses
-- full names (e.g. "club weapons"). Run this once against your database.

UPDATE `epic_items_modifiers`
SET `applied_to_type` = 'sword weapons,axe weapons,club weapons,distance weapons,wands,ammunition'
WHERE `effect` IN (
    'ADD_COLD_DAMAGE', 'ADD_FIRE_DAMAGE', 'ADD_LIGHTNING_DAMAGE',
    'ADD_POISON_DAMAGE', 'ADD_HOLY_DAMAGE', 'ADD_DARKNESS_DAMAGE', 'ADD_PHYSICAL_DAMAGE'
);

UPDATE `epic_items_modifiers`
SET `applied_to_type` = 'armors,helmets,legs,boots,shields,amulets and necklaces,rings,quivers,spellbooks'
WHERE `effect` IN (
    'ADD_PHYSICAL_DEFENSE', 'ADD_FIRE_RESISTENCE', 'ADD_COLD_RESISTENCE',
    'ADD_LIGHTNING_RESISTENCE', 'ADD_POISON_RESISTENCE', 'ADD_HOLY_RESISTENCE', 'ADD_DARKNESS_RESISTENCE'
);

UPDATE `epic_items_modifiers`
SET `applied_to_type` = 'sword weapons,axe weapons,club weapons,distance weapons,wands,ammunition,armors,helmets,legs,boots,shields,amulets and necklaces,rings,quivers,spellbooks'
WHERE `effect` IN (
    'ADD_DROP_CHANCE', 'ADD_MAX_LIFE', 'ADD_LIFE_STEAL',
    'ADD_MANA_STEAL', 'ADD_ATTACK_SPEED', 'ADD_MOVEMENT_SPEED', 'ADD_MAX_MANA'
);
