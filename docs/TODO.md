# TODOs

## Epic Items System

### Ajustes
- [ ] Ajustar como o drop do item vai funcionar (1. O item dropou ou não ? 2. O item é normal ou não identificado ?)

### Cleanup de Testes
- [ ] Remover seed de teste do Epic Mace (`server_item_id=3286, server_item_unidentified_id=3322, base_drop_chance=1.0`) da migration `45.lua`
- [ ] Restaurar comportamento original da SD Rune (id=3155) — remover `action:id(3155)` de `identify_rune.lua`
- [ ] Remover item 44614 de `data/items/items.xml` (placeholder da runa, substituído pelo ID definitivo)

### Identify Rune
- [ ] Criar sprite da runa de identificação e adicioná-la ao `appearances.dat` do client
- [ ] Registrar o novo item em `data/items/items.xml` com o ID definitivo (atualmente usando SD Rune id=3155 como proxy)
- [ ] Atualizar `data/scripts/actions/items/identify_rune.lua`: trocar `action:id(3155)` pelo ID definitivo e remover o proxy
- [ ] Adicionar seed da runa no loot de monstros ou vendor NPC para os jogadores conseguirem obtê-la

### Modifier Description
- [ ] Adicionar coluna `description` em `epic_items_modifiers` (ex: `"+{value}% de dano de fogo"`)
- [ ] Atualizar migration `45.lua` com a nova coluna e seed dos textos de cada modifier
- [ ] Carregar `description` no cache `EpicItems.modifiers` em `epic_items.lua`
- [ ] Usar `description` no look do item identificado (substituir ou complementar o look atual `modifier.name: +value%`)

### Items
- [ ] Remover item de teste (id=349 "test belt") de `data/items/items.xml`
- [ ] Criar itens belt reais no `data/items/items.xml` com `potionbonus`, `armor` e `slottype="belt"`

## Belt Slot

### Sprites
- [ ] Criar `belt.png` (34×34 px) em `client/data/images/game/slots/`
- [ ] Criar `belt-blessed.png` (34×34 px) em `client/data/images/game/slots/`


