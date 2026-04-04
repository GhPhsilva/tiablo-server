# Server: Adicionar Slot de Belt

## Objetivo

Adicionar um novo slot de equipamento para cintos (belts) no servidor, com:
- Slot físico para equipar belts (entre armor e legs na UI)
- Nova categoria de item `ITEM_TYPE_BELT` / `SLOTP_BELT`
- Atributo `potionBonus` — aumenta ou reduz eficácia de poções (suporta negativo)
- Atributo `armor` (defesa) — já suportado nativamente pelo sistema
- Exibição de `potionBonus` no comando "look"
- Binding Lua `player:getPotionBonus()` para uso em scripts de poções

## Contexto

Tiablo é baseado em Diablo 2. Belts no D2 são um equipamento de cintura importante que aumenta o número de poções no cinto e a eficácia delas. O slot segue o padrão já estabelecido no projeto (cf. `docs/plans/server-arrow-to-ring-slot.md`).

## Decisão de numeração do slot

`CONST_SLOT_BELT = 12` — adicionado **após** `CONST_SLOT_STORE_INBOX = 11`, sem deslocar nenhum slot existente.

```
CONST_SLOT_AMMO        = 10  (sem mudança)
CONST_SLOT_STORE_INBOX = 11  (sem mudança — dados no banco não afetados)
CONST_SLOT_BELT        = 12  (NOVO)
CONST_SLOT_LAST        = CONST_SLOT_BELT  (= 12)
```

Risco de conflito no banco: **zero** — `player_items` usa linhas dinâmicas por slot; nenhum registro existente tem `sid = 12`.

## Análise de impacto

| Aspecto | Resultado |
|---|---|
| Slots existentes (1–11) | Sem alteração — numeração mantida |
| Banco de dados | Sem migração — nova linha `sid=12` inserida ao equipar |
| Protocolo de rede | Novo slot 12 transmitido via `sendInventoryItem(CONST_SLOT_BELT, item)` |
| `inventoryAbilities[13]` | Array cresce de 12 para 13 posições (automático via `CONST_SLOT_LAST + 1`) |
| potionBonus negativo | Suportado — belts malditos reduzem eficácia de poções |

## Mudanças necessárias

### 1. `src/creatures/creatures_definitions.hpp`

Adicionar `CONST_SLOT_BELT` e atualizar `CONST_SLOT_LAST`:

```cpp
// ANTES:
CONST_SLOT_STORE_INBOX = 11,
CONST_SLOT_FIRST = CONST_SLOT_HEAD,
CONST_SLOT_LAST = CONST_SLOT_STORE_INBOX,

// DEPOIS:
CONST_SLOT_STORE_INBOX = 11,
CONST_SLOT_BELT = 12,          // NOVO
CONST_SLOT_FIRST = CONST_SLOT_HEAD,
CONST_SLOT_LAST = CONST_SLOT_BELT,
```

### 2. `src/items/items_definitions.hpp`

**SlotPositionBits** — adicionar bit para belt:

```cpp
// ANTES:
SLOTP_TWO_HAND = 1 << 11,
SLOTP_HAND = (SLOTP_LEFT | SLOTP_RIGHT)

// DEPOIS:
SLOTP_TWO_HAND = 1 << 11,
SLOTP_BELT = 1 << 12,          // NOVO
SLOTP_HAND = (SLOTP_LEFT | SLOTP_RIGHT)
```

**ItemType_t** — adicionar tipo belt (após `ITEM_TYPE_ARMOR`):

```cpp
ITEM_TYPE_BELT,   // NOVO
```

### 3. `src/items/items.hpp`

Adicionar campo `potionBonus` na struct `Abilities`:

```cpp
// Adicionar junto aos outros campos int32_t:
int32_t potionBonus = 0;  // % bônus/debuff na eficácia de poções (suporta negativo)
```

### 4. `src/io/ioitem.cpp`

Parse do atributo `potionbonus` no XML de itens:

```cpp
// Dentro do bloco de parse de abilities, junto a outros atributos int:
} else if (tmpStrValue == "potionbonus") {
    abilities.potionBonus = pugi::cast<int32_t>(keyValue.value());
}
```

### 5. `src/creatures/players/player.cpp`

**queryAdd** — adicionar case para `CONST_SLOT_BELT`:

```cpp
// Adicionar após o case CONST_SLOT_AMMO:
case CONST_SLOT_BELT: {
    if (slotPosition & SLOTP_BELT) {
        ret = RETURNVALUE_NOERROR;
    }
    break;
}
```

