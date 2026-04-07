Waypoints = {}
Waypoints.OPCODE = 100

-- Send the player's unlocked waypoints to the client via extended opcode 100.
-- Uses Player.sendExtendedOpcode (data/libs/functions/player.lua:55) which writes byte 0x32.
-- Buffer prefix "O" = single packet (no chunking needed for typical waypoint counts).
local function jsonEscape(s)
	return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '')
end

function Waypoints.sendToPlayer(player)
	local playerId = player:getGuid()
	local result = db.storeQuery(
		"SELECT w.`id`, w.`name`, w.`category`, w.`image`, w.`description` FROM `waypoints` w"
		.. " INNER JOIN `player_waypoints` pw ON pw.`waypoint_id` = w.`id`"
		.. " WHERE pw.`player_id` = " .. playerId
		.. " ORDER BY w.`category`, w.`name`"
	)
	local parts = {}
	if result then
		repeat
			local id = Result.getNumber(result, "id")
			local name = jsonEscape(Result.getString(result, "name"))
			local category = jsonEscape(Result.getString(result, "category"))
			local image = jsonEscape(Result.getString(result, "image"))
			local description = jsonEscape(Result.getString(result, "description"))
			table.insert(parts, string.format(
				'{"id":%d,"name":"%s","category":"%s","image":"%s","description":"%s"}',
				id, name, category, image, description
			))
		until not Result.next(result)
		Result.free(result)
	end
	local json = "[" .. table.concat(parts, ",") .. "]"
	player:sendExtendedOpcode(Waypoints.OPCODE, "O" .. json)
end

-- Unlock a waypoint for the player.
-- Returns true on success, or false + reason string on failure.
function Waypoints.unlock(player, waypointId)
	local playerId = player:getGuid()
	local wpResult = db.storeQuery("SELECT `id` FROM `waypoints` WHERE `id` = " .. waypointId)
	if not wpResult then
		return false, "waypoint_not_found"
	end
	Result.free(wpResult)

	local existResult = db.storeQuery(
		"SELECT 1 FROM `player_waypoints` WHERE `player_id` = " .. playerId
		.. " AND `waypoint_id` = " .. waypointId
	)
	if existResult then
		Result.free(existResult)
		return false, "already_unlocked"
	end

	db.query(
		"INSERT INTO `player_waypoints` (`player_id`, `waypoint_id`) VALUES ("
		.. playerId .. ", " .. waypointId .. ")"
	)
	return true
end

-- Teleport player to an unlocked waypoint. Player must be standing in a protection zone.
function Waypoints.teleport(player, waypointId)
	if not player:getTile():hasFlag(TILESTATE_PROTECTIONZONE) then
		player:sendCancelMessage("You can only use waypoints from a protection zone.")
		return false
	end

	local unlockCheck = db.storeQuery(
		"SELECT 1 FROM `player_waypoints` WHERE `player_id` = " .. player:getGuid()
		.. " AND `waypoint_id` = " .. waypointId
	)
	if not unlockCheck then
		player:sendCancelMessage("You have not unlocked this waypoint.")
		return false
	end
	Result.free(unlockCheck)

	local result = db.storeQuery(
		"SELECT `x`, `y`, `z` FROM `waypoints` WHERE `id` = " .. waypointId
	)
	if not result then
		player:sendCancelMessage("Waypoint not found.")
		return false
	end

	local pos = Position(
		Result.getNumber(result, "x"),
		Result.getNumber(result, "y"),
		Result.getNumber(result, "z")
	)
	Result.free(result)

	player:teleportTo(pos)
	pos:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end
