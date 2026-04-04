# Atributo `enhancedattackspeed`

Modifica o intervalo entre ataques do jogador de forma flat (em ms). Valores positivos aceleram o ataque; valores negativos funcionam como penalidade.

## Conceito

```
varAttackSpeed = soma de todos os enhancedattackspeed equipados
intervalo_final = max(500, vocation_base - varAttackSpeed)
```

A acumulação é **aditiva**. O cap mínimo de **500ms** (mesmo do sistema de fist attack speed) protege contra stacking excessivo pelo lado rápido. Penalidades não têm cap superior — o intervalo pode crescer livremente.

**Exemplos:**
- Espada com `enhancedattackspeed=100` → 1500ms → 1400ms
- Espada `100` + anel `50` → 1500ms − 150 = 1350ms
- Armadura pesada com `enhancedattackspeed=-200` → 1500ms → 1700ms
- Total positivo > (base − 500): cap em 500ms

---

## Sistema atual — nada existe ainda

`Player::getAttackSpeed()` (`player.hpp:2937`) retorna apenas `vocation->getAttackSpeed()`, sem nenhum hook para itens. Há um `TODO: ADD_ATTACK_SPEED` em `movement.cpp:105` que confirma a intenção original.

---

## Plano de implementação

### Passo 1 — `src/items/items.hpp`

Adicionar campo em `ItemAbilities`, após o campo `speed`:

```cpp
int32_t attackSpeed = 0;   // flat ms modifier to attack interval
```

---

### Passo 2 — `src/items/functions/item/item_parse.hpp`

Adicionar ao enum `ItemParseAttributes_t`:

```cpp
ITEM_PARSE_ENHANCEDATTACKSPEED,
```

E ao mapa de strings:

```cpp
{ "enhancedattackspeed", ITEM_PARSE_ENHANCEDATTACKSPEED },
```

---

### Passo 3 — `src/items/functions/item/item_parse.cpp`

Adicionar método de parse e seu case no switch principal:

```cpp
void ItemParse::parseEnhancedAttackSpeed(pugi::xml_attribute valueAttribute, ItemType &itemType) {
    itemType.getAbilities().attackSpeed = pugi::cast<int32_t>(valueAttribute.value());
}
```

---

### Passo 4 — `src/creatures/players/player.hpp`

**a) Campo `varAttackSpeed`** — junto de `varSkills` / `varStats`:

```cpp
int32_t varAttackSpeed = 0;
```

**b) Setter:**

```cpp
void setVarAttackSpeed(int32_t modifier) {
    varAttackSpeed += modifier;
}
```

**c) Modificar `getAttackSpeed()`** para aplicar `varAttackSpeed` e o cap:

```cpp
// ANTES
uint32_t getAttackSpeed() const {
    if (onFistAttackSpeed) {
        uint32_t baseAttackSpeed = vocation->getAttackSpeed();
        uint32_t skillLevel = getSkillLevel(SKILL_FIST);
        uint32_t attackSpeed = baseAttackSpeed - (skillLevel * g_configManager().getNumber(MULTIPLIER_ATTACKONFIST, __FUNCTION__));
        if (attackSpeed < MAX_ATTACK_SPEED) {
            attackSpeed = MAX_ATTACK_SPEED;
        }
        return static_cast<uint32_t>(attackSpeed);
    } else {
        return vocation->getAttackSpeed();
    }
}

// DEPOIS
uint32_t getAttackSpeed() const {
    uint32_t base;
    if (onFistAttackSpeed) {
        uint32_t baseAttackSpeed = vocation->getAttackSpeed();
        uint32_t skillLevel = getSkillLevel(SKILL_FIST);
        uint32_t attackSpeed = baseAttackSpeed - (skillLevel * g_configManager().getNumber(MULTIPLIER_ATTACKONFIST, __FUNCTION__));
        if (attackSpeed < MAX_ATTACK_SPEED) {
            attackSpeed = MAX_ATTACK_SPEED;
        }
        base = attackSpeed;
    } else {
        base = vocation->getAttackSpeed();
    }

    int32_t modified = static_cast<int32_t>(base) - varAttackSpeed;
    // Bônus (varAttackSpeed > 0): limitado pelo cap de 500ms
    // Penalidade (varAttackSpeed < 0): intervalo aumenta livremente
    return static_cast<uint32_t>(std::max<int32_t>(static_cast<int32_t>(MAX_ATTACK_SPEED), modified));
}
```

---

### Passo 5 — `src/lua/creature/movement.cpp`

**Ao equipar** — após o loop de skills (~linha 696):

```cpp
if (it.abilities && it.abilities->attackSpeed != 0) {
    player->setVarAttackSpeed(it.abilities->attackSpeed);
}
```

**Ao desequipar** — após o loop de remoção de skills (~linha 779):

```cpp
if (it.abilities && it.abilities->attackSpeed != 0) {
    player->setVarAttackSpeed(-it.abilities->attackSpeed);
}
```

---

### Passo 6 — `src/items/item.cpp`

Adicionar exibição no tooltip próximo ao bloco de `cleavePercent` / `perfectShotDamage`:

```cpp
if (it.abilities->attackSpeed != 0) {
    descriptions.emplace_back("Attack Speed", fmt::format("{:+} ms", -it.abilities->attackSpeed));
    // Invertido no display: valor positivo = "mais rápido" = exibe como negativo em ms
}
```

---

## Uso no XML

```xml
<!-- Bônus: reduz o intervalo de ataque -->
<item id="3264" article="a" name="fire sword">
    <attribute key="enhancedattackspeed" value="100"/>  <!-- 1500ms → 1400ms -->
</item>

<!-- Penalidade: aumenta o intervalo de ataque -->
<item id="2472" article="a" name="heavy plate armor">
    <attribute key="enhancedattackspeed" value="-200"/>  <!-- 1500ms → 1700ms -->
</item>
```

---

## Resumo de arquivos

| Arquivo | Natureza da mudança |
|---|---|
| `src/items/items.hpp` | +1 campo `attackSpeed` em `ItemAbilities` |
| `src/items/functions/item/item_parse.hpp` | +1 enum + entrada no mapa de strings |
| `src/items/functions/item/item_parse.cpp` | +1 método de parse + case no switch |
| `src/creatures/players/player.hpp` | `varAttackSpeed`, `setVarAttackSpeed()`, `getAttackSpeed()` modificado |
| `src/lua/creature/movement.cpp` | Apply/remove no equip/unequip |
| `src/items/item.cpp` | Tooltip |

---

## Notas

- A acumulação é **aditiva** — sem diminishing returns. O hard cap de 500ms protege contra stacking pelo lado positivo.
- Penalidades (valores negativos) não têm cap superior — o intervalo pode crescer além do valor de vocation base.
- O `varAttackSpeed` acumula corretamente com o sistema de fist attack speed (`TOGGLE_ATTACK_SPEED_ONFIST`): o fist system calcula o `base` primeiro, depois o `varAttackSpeed` é subtraído.
- `doAttacking()` em `player.cpp:4348` usa `getAttackSpeed()` diretamente para agendar o próximo ataque — nenhuma mudança necessária nessa função.
