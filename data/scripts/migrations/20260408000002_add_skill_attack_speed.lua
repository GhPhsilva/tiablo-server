local migration = Migration("20260408000002_add_skill_attack_speed")

function migration:onExecute()
	db.query("ALTER TABLE `players` ADD COLUMN `skill_attack_speed` int(11) NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_attack_speed_tries` bigint(20) NOT NULL DEFAULT 0")
end

migration:register()
