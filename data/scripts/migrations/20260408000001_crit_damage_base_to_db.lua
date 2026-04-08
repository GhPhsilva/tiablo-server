local migration = Migration("20260408000001_crit_damage_base_to_db")

function migration:onExecute()
	-- Move the hardcoded 50% critical hit damage base (5000 in scale 0-10000) into the DB.
	-- Existing players have skill_critical_hit_damage = 0 (bonus was added in C++ code).
	-- Set all players to 5000 so the base is now data-driven.
	db.query("UPDATE `players` SET `skill_critical_hit_damage` = 5000 WHERE `skill_critical_hit_damage` = 0")

	-- Change column default so new characters start with 5000.
	db.query("ALTER TABLE `players` MODIFY COLUMN `skill_critical_hit_damage` int(11) NOT NULL DEFAULT 5000")
end

migration:register()
