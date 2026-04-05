# Server: Adicionar Slot de Gloves

## Objetivo

Adicionar um novo slot de equipamento para luvas (gloves) no servidor, com:
- Slot físico para equipar gloves (abaixo de feet na UI)
- Nova categoria de item `ITEM_TYPE_GLOVES` / `SLOTP_GLOVES`
- Atributo `armor` (defesa) — já suportado nativamente pelo sistema
- Exibição de "gloves" no comando "look" (Body Position)

## Contexto

Tiablo é baseado em Diablo 2. Gloves no D2 são um equipamento de mãos que fornece defesa e bônus variados. O slot segue o padrão já estabelecido no projeto (cf. `docs/belt/server-belt-slot.md`).

## Decisão de numeração do slot

`CONST_SLOT_GLOVES = 13` — adicionado **após** `CONST_SLOT_BELT = 12`, sem deslocar nenhum slot existente.

```
CONST_SLOT_BELT        = 12  (sem mudança)
CONST_SLOT_GLOVES      = 13  (NOVO)
CONST_SLOT_LAST        = CONST_SLOT_GLOVES  (= 13)
```

Risco de conflito no banco: **zero** — `player_items` usa linhas dinâmicas por slot; nenhum registro existente tem `sid = 13`.

## Análise de impacto

| Aspecto | Resultado |
|---|---|
| Slots existentes (1–12) | Sem alteração — numeração mantida |
| Banco de dados | Sem migração — nova linha `sid=13` inserida ao equipar |
| Protocolo de rede | Novo slot 13 transmitido via `sendInventoryItem(CONST_SLOT_GLOVES, item)` |
| `inventoryAbilities[14]` | Array cresce de 13 para 14 posições (automático via `CONST_SLOT_LAST + 1`) |

## Mudanças necessárias

### 1. `src/creatures/creatures_definitions.hpp`

Adicionar `CONST_SLOT_GLOVES` e atualizar `CONST_SLOT_LAST`:

```cpp
// ANTES:
CONST_SLOT_BELT = 12,
CONST_SLOT_FIRST = CONST_SLOT_HEAD,
CONST_SLOT_LAST = CONST_SLOT_BELT,

// DEPOIS:
CONST_SLOT_BELT = 12,
CONST_SLOT_GLOVES = 13,        // NOVO
CONST_SLOT_FIRST = CONST_SLOT_HEAD,
CONST_SLOT_LAST = CONST_SLOT_GLOVES,
```

### 2. `src/items/items_definitions.hpp`

**SlotPositionBits** — adicionar bit para gloves:

```cpp
// ANTES:
SLOTP_BELT = 1 << 12,
SLOTP_HAND = (SLOTP_LEFT | SLOTP_RIGHT)

// DEPOIS:
SLOTP_BELT = 1 << 12,
SLOTP_GLOVES = 1 << 13,        // NOVO
SLOTP_HAND = (SLOTP_LEFT | SLOTP_RIGHT)
```

**ItemType_t** — adicionar tipo gloves (após `ITEM_TYPE_BELT`):

```cpp
ITEM_TYPE_GLOVES,   // NOVO
```

### 3. `src/creatures/players/player.cpp`

**queryAdd** — adicionar case para `CONST_SLOT_GLOVES`:

```cpp
// Adicionar após o case CONST_SLOT_BELT:
case CONST_SLOT_GLOVES: {
    if (slotPosition & SLOTP_GLOVES) {
        ret = RETURNVALUE_NOERROR;
    }
    break;
}
```

**armorSlots** — incluir gloves no array de slots de armadura:

```cpp
// ANTES:
static const Slots_t armorSlots[] = {
    CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR,
    CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING, CONST_SLOT_AMMO,
    CONST_SLOT_BELT
};

// DEPOIS:
static const Slots_t armorSlots[] = {
    CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR,
    CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING, CONST_SLOT_AMMO,
    CONST_SLOT_BELT, CONST_SLOT_GLOVES
};
```

### 4. `src/lua/creature/movement.cpp`

Mapear `CONST_SLOT_GLOVES` → `SLOTP_GLOVES` para que eventos de equip/deequip funcionem:

```cpp
// Adicionar no switch de slot → slotp:
case CONST_SLOT_GLOVES:
    slotp = SLOTP_GLOVES;
    break;
```

### 5. `src/items/item.cpp`

**Body Position** — adicionar exibição de "gloves" (em `getDescriptions()`):

```cpp
// Adicionar após o bloco de SLOTP_BELT:
} else if (it.slotPosition & SLOTP_GLOVES) {
    descriptions.emplace_back("Body Position", "gloves");
```

## O que NÃO precisa ser alterado

- `CONST_SLOT_BELT = 12` — mantido sem mudança
- Schema do banco de dados — sem migrations
- Itens existentes — nenhuma alteração em `items.xml`
- Nenhum atributo especial novo — gloves usa apenas habilidades já existentes (armor, absorbPercent, etc.)

## Como recompilar

```bash
cmake --build --preset windows-release
```

## Verificação

1. Criar item de teste em `items.xml`:
   ```xml
   <item id="XXXX" name="Test Gloves">
     <attribute key="type" value="gloves"/>
     <attribute key="slotType" value="gloves"/>
     <attribute key="armor" value="10"/>
   </item>
   ```
2. Equipar as gloves → deve aceitar no slot 13
3. `/look` nas gloves → "Body Position: gloves"
4. Gloves com `armor="10"` → defesa deve aparecer no cálculo de combate
5. Tentar equipar item não-gloves no slot 13 → deve rejeitar
