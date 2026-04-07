Vamos criar um sistema de waypoints. 

## Server
Esse sistema vai funcionar da seguinte forma:

O jogador anda até o waypoint e da USE nele assim habilitando o waypoint.

O item ID 8836 vai reprensetar o waypoint.

A ideia é a seguinte:

- no REMERES vamos adicionar o item ID 8836 com um unique_id
- vamos criar uma tabela para armezenar os waypoints
  - waypoints (id, name, x, y, z, description)
- Vamos criar uma tabela para armazenar quais waypoints o jogador liberou
  - player_waypoints (player_id, waypoint_id)

Então quando o jogador der use no item 8836, vamos habilitar o waypoint para o jogador e ele podera se teletransportar para la, caso esteja em uma protection zone.


## Client

Vamos criar um novo botão que vai abrir uma modal com a lista de todos os waypoints habilitados pelo jogador.

- O botão vai ficar localizado ao lado do botão de bot e vai ter o mesmo icone
- A modal deve mostrar apenas os waypoints que o jogador habilitou (mostrar o name do waypoint)
- A modal deve ter um botão OK para confirmar a ação de teletransporte


## output 
- plano para o server
- plano para o client