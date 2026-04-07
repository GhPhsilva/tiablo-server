local migration = Migration("20260407000001_waypoints_add_category_image")

function migration:onExecute()
	db.query("ALTER TABLE `waypoints` ADD COLUMN `category` VARCHAR(50) NOT NULL DEFAULT 'General' AFTER `description`")
	db.query("ALTER TABLE `waypoints` ADD COLUMN `image` VARCHAR(255) NOT NULL DEFAULT '' AFTER `category`")
end

migration:register()
