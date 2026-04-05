# Client: Adicionar Slot de Gloves

## Objetivo

Atualizar a UI do client OtClientV8 para exibir o novo slot de gloves (slot 13) abaixo do slot de feet, com ícone próprio e suporte ao estilo blessed.

## Contexto

O client usa engine C++ pré-compilada + scripts Lua/OTUI interpretados em runtime. **Não é necessário recompilar o client** — todas as mudanças são em arquivos de dados. Hot-reload disponível com **Ctrl+Shift+R**.

O servidor adicionou `CONST_SLOT_GLOVES = 13`. O client deve refletir isso com `InventorySlotGloves = 13`.

## Branch

Criar branch `feat/add-glove-slot` no repositório do client antes das alterações.

## Como o novo slot funciona no client

- **Lua:** `InventorySlotGloves = 13` (novo)
- **Widget ID:** `slot13` (gerado dinamicamente em `game_inventory/inventory.lua`)
- **Style:** `GlovesSlot` (`data/styles/40-inventory.otui`)
- **Protocolo:** posição `{x=65535, y=13, z=0}` — novo, correspondente ao slot 13 do servidor

## Dimensões das imagens

- `gloves.png` e `gloves-blessed.png`: **34×34 px** (mesmo padrão dos outros slots)
- Pixel art estilo dos ícones existentes (fundo escuro, contorno, ícone centralizado)
- `gloves-blessed.png`: versão com overlay dourado (mesmo padrão do `*-blessed.png` existente)

## Mudanças necessárias

### Recompilação necessária? **NÃO**

---

### 1. Criar imagens do slot

Criar dois arquivos PNG em `data/images/game/slots/`:

```
data/images/game/slots/gloves.png         ← ícone de luvas vazio (34×34 px)
data/images/game/slots/gloves-blessed.png ← versão blessed com overlay dourado (34×34 px)
```

Referência visual: estilo similar aos ícones existentes (ex: `feet.png`, `body.png`).

---

### 2. `data/modules/gamelib/player.lua`

Adicionar constante `InventorySlotGloves` e atualizar `InventorySlotLast`:

```lua
-- ANTES:
InventorySlotBelt = 12
InventorySlotFirst = 1
InventorySlotLast = 12

-- DEPOIS:
InventorySlotBelt = 12
InventorySlotGloves = 13    -- NOVO
InventorySlotFirst = 1
InventorySlotLast = 13      -- atualizado
```

---

### 3. `data/modules/game_inventory/inventory.lua`

Adicionar `GlovesSlot` ao mapa `InventorySlotStyles`:

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
  [InventorySlotAmmo]   = "AmmoSlot",
  [InventorySlotBelt]   = "BeltSlot",
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
  [InventorySlotBelt]   = "BeltSlot",
  [InventorySlotGloves] = "GlovesSlot",   -- NOVO
}
```

---

### 4. `data/styles/40-inventory.otui` (layout padrão)

Adicionar widget `GlovesSlot` abaixo de `FeetSlot`:

```otui
# ADICIONAR após o bloco FeetSlot:
GlovesSlot < InventoryItem
  id: slot13
  image-source: /images/game/slots/gloves
  &position: {x=65535, y=13, z=0}
  anchors.top: FeetSlot.bottom
  anchors.horizontalCenter: FeetSlot.horizontalCenter
  margin-top: 3
  $on:
    image-source: /images/game/slots/gloves-blessed
```

---

### 5. `layouts/retro/styles/40-inventory.otui` (layout retro)

Mesmas alterações do item 4 acima.

---

## Layout visual resultante

```
         [Head]
[Neck]   [Body]  [Back]
[Left]   [Belt]  [Right]
[Finger] [Legs]  [Ring2]
[Gloves] [Feet]
                   
```

## O que NÃO precisa ser alterado

- `data/modules/game_inventory/inventory.lua` — lógica de `onInventoryChange` já funciona com qualquer slot pelo ID
- Protocolo cliente — apenas o número do slot (13) é novo
- `InventorySlotBelt = 12` — sem mudança

## Como aplicar sem reiniciar o client

1. Criar as imagens PNG
2. Salvar os arquivos editados
3. Pressionar **Ctrl+Shift+R** dentro do client para hot-reload

## Verificação

1. Hot-reload (Ctrl+Shift+R) após as mudanças
2. Slot gloves visível abaixo de feet na UI
3. Equipar gloves via servidor → ícone do gloves equipado aparece no slot 13
4. Desequipar → slot volta ao ícone `gloves.png` vazio
5. Ativar Adventurer blessing → slot deve usar `gloves-blessed.png`
6. Teste no layout retro — slot deve aparecer no mesmo posicionamento