**armorSlots** — incluir belt no array de slots de armadura:

```cpp
// ANTES:
static const Slots_t armorSlots[] = {
    CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR,
    CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING, CONST_SLOT_AMMO
};

// DEPOIS:
static const Slots_t armorSlots[] = {
    CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR,
    CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING, CONST_SLOT_AMMO,
    CONST_SLOT_BELT
};
```

**getBeltPotionBonus** — novo método:

```cpp
int32_t Player::getBeltPotionBonus() const {
    auto belt = getInventoryItem(CONST_SLOT_BELT);
    if (belt) {
        const ItemType &it = Item::items[belt->getID()];
        if (it.abilities) {
            return it.abilities->potionBonus;
        }
    }
    return 0;
}
```

### 6. `src/creatures/players/player.hpp`

Declarar o método público:

```cpp
int32_t getBeltPotionBonus() const;
```

### 7. `src/lua/creature/movement.cpp`

Mapear `CONST_SLOT_BELT` → `SLOTP_BELT` para que eventos de equip/deequip funcionem:

```cpp
// Adicionar no switch de slot → slotp:
case CONST_SLOT_BELT:
    slotp = SLOTP_BELT;
    break;
```

### 8. `src/items/item.cpp`

**Body Position** — adicionar exibição de "belt" (em `getDescriptions()`):

```cpp
// Adicionar após o bloco de SLOTP_AMMO:
} else if (it.slotPosition & SLOTP_BELT) {
    descriptions.emplace_back("Body Position", "belt");
```

**Potion Bonus** — exibir atributo no look (com sinal explícito):

```cpp
// Adicionar junto aos outros atributos de abilities:
if (abilities.potionBonus != 0) {
    std::string bonusStr = (abilities.potionBonus > 0 ? "+" : "")
                         + std::to_string(abilities.potionBonus) + "%";
    descriptions.emplace_back("Potion Bonus", bonusStr);
}
```

### 9. `src/lua/functions/creatures/player_functions.cpp`

Registrar e implementar o binding Lua:

```cpp
// No bloco de registro de métodos:
Lua::registerMethod(L, "Player", "getPotionBonus", PlayerFunctions::luaPlayerGetPotionBonus);

// Implementação:
int PlayerFunctions::luaPlayerGetPotionBonus(lua_State* L) {
    // player:getPotionBonus() → number
    const auto player = getUserdataShared<Player>(L, 1);
    if (!player) {
        reportError(__FUNCTION__, getErrorDesc(LUA_ERROR_PLAYER_NOT_FOUND));
        lua_pushnil(L);
        return 1;
    }
    lua_pushnumber(L, player->getBeltPotionBonus());
    return 1;
}
```

Declarar em `player_functions.hpp`:

```cpp
static int luaPlayerGetPotionBonus(lua_State* L);
```

### 10. Scripts de poções em `data/`

Localizar os scripts de uso de poções e escalar o efeito pelo bônus do belt:

```lua
local bonus = player:getPotionBonus()  -- ex: 20 = +20%, -10 = -10%
local healAmount = math.max(1, math.floor(baseHeal * (100 + bonus) / 100))
player:addHealth(healAmount)
-- mesmo padrão para addMana
```

## O que NÃO precisa ser alterado

- `CONST_SLOT_AMMO = 10` — mantido (já reproposto como segundo ring slot)
- `CONST_SLOT_STORE_INBOX = 11` — mantido sem mudança
- Schema do banco de dados — sem migrations
- Itens existentes — nenhuma alteração em `items.xml`
- Enum Lua `CONST_SLOT_AMMO` — continua registrado

## Como recompilar

```bash
cmake --build --preset windows-release
```

## Verificação

1. Criar item de teste em `items.xml`:
   ```xml
   <item id="XXXX" name="Test Belt">
     <attribute key="type" value="belt"/>
     <attribute key="slotType" value="belt"/>
     <attribute key="armor" value="10"/>
     <attribute key="potionbonus" value="20"/>
   </item>
   ```
2. Equipar o belt → deve aceitar no slot 12
3. `/look` no belt → "Body Position: belt" e "Potion Bonus: +20%"
4. Belt com `armor="10"` → defesa deve aparecer no cálculo de combate
5. Tomar poção com belt equipado → cura deve ser 20% maior
6. Belt com `potionbonus="-10"` → cura deve ser 10% menor
7. Tentar equipar item não-belt no slot 12 → deve rejeitar
