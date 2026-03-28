local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	logger.info("[identify_rune] ITEM_ATTRIBUTE_EPIC_ITEM_ID = {}", tostring(ITEM_ATTRIBUTE_EPIC_ITEM_ID))
	if target and target.isItem and target:isItem() then
		logger.info("[identify_rune] target has epic id attr = {}", tostring(target:hasAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID)))
	end
	if not target or not target.isItem or not target:isItem() then
		player:sendTextMessage(MESSAGE_FAILURE, "Use this rune on an unidentified epic item.")
		return true
	end

	if not target:hasAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID) then
		player:sendTextMessage(MESSAGE_FAILURE, "This item cannot be identified.")
		return true
	end

	if target:getAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED) == 1 then
		player:sendTextMessage(MESSAGE_FAILURE, "This item is already identified.")
		return true
	end

	local epicItemId = target:getAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID)
	local epicRow = EpicItems.items[epicItemId]
	if not epicRow then
		logger.warn("[identify_rune] No epic_items row found for id {}", epicItemId)
		return true
	end

	local rarity = EpicItems.identify(target, epicRow, player)

	item:remove(1)

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"You identified the " .. target:getName() .. ". [" .. rarity.name .. "]")
	return true
end

action:id(44614) -- custom ID (requires appearances.dat entry for production)
action:id(3155)   -- Sudden Death Rune (test proxy until custom appearances are added)
action:register()
