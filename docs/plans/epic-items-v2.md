## Objetivo

Atualizar o sistema epic items. Atualmente o sistema usa a tabela epic_items para armazenar os items epicos que podem ser dropados, vamos atualizar o sistema para utilizar o items.xml

Ou seja, vamos criar items novos para cada tier de raridade 

Esse é o XML para o Mace
<item id="3286" article="a" name="mace">
    <attribute key="primarytype" value="club weapons"/>
    <attribute key="weaponType" value="club"/>
    <attribute key="attack" value="16"/>
    <attribute key="defense" value="11"/>
    <attribute key="weight" value="3800"/>
    <attribute key="script" value="moveevent;weapon">
        <attribute key="weaponType" value="club"/>
        <attribute key="slot" value="hand"/>
    </attribute>
</item>

Teriamos algo assim para um Magic Mace
<item id="3286" article="a" name="unidentified magic mace">
    <attribute key="primarytype" value="club weapons"/>
    <attribute key="weaponType" value="club"/>
    <attribute key="attack" value="16"/>
    <attribute key="defense" value="11"/>
    <attribute key="weight" value="3800"/>
    <attribute key="script" value="moveevent;weapon">
        <attribute key="weaponType" value="club"/>
        <attribute key="slot" value="hand"/>
    </attribute>
    <attribute key="epic" value="true">
        <attribute key="rarity" value="magic"/>
        <attribute key="identified" value="false"/>
    </attribute>
</item>

Teriamos algo assim para um Rare Mace
<item id="3286" article="a" name="unidentified rare mace">
    <attribute key="primarytype" value="club weapons"/>
    <attribute key="weaponType" value="club"/>
    <attribute key="attack" value="16"/>
    <attribute key="defense" value="11"/>
    <attribute key="weight" value="3800"/>
    <attribute key="script" value="moveevent;weapon">
        <attribute key="weaponType" value="club"/>
        <attribute key="slot" value="hand"/>
    </attribute>
    <attribute key="epic" value="true">
        <attribute key="rarity" value="rare"/>
        <attribute key="identified" value="false"/>
    </attribute>
</item>


O attribute epic informa o servidor se esse item é epico ou não, caso não exista o servidor entende como false.
O attribute rarity configura qual a raridade desse item, e instrui como carregar as configs da raridade
O attribute identified informa o servidor se o item ja foi identificado, caso false não podemos equipar o item

## Mudanças MySQL

### Remover

- epic_items (Vamos controlar os epic items direto no items.xml)
- epic_items_types

### Atualizar

- epic_items_modifiers
  - Adicionar a coluna description para podermos adicionar uma descrição que explique o modifier no look do item. Exemplo: Adds 7% fire damage to attacks
  - Remover name
  - Remover min_value
  - Remover max_value
  - adicionar min_magic_value (valor minimo de aumento para o tier magic)
  - adicionar max_magic_value (valor maximo de aumento para o tier magic)
  - adicionar min_rare_value  (valor minimo de aumento para o tier rare)
  - adicionar max_rare_value  (valor maximo de aumento para o tier rare)
  - adicionar applied_to_type (string separada por virgula com os tipos de items que esse modifier por se aplicar)
    - valores possiveis: name,ammunition,amulets and necklaces,armors,axe,belts,boots,club,distance,gloves,helmets,legs,missile,quivers,rings,shield,spellbook,sword,wand
    

- epic_items_rarity
  - remover drop_chance (vamos definir direto no loot dos monstros)
  - adicionar min_modifiers (numero minimo de modifiers)
  - adicionar max_modifiers (numero maximo de modifiers)
  - remover modifiers_count


## Processo de identificar o item

- Só podemos usar a runa em items não identificados e epicos (verificar atributos xml)

Ao usar a runa que identifica o item acontece o seguinte processo.

1. Com base no atributo xml rarity vamos busar a configuração da raridade (epic_items_rarity) 
2. Com base na configuração (min_increase, max_increase), calculamos o increase e transformamos os atributos base do item (attack, defense) 
3. Com base na configuração (min_modifiers, max_modifiers), calculamos o numero de modifiers e adicionamos modifiers ao item
4. Atualizamos o atributo identified do item para true


## Look no item epico

- ao dar look em um item epico precisamos monstrar de forma clara seus modifiers adicionais

## Outras mudanças

- vamos remover o config global no config.lua epicItemMode (epic items vai ser controlado diratamente pelo drop do monstro)





