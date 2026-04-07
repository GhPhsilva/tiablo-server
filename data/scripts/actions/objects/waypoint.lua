local waypointAction = Action()

function waypointAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local waypointId = item.uid
	if waypointId == 0 then
		player:sendTextMessage(MESSAGE_STATUS, "This waypoint is not configured.")
		return true
	end

	local ok, reason = Waypoints.unlock(player, waypointId)
	if ok then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Waypoint unlocked!")
		Waypoints.sendToPlayer(player)
	elseif reason == "already_unlocked" then
		player:sendTextMessage(MESSAGE_STATUS, "You have already unlocked this waypoint.")
	else
		player:sendTextMessage(MESSAGE_STATUS, "This is not a valid waypoint.")
	end
	return true
end

waypointAction:id(8836)
waypointAction:register()
