# Novo sistema

Vamos criar um novo sistema de items no servidor, o novo sistema vai se chamar Epic items. 

A ideia é adicionar items novos no servidor e esses items podem ser de alguns tiers diferentes (magic, rare, epic), para obter um item deste tipo o jogador vai precisar dropar um item não identificado, e usar uma runa especifica para identificar o item.

Os items épicos, após identificados, irão sofrer uma transformação, modificando alguns aspectos:

1. Name change
   - O nome é alterado com base no Tier do item não identificado
   - Ex: unidentified magic mace -> magic mace
2. Base Enhance
   - Com base no Tier, vamos calcular o Base Enhance
   - ataque, defesa, armor, peso e range (cada propriedade vai ter o seu multiplicador)
   - caso o item não possua um dos atributos apenas ignoramos
3. Magic Enhance
   - Com base no Tier, vamos calcular quantos magic modifiers vamos aplicar ao item
   - Cada modifier vai adicionar um efeito 
4. Description change
   - Vamos alterar a description do item com base nos modifiers
   - O look do item vai ser alterado


Aqui esta um diagrama do fluxo básico dos items epicos:

1. Monstro morre e dropa um item não identificado (Ex: unidentified magic mace)
2. Jogador usa uma runa para identificar o item não identificado
3. Com base no Tier do item o sistema calcula algumas propriedades:
   1. Aumento dos atributos base (ataque, defesa, armor, peso, range)
   2. Numero de modifiers
   3. Descrição do item (look)

## Definições do sistema

O sistema vai ser hibrido, parte das configurações vai ficar no MySQL e parte vai ficar no data\items\items.xml.

### C++

- Vamos precisar de novos atributos para representar os 6 possiveis modifiers dos items epicos
- Vamos precisar de um atributo para marcar se o item é epico ou não
- Vamos precisar de um atributo para marcar se o item esta identificado ou não
- Vamos precisar de um atributo para marcar a raridade do item epico
- Vamos precisar de um atributo para guardar o tipo do item

### XML

Vamos implementar o suporte a multiplos xmls de items. Para entender como leia docs\epic_items\multiple-xml-support.md.

Os items epicos vão ter um tributo extra no xml

<attribute key="epic" value="true">
   <attribute key="rarity" value="magic"/> // define a raridade do item
   <attribute key="identified" value="false"/> // define se o item esta identificado ou não
   <attribute key="type" value="club"> // tipo do item, esse atributo é usado para definir quais modifiers ele pode receber
</attribute>

### MySQL

- epic_items_rarities
  - tier (enum, not null, [magic, rare, epic])
  - min_base_enhance (unsigned int, not null, default 1)
  - max_base_enhance (unsigned int, not null, default 1)
  - min_modifiers (unsigned integer, not null, default 1)
  - max_modifiers (unsigned integer, not null, default 1)

Valores para inserir na tabela epic_items_rarities
(magic, 5, 10, 1, 3)
(rare, 10, 15, 2, 5)
(epic, 15, 25, 3, 6)

- epic_items_modifiers
  - type (enum, not null, [elemental_damage, defense, attack, support])
  - modifier (string, unique, not null)
  - modifier_type (enum, not null, [fixed, percent])
  - min_magic_enhance (unsigned integer, not null, default 1)
  - max_magic_enhance (unsigned integer, not null, default 1)
  - min_rare_enhance (unsigned integer, not null, default 1)
  - max_rare_enhance (unsigned integer, not null, default 1)
  - min_epic_enhance (unsigned integer, not null, default 1)
  - max_epic_enhance (unsigned integer, not null, default 1)
  - xml_attribute (string, nullabel)
  - applied_to (string separada por virgulas) 

