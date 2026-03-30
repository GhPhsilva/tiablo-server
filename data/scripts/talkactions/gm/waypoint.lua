local waypoint = TalkAction("/waypoint")

function waypoint.onSay(player, words, param)
	if param == "" then
		player:sendCancelMessage("Use: /waypoint <nome>")
		return true
	end

	local pos = getWaypointPositionByName(param)
	if not pos then
		player:sendCancelMessage("Waypoint '" .. param .. "' nao encontrado.")
		return true
	end

	player:teleportTo(pos)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Teleportado para waypoint '" .. param .. "' em " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
	return true
end

waypoint:separator(" ")
waypoint:groupType("gamemaster")
waypoint:register()
