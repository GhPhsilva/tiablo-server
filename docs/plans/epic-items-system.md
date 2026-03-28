# Sistema de items epicos

Não vamos remover completamente o items.xml, a ideia agora é criar um novo sistema chamado **Epic Items**.
Vamos precisar criar uma configuração global, algo no config.lua, para configurar como o dropa vai funcionar no servidor, com as seguintes opções
- NORMAL (usa o sistema baseado no items.xml normal)
- MIXED (usa o sistema baseado no items.xml normal, porem ao morrer os monstros vão tambem dropar items epicos)
- EPIC (usa apenas o novo sistema, monstro ao morrer dropam apenas items epicos)

O sistema **Epic Items** vai ser 100% MySQL, com as seguintes tabelas

- epic_items
- epic_items_rarity
- epic_items_modifiers
- epic_items_types
- epic_items_modifiers_epic_items_types


## Tabelas do mysql:

### `epic_items`

Essa tabela vai armazenar de fato as informações dos novos items. Vamos precisar analisar o arquivo data\items\items.xml e determinar quais atributos podemos tranformar em colunas, lembrando que as habilidades vão ser atribuidas de forma dinamica

Atributos que vamos precisar com certeza:
- weight
- primarytype
- script
- slot
- level
- vocation (por enquanto vai ser o id de uma vocação, depois vamos pensar em como atribuir multiplas)
- attack
- defense
- armor
- range


### `epic_items_rarity`
```sql
CREATE TABLE `epic_items_rarity` (
    `id`              TINYINT UNSIGNED  NOT NULL,
    `name`            VARCHAR(32)       NOT NULL,
    `code`            VARCHAR(32)       NOT NULL,
    `modifiers_count` TINYINT UNSIGNED  NOT NULL DEFAULT 1,
    `min_increase`    FLOAT             NOT NULL DEFAULT 1.0,
    `max_increase`    FLOAT             NOT NULL DEFAULT 1.0,
    `color_name`      VARCHAR(32)       NOT NULL DEFAULT 'white',
    `drop_chance`     FLOAT             NOT NULL,
    PRIMARY KEY (`id`), UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB;
-- Seed: (1,Normal,normal,1,1.0,1.0,white,0), (2,Magic,magic,1,1.1,1.3,blue,1), (3,Rare,rare,1,1.3,1.5,yellow,1)
```

### `epic_items_modifiers`
```sql
CREATE TABLE `epic_items_modifiers` (
    `id`          SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type`        ENUM('attack','defense','support') NOT NULL,
    `effect`      VARCHAR(64) NOT NULL,
    `name`        VARCHAR(64) NOT NULL,
    `effect_type` ENUM('fixed','percent') NOT NULL DEFAULT 'fixed',
    `min_value`   FLOAT NOT NULL DEFAULT 0,
    `max_value`   FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`), UNIQUE KEY `effect` (`effect`)
) ENGINE=InnoDB;
-- Seeded with all 21 abilities:
-- (1,'attack','ADD_COLD_DAMAGE','Shivering','percent',1,10)
-- (2,'attack','ADD_FIRE_DAMAGE','Flaming','percent',1,10)
-- (3,'attack','ADD_LIGHTNING_DAMAGE','Shocking','percent',1,10)
-- (4,'attack','ADD_POISON_DAMAGE','Toxic','percent',1,10)
-- (5,'attack','ADD_HOLY_DAMAGE','Holy','percent',1,10)
-- (6,'attack','ADD_DARKNESS_DAMAGE','Cursed','percent',1,10)
-- (7,'attack','ADD_PHYSICAL_DAMAGE','Savage','percent',1,10)
-- (8,'defense','ADD_PHYSICAL_DEFENSE','Diamond','fixed',1,15)
-- (9,'defense','ADD_FIRE_RESISTENCE','Ruby','percent',1,10)
-- (10,'defense','ADD_COLD_RESISTENCE','Sapphire','percent',1,10)
-- (11,'defense','ADD_LIGHTNING_RESISTENCE','Amber','percent',1,10)
-- (12,'defense','ADD_POISON_RESISTENCE','Jade','percent',1,10)
-- (13,'defense','ADD_HOLY_RESISTENCE','Topaz','percent',1,10)
-- (14,'defense','ADD_DARKNESS_RESISTENCE','Sacred','percent',1,10)
-- (15,'support','ADD_DROP_CHANCE','Fortuitous','fixed',1,5)
-- (16,'support','ADD_MAX_LIFE','Tiger','percent',1,5)
-- (17,'support','ADD_LIFE_STEAL','Vampire','percent',1,5)
-- (18,'support','ADD_MANA_STEAL','Wraith','percent',1,5)
-- (19,'support','ADD_ATTACK_SPEED','Swiftness','percent',1,10)
-- (20,'support','ADD_MOVEMENT_SPEED','Haste','fixed',10,20)
-- (21,'support','ADD_MAX_MANA','Snake','percent',1,5)
```

