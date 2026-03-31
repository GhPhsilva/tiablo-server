local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() then
		player:sendTextMessage(MESSAGE_FAILURE, "Use this rune on an unidentified epic item.")
		return true
	end

	local targetType = target:getType()
	if not targetType:isEpic() then
		player:sendTextMessage(MESSAGE_FAILURE, "This item cannot be identified.")
		return true
	end

	if target:getAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED) == 1 then
		player:sendTextMessage(MESSAGE_FAILURE, "This item is already identified.")
		return true
	end

	local rarity = EpicItems.identify(target, player)
	if not rarity then
		logger.warn("[identify_rune] EpicItems.identify returned nil for item {}", target:getId())
		return true
	end

	item:remove(1)

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"You identified the " .. target:getName() .. ". [" .. rarity.name .. "]")
	return true
end

action:id(44782) -- custom ID (requires appearances.dat entry for production)
action:register()
