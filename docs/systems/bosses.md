## Objetivo

Criar um sistema que permita que os monstro ao spawnar tenham a chance de se tornar epicos.

## Pontos Importantes

- Monstros epicos tem o nome composto por Prefixo + nome do monstro
- Possiveis prefixos:
  - Cursed
  - Damned
  - Forsaken
  - Ancient
  - Cruel
  - Vile
  - Infernal
  - Wicked
  - Merciless
  - Savage
  - Burning
  - Fallen
  - Feral
  - Rabid
  - Ancient
  - Primal
  - Savage
  - Shadow
  - Mad
- Monstros epicos tem uma skull (quanto maior a dificuldade do monstro mais ameaçadora a skull)
- Monstros epicos podem nascer em 3 dificuldades:
  - Normal: 1 habilidade extras e skull branca
  - Nightmare: 2 habilidades extras e skull vermelha
  - Hell: 3 habilidades extras e skull preta
- Monstros epicos tem chance de loot aumentada
- Monstros epicos tem HP aumentado
- Monstros epicos tem Mana aumentado
- Monstros epicos dão mais XP ao morrer
- Monstros especias dão mais dano
- Os Summons dos monstros epicos não são epicos
- Habilidades possiveis para os monstros epicos
  - Extra strong (ataques dão mais dano)
  - Extra fast (velocidade aumentada)
  - Assassin (chance de critico)
  - Regenerador (life regen)
  - Tank (defesa e resistencias elementais aumentadas)
- Precisamos de uma estrutura em MySQL para armazenar as configurações dos monstros epicos, quero que o sistema seja totalmente customizavel no MySQL
  - O fluxo de dados seria algo como MySQL armazena as configurações e os scripts lua carregam as informações
- Configurações que precisamos armazenar no MySQL
  - Skull por dificuldade
  - Chance de loot por dificuldade
  - Scale de HP por dificuldade
  - Scale de mana por dificuldade
  - Scale de XP por dificuldade
  - Scale de dano por dificuldade
- Vamos ter uma tabela responsavel por criar a configuração, algo como epic_monsters_config
- Vamos ter uma tabela responsavel por definir o scale por dificuldade, algo como epic_monsters_scaling

## Próxima etapa
- recompilar servidor para permitir setName


