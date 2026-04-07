local waypointsOpcode = CreatureEvent("WaypointsOpcode")

function waypointsOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Waypoints.OPCODE then
		return
	end
	local action = buffer:match('"action"%s*:%s*"([^"]+)"')
	if action == "request" then
		Waypoints.sendToPlayer(player)
		return
	end
	local waypointId = tonumber(buffer:match('"waypoint_id"%s*:%s*(%d+)'))
	if action == "teleport" and waypointId then
		Waypoints.teleport(player, waypointId)
	end
end

waypointsOpcode:register()
