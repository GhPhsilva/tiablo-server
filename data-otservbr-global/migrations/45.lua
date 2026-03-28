function onUpdateDatabase()
	logger.info("Running migration 45: Epic Items System")

	-- epic_items_rarity
	db.query([[
		CREATE TABLE IF NOT EXISTS `epic_items_rarity` (
			`id`              TINYINT UNSIGNED  NOT NULL,
			`name`            VARCHAR(32)       NOT NULL,
			`code`            VARCHAR(32)       NOT NULL,
			`modifiers_count` TINYINT UNSIGNED  NOT NULL DEFAULT 0,
			`min_increase`    FLOAT             NOT NULL DEFAULT 1.0,
			`max_increase`    FLOAT             NOT NULL DEFAULT 1.0,
			`color_name`      VARCHAR(32)       NOT NULL DEFAULT 'white',
			`drop_chance`     FLOAT             NOT NULL DEFAULT 0.0,
			PRIMARY KEY (`id`),
			UNIQUE KEY `code` (`code`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

	db.query([[
		INSERT IGNORE INTO `epic_items_rarity` (`id`, `name`, `code`, `modifiers_count`, `min_increase`, `max_increase`, `color_name`, `drop_chance`) VALUES
		(1, 'Normal', 'normal', 0, 1.0,  1.0,  'white',  0.0),
		(2, 'Magic',  'magic',  1, 1.1,  1.3,  'blue',   0.08),
		(3, 'Rare',   'rare',   2, 1.3,  1.5,  'yellow', 0.01);
	]])

	-- epic_items_modifiers
	db.query([[
		CREATE TABLE IF NOT EXISTS `epic_items_modifiers` (
			`id`          SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`type`        ENUM('attack','defense','support') NOT NULL,
			`effect`      VARCHAR(64) NOT NULL,
			`name`        VARCHAR(64) NOT NULL,
			`effect_type` ENUM('fixed','percent') NOT NULL DEFAULT 'fixed',
			`min_value`   FLOAT NOT NULL DEFAULT 0,
			`max_value`   FLOAT NOT NULL DEFAULT 0,
			PRIMARY KEY (`id`),
			UNIQUE KEY `effect` (`effect`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

	db.query([[
		INSERT IGNORE INTO `epic_items_modifiers` (`id`, `type`, `effect`, `name`, `effect_type`, `min_value`, `max_value`) VALUES
		(1,  'attack',  'ADD_COLD_DAMAGE',         'Shivering', 'percent', 1,  10),
		(2,  'attack',  'ADD_FIRE_DAMAGE',          'Flaming',   'percent', 1,  10),
		(3,  'attack',  'ADD_LIGHTNING_DAMAGE',     'Shocking',  'percent', 1,  10),
		(4,  'attack',  'ADD_POISON_DAMAGE',        'Toxic',     'percent', 1,  10),
		(5,  'attack',  'ADD_HOLY_DAMAGE',          'Holy',      'percent', 1,  10),
		(6,  'attack',  'ADD_DARKNESS_DAMAGE',      'Cursed',    'percent', 1,  10),
		(7,  'attack',  'ADD_PHYSICAL_DAMAGE',      'Savage',    'percent', 1,  10),
		(8,  'defense', 'ADD_PHYSICAL_DEFENSE',     'Diamond',   'fixed',   1,  15),
		(9,  'defense', 'ADD_FIRE_RESISTENCE',      'Ruby',      'percent', 1,  10),
		(10, 'defense', 'ADD_COLD_RESISTENCE',      'Sapphire',  'percent', 1,  10),
		(11, 'defense', 'ADD_LIGHTNING_RESISTENCE', 'Amber',     'percent', 1,  10),
		(12, 'defense', 'ADD_POISON_RESISTENCE',    'Jade',      'percent', 1,  10),
		(13, 'defense', 'ADD_HOLY_RESISTENCE',      'Topaz',     'percent', 1,  10),
		(14, 'defense', 'ADD_DARKNESS_RESISTENCE',  'Sacred',    'percent', 1,  10),
		(15, 'support', 'ADD_DROP_CHANCE',          'Fortuitous','fixed',   1,  5),
		(16, 'support', 'ADD_MAX_LIFE',             'Tiger',     'percent', 1,  5),
		(17, 'support', 'ADD_LIFE_STEAL',           'Vampire',   'percent', 1,  5),
		(18, 'support', 'ADD_MANA_STEAL',           'Wraith',    'percent', 1,  5),
		(19, 'support', 'ADD_ATTACK_SPEED',         'Swiftness', 'percent', 1,  10),
		(20, 'support', 'ADD_MOVEMENT_SPEED',       'Haste',     'fixed',   10, 20),
		(21, 'support', 'ADD_MAX_MANA',             'Snake',     'percent', 1,  5);
	]])

	-- epic_item_types
	db.query([[
		CREATE TABLE IF NOT EXISTS `epic_item_types` (
			`id`   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`name` VARCHAR(64)       NOT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `name` (`name`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

	db.query([[
		INSERT IGNORE INTO `epic_item_types` (`id`, `name`) VALUES
		(1,  'sword'),
		(2,  'axe'),
		(3,  'club'),
		(4,  'distance'),
		(5,  'wand'),
		(6,  'ammunition'),
		(7,  'missile'),
		(8,  'shield'),
		(9,  'spellbook'),
		(10, 'armors'),
		(11, 'legs'),
		(12, 'boots'),
		(13, 'helmets'),
		(14, 'quivers'),
		(15, 'rings'),
		(16, 'amulets and necklaces'),
		(17, 'belts'),
		(18, 'gloves');
	]])

	-- epic_items
	db.query([[
		CREATE TABLE IF NOT EXISTS `epic_items` (
			`id`                          INT UNSIGNED      NOT NULL AUTO_INCREMENT,
			`name`                        VARCHAR(64)       NOT NULL,
			`server_item_id`              SMALLINT UNSIGNED NOT NULL COMMENT 'items.xml ID for identified item',
			`server_item_unidentified_id` SMALLINT UNSIGNED NOT NULL COMMENT 'items.xml ID for unidentified item',
			`epic_item_type_id`           SMALLINT UNSIGNED NOT NULL,
			`weight`                      FLOAT             NOT NULL DEFAULT 0,
			`primary_type`                VARCHAR(32)       NOT NULL DEFAULT '',
			`script`                      VARCHAR(255)      NOT NULL DEFAULT '',
			`slot`                        VARCHAR(32)       NOT NULL DEFAULT '',
			`req_level`                   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
			`vocation_id`                 TINYINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '0 = all vocations',
			`attack`                      SMALLINT          NOT NULL DEFAULT 0,
			`defense`                     SMALLINT          NOT NULL DEFAULT 0,
			`armor`                       SMALLINT          NOT NULL DEFAULT 0,
			`range`                       TINYINT           NOT NULL DEFAULT 0,
			`min_monster_level`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
			`max_monster_level`           SMALLINT UNSIGNED NOT NULL DEFAULT 65535,
			`base_drop_chance`            FLOAT             NOT NULL DEFAULT 0.01,
			PRIMARY KEY (`id`),
			KEY `level_idx` (`min_monster_level`, `max_monster_level`),
			FOREIGN KEY (`epic_item_type_id`) REFERENCES `epic_item_types` (`id`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

	-- Test seed: Epic Mace (base_drop_chance=1.0 for easy testing)
	db.query([[
		INSERT IGNORE INTO `epic_items`
			(`name`, `server_item_id`, `server_item_unidentified_id`, `epic_item_type_id`,
			 `weight`, `primary_type`, `script`, `slot`, `req_level`, `vocation_id`,
			 `attack`, `defense`, `armor`, `range`, `min_monster_level`, `max_monster_level`, `base_drop_chance`)
		VALUES
			('Epic Mace', 3286, 3322, 3,
			 3800, 'club weapons', 'moveevent;weapon', 'hand', 0, 0,
			 16, 11, 0, 0, 1, 65535, 1.0);
	]])

	-- epic_items_modifiers_epic_item_types
	db.query([[
		CREATE TABLE IF NOT EXISTS `epic_items_modifiers_epic_item_types` (
			`id`                    INT UNSIGNED      NOT NULL AUTO_INCREMENT,
			`epic_item_modifier_id` SMALLINT UNSIGNED NOT NULL,
			`epic_item_type_id`     SMALLINT UNSIGNED NOT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `modifier_type` (`epic_item_modifier_id`, `epic_item_type_id`),
			KEY `type_idx` (`epic_item_type_id`),
			FOREIGN KEY (`epic_item_modifier_id`) REFERENCES `epic_items_modifiers` (`id`),
			FOREIGN KEY (`epic_item_type_id`) REFERENCES `epic_item_types` (`id`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

	-- Seed: all modifiers available for club weapons (type_id=3)
	db.query([[
		INSERT IGNORE INTO `epic_items_modifiers_epic_item_types` (`epic_item_modifier_id`, `epic_item_type_id`) VALUES
		(1,3),(2,3),(3,3),(4,3),(5,3),(6,3),(7,3),
		(8,3),(9,3),(10,3),(11,3),(12,3),(13,3),(14,3),
		(15,3),(16,3),(17,3),(18,3),(19,3),(20,3),(21,3);
	]])

	-- Player drop chance bonus column
	db.query([[
		ALTER TABLE `players` ADD COLUMN `drop_chance_bonus` FLOAT NOT NULL DEFAULT 0.0;
	]])

	logger.info("Migration 45 complete: Epic Items System tables created.")

	return false -- this is the last migration file
end