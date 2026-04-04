# Atributo `enhanceddefense`

Aplica um bônus percentual sobre o valor de `armor` ou `defense` do próprio item que possui o atributo.

## Conceito

```
contribuição_efetiva = valor_base * (100 + enhanceddefense) / 100
```

O bônus é **por item** — cada item que possui `enhanceddefense` potencializa seu próprio atributo de defesa (`armor` ou `defense`). Múltiplos itens com `enhanceddefense` se aplicam independentemente, cada um sobre o seu próprio valor base.

**Exemplo:**
- Capacete com `armor=8, enhanceddefense=20` → contribui 9 armor
- Armadura com `armor=15, enhanceddefense=10` → contribui 16 armor
- Escudo com `defense=30, enhanceddefense=15` → contribui 34 defense

## Como armor e defense funcionam no engine

São calculados em funções separadas em `player.cpp`:

**`getArmor()`** — itera slots: HEAD, NECKLACE, ARMOR, LEGS, FEET, RING, AMMO, BELT.
Soma `item->getArmor()` de cada slot e multiplica por `vocation->armorMultiplier`.

**`getDefense()`** — lê apenas o weapon e o shield dos slots LEFT/RIGHT.
`defenseValue` = `shield->getDefense() + weapon->getExtraDefense()` (ou só weapon se não houver shield).
O valor final passa por uma fórmula com `defenseSkill`, `defenseFactor` e `vocation->defenseMultiplier`.

Isso determina exatamente onde cada tipo de item tem seu bônus aplicado:
- Itens de armor (capacete, armadura, etc.) → `getArmor()`
- Weapon / Shield → `getDefense()`

---

## Plano de implementação

### Passo 1 — `src/items/items.hpp`

Adicionar um campo em `ItemAbilities`:

```cpp
uint8_t enhanceDefense = 0;
```

---

### Passo 2 — `src/items/functions/item/item_parse.cpp`

Adicionar um novo case no parser:

```cpp
} else if (stringValue == "enhanceddefense") {
    abilities.enhanceDefense = pugi::cast<uint8_t>(valueAttribute.value());
}
```

---

### Passo 3 — `src/creatures/players/player.cpp` — `getArmor()`

Modificar o loop de `getArmor()` para checar `enhanceDefense` de cada item antes de acumular:

```cpp
// ANTES
for (Slots_t slot : armorSlots) {
    std::shared_ptr<Item> inventoryItem = inventory[slot];
    if (inventoryItem) {
        armor += inventoryItem->getArmor();
    }
}

// DEPOIS
for (Slots_t slot : armorSlots) {
    std::shared_ptr<Item> inventoryItem = inventory[slot];
    if (!inventoryItem) {
        continue;
    }
    int32_t itemArmor = inventoryItem->getArmor();
    if (itemArmor > 0) {
        const ItemType &it = Item::items[inventoryItem->getID()];
        if (it.abilities && it.abilities->enhanceDefense > 0) {
            itemArmor = itemArmor * (100 + it.abilities->enhanceDefense) / 100;
        }
    }
    armor += itemArmor;
}
```

---

### Passo 4 — `src/creatures/players/player.cpp` — `getDefense()`

Modificar os blocos de weapon e shield para aplicar o bônus sobre o `defenseValue` de cada um:

```cpp
if (weapon) {
    int32_t weaponDefense = weapon->getDefense();
    const ItemType &weaponIt = Item::items[weapon->getID()];
    if (weaponIt.abilities && weaponIt.abilities->enhanceDefense > 0) {
        weaponDefense = weaponDefense * (100 + weaponIt.abilities->enhanceDefense) / 100;
    }
    defenseValue = weaponDefense + weapon->getExtraDefense();
    defenseSkill = getWeaponSkill(weapon);
}

if (shield) {
    int32_t shieldDefense = shield->getDefense();
    const ItemType &shieldIt = Item::items[shield->getID()];
    if (shieldIt.abilities && shieldIt.abilities->enhanceDefense > 0) {
        shieldDefense = shieldDefense * (100 + shieldIt.abilities->enhanceDefense) / 100;
    }
    defenseValue = weapon != nullptr
        ? shieldDefense + weapon->getExtraDefense()
        : shieldDefense;
    ...
}
```

---

### Passo 5 — `src/items/item.cpp`

Exibir o bônus no tooltip do item quando `enhanceDefense > 0`:

```
"Enhance defense: +X%"
```

---

### Passo 6 — `data/items/items.xml`

```xml
<!-- Item de armor -->
<item id="2472" article="a" name="plate armor">
    ...
    <attribute key="enhanceddefense" value="20"/>
</item>

<!-- Shield -->
<item id="2512" article="a" name="tower shield">
    ...
    <attribute key="enhanceddefense" value="15"/>
</item>
```

---

## Resumo de arquivos

| Arquivo | Natureza da mudança |
|---|---|
| `src/items/items.hpp` | +1 campo em `ItemAbilities` |
| `src/items/functions/item/item_parse.cpp` | +1 case de parsing |
| `src/creatures/players/player.cpp` | `getArmor()` e `getDefense()` — boost por item |
| `src/items/item.cpp` | Exibição no tooltip |
| `data/items/items.xml` | Atributos nos itens desejados |

## Notas

- O bônus é aplicado **por item sobre seu próprio atributo** — diferente do `enhancedamage` que acumula um total global.
- Um item com `enhanceddefense` mas sem `armor` e sem `defense` não tem efeito prático.
- `extraDefense` de weapons (bônus de defesa por two-handed, etc.) não é afetado pelo `enhanceddefense` — apenas o `defense` base do item.
- `vocation->armorMultiplier` e `vocation->defenseMultiplier` continuam sendo aplicados normalmente após o boost por item.
