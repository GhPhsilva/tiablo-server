# TODOs

## Epic Items System

### Cleanup de Testes
- [ ] Restaurar comportamento original da SD Rune (id=3155) — remover `action:id(3155)` de `identify_rune.lua`
- [ ] Remover item 44614 de `data/items/items.xml` (placeholder da runa, substituído pelo ID definitivo)

### Identify Rune
- [ ] Criar sprite da runa de identificação e adicioná-la ao `appearances.dat` do client
- [ ] Registrar o novo item em `data/items/items.xml` com o ID definitivo (atualmente usando SD Rune id=3155 como proxy)
- [ ] Atualizar `data/scripts/actions/items/identify_rune.lua`: trocar `action:id(3155)` pelo ID definitivo e remover o proxy
- [ ] Adicionar seed da runa no loot de monstros ou vendor NPC para os jogadores conseguirem obtê-la

### Modifier Description
- [ ] Implementar novas cores para look

## Belt Slot

### Items
- [ ] Remover item de teste (id=349 "test belt") de `data/items/items.xml`
- [ ] Criar itens belt reais no `data/items/items.xml` com `potionbonus`, `armor` e `slottype="belt"`

### Sprites
- [ ] Criar `belt.png` (34×34 px) em `client/data/images/game/slots/`
- [ ] Criar `belt-blessed.png` (34×34 px) em `client/data/images/game/slots/`