valores para inserir na tabela epic_items_modifiers
(elemental_damage, FIRE_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(elemental_damage, ICE_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementice, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(elemental_damage, EARTH_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementearth, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(elemental_damage, ENERGY_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementenergy, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(elemental_damage, DEATH_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementdeath, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(elemental_damage, HOLY_DAMAGE, percent, 5, 10, 10, 15, 15, 30, elementholy, elementfire, fist,sword,axe,club,bow,spear,throwing, crossbow)
(absorb, FIRE_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentfire, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, ICE_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentice, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, EARTH_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentearth, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, ENERGY_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentenergy, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, DEATH_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentdeath, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, HOLY_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentholy, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, PHYSICAL_ABSORB, percent, 5, 8, 6, 10, 9, 15, absorbpercentphysical, glove,helmet,armor,belt,leg,boot,shield,amulet,ring,quiver,spellbook)
(absorb, MAGIC_ABSORB, percent, 1, 3, 3, 5, 5, 10, absorbpercentmagic, armor,shield,amulet,ring)
(defense, ENHANCED_DEFENSE, percent, 5, 10, 6, 15, 15, 20, enhanceddefense, glove,helmet,armor,belt,leg,boot,shield)
(defense, THORNS, percent, 2, 5, 5, 10, 10, 15, reflectpercentall, fist,club,helmet,armor,leg,shield)
(defense, LIFE_DRAIN_ABSORB, percent, 2, 5, 5, 10, 10, 15, absorbpercentlifedrain, helmet,armor,belt,leg,boot,shield,amulet,ring)
(defense, MANA_DRAIN_ABSORB, percent, 2, 5, 5, 10, 10, 15, absorbpercentmanadrain, helmet,armor,belt,leg,boot,shield,amulet,ring,spellbook)
(attack, ENHANCED_DAMAGE, percent, 5, 10, 6, 15, 15, 20, enhancedamage, fist,sword,axe,club,spear,throwing,bow,crossbow,wand,glove)
(attack, ENHANCED_ATTACK_SPEED, percent, 1, 3, 3, 5, 5, 10, enhancedattackspeed, glove,fist,sword,axe,club,spear,throwing,bow,crossbow,wand,belt,quiver)
(attack, CRITICAL_DAMAGE, percent, 500, 1000, 800, 2000, 1000, 2500, criticalhitdamage, glove,fist,sword,axe,club,spear,throwing,bow,crossbow,wand,ring,amulet,quiver,spellbook,shield)
(attack, CLEAVE, percent, 5, 10, 10, 15, 15, 25, cleavepercent, fist,sword,axe,club)
(support, LIFE_LEECH, percent, 100, 300, 300, 500, 500, 1000, lifeleechamount, glove,fist,sword,axe,club,spear,throwing,bow,crossbow,ring,amulet)
(support, MANA_LEECH, percent, 100, 300, 300, 500, 500, 1000, manaleechamount, glove,fist,sword,axe,club,spear,throwing,bow,crossbow,ring,amulet,wand)
(support, SPEED, fixed, 5, 15, 10, 20, 15, 30, speed, belt,boot,ring,amulet,bow,quiver)
(support, MAX_HEALTH, percent, 102, 104, 104, 106, 105, 108, maxhitpointspercent, helmet,armor,belt,leg,boot,shield,ring,amulet)
(support, MAX_MANA, percent, 102, 104, 104, 106, 105, 108, maxmanapointspercent, helmet,armor,belt,leg,boot,shield,ring,amulet,spellbook)
(support, HITCHANCE, percent, 5, 10, 7, 15, 10, 20, hitchance, bow,crossbow)
(support, MAGIC_SHIELD_CAPACITY, percent, 5, 10, 7, 15, 10, 20, magicshieldcapacitypercent, wand,spellbook,ring,amulet)
(skill, MAGIC_SKILL, fixed, 1, 2, 2, 4, 4, 6, magiclevelpoints, wand,ring,amulet)
(skill, SWORD_SKILL, fixed, 2, 4, 4, 6, 5, 10, skillsword, sword,ring,amulet,glove)
(skill, SKILL_AXE, fixed, 2, 4, 4, 6, 5, 10, skillaxe, axe,ring,amulet,glove)
(skill, SKILL_CLUB, fixed, 2, 4, 4, 6, 5, 10, skillclub, club,ring,amulet,glove)
(skill, SKILL_DISTANCE, fixed, 2, 4, 4, 6, 5, 10, skilldist, bow,crossbow,spear,throwing,ring,amulet,glove,quiver)
(skill, SKILL_SHIELD, fixed, 2, 4, 4, 6, 5, 10, skillshield, shield,ring,amulet,glove)
(skill, SKILL_FIST, fixed, 2, 4, 4, 6, 5, 10, skillfist, fist,ring,amulet,glove)

## Regras do sistema

- Não sera possivel equipar itens não identificados
- Só é permitido 1 modifier do tipo elemental_damage por item

## Identify rune

Vamos precisar de um script para identificar o item epico que não esta identificado. Essa runa só pode ser usada
em items epicos não identificados.

Esse script vai fazer o seguinte

1. Renomear o item, removendo a palavra unidentified
   - Ex: Unidentifed magic mace -> magic mace
2. Com base no tier de raridade, vai sortear quantos modifiers esse item vai ganhar
   - Ex: magic, minimo:1, maximo:3 -> após sorteio... 3
3. Vai sortear os modifiers, respeitando a regra de apenas 1 modifier do tipo elemental_damage, e vai sortear apenas modifier que são permitidos para o item item
   - Ex: Modifier 1: elementFire, Modifier 2: enhancedDamage, MODIFIER 3: enhancedattackspeed
4. Para cada modifier, vamos chamar o parser correto no c++
5. Marcar o item como identificado


criticalhitchance -> base in skill (25%) (global)
manaleechchance -> base in skill (25%) (global)
lifeleechchance -> base in skill (25%) (global)




### remover
- imbuementslot