-- Epic Monsters System
-- Gives spawning monsters a configurable chance to become "epic" variants
-- with scaled stats, random abilities, a skull, and bonus loot/XP.
-- All tunable values are stored in MySQL (epic_monsters_config / epic_monsters_scaling).

EpicMonster = {}

-- Creature storage keys (ephemeral, not persisted to DB)
local STORAGE_EPIC_DIFF      = 99001  -- difficulty id (1/2/3); 0 = not epic
local STORAGE_EPIC_LOOT      = 99002  -- loot_bonus * 100 (stored as integer)
local STORAGE_EPIC_XP        = 99003  -- xp_scale * 100 (stored as integer)
local STORAGE_EPIC_ABILITIES = 99004  -- bitmask of applied abilities

-- Expose storage keys so callbacks can read them without depending on load order
EpicMonster.STORAGE_EPIC_DIFF      = STORAGE_EPIC_DIFF
EpicMonster.STORAGE_EPIC_LOOT      = STORAGE_EPIC_LOOT
EpicMonster.STORAGE_EPIC_XP        = STORAGE_EPIC_XP
EpicMonster.STORAGE_EPIC_ABILITIES = STORAGE_EPIC_ABILITIES

-- Bitmask values for each ability (used to encode/decode applied abilities)
local ABILITY_BITS = {
	extra_strong = 1,
	extra_fast   = 2,
	assassin     = 4,
	regenerador  = 8,
	tank         = 16,
}

-- Human-readable labels shown on look
local ABILITY_LABELS = {
	extra_strong = "Extra Strong",
	extra_fast   = "Extra Fast",
	assassin     = "Assassin",
	regenerador  = "Regeneration",
	tank         = "Tank",
}

EpicMonster.config  = { enabled = false, spawn_chance = 0, title = "Epic" }
EpicMonster.scaling = {}  -- array of difficulty rows, sorted by id

EpicMonster.prefixes = {}  -- populated from DB by loadConfig()


-- ──────────────────────────────────────────────────────────────────────────────
-- Combat-gated loops (fire only when players are nearby, stop on monster death)
-- ──────────────────────────────────────────────────────────────────────────────

local function hasNearbyPlayer(position)
	return #Game.getSpectators(position, false, true) > 0
end

local REGEN_INTERVAL_MS = 5000

local function scheduleRegen(monsterId, healAmount)
	local monster = Monster(monsterId)
	if not monster then return end  -- died, stop loop
	if hasNearbyPlayer(monster:getPosition()) then
		monster:addHealth(healAmount)
	end
	addEvent(scheduleRegen, REGEN_INTERVAL_MS, monsterId, healAmount)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Abilities
-- Each function receives (monster, scalingRow) and applies its effect.
-- ──────────────────────────────────────────────────────────────────────────────
local abilityPool = {
	-- Extra Strong: boosts melee skill and enables hazard damage multiplier
	extra_strong = function(monster, scale)
		local bonus = math.floor((scale.damage_scale - 1.0) * 100)
		if bonus > 0 then
			local cond = Condition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT)
			cond:setParameter(CONDITION_PARAM_SKILL_MELEE, bonus)
			cond:setTicks(-1)
			monster:addCondition(cond)
		end
		monster:hazardDamageBoost(true)
	end,

	-- Extra Fast: raises movement speed by speed_scale
	extra_fast = function(monster, scale)
		local factor = (scale.speed_scale and scale.speed_scale > 1.0) and scale.speed_scale or 1.3
		local speedDelta = math.ceil(monster:getBaseSpeed() * (factor - 1.0))
		monster:changeSpeed(speedDelta)
	end,

	-- Assassin: enables critical-hit pathway via hazard system
	assassin = function(monster, _scale)
		monster:hazardCrit(true)
	end,

	-- Regenerador: heals ~2% max HP every 5s, only while a player is nearby
	regenerador = function(monster, _scale)
		local healAmount = math.max(1, math.ceil(monster:getMaxHealth() * 0.02))
		addEvent(scheduleRegen, REGEN_INTERVAL_MS, monster:getId(), healAmount)
	end,

	-- Tank: permanent armor and defense boost
	tank = function(monster, _scale)
		local cond = Condition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT)
		cond:setParameter(CONDITION_PARAM_STAT_ARMOR, 50)
		cond:setParameter(CONDITION_PARAM_STAT_DEFENSE, 50)
		cond:setTicks(-1)
		monster:addCondition(cond)
	end,
}

