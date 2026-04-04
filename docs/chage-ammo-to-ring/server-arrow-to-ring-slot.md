# Server: Transformar Arrow Slot em Segundo Ring Slot

## Objetivo

Repropor o slot de ammo (slot 10, `CONST_SLOT_AMMO`) como segundo slot de ring, permitindo ao jogador equipar dois anéis simultaneamente, alinhado com o estilo Diablo 2.

## Contexto

O servidor Tiablo é baseado em Diablo 2 e não utiliza o sistema de arqueiros/ammo do Tibia original. O slot 10 estava reservado para flechas e bolts, mas não é necessário nesse contexto. O sistema de quivers é completamente independente do slot 10 (quivers ficam no slot 5 — mão direita), portanto a mudança tem impacto mínimo.

## Análise de impacto

### Quivers e ammo

| Aspecto | Resultado |
|---|---|
| Quivers continuam funcionando | SIM — equipam em `CONST_SLOT_RIGHT` (slot 5) |
| Ammo entra em quivers | SIM — validado por `WEAPON_AMMO` type, não por `SLOTP_AMMO` |
| Armas de distância encontram ammo | SIM — `getQuiverAmmoOfType()` busca no quiver do slot 5 |
| 24 itens ammo (flechas/bolts) | Não equipáveis diretamente no slot 10 (intencional) |

### Stacking de abilities com 2 rings

| Ability | Comportamento |
|---|---|
| Speed | Acumula (aditivo) |
| Skills / Stats | Acumula (aditivo) |
| Invisibility / Mana Shield | Ambas as condições ativas (IDs diferentes por slot) |
| Regeneration | Sobrescreve (último equipado controla) |

Stacking permitido intencionalmente — consistente com o estilo Diablo 2.

## Mudanças implementadas

### 1. `src/creatures/players/player.cpp`

**Validação do slot** — `case CONST_SLOT_AMMO` agora aceita `SLOTP_RING`:

```cpp
// ANTES:
case CONST_SLOT_AMMO: {
    bool allowPutItemsOnAmmoSlot = g_configManager().getBoolean(ENABLE_PLAYER_PUT_ITEM_IN_AMMO_SLOT, __FUNCTION__);
    if (allowPutItemsOnAmmoSlot) {
        ret = RETURNVALUE_NOERROR;
    } else {
        if ((slotPosition & SLOTP_AMMO)) {
            ret = RETURNVALUE_NOERROR;
        }
    }
    break;
}

// DEPOIS:
case CONST_SLOT_AMMO: {
    if (slotPosition & SLOTP_RING) {
        ret = RETURNVALUE_NOERROR;
    }
    break;
}
```

### 2. `src/lua/creature/movement.cpp`

**Lookup do equip event** — `CONST_SLOT_AMMO` mapeado para `SLOTP_RING` para que o evento de equip/deequip de rings seja encontrado corretamente quando equipado no slot 10:

```cpp
// ANTES:
case CONST_SLOT_AMMO:
    slotp = SLOTP_AMMO;
    break;

// DEPOIS:
case CONST_SLOT_AMMO:
    slotp = SLOTP_RING;
    break;
```

### 3. `src/items/item.cpp`

**Display name** — duas ocorrências (linhas 1547 e 1882) alteradas de "extra slot" para "finger":

```cpp
// ANTES:
} else if (it.slotPosition & SLOTP_AMMO) {
    descriptions.emplace_back("Body Position", "extra slot");

// DEPOIS:
} else if (it.slotPosition & SLOTP_AMMO) {
    descriptions.emplace_back("Body Position", "finger");
```

## O que NÃO foi alterado

- `src/creatures/creatures_definitions.hpp` — `CONST_SLOT_AMMO = 10` mantido (protocolo de rede)
- `src/items/items_definitions.hpp` — `SLOTP_AMMO = 1<<9` mantido
- `data/items/items.xml` — 24 itens ammo intactos (continuam funcionais via quiver)
- Schema do banco de dados — sem mudanças estruturais
- Lua enums — `CONST_SLOT_AMMO` continua registrado

## Como recompilar

```bash
cmake --build --preset windows-release
```

## Verificação

1. Equipar um **ring** no slot 10 → deve aceitar
2. Tentar equipar uma **flecha** no slot 10 → deve rejeitar
3. Equipar 2 rings de speed → velocidade deve somar
4. Ring com ability (ex: ring of healing) no slot 10 → ability deve funcionar
5. Arco + quiver no slot 5 com flechas → deve continuar funcionando normalmente