### `epic_item_types`

Types:
- sword
- axe
- club
- distance
- wand
- ammunition
- missile
- shield
- spellbook
- armors
- legs
- boots
- helmets
- quivers
- rings
- amulets and necklaces
- belts
- gloves

A tabela pode ser (id, name)

### `epic_items_modifiers_epic_items_types`
```sql
CREATE TABLE `epic_items_modifiers_epic_items_types` (
    `id`               INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `epic_item_modifier_id` SMALLINT UNSIGNED NOT NULL,
    `epic_item_type_id`     SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `modifier_type` (`epic_item_modifier_id`, `epic_item_type_id`),
    KEY `epic_item_type_idx` (`epic_item_type_id`),
    FOREIGN KEY (`epic_item_modifier_id`) REFERENCES `epic_item_modifiers` (`id`),
    FOREIGN KEY (`epic_item_type_id`) REFERENCES `epic_item_types` (`id`)
) ENGINE=InnoDB;
```

## Fluxo de drop

1. monstro morre
2. os items que ele pode dropar são calculados com base no nivel dele
3. após calcular os items, precisamos calcular se ele veio identificado ou não (baseado na chance do player de obter items não identificados)
   1. Se veio identificado ele é de raridade normal e a flag no item is_identified é true, o fluxo termina
   2. Se veio não identificado é gerado um item não identificado (raridade null, is_identified false), o fluxo termina
   

## Fluxo de identificação do item

1. após usar a runa em um item não identificado precisamos calcular a chance do item ser magico ou raro
2. após calculada essa chance vamos aplicar os efeitos no item
  1. mudar stats base
  2. adicionar habilidades com base na raridade
  3. mudar a cor do item no look com base na raridade
  4. se possivel mudar a cor da sprite (adicionando um effect azul ou amarelo) com base na raridade
  5. atualizar as colunas rarity e is_identified da tabela de items
  6. mudar o nome do item com base nas habilidades
     1. Caso tenha uma adicione como prefixo (coluna name da tabela epic_item_modifiers)
     2. Caso tenha 2 habilidades a primeira fica como prefixo a segunda como sufixo (Prefixo + nome do item + "of Sufixo")

## Informações sobres os items

- Todo item do servidor vai ter 2 sprites 
  - Uma para quando ele dropa normal (identificado)
  - Uma para quando ele dropa não identificado
- não é possivel usar a runa que identifica em um item ja identificado
- não é possivel equipar um item não identificado
- items não identificados são stackaveis
- Items só podem ter 1 habilidade de cada tipo (attack, defense, support)
  

## Pontos importantes

- Essa estrutura precisa ser flexivel, ou seja, vamos acabar adicionando novas habilidades para os items
- O sistema vai ser baseado no sistema de items do diablo 2
- os items vão poder aparecer em 2 tipos normal e não-identificado
  - após identificar ele pode ser magico ou raro
- Items normais vão ter os stats basicos fixos (definidos nas tabelas mysql).
- precisamos analisar o impacto de fazer essa alteração no client.
  - para isso vamos analisar "C:\Users\Pedro\Documents\tiablo\client\CLAUDE.md"
- precisamos garantir que podemos optar por usar ou não o sistema de items epicos, e caso ele esteja habilitado todos os monstros terão a chance de dropar baseado em seu level
- Precisamos entender como aplicar as habilidades extras dos items no jogar