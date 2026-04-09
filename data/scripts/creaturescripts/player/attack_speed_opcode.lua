local handler = CreatureEvent("AttackSpeedOpcodeRequest")
local ATTACK_SPEED_OPCODE = 101
local SKILL_ATTACK_SPEED = 13

-- Mirror of C++ Player::getWeaponSkill() for attack speed display calculation.
local function getWeaponSkillForAttackSpeed(player)
	local weaponItem = player:getSlotItem(CONST_SLOT_RIGHT)
	if not weaponItem then
		return player:getSkillLevel(SKILL_FIST)
	end
	local wt = weaponItem:getType():getWeaponType()
	if wt == WEAPON_SWORD then
		return player:getSkillLevel(SKILL_SWORD)
	elseif wt == WEAPON_CLUB then
		return player:getSkillLevel(SKILL_CLUB)
	elseif wt == WEAPON_AXE then
		return player:getSkillLevel(SKILL_AXE)
	elseif wt == WEAPON_DISTANCE or wt == WEAPON_MISSILE then
		return player:getSkillLevel(SKILL_DISTANCE)
	elseif wt == WEAPON_WAND then
		return player:getMagicLevel()
	end
	return 0
end

-- Handles "request" sent by the client in skills.lua refresh() after onGameStart.
-- Computes the same display value as C++ sendAttackSpeedExtendedOpcode() and sends it back.
function handler.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= ATTACK_SPEED_OPCODE then return end
	if buffer ~= "request" then return end

	local weaponBonus = math.min(getWeaponSkillForAttackSpeed(player), 250)
	local display = player:getSkillLevel(SKILL_ATTACK_SPEED) * 10 + weaponBonus
	player:sendExtendedOpcode(ATTACK_SPEED_OPCODE, tostring(display))
end

handler:register()
