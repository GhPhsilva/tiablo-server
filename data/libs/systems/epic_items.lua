-- Epic Items System
-- Items are defined directly in items.xml with epic/rarity/epicname attributes.
-- Drops are controlled by monster loot tables in XML.
-- This module handles identification logic only.

EpicItems = {
	rarities       = {}, -- [id]   = {id, name, code, min_increase, max_increase, color_name, min_modifiers, max_modifiers}
	raritiesByCode = {}, -- ["magic"] = rarity row
	modifiers      = {}, -- [id]   = {id, type, effect, effect_type, label, description,
	                     --           min_magic_value, max_magic_value, min_rare_value, max_rare_value, applied_to_type}

	-- Maps effect name → CombatType_t constant
	-- Used at identification time to store EPIC_ELEMENT_TYPE on the item permanently.
	elementCombatTypes = {
		ADD_COLD_DAMAGE      = COMBAT_ICEDAMAGE,
		ADD_FIRE_DAMAGE      = COMBAT_FIREDAMAGE,
		ADD_LIGHTNING_DAMAGE = COMBAT_ENERGYDAMAGE,
		ADD_HOLY_DAMAGE      = COMBAT_HOLYDAMAGE,
		ADD_DARKNESS_DAMAGE  = COMBAT_DEATHDAMAGE,
		ADD_POISON_DAMAGE    = COMBAT_EARTHDAMAGE,
	},
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Startup cache loading
-- ──────────────────────────────────────────────────────────────────────────────

function EpicItems.init()
	-- Rarities
	local rarityCount = 0
	local result = db.storeQuery("SELECT * FROM `epic_items_rarity` ORDER BY `id` ASC")
	if result then
		repeat
			local row = {
				id            = Result.getNumber(result, "id"),
				name          = Result.getString(result, "name"),
				code          = Result.getString(result, "code"),
				min_increase  = tonumber(Result.getString(result, "min_increase")),
				max_increase  = tonumber(Result.getString(result, "max_increase")),
				color_name    = Result.getString(result, "color_name"),
				min_modifiers = Result.getNumber(result, "min_modifiers"),
				max_modifiers = Result.getNumber(result, "max_modifiers"),
			}
			EpicItems.rarities[row.id] = row
			EpicItems.raritiesByCode[row.code] = row
			rarityCount = rarityCount + 1
		until not Result.next(result)
		Result.free(result)
	else
		logger.warn("[EpicItems] epic_items_rarity table missing or empty.")
	end

	-- Modifiers
	local modifierCount = 0
	result = db.storeQuery("SELECT * FROM `epic_items_modifiers` ORDER BY `id` ASC")
	if result then
		repeat
			local row = {
				id              = Result.getNumber(result, "id"),
				type            = Result.getString(result, "type"),
				effect          = Result.getString(result, "effect"),
				effect_type     = Result.getString(result, "effect_type"),
				label           = Result.getString(result, "label"),
				description     = Result.getString(result, "description"),
				min_magic_value = tonumber(Result.getString(result, "min_magic_value")),
				max_magic_value = tonumber(Result.getString(result, "max_magic_value")),
				min_rare_value  = tonumber(Result.getString(result, "min_rare_value")),
				max_rare_value  = tonumber(Result.getString(result, "max_rare_value")),
				applied_to_type = Result.getString(result, "applied_to_type"),
			}
			EpicItems.modifiers[row.id] = row
			modifierCount = modifierCount + 1
		until not Result.next(result)
		Result.free(result)
	end

	logger.info("[EpicItems] Loaded {} rarities, {} modifiers.", rarityCount, modifierCount)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────────────────────────

local function shuffleTable(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Splits a comma-separated string and trims whitespace from each part.
local function splitCSV(str)
	local parts = {}
	for part in str:gmatch("[^,]+") do
		parts[#parts + 1] = part:match("^%s*(.-)%s*$")
	end
	return parts
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Identification
-- ──────────────────────────────────────────────────────────────────────────────

-- Identifies an unidentified epic item.
-- item:   Item userdata (must have itemType:isEpic() == true and not yet identified)
-- player: Player userdata (optional, reserved for future drop_chance_bonus integration)
-- Returns the rarity row on success, or nil on failure.
function EpicItems.identify(item, player)
	local itemType = item:getType()
	local rarityCode = itemType:getEpicRarity()
	local rarity = EpicItems.raritiesByCode[rarityCode]
	if not rarity then
		logger.warn("[EpicItems.identify] Unknown rarity code '{}' for item id {}", rarityCode, item:getId())
		return nil
	end

	-- Base stats from ItemType (defined in items.xml)
	local baseAttack  = itemType:getAttack()
	local baseDefense = itemType:getDefense()
	local baseArmor   = itemType:getArmor()

	-- Item type used to filter eligible modifiers
	local primaryType = itemType:getPrimaryType()

	-- Stat multiplier (random within rarity bounds, rounded to 1 decimal place)
	local mult = math.floor((rarity.min_increase + math.random() * (rarity.max_increase - rarity.min_increase)) * 10 + 0.5) / 10

	-- Filter modifiers whose applied_to_type CSV contains this item's primaryType
	local eligible = {}
	for _, mod in pairs(EpicItems.modifiers) do
		local types = splitCSV(mod.applied_to_type)
		for _, t in ipairs(types) do
			if t == primaryType then
				eligible[#eligible + 1] = mod
				break
			end
		end
	end
	shuffleTable(eligible)

	-- Roll modifier count (random within rarity bounds, no type restriction)
	local count = 0
	if rarity.min_modifiers <= rarity.max_modifiers and rarity.max_modifiers > 0 then
		count = math.random(rarity.min_modifiers, rarity.max_modifiers)
	end
	count = math.min(count, #eligible)

	local rolledMods = {}
	for i = 1, count do
		local mod = eligible[i]
		local minVal = rarityCode == "rare" and mod.min_rare_value or mod.min_magic_value
		local maxVal = rarityCode == "rare" and mod.max_rare_value or mod.max_magic_value
		local value  = math.floor(minVal + math.random() * (maxVal - minVal))
		value = math.floor(value * mult)
		rolledMods[#rolledMods + 1] = { mod = mod, value = value }
	end

	-- Derive identified name: strip "unidentified " prefix and any existing rarity prefix
	local currentName = item:getName()
	local baseName = currentName:gsub("^unidentified ", "")
	for code, _ in pairs(EpicItems.raritiesByCode) do
		baseName = baseName:gsub("^" .. code .. " ", "")
	end
	local newName = rarityCode .. " " .. baseName

	-- Apply scaled stats
	local scaledAttack  = math.floor(baseAttack  * mult)
	local scaledDefense = math.floor(baseDefense * mult)
	local scaledArmor   = math.floor(baseArmor   * mult)

	-- ENHANCED_ATTACK: permanently boost scaledAttack by the rolled percentage
	for _, rolled in ipairs(rolledMods) do
		if rolled.mod.effect == "ENHANCED_ATTACK" and scaledAttack > 0 then
			scaledAttack = scaledAttack + math.max(1, math.floor(scaledAttack * rolled.value / 100))
		end
	end

	-- ELEMENTAL DAMAGE: store first elemental modifier as a permanent item attribute
	-- The weapon system reads EPIC_ELEMENT_TYPE/VALUE directly (like a fire sword).
	local elemCombatType = nil
	local elemValue = 0
	for _, rolled in ipairs(rolledMods) do
		local combatType = EpicItems.elementCombatTypes[rolled.mod.effect]
		if combatType and scaledAttack > 0 then
			elemCombatType = combatType
			elemValue = math.max(1, math.floor(scaledAttack * rolled.value / 100))
			break
		end
	end

	-- Set identification attributes
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_RARITY,     rarity.id)
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 1)
	item:setAttribute(ITEM_ATTRIBUTE_NAME, newName)

	-- Override combat stats
	if scaledAttack  > 0 then item:setAttribute(ITEM_ATTRIBUTE_ATTACK,  scaledAttack)  end
	if scaledDefense > 0 then item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, scaledDefense) end
	if scaledArmor   > 0 then item:setAttribute(ITEM_ATTRIBUTE_ARMOR,   scaledArmor)   end

	-- Elemental bonus (stored permanently, handled by C++ weapon system)
	if elemCombatType then
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ELEMENT_TYPE,  elemCombatType)
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ELEMENT_VALUE, elemValue)
	end

	-- Store modifier attributes (up to 5 slots)
	local modAttrIds = {
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_1_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_1_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_2_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_2_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_3_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_3_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_4_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_4_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_5_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_5_VALUE },
	}
	for i, rolled in ipairs(rolledMods) do
		if modAttrIds[i] then
			item:setAttribute(modAttrIds[i][1], rolled.mod.id)
			item:setAttribute(modAttrIds[i][2], rolled.value)
		end
	end

	-- Build look description
	local descLines = { "[" .. rarity.name .. " Epic Item]" }
	for _, rolled in ipairs(rolledMods) do
		-- description field contains a format string like "Adds %d%% fire damage to attacks"
		local formatted = string.format(rolled.mod.description, rolled.value)
		descLines[#descLines + 1] = formatted
	end
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, table.concat(descLines, "\n"))

	-- Loot message suffix
	item:setAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX, " [" .. rarity.name .. "]")

	logger.info("[EpicItems.identify] rarity={} mult={} atk={}->{} def={}->{} armor={}->{} mods={}",
		rarity.name, mult, baseAttack, scaledAttack, baseDefense, scaledDefense, baseArmor, scaledArmor, #rolledMods)

	return rarity
end
