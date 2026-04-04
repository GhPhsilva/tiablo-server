# Atributo `criticalhitdamage`

Aumenta o multiplicador de dano aplicado quando um critical hit ocorre.

## Conceito

```
bonus     = getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE)   ← soma de todos os itens equipados
multiplier = 1.0 + bonus / 10000
dano_crit  = dano_base * multiplier
```

O `bonus` acumula **aditivamente** — cada item equipado com `criticalhitdamage` soma diretamente ao valor total. O multiplicador é aplicado sobre `damage.primary.value` e `damage.secondary.value` quando o critical hit dispara.

**Unidade:** centésimos de porcento. `value="100"` = +1% de dano no crit.

**Exemplo:** espada com `criticalhitdamage=200` + amuleto com `criticalhitdamage=100`:
- bonus = 300
- multiplier = 1.0 + 300/10000 = 1.03 → +3% de dano no crit

**Valor base sem item:** `bonus=50` (hardcoded em `combat.cpp`) → +0.5% de dano no crit mínimo quando o crit dispara.

---

## Sistema já implementado — nenhuma mudança de lógica necessária

### Parsing (`src/items/functions/item/item_parse.cpp`)

Já existe:

```cpp
} else if (stringValue == "criticalhitdamage") {
    itemType.getAbilities().skills[SKILL_CRITICAL_HIT_DAMAGE] = pugi::cast<int32_t>(valueAttribute.value());
}
```

### Acumulação ao equipar/desequipar (`src/lua/creature/movement.cpp:694`)

Usa o mesmo mecanismo de todos os outros skills de item via `varSkills`:

```cpp
// Ao equipar
player->setVarSkill(static_cast<skills_t>(i), item->getSkill(static_cast<skills_t>(i)));

// Ao desequipar
player->setVarSkill(static_cast<skills_t>(i), -item->getSkill(static_cast<skills_t>(i)));
```

`setVarSkill` apenas faz `varSkills[skill] += modifier` — cada item equipado soma diretamente ao acumulador global.

### Leitura em combate (`src/creatures/combat/combat.cpp:2107`)

```cpp
uint16_t chance = 0;
int32_t bonus = 50;   // base mínima hardcoded

if (player) {
    chance = player->getSkillLevel(SKILL_CRITICAL_HIT_CHANCE);
    bonus  = player->getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE);
    // getSkillLevel = base + varSkills[skill] + wheel bonuses
}

bonus += damage.criticalDamage;   // bônus extra por spell/habilidade específica
double multiplier = 1.0 + static_cast<double>(bonus) / 10000;
chance += (uint16_t)damage.criticalChance;

if (chance != 0 && uniform_random(1, 10000) <= chance) {
    damage.critical = true;
    damage.primary.value   *= multiplier;
    damage.secondary.value *= multiplier;
}
```

> `SKILL_CRITICAL_HIT_CHANCE` determina a probabilidade (0–100, cap configurável via `criticalChance` em `config.lua`, default 10).
> `SKILL_CRITICAL_HIT_DAMAGE` determina o bônus de dano quando o crit dispara — sem cap hardcoded.

### Tooltip

Exibido automaticamente via `protocolgame.cpp` no bloco de combat stats (`SKILL_CRITICAL_HIT_CHANCE` até `SKILL_LAST`). Nenhuma adição necessária em `item.cpp`.

---

## Slots compatíveis

O acúmulo acontece via `varSkills` ao equipar/desequipar em **qualquer slot**. Não há restrição de slot:

| Item | Slot |
|---|---|
| Helmet | `CONST_SLOT_HEAD` |
| Armor | `CONST_SLOT_ARMOR` |
| Legs | `CONST_SLOT_LEGS` |
| Boots | `CONST_SLOT_FEET` |
| Shield | `CONST_SLOT_RIGHT` |
| Weapon | `CONST_SLOT_LEFT` |
| Amulet | `CONST_SLOT_NECKLACE` |
| Ring | `CONST_SLOT_RING` |
| Belt | `CONST_SLOT_BELT` |

---

## Uso no XML

Já funciona sem nenhuma mudança no código:

```xml
<item id="2392" article="a" name="helmet of the ancients">
    <attribute key="criticalhitdamage" value="200"/>  <!-- +2% de dano no crit -->
</item>

<item id="2472" article="a" name="plate armor">
    <attribute key="criticalhitdamage" value="150"/>  <!-- +1.5% de dano no crit -->
</item>
```

---

## Resumo de arquivos

| Arquivo | Natureza da mudança |
|---|---|
| `data/items/items.xml` | Atributos nos itens desejados |

Todos os outros arquivos (`item_parse.cpp`, `movement.cpp`, `combat.cpp`, `protocolgame.cpp`) **já estão prontos**.

---

## Notas

- A acumulação é **aditiva** — sem diminishing returns. Diferente do `enhancedamage`, que usa fórmula hiperbólica.
- O `criticalhitchance` (probabilidade de ocorrer o crit) é um atributo separado e independente, também já suportado.
- `bonus=50` hardcoded garante que mesmo sem nenhum item, um crit sempre aplica ao menos +0.5% de dano. Na prática esse valor base é irrelevante — o que importa é o total dos itens.
- O valor de `criticalhitdamage` nos itens está em centésimos de porcento para permitir granularidade fina sem usar float no XML.
