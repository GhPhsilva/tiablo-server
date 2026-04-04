# Atributo `enhancedamage`

Adiciona um bônus percentual de dano a armas melee, distance (bow/crossbow) e wands.

## Conceito

```
raw       = soma de todos os enhancedamage equipados
effective = raw * 75 / (raw + 75)   ← diminishing returns
dano_final = dano_calculado * (100 + effective) / 100
```

O multiplicador é aplicado **após** o cálculo base de dano, sobre `damage.primary` e `damage.secondary`. Múltiplos itens acumulam o `raw` aditivamente, mas o bônus efetivo segue uma curva hiperbólica — cada item adicional contribui menos que o anterior. O teto assintótico é **+75% de dano** (nunca atingido na prática).

**Exemplo:** espada com `enhancedamage=10` + anel com `enhancedamage=5` + amuleto com `enhancedamage=8`:
- raw = 23
- effective = 23 * 75 / (23 + 75) = 1725 / 98 ≈ 17.6%
- (vs +23% que seria aditivo puro)

**Tabela de referência:**

| raw acumulado | bônus efetivo | teto |
|---|---|---|
| 10 | 8.8% | — |
| 20 | 15.8% | — |
| 30 | 21.4% | — |
| 50 | 30.0% | — |
| 100 | 42.9% | — |
| ∞ | → 75% | assíntota |

## Comportamento por tipo de arma

| Tipo | Fonte do `enhancedamage` | Incide sobre |
|---|---|---|
| Melee | Todos os itens equipados | primary + secondary |
| Bow / Crossbow | Todos os itens equipados | primary + secondary da munição |
| Wand | Todos os itens equipados | primary (secondary é sempre 0) |

> O bônus total é sempre a soma de **todos os slots equipados** (arma, armadura, capacete, botas, anéis, amuleto, etc.). O tipo da arma determina apenas sobre qual dano o bônus incide.

## XML

```xml
<attribute key="enhancedamage" value="20"/>
```

Valor em porcentagem inteira. Exemplo: `20` = +20% de dano.

---

## Plano de implementação

### Passo 1 — `src/items/items.hpp`

Adicionar um campo em `ItemAbilities`:

```cpp
uint8_t enhanceDamage = 0;
```

---

### Passo 2 — `src/items/functions/item/item_parse.cpp`

Adicionar um novo case no parser de atributos de item, próximo dos outros atributos de combate:

```cpp
} else if (stringValue == "enhancedamage") {
    abilities.enhanceDamage = pugi::cast<uint8_t>(valueAttribute.value());
}
```

---

### Passo 3 — `src/items/weapons/weapons.cpp`

Em `Weapon::internalUseWeapon`, após os cálculos de `damage.primary.value` e `damage.secondary.value`, somar o `enhanceDamage` de todos os slots equipados e aplicar o total:

```cpp
// Somar enhanceDamage de todos os itens equipados (raw)
int32_t rawEnhance = 0;
for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
    std::shared_ptr<Item> equipped = player->getInventoryItem(static_cast<Slots_t>(slot));
    if (!equipped) {
        continue;
    }
    const ItemType &equippedIt = Item::items[equipped->getID()];
    if (equippedIt.abilities) {
        rawEnhance += equippedIt.abilities->enhanceDamage;
    }
}

if (rawEnhance > 0) {
    // Diminishing returns: effective = raw * 75 / (raw + 75)
    int32_t effectiveEnhance = rawEnhance * 75 / (rawEnhance + 75);
    damage.primary.value   = damage.primary.value   * (100 + effectiveEnhance) / 100;
    damage.secondary.value = damage.secondary.value * (100 + effectiveEnhance) / 100;
}
```

> O loop itera no máximo 11 slots de inventário com acesso a dados estáticos (`ItemType`), sem impacto de performance relevante.

---

### Passo 4 — `src/items/item.cpp`

Na função que monta a descrição de armas, adicionar exibição do bônus no tooltip quando `enhanceDamage > 0`:

```
"Enhance damage: +X%"
```

Aplicável para melee, bow/crossbow e wands.

---

### Passo 5 — `data/items/items.xml`

Com a implementação concluída, adicionar o atributo nos itens desejados:

```xml
<!-- Exemplo em um bow -->
<item id="22866" article="a" name="rift bow">
    ...
    <attribute key="enhancedamage" value="15"/>
</item>

<!-- Exemplo em uma espada -->
<item id="3264" article="a" name="fire sword">
    ...
    <attribute key="enhancedamage" value="10"/>
</item>

<!-- Exemplo em uma wand -->
<item id="3075" article="a" name="wand of vortex">
    ...
    <attribute key="enhancedamage" value="12"/>
</item>
```

---

## Resumo de arquivos

| Arquivo | Natureza da mudança |
|---|---|
| `src/items/items.hpp` | +1 campo em `ItemAbilities` |
| `src/items/functions/item/item_parse.cpp` | +1 case de parsing |
| `src/items/weapons/weapons.cpp` | ~15 linhas em `internalUseWeapon` |
| `src/items/item.cpp` | Exibição no tooltip |
| `data/items/items.xml` | Atributos nos itens desejados |

## Notas

- Múltiplos itens acumulam o valor **raw aditivamente**, mas o bônus efetivo segue diminishing returns hiperbólicos (`raw * 75 / (raw + 75)`). O teto assintótico é +75% — impossível de atingir na prática.
- Mudar a fórmula de dano das wands no futuro (ex: `magic level + level`) **não impacta** o `enhancedamage` — o multiplicador opera sobre o valor final, independente de como ele foi calculado.
- O atributo não interfere com secondary element damage de melee ou qualquer outro sistema existente.
