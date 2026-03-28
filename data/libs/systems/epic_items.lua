-- Epic Items System
-- Manages drop and identification of epic items.
-- Items drop as unidentified; players use an identify rune to reveal rarity and modifiers.

EpicItems = {
	rarities      = {},  -- [id] = { id, name, code, modifiers_count, min_increase, max_increase, color_name, drop_chance }
	modifiers     = {},  -- [id] = { id, type, effect, name, effect_type, min_value, max_value }
	typeModifiers = {},  -- [epic_item_type_id] = { modifier_id, ... }
	items         = {},  -- [id] = row from epic_items
	byLevel       = {},  -- sorted list of epic_item rows for level-based lookup
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Startup cache loading
-- ──────────────────────────────────────────────────────────────────────────────

function EpicItems.init()
	-- Rarities
	local result = db.storeQuery("SELECT * FROM `epic_items_rarity` ORDER BY `id` ASC")
	if result then
		repeat
			local row = {
				id             = Result.getNumber(result, "id"),
				name           = Result.getString(result, "name"),
				code           = Result.getString(result, "code"),
				modifiers_count= Result.getNumber(result, "modifiers_count"),
				min_increase   = tonumber(Result.getString(result, "min_increase")),
				max_increase   = tonumber(Result.getString(result, "max_increase")),
				color_name     = Result.getString(result, "color_name"),
				drop_chance    = tonumber(Result.getString(result, "drop_chance")),
			}
			EpicItems.rarities[row.id] = row
		until not Result.next(result)
		Result.free(result)
	else
		logger.warn("[EpicItems] epic_items_rarity table missing or empty.")
	end

	-- Modifiers
	result = db.storeQuery("SELECT * FROM `epic_items_modifiers` ORDER BY `id` ASC")
	if result then
		repeat
			local row = {
				id          = Result.getNumber(result, "id"),
				type        = Result.getString(result, "type"),
				effect      = Result.getString(result, "effect"),
				name        = Result.getString(result, "name"),
				effect_type = Result.getString(result, "effect_type"),
				min_value   = tonumber(Result.getString(result, "min_value")),
				max_value   = tonumber(Result.getString(result, "max_value")),
			}
			EpicItems.modifiers[row.id] = row
		until not Result.next(result)
		Result.free(result)
	end

	-- Type → Modifiers mapping
	result = db.storeQuery("SELECT * FROM `epic_items_modifiers_epic_item_types`")
	if result then
		repeat
			local typeId = Result.getNumber(result, "epic_item_type_id")
			local modId  = Result.getNumber(result, "epic_item_modifier_id")
			if not EpicItems.typeModifiers[typeId] then
				EpicItems.typeModifiers[typeId] = {}
			end
			table.insert(EpicItems.typeModifiers[typeId], modId)
		until not Result.next(result)
		Result.free(result)
	end

	-- Epic Items
	result = db.storeQuery("SELECT * FROM `epic_items` ORDER BY `min_monster_level` ASC")
	if result then
		repeat
			local row = {
				id                          = Result.getNumber(result, "id"),
				name                        = Result.getString(result, "name"),
				server_item_id              = Result.getNumber(result, "server_item_id"),
				server_item_unidentified_id = Result.getNumber(result, "server_item_unidentified_id"),
				epic_item_type_id           = Result.getNumber(result, "epic_item_type_id"),
				weight                      = Result.getNumber(result, "weight"),
				attack                      = Result.getNumber(result, "attack"),
				defense                     = Result.getNumber(result, "defense"),
				armor                       = Result.getNumber(result, "armor"),
				range                       = Result.getNumber(result, "range"),
				req_level                   = Result.getNumber(result, "req_level"),
				vocation_id                 = Result.getNumber(result, "vocation_id"),
				min_monster_level           = Result.getNumber(result, "min_monster_level"),
				max_monster_level           = Result.getNumber(result, "max_monster_level"),
				base_drop_chance            = tonumber(Result.getString(result, "base_drop_chance")),
			}
			EpicItems.items[row.id] = row
			table.insert(EpicItems.byLevel, row)
		until not Result.next(result)
		Result.free(result)
	else
		logger.warn("[EpicItems] epic_items table missing or empty.")
	end

	logger.info("[EpicItems] Loaded {} rarities, {} modifiers, {} items.",
		#EpicItems.rarities, #EpicItems.modifiers, #EpicItems.byLevel)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Drop logic
-- ──────────────────────────────────────────────────────────────────────────────

-- Returns a random epic_items row eligible for the given monster level, or nil.
function EpicItems.rollDrop(monsterLevel, player)
	local eligible = {}
	for _, row in ipairs(EpicItems.byLevel) do
		if monsterLevel >= row.min_monster_level and monsterLevel <= row.max_monster_level then
			table.insert(eligible, row)
		end
	end
	if #eligible == 0 then
		return nil
	end

	local dropBonus = (player and player.getDropChanceBonus) and player:getDropChanceBonus() or 0
	-- Roll each eligible item independently
	local dropped = {}
	for _, row in ipairs(eligible) do
		local chance = row.base_drop_chance * (1 + dropBonus)
		if math.random() < chance then
			table.insert(dropped, row)
		end
	end
	if #dropped == 0 then
		return nil
	end
	-- Return one random dropped item
	return dropped[math.random(#dropped)]
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Item creation
-- ──────────────────────────────────────────────────────────────────────────────

-- Creates and returns an unidentified Item instance for the given epic_items row.
function EpicItems.createUnidentified(epicRow)
	local item = Game.createItem(epicRow.server_item_unidentified_id, 1)
	if not item then
		logger.warn("[EpicItems] Failed to create item with id {}", epicRow.server_item_unidentified_id)
		return nil
	end
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID, epicRow.id)
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 0)
	item:setAttribute(ITEM_ATTRIBUTE_NAME, "Unidentified " .. epicRow.name)
	return item
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Identification
-- ──────────────────────────────────────────────────────────────────────────────

local function shuffleTable(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Rolls rarity for identification. Returns rarity row (Rare or Magic or Normal).
local function rollRarity(player)
	local dropBonus = (player and player.getDropChanceBonus) and player:getDropChanceBonus() or 0

	-- Try Rare first (id=3), then Magic (id=2), fallback Normal (id=1)
	local rare   = EpicItems.rarities[3]
	local magic  = EpicItems.rarities[2]
	local normal = EpicItems.rarities[1]

	if rare then
		local rareChance = rare.drop_chance * (1 + dropBonus)
		if math.random() < rareChance then
			return rare
		end
	end
	if magic then
		if math.random() < magic.drop_chance then
			return magic
		end
	end
	return normal
end

-- Applies scaled stats + modifiers to an item, transforming it to its identified form.
-- item: Item userdata (unidentified, stackable)
-- epicRow: row from EpicItems.items
-- player: Player userdata (for drop_chance_bonus)
function EpicItems.identify(item, epicRow, player)
	local rarity = rollRarity(player)
	-- Rune identification always yields at least Magic (id=2)
	if rarity.id < 2 then rarity = EpicItems.rarities[2] end

	-- Apply stat multiplier (random between min_increase and max_increase)
	local mult = rarity.min_increase + math.random() * (rarity.max_increase - rarity.min_increase)
	local scaledAttack  = math.floor(epicRow.attack  * mult)
	local scaledDefense = math.floor(epicRow.defense * mult)
	local scaledArmor   = math.floor(epicRow.armor   * mult)

	-- Roll modifiers (before transform, no side effects)
	local availableModIds = EpicItems.typeModifiers[epicRow.epic_item_type_id] or {}
	local shuffled = {}
	for _, mid in ipairs(availableModIds) do
		table.insert(shuffled, mid)
	end
	shuffleTable(shuffled)

	local usedTypes = {}
	local rolledMods = {}  -- {mod, value}
	for _, modId in ipairs(shuffled) do
		if #rolledMods >= rarity.modifiers_count then break end
		local mod = EpicItems.modifiers[modId]
		if mod and not usedTypes[mod.type] then
			local value = math.floor(mod.min_value + math.random() * (mod.max_value - mod.min_value))
			value = math.floor(value * mult)
			table.insert(rolledMods, { mod = mod, value = value })
			usedTypes[mod.type] = true
		end
	end

	-- Build name (before transform, no side effects)
	local baseName = epicRow.name
	local newName = baseName
	if #rolledMods == 1 then
		newName = rolledMods[1].mod.name .. " " .. baseName
	elseif #rolledMods >= 2 then
		newName = rolledMods[1].mod.name .. " " .. baseName .. " of " .. rolledMods[2].mod.name
	end

	-- Transform to identified sprite FIRST — transform resets item attributes
	item:transform(epicRow.server_item_id)

	-- Set ALL attributes after transform so they are preserved
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_RARITY,     rarity.id)
	item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 1)
	item:setAttribute(ITEM_ATTRIBUTE_NAME, newName)

	-- Override combat stats
	logger.info("[EpicItems.identify] rarity={} mult={} atk={}->{} def={}->{} armor={}->{}",
		rarity.name, mult, epicRow.attack, scaledAttack, epicRow.defense, scaledDefense, epicRow.armor, scaledArmor)
	if scaledAttack > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_ATTACK, scaledAttack)
	end
	if scaledDefense > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, scaledDefense)
	end
	if scaledArmor > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_ARMOR, scaledArmor)
	end
	logger.info("[EpicItems.identify] after setAttribute: item atk={} def={}",
		item:getAttribute(ITEM_ATTRIBUTE_ATTACK), item:getAttribute(ITEM_ATTRIBUTE_DEFENSE))

	-- Store modifier attributes
	local modAttrIds = {
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_1_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_1_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_2_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_2_VALUE },
		{ ITEM_ATTRIBUTE_EPIC_MODIFIER_3_ID, ITEM_ATTRIBUTE_EPIC_MODIFIER_3_VALUE },
	}
	for i, rolled in ipairs(rolledMods) do
		item:setAttribute(modAttrIds[i][1], rolled.mod.id)
		item:setAttribute(modAttrIds[i][2], rolled.value)
	end

	-- Build look description: rarity line + one line per modifier
	local descLines = { "[" .. rarity.name .. " Epic Item]" }
	for _, rolled in ipairs(rolledMods) do
		local sign = rolled.value >= 0 and "+" or ""
		local suffix = rolled.mod.effect_type == "percent" and "%" or ""
		table.insert(descLines, rolled.mod.name .. ": " .. sign .. rolled.value .. suffix)
	end
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, table.concat(descLines, "\n"))

	-- Loot message suffix with rarity color hint
	item:setAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX,
		" [" .. rarity.name .. "]")

	return rarity
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Monster drop callback (called from ondroploot__base.lua in mixed/epic modes)
-- ──────────────────────────────────────────────────────────────────────────────

