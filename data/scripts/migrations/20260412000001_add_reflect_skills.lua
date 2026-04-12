local migration = Migration("20260412000001_add_reflect_skills")

function migration:onExecute()
	db.query("ALTER TABLE `players` ADD COLUMN `skill_reflect_damage` int(11) NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_reflect_damage_tries` bigint(20) NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_reflect_chance` int(11) NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_reflect_chance_tries` bigint(20) NOT NULL DEFAULT 0")
end

migration:register()
