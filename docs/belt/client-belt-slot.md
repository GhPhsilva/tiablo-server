# Client: Adicionar Slot de Belt

## Objetivo

Atualizar a UI do client OtClientV8 para exibir o novo slot de belt (slot 12) entre o slot de armor e o de legs, com ícone próprio e suporte ao estilo blessed.

## Contexto

O client usa engine C++ pré-compilada + scripts Lua/OTUI interpretados em runtime. **Não é necessário recompilar o client** — todas as mudanças são em arquivos de dados. Hot-reload disponível com **Ctrl+Shift+R**.

O servidor adicionou `CONST_SLOT_BELT = 12`. O client deve refletir isso com `InventorySlotBelt = 12`.

## Branch

Criar branch `feat/add-belt-slot` no repositório do client antes das alterações.

## Como o novo slot funciona no client

- **Lua:** `InventorySlotBelt = 12` (novo)
- **Widget ID:** `slot12` (gerado dinamicamente em `game_inventory/inventory.lua`)
- **Style:** `BeltSlot` (`data/styles/40-inventory.otui`)
- **Protocolo:** posição `{x=65535, y=12, z=0}` — novo, correspondente ao slot 12 do servidor

## Dimensões das imagens

- `belt.png` e `belt-blessed.png`: **34×34 px** (mesmo padrão dos outros slots)
- Pixel art estilo dos ícones existentes (fundo escuro, contorno, ícone centralizado)
- `belt-blessed.png`: versão com overlay dourado (mesmo padrão do `*-blessed.png` existente)

## Mudanças necessárias

### Recompilação necessária? **NÃO**

---

### 1. Criar imagens do slot

Criar dois arquivos PNG em `data/images/game/slots/`:

```
data/images/game/slots/belt.png         ← ícone de cinto vazio (34×34 px)
data/images/game/slots/belt-blessed.png ← versão blessed com overlay dourado (34×34 px)
```

Referência visual: estilo similar aos ícones existentes (ex: `body.png`, `legs.png`).

---

### 2. `data/modules/gamelib/player.lua`

Adicionar constante `InventorySlotBelt` e atualizar `InventorySlotLast`:

```lua
-- ANTES:
InventorySlotAmmo = 10
InventorySlotPurse = 11
InventorySlotFirst = 1
InventorySlotLast = 10

-- DEPOIS:
InventorySlotAmmo = 10
InventorySlotPurse = 11
InventorySlotBelt = 12    -- NOVO
InventorySlotFirst = 1
InventorySlotLast = 12    -- atualizado
```

---

### 3. `data/modules/game_inventory/inventory.lua`

Adicionar `BeltSlot` ao mapa `InventorySlotStyles`:

```lua
-- ANTES:
InventorySlotStyles = {
  [InventorySlotHead]   = "HeadSlot",
  [InventorySlotNeck]   = "NeckSlot",
  [InventorySlotBack]   = "BackSlot",
  [InventorySlotBody]   = "BodySlot",
  [InventorySlotRight]  = "RightSlot",
  [InventorySlotLeft]   = "LeftSlot",
  [InventorySlotLeg]    = "LegSlot",
  [InventorySlotFeet]   = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo]   = "AmmoSlot"
}

-- DEPOIS:
InventorySlotStyles = {
  [InventorySlotHead]   = "HeadSlot",
  [InventorySlotNeck]   = "NeckSlot",
  [InventorySlotBack]   = "BackSlot",
  [InventorySlotBody]   = "BodySlot",
  [InventorySlotRight]  = "RightSlot",
  [InventorySlotLeft]   = "LeftSlot",
  [InventorySlotLeg]    = "LegSlot",
  [InventorySlotFeet]   = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo]   = "AmmoSlot",
  [InventorySlotBelt]   = "BeltSlot",   -- NOVO
}
```

---

### 4. `data/styles/40-inventory.otui` (layout padrão)

Adicionar widget `BeltSlot` entre `BodySlot` e `LegSlot`, e atualizar o anchor de `LegSlot`:

```otui
# ADICIONAR após o bloco BodySlot:
BeltSlot < InventoryItem
  id: slot12
  image-source: /images/game/slots/belt
  &position: {x=65535, y=12, z=0}
  anchors.top: BodySlot.bottom
  anchors.horizontalCenter: BodySlot.horizontalCenter
  margin-top: 3
  $on:
    image-source: /images/game/slots/belt-blessed

# ATUALIZAR no bloco LegSlot:
# ANTES:
#   anchors.top: BodySlot.bottom
# DEPOIS:
#   anchors.top: slot12.bottom
```

---

### 5. `layouts/retro/styles/40-inventory.otui` (layout retro)

Mesmas alterações do item 4 acima.

---

## Layout visual resultante

```
         [Head]
[Neck]  [Body]  [Back]
[Left]  [Belt]  [Right]   ← slot12, 34×34 px
[Finger][Legs]  [Ring2]
         [Feet]
```

## O que NÃO precisa ser alterado

- `data/modules/game_inventory/inventory.lua` — lógica de `onInventoryChange` já funciona com qualquer slot pelo ID
- Protocolo cliente — apenas o número do slot (12) é novo
- `InventorySlotPurse = 11` — sem mudança

## Como aplicar sem reiniciar o client

1. Criar as imagens PNG
2. Salvar os arquivos editados
3. Pressionar **Ctrl+Shift+R** dentro do client para hot-reload

## Verificação

1. Hot-reload (Ctrl+Shift+R) após as mudanças
2. Slot belt visível entre armor e legs na UI
3. Equipar um belt via servidor → ícone do belt equipado aparece no slot 12
4. Desquipar → slot volta ao ícone `belt.png` vazio
5. Ativar Adventurer blessing → slot deve usar `belt-blessed.png`
6. Teste no layout retro — slot deve aparecer no mesmo posicionamento
