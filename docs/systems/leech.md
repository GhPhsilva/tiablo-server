# Leech Systems (Life & Mana)

## Life Leech

Applied in `src/game/game.cpp` → `Game::applyLifeLeech()`.

**Chance formula**: `weaponLeechBonus = min(skillLevel, 250)` (scale 0–1000, 0.1% per unit)

Weapon → skill: Sword/Axe/Club → melee; Bow/Distance → `SKILL_DISTANCE`; Wand → **no bonus**; none → `SKILL_FIST`.

| Skill | Chance |
|---|---|
| 100 | 10.0% |
| 250 | 25.0% (cap) |

Scales: `SKILL_LIFE_LEECH_CHANCE` (9) DB 0–100 → internal ×10. `SKILL_LIFE_LEECH_AMOUNT` (10) 0–10000.

Protocol: `effectiveLifeLeechChanceDisplay` = base×10 + weaponBonus. Client: chance ÷10, amount ÷100.

**Testing**: `UPDATE players SET skill_life_leech_chance=100, skill_life_leech_amount=10000`. Reduce HP first to see heal. Effect: `CONST_ME_MAGIC_RED`.

## Mana Leech

Applied in `src/game/game.cpp` → `Game::applyManaLeech()`.

**Weapon → skill**: Wand → `getMagicLevel()` only. All others → **no bonus**.

Scales: `SKILL_MANA_LEECH_CHANCE` (11), `SKILL_MANA_LEECH_AMOUNT` (12). Same scaling as life leech.

Protocol: `effectiveManaLeechChanceDisplay` = base×10 + magicLevel bonus.

**Testing**: `UPDATE players SET skill_mana_leech_chance=100, skill_mana_leech_amount=10000`. Effect: `CONST_ME_MAGIC_BLUE`.

## Weapon Skill Pitfall

`getWeapon()` (ignoreAmmo=false) for bows returns **ammo item**, not the bow. Without quiver → `nullptr` → `SKILL_FIST`.

**Always use `getWeapon(true)`** for crit/leech/display calculations.

Affected: `combat.cpp::applyExtensions()`, `game.cpp::applyLifeLeech()`, `game.cpp::applyManaLeech()`, `protocolgame.cpp::AddPlayerSkills()` (3 calls).
