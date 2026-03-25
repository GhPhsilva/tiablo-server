local createEpicMonster = TalkAction("/em")

-- Usage:
--   /em Rat              → spawns a Rat with random epic difficulty
--   /em Rat, normal      → spawns a Rat forced as normal epic
--   /em Rat, nightmare   → spawns a Rat forced as nightmare epic
--   /em Rat, hell        → spawns a Rat forced as hell epic
function createEpicMonster.onSay(player, words, param)
	logCommand(player, words, param)

	if param == "" then
		player:sendCancelMessage("Usage: /em <monster name>[, normal|nightmare|hell]")
		return true
	end

	local split = param:split(",")
	local monsterName = split[1]:gsub("^%s*(.-)%s*$", "%1")
	local difficulty  = split[2] and split[2]:gsub("^%s*(.-)%s*$", "%1"):lower() or nil

	if difficulty and difficulty ~= "normal" and difficulty ~= "nightmare" and difficulty ~= "hell" then
		player:sendCancelMessage("Invalid difficulty. Use: normal, nightmare or hell.")
		return true
	end

	local position = player:getPosition()
	local monster  = Game.createMonster(monsterName, position)
	if not monster then
		player:sendCancelMessage("Could not spawn monster '" .. monsterName .. "'. Check the name.")
		position:sendMagicEffect(CONST_ME_POFF)
		return true
	end

	local ok = EpicMonster.makeEpic(monster, difficulty)
	if not ok then
		player:sendCancelMessage("Monster spawned, but epic system not ready or difficulty not found.")
	end

	monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	position:sendMagicEffect(CONST_ME_MAGIC_RED)

	local tierLabel = difficulty or "random"
	logger.info("Player {} spawned epic '{}' [{}]", player:getName(), monsterName, tierLabel)
	return true
end

createEpicMonster:separator(" ")
createEpicMonster:groupType("god")
createEpicMonster:register()
