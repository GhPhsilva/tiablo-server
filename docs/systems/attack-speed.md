# Bonus Attack Speed System

`SKILL_ATTACK_SPEED = 13` — static (non-trainable) skill reducing attack interval in ms.

## Formula (`src/creatures/players/player.hpp` → `getAttackSpeed()`)

```
totalBonus_1000 = getSkillLevel(SKILL_ATTACK_SPEED) * 10 + min(weaponSkill, 250)
msReduction     = base * totalBonus_1000 / 1000
result          = max(MAX_ATTACK_SPEED, base - msReduction)
```

## Weapon → Skill Mapping

Sword/Axe/Club → melee; Bow/Distance → `SKILL_DISTANCE`; Wand → `getMagicLevel()`; none → `SKILL_FIST`. Cap: 250 (25%).

Item bonuses: `enhancedattackspeed` XML attribute → `varSkills[SKILL_ATTACK_SPEED]` via `movement.cpp`.

## Protocol

Sent via **extended opcode 101** (not binary skills) to avoid 4-byte desync in pre-compiled OtClientV8.

Flow: `onGameStart` → client sends `"request"` → server `attack_speed_opcode.lua` replies with `DB×10 + weaponBonus` → client sets `skillId13`.

On equip/deequip: `movement.cpp` → `sendSkills()` → `sendAttackSpeedExtendedOpcode()` (`protocolgame.cpp`).

```cpp
void ProtocolGame::sendAttackSpeedExtendedOpcode() {
    auto weaponForSpeed = player->getWeapon(true);
    int32_t weaponBonus = std::min<int32_t>(player->getWeaponSkill(weaponForSpeed), 250);
    uint16_t display = static_cast<uint16_t>(
        static_cast<int32_t>(player->getSkillLevel(SKILL_ATTACK_SPEED)) * 10 + weaponBonus
    );
    // sends via extMsg byte 0x32, opcode 101
}
```

## DB Migration

`20260408000002_add_skill_attack_speed.lua` adds `skill_attack_speed int DEFAULT 0` and `skill_attack_speed_tries bigint DEFAULT 0`.

## Testing

`UPDATE players SET skill_attack_speed=50` → display 50.0% + weapon bonus. Wand + ML 100 → +10.00%.