function EpicItems.onDropLoot(monster, corpse)
	local player = Player(corpse:getCorpseOwner())
	local mType = monster:getType()
	if not mType then return end

	local monsterLevel = mType:level() or 1
	local epicRow = EpicItems.rollDrop(monsterLevel, player)
	if not epicRow then return end

	-- 50% chance: drop already-identified Normal; 50%: drop unidentified
	if math.random() < 0.5 then
		-- Drop Normal identified version — base stats, no modifiers
		local item = corpse:addItem(epicRow.server_item_id, 1)
		if not item or type(item) ~= "userdata" then
			logger.warn("[EpicItems] Failed to add identified item {} to corpse", epicRow.server_item_id)
			return
		end
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID, epicRow.id)
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_RARITY, 1)
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 1)
		item:setAttribute(ITEM_ATTRIBUTE_NAME, epicRow.name)
	else
		-- Drop unidentified version
		local item = corpse:addItem(epicRow.server_item_unidentified_id, 1)
		if not item or type(item) ~= "userdata" then
			logger.warn("[EpicItems] Failed to add unidentified item {} to corpse", epicRow.server_item_unidentified_id)
			return
		end
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_ID, epicRow.id)
		item:setAttribute(ITEM_ATTRIBUTE_EPIC_ITEM_IDENTIFIED, 0)
		item:setAttribute(ITEM_ATTRIBUTE_NAME, "Unidentified " .. epicRow.name)
	end
end
