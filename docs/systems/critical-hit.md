# Critical Hit System

## Chance (Weapon Skill Based)

Applied in `src/creatures/combat/combat.cpp` → `Combat::applyExtensions()`.

**Formula**: `weaponCritChance = min(skillLevel * 25, 5000)` (10000 = 100%)

| Skill | Crit chance |
|---|---|
| 10 | 2.5% |
| 100 | 25.0% |
| 200 | 50.0% (cap) |

Weapon → skill mapping via `player->getWeaponSkill(item)` — use `getWeapon(true)`:
- Sword/Axe/Club → melee skill
- Bow/Crossbow/Spear/Throwing knife → `SKILL_DISTANCE`
- Wand → `getMagicLevel()`
- No weapon → `SKILL_FIST`

Item bonuses (`SKILL_CRITICAL_HIT_CHANCE` via `varSkills`) stack on top.

## Damage

Base stored in `skill_critical_hit_damage` DB column (default `5000` = 50%).

Migration `20260408000001_crit_damage_base_to_db.lua` seeds existing players to `5000`.

**Multiplier**: `1.0 + getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE) / 10000`
- DB=5000: ×1.5 (+50%)
- DB=5000 + item=2500: ×1.75 (+75%)

## Protocol

`AddPlayerSkills` sends `getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE)` directly. Client formats as `"X.XX%"` (÷100). `sendSkills()` called on equip/deequip.
