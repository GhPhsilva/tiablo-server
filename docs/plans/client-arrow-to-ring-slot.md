# Client: Transformar Arrow Slot em Segundo Ring Slot

## Objetivo

Atualizar a UI do client OtClientV8 para que o slot 10 (ammo) exiba visualmente um ícone de ring em vez de flecha, refletindo a mudança no servidor.

## Contexto

O client usa uma arquitetura de engine C++ pré-compilada + scripts Lua/OTUI interpretados em runtime. **Não é necessário recompilar o client** — todas as mudanças necessárias são em arquivos de dados (PNG e OTUI). Hot-reload disponível com **Ctrl+Shift+R**.

## Como o slot 10 funciona no client

O slot ammo é identificado no client como:
- **Lua:** `InventorySlotAmmo = 10` (`data/modules/gamelib/player.lua`)
- **Widget ID:** `slot10` (gerado dinamicamente em `game_inventory/inventory.lua`)
- **Style:** `AmmoSlot` (`data/styles/40-inventory.otui`)
- **Protocolo:** posição `{x=65535, y=10, z=0}` — permanece igual, sem mudanças no protocolo

## Mudanças necessárias

### Recompilação necessária? **NÃO**

### 1. Criar imagens de ring para o slot 10

Criar dois novos arquivos PNG a partir dos existentes do slot finger:

```
data/images/game/slots/finger.png         → copiar como → ring2.png
data/images/game/slots/finger-blessed.png → copiar como → ring2-blessed.png
```

Caminhos finais:
- `data/images/game/slots/ring2.png`
- `data/images/game/slots/ring2-blessed.png`

> Alternativa: substituir diretamente `ammo.png` e `ammo-blessed.png` se não quiser criar novos arquivos.

### 2. Atualizar os arquivos `.otui` (3 arquivos)

Mudar o `image-source` do `AmmoSlot` em todos os layouts:

```otui
# ANTES:
AmmoSlot < InventoryItem
  id: slot10
  image-source: /images/game/slots/ammo
  &position: {x=65535, y=10, z=0}
  $on:
    image-source: /images/game/slots/ammo-blessed

# DEPOIS:
AmmoSlot < InventoryItem
  id: slot10
  image-source: /images/game/slots/ring2
  &position: {x=65535, y=10, z=0}
  $on:
    image-source: /images/game/slots/ring2-blessed
```

Arquivos a editar:
| Arquivo | Localização |
|---|---|
| Layout padrão | `data/styles/40-inventory.otui` (~linha 68) |
| Layout retro | `layouts/retro/styles/40-inventory.otui` (~linha 68) |
| Layout mobile | `layouts/mobile/styles/40-inventory.otui` (~linha 68) |

### 3. Alias Lua — opcional

Para clareza semântica, adicionar alias em `data/modules/gamelib/player.lua` (~linha 34):

```lua
InventorySlotAmmo = 10   -- mantido para compatibilidade
InventorySlotRing2 = 10  -- alias Diablo 2 style
```

## O que NÃO precisa ser alterado

- `data/modules/game_inventory/inventory.lua` — widget `id: slot10` já funciona
- Protocolo cliente — slot number 10 permanece igual
- `InventorySlotStyles` — `AmmoSlot` style continua mapeado para slot 10

## Como aplicar sem reiniciar o client

1. Salvar os arquivos editados
2. Pressionar **Ctrl+Shift+R** dentro do client para hot-reload

## Verificação

1. Hot-reload (Ctrl+Shift+R) após as mudanças
2. Confirmar visualmente que o slot 10 exibe ícone de ring
3. Equipar um ring no slot 10 via servidor → ícone deve aparecer corretamente na UI
4. Desequipar → slot deve voltar a mostrar o ícone de ring vazio
