## Objetivo

Fazer com que o servidor deixe de usar o items.xml e passe a usar uma estrutura em tabelas mysql. Essa nova estrutura sql precisa suportar o novo sistema de items que vamos criar, esse sistema vai ser baseado no diablo 2.

## Tipos de items
Como vamos migrar para estruturas sql, os tipos de items vão precisar migrar para uma tabela separada

Precisamos extrair todos os tipos que existem em data\items\items.xml e armazena-los em uma tabela MySQL, algo como item_types

## Tabela items

Vamos criar essa tabela lendo o arquivo data\items\items.xml. Após ler e definir a estrutura da tabela. Caso o item use algum script, vamos salvar o path para esse script em uma coluna da tabela.

Vamos precisar adicionar mais 3 campos a essa nova tabela:
- min_level (level minimo do monstro para dropar)
- max_level (level maximo do monstro para dropar)
- drop_chance (chance de drop)

## Tipos de raridade
Vamos criar tipos e raridade para os items. A raridade vai influenciar nos stats base do item e em quantas habilidades extras ele tem, alem de mudar sua cor nas mensagens de look e no futuro tooltip que iremos implementar. Items magicos e raros vão ser não indentificados, ou seja o jogador vai precisar identifica-los, ao fazer isso vamos calcular com base na raridade seus atributos.

Items que precisam ser identificados podem ser agrupados (stacked)

O item que identifica vai ser uma runa que vamos implementar depois.

1. normal (normal, 0, 1, 1, white)
2. magico (magic, 1, 1.1, 1.3, blue)
3. raro -> (rare, 2, 1.3, 1.5, yellow)

Vamos precisar de uma tabela no MySQL para guardar os tipos de raridade.
Algo como item_rarity (id, name, habilites[number of habilites], min_increase, max_increase, color, is_identified)

## Novas Habilidades
- ADD_COLD_DAMAGE (attack, Shivering, percent, 1, 10)
- ADD_FIRE_DAMAGE (attack, Flaming, percent, 1, 10)
- ADD_LIGHTNING_DAMAGE (attack, Shocking, percent, 1, 10)
- ADD_POISON_DAMAGE (attack, Toxic, percent, 1, 10)
- ADD_HOLY_DAMAGE (attack, Holy, percent, 1, 10)
- ADD_DARKNESS_DAMAGE (attack, Cursed, percent, 1, 10)
- ADD_PHYSICAL_DAMAGE (attack, Savage, percent, 1, 10)
- ADD_PHYSICAL_DEFENSE (defense, Diamond, fixed, 1, 15)
- ADD_FIRE_RESISTENCE(defense, Ruby, percent, 1, 10)
- ADD_COLD_RESISTENCE (defense, Sapphire, percent, 1, 10)
- ADD_LIGHTNING_RESISTENCE (defense, Amber, percent, 1, 10)
- ADD_POSION_RESISTENCE (defense, Jade, percent, 1, 10)
- ADD_HOLY_RESISTENCE (defense, Topaz, percent, 1, 10)
- ADD_DARKNESS_RESISTENCE (defense, Sacred, percent, 1, 10)
- ADD_DROP_CHANCE (support, Fortuitous, fixed, 1, 5)
- ADD_MAX_LIFE (support, Tiger, percent, 1, 5)
- ADD_LIFE_STEAL (support, Vampire, percent, 1, 5)
- ADD_MANA_STEAL (support, Wraith, percent, 1, 5)
- ADD_ATTACK_SPEED (support, Swiftness, percent, 1, 10)
- ADD_MOVEMENT_SPEED (support, Haste, fixed, 10, 20)
- ADD_MAX_MANA (support, Snake, percent, 1, 5)

Vamos precisar de uma tabela no MySQL para guardar as habilidades. 
item_habilities (id, type, effect, name, effect_type[fixed, percent], min_value, max_value)

Vamos precisar de uma tabela no MySQL para guardar a relação entre item type e hability

item_habilities_item_type
(id, item_hability_id, id_item_type)

Vamos precisar de uma tabela no MySQL para guardar a relação entre item type e hability
item_habilitie_item_rarity
(id, item_hability_id, rarity_id)

## Fluxo de drop

1. monstro morre
2. os items que ele pode dropar são calculados com base no nivel dele
3. após calcular os items, precisamos calcular a raridade (normal, magico ou raro)
   
Ou seja, os monstros vão dropar ouro e items consumives normalmente, porem items vai ser dinamico. Precisamos pensar em uma maneira de calcular o drop de forma eficiente

## Novas habilidades nos items

Com base nas habilidades que definimos acima, precisamos analisar quais delas os items já suportam nativamente e ajustar, e quais delas precisamos dar suport nativamente. 

Após esse processo é necessário pensar em uma maneira de aplicar os efeitos no personagem ao equipar o item, e remover os efeitos ao remover o item.

## Pontos Importantes

- Essa estrutura precisa ser flexivel, ou seja, vamos acabar adicionando novos atributos para os items.
- O sistema vai ser baseado no sistema de items do diablo 2
- os items vão poder aparecer em diferentes nives de raridade: normal, magico, raro e unico
- Items normais vão ter os stats basicos fixos (definidos nas tabelas mysql).
- Items só podem ter 1 habilidade de cada tipo (attack, defense, support)
- precisamos analisar o impacto de fazer essa alteração no client.
- precisamos entender se os editores de mapa RME dependem desse arquivo XML
- precisamos ter certeza que não vamos quebrar nada ao remover o items.xml e passar a usar nossas novas tabelas no MySQL