-- Ordered list of ability keys (for consistent random selection)
local abilityKeys = { "extra_strong", "extra_fast", "assassin", "regenerador", "tank" }

-- ──────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────────────────────────

-- Weighted random pick: returns index into EpicMonster.scaling
local function pickDifficulty()
	local totalWeight = 0
	for _, row in ipairs(EpicMonster.scaling) do
		totalWeight = totalWeight + row.weight
	end
	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for i, row in ipairs(EpicMonster.scaling) do
		cumulative = cumulative + row.weight
		if roll <= cumulative then
			return i
		end
	end
	return #EpicMonster.scaling
end

-- Pick `count` distinct random abilities from the pool
local function pickAbilities(count)
	local available = {}
	for _, key in ipairs(abilityKeys) do
		available[#available + 1] = key
	end
	local chosen = {}
	count = math.min(count, #available)
	for _ = 1, count do
		local idx = math.random(1, #available)
		chosen[#chosen + 1] = available[idx]
		table.remove(available, idx)
	end
	return chosen
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────────────

function EpicMonster.isEpic(monster)
	return monster:getStorageValue(STORAGE_EPIC_DIFF) > 0
end

-- Returns a list of human-readable ability names applied to this monster.
function EpicMonster.getAbilityLabels(monster)
	local mask = monster:getStorageValue(STORAGE_EPIC_ABILITIES)
	if mask <= 0 then
		return {}
	end
	local labels = {}
	for key, bit in pairs(ABILITY_BITS) do
		if math.floor(mask / bit) % 2 == 1 then
			labels[#labels + 1] = ABILITY_LABELS[key]
		end
	end
	return labels
end

-- Load configuration from MySQL. Called once at server startup.
function EpicMonster.loadConfig()
	-- Global config
	local cfgResult = db.storeQuery("SELECT `enabled`, `spawn_chance`, `title` FROM `epic_monsters_config` WHERE `enabled` = 1 LIMIT 1")
	if not cfgResult then
		logger.warn("[EpicMonster] epic_monsters_config table is empty or missing. System disabled.")
		return
	end
	EpicMonster.config.enabled      = Result.getNumber(cfgResult, "enabled") == 1
	EpicMonster.config.spawn_chance = Result.getNumber(cfgResult, "spawn_chance")
	EpicMonster.config.title        = Result.getString(cfgResult, "title")
	Result.free(cfgResult)

	-- Per-difficulty scaling
	EpicMonster.scaling = {}
	local scalingResult = db.storeQuery(
		"SELECT `id`, `difficulty`, `weight`, `skull`, `loot_bonus`, " ..
		"`hp_scale`, `speed_scale`, `xp_scale`, `damage_scale`, `abilities_count` " ..
		"FROM `epic_monsters_scaling` ORDER BY `id` ASC"
	)
	if not scalingResult then
		logger.warn("[EpicMonster] epic_monsters_scaling table is empty or missing. System disabled.")
		EpicMonster.config.enabled = false
		return
	end
	repeat
		local row = {
			id              = Result.getNumber(scalingResult, "id"),
			difficulty      = Result.getString(scalingResult, "difficulty"),
			weight          = Result.getNumber(scalingResult, "weight"),
			skull           = Result.getNumber(scalingResult, "skull"),
			loot_bonus      = Result.getNumber(scalingResult, "loot_bonus"),
			hp_scale        = Result.getNumber(scalingResult, "hp_scale"),
			speed_scale     = Result.getNumber(scalingResult, "speed_scale"),
			xp_scale        = Result.getNumber(scalingResult, "xp_scale"),
			damage_scale    = Result.getNumber(scalingResult, "damage_scale"),
			abilities_count = Result.getNumber(scalingResult, "abilities_count"),
		}
		EpicMonster.scaling[#EpicMonster.scaling + 1] = row
	until not Result.next(scalingResult)
	Result.free(scalingResult)

	-- Prefixes
	EpicMonster.prefixes = {}
	local prefixResult = db.storeQuery("SELECT `prefix` FROM `epic_monsters_prefixes` WHERE `enabled` = 1 ORDER BY `id` ASC")
	if prefixResult then
		repeat
			EpicMonster.prefixes[#EpicMonster.prefixes + 1] = Result.getString(prefixResult, "prefix")
		until not Result.next(prefixResult)
		Result.free(prefixResult)
	else
		logger.warn("[EpicMonster] epic_monsters_prefixes table is empty or missing. No prefixes loaded.")
	end
end

-- Internal: applies epic transformation to a monster using a specific scaling row index.
local function applyEpic(monster, diffIdx)
	local scale = EpicMonster.scaling[diffIdx]
	if not scale then return false end

	-- ── Skull ─────────────────────────────────────────────────────────────
	monster:setSkull(scale.skull)

	-- ── HP ────────────────────────────────────────────────────────────────
	local newMaxHP = math.ceil(monster:getMaxHealth() * scale.hp_scale)
	monster:setMaxHealth(newMaxHP)
	monster:setHealth(newMaxHP)

	-- ── Store metadata for loot/XP callbacks ──────────────────────────────
	monster:setStorageValue(STORAGE_EPIC_DIFF, diffIdx)
	monster:setStorageValue(STORAGE_EPIC_LOOT, math.floor(scale.loot_bonus * 100))
	monster:setStorageValue(STORAGE_EPIC_XP,   math.floor(scale.xp_scale   * 100))

	-- ── Abilities ─────────────────────────────────────────────────────────
	local chosen = pickAbilities(scale.abilities_count)
	local abilityMask = 0
	for _, key in ipairs(chosen) do
		abilityPool[key](monster, scale)
		abilityMask = abilityMask + (ABILITY_BITS[key] or 0)
	end
	monster:setStorageValue(STORAGE_EPIC_ABILITIES, abilityMask)

	return true
end

-- Called from monsterOnSpawn EventCallback.
function EpicMonster.onSpawn(monster, _position)
	-- Skip summons
	if monster:getMaster() ~= nil then
		return
	end

	if not EpicMonster.config.enabled then
		return
	end

	if #EpicMonster.scaling == 0 then
		return
	end

	-- Roll for epic
	if math.random(1, 100) > EpicMonster.config.spawn_chance then
		return
	end

	applyEpic(monster, pickDifficulty())
end

-- Forces a monster to become epic with an optional specific difficulty name.
-- difficultyName: "normal", "nightmare", "hell", or nil for random.
-- Returns true on success, false if difficulty not found or scaling not loaded.
function EpicMonster.makeEpic(monster, difficultyName)
	if #EpicMonster.scaling == 0 then
		return false
	end

	local diffIdx
	if difficultyName then
		local name = difficultyName:lower()
		for i, row in ipairs(EpicMonster.scaling) do
			if row.difficulty == name then
				diffIdx = i
				break
			end
		end
		if not diffIdx then
			return false
		end
	else
		diffIdx = pickDifficulty()
	end

	return applyEpic(monster, diffIdx)
end

-- Called from monsterOnDropLoot EventCallback.
function EpicMonster.onDropLoot(monster, corpse)
	if not EpicMonster.isEpic(monster) then
		return
	end

	local mType = monster:getType()
	if not mType then
		return
	end

	-- ── Bonus loot roll ───────────────────────────────────────────────────
	local bonusInt = monster:getStorageValue(STORAGE_EPIC_LOOT)
	if bonusInt > 0 then
		local lootTable = mType:generateLootRoll({ factor = bonusInt / 100, gut = false }, {})
		corpse:addLoot(lootTable)
	end

	-- ── Bonus XP to corpse owner ──────────────────────────────────────────
	local xpInt = monster:getStorageValue(STORAGE_EPIC_XP)
	if xpInt > 100 then
		local player = Player(corpse:getCorpseOwner())
		if player then
			local bonusXP = math.floor(mType:experience() * (xpInt / 100 - 1))
			if bonusXP > 0 then
				player:addExperience(bonusXP, true)
			end
		end
	end

	-- ── Loot message suffix ───────────────────────────────────────────────
	local difficulty = EpicMonster.scaling[monster:getStorageValue(STORAGE_EPIC_DIFF)]
	if difficulty then
		local suffix = corpse:getAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX) or ""
		corpse:setAttribute(ITEM_ATTRIBUTE_LOOTMESSAGE_SUFFIX,
			suffix .. " (epic " .. difficulty.difficulty .. ")")
	end
end
