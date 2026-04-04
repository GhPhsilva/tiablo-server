-- /epicitem itemid, raritycode[, modid:value, modid:value, ...]
--
-- Examples:
--   /epicitem 3277, magic              → random modifiers
--   /epicitem 3277, rare               → random modifiers (rare)
--   /epicitem 3277, magic, 1:5, 2:3    → specific modifiers: mod 1 value 5, mod 2 value 3
--   /epicitem 3277, rare, 1:10         → specific modifier: mod 1 value 10

local modifierAttrIds = {
	{ ITEM_ATTRIBUTE_EPIC_MODIFIER_1_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_1_VALUE },
	{ ITEM_ATTRIBUTE_EPIC_MODIFIER_2_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_2_VALUE },
	{ ITEM_ATTRIBUTE_EPIC_MODIFIER_3_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_3_VALUE },
	{ ITEM_ATTRIBUTE_EPIC_MODIFIER_4_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_4_VALUE },
	{ ITEM_ATTRIBUTE_EPIC_MODIFIER_5_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_5_VALUE },
}

local talkAction = TalkAction("/epicitem")

function talkAction.onSay(player, words, param)
	logCommand(player, words, param)

	local parts = param:split(",")
	if #parts < 2 then
		player:sendCancelMessage("Usage: /epicitem itemid, raritycode[, modid:value, ...]")
		return true
	end

	-- Resolve item
	local rawId = parts[1]:match("^%s*(.-)%s*$")
	local itemType = ItemType(rawId)
	if itemType:getId() == 0 then
		itemType = ItemType(tonumber(rawId))
		if not tonumber(rawId) or itemType:getId() == 0 then
			player:sendCancelMessage("Item not found: " .. rawId)
			return true
		end
	end

	if not itemType:isEpic() then
		player:sendCancelMessage("Item '" .. itemType:getName() .. "' is not an epic item.")
		return true
	end

	-- Resolve rarity
	local rarityCode = parts[2]:match("^%s*(.-)%s*$"):lower()
	local rarity = EpicItems.raritiesByCode[rarityCode]
	if not rarity then
		player:sendCancelMessage("Unknown rarity '" .. rarityCode .. "'. Use: magic, rare, etc.")
		return true
	end

	-- Parse optional modifiers: "modid:value"
	local forcedMods = {}
	for i = 3, #parts do
		local raw = parts[i]:match("^%s*(.-)%s*$")
		local modId, modVal = raw:match("^(%d+):(-?%d+)$")
		if not modId then
			player:sendCancelMessage("Invalid modifier format '" .. raw .. "'. Expected modid:value (e.g. 1:5)")
			return true
		end
		modId  = tonumber(modId)
		modVal = tonumber(modVal)
		if not EpicItems.modifiers[modId] then
			player:sendCancelMessage("Modifier id " .. modId .. " not found in epic_items_modifiers.")
			return true
		end
		if #forcedMods >= 5 then
			player:sendCancelMessage("Maximum 5 modifiers allowed.")
			return true
		end
		forcedMods[#forcedMods + 1] = { mod = EpicItems.modifiers[modId], value = modVal }
	end

	-- Create item
	local item = player:addItem(itemType:getId(), 1)
	if not item then
		player:sendCancelMessage("Failed to create item.")
		return true
	end

	if #forcedMods == 0 then
		-- Auto-roll via standard identify
		EpicItems.identify(item, player)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Created [" .. rarityCode .. "] " .. itemType:getName() .. " with random modifiers.")
	else
		-- Apply manually with forced modifiers
		local mult = 1.0 -- no scaling for manual test items

		local baseAttack  = itemType:getAttack()
		local baseDefense = itemType:getDefense()
		local baseArmor   = itemType:getArmor()

		-- Apply ENHANCED_ATTACK modifier to base attack
		for _, rolled in ipairs(forcedMods) do
			if rolled.mod.effect == "ENHANCED_ATTACK" and baseAttack > 0 then
				baseAttack = baseAttack + math.max(1, math.floor(baseAttack * rolled.value / 100))
			end
		end

		local baseName = itemType:getName():gsub("^unidentified ", "")
		for code, _ in pairs(EpicItems.raritiesByCode) do
			baseName = baseName:gsub("^" .. code .. " ", "")
		end
		local newName  = rarityCode .. " " .. baseName

		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_RARITY,     rarity.id)
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 1)
		item:setAttribute(ITEM_ATTRIBUTE_NAME, newName)

		if baseAttack  > 0 then item:setAttribute(ITEM_ATTRIBUTE_ATTACK,  baseAttack)  end
		if baseDefense > 0 then item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, baseDefense) end
		if baseArmor   > 0 then item:setAttribute(ITEM_ATTRIBUTE_ARMOR,   baseArmor)   end

		-- Elemental bonus: first elemental modifier stored as permanent attribute
		local elemCombatType = nil
		local elemValue = 0
		for _, rolled in ipairs(forcedMods) do
			local combatType = EpicItems.elementCombatTypes[rolled.mod.effect]
			if combatType and baseAttack > 0 then
				elemCombatType = combatType
				elemValue = math.max(1, math.floor(baseAttack * rolled.value / 100))
				break
			end
		end
		if elemCombatType then
			item:setAttribute(ITEM_ATTRIBUTE_EPIC_ELEMENT_TYPE,  elemCombatType)
			item:setAttribute(ITEM_ATTRIBUTE_EPIC_ELEMENT_VALUE, elemValue)
		end

		local descLines = { "[" .. rarity.name .. " Epic Item]" }
		for i, rolled in ipairs(forcedMods) do
			item:setAttribute(modifierAttrIds[i][1], rolled.mod.id)
			item:setAttribute(modifierAttrIds[i][2], rolled.value)
			descLines[#descLines + 1] = string.format(rolled.mod.description, rolled.value)
		end

		item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION,     table.concat(descLines, "\n"))
		item:setAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX, " [" .. rarity.name .. "]")

		local summary = {}
		for _, rolled in ipairs(forcedMods) do
			summary[#summary + 1] = rolled.mod.label .. "=" .. rolled.value
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
			"Created [" .. rarityCode .. "] " .. newName .. " | " .. table.concat(summary, ", "))
	end

	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end

talkAction:separator(" ")
talkAction:groupType("god")
talkAction:register()
