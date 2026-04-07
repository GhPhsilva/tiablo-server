local migration = Migration("20260406000001_add_waypoints")

function migration:onExecute()
	db.query([[CREATE TABLE IF NOT EXISTS `waypoints` (
		`id` int(11) NOT NULL,
		`name` varchar(255) NOT NULL,
		`x` int(11) NOT NULL,
		`y` int(11) NOT NULL,
		`z` int(3) NOT NULL,
		`description` varchar(500) NOT NULL DEFAULT '',
		PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8]])

	db.query([[CREATE TABLE IF NOT EXISTS `player_waypoints` (
		`player_id` int(11) NOT NULL,
		`waypoint_id` int(11) NOT NULL,
		PRIMARY KEY (`player_id`, `waypoint_id`),
		CONSTRAINT `player_waypoints_players_fk`
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
		CONSTRAINT `player_waypoints_waypoints_fk`
			FOREIGN KEY (`waypoint_id`) REFERENCES `waypoints` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8]])
end

migration:register()
