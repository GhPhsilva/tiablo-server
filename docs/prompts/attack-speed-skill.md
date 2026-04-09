Nós adicionamos o novo item attribute attack speed, agora vamos adicionar uma nova skill para o player, vamos adicionar a skill attack speed.

Essa skill vai ser estatica, não vai ser possivel treina-la, vai ser parecida com o critical hit chance.

Ou seja, cada player vai ter um attack_speed base, por hora esse base vai ser 2000 ms, porem eu quero mostrar em porcentagem, então 2000 ms -> 0%.

## MySQL
Vamos precisar adicionar uma nova coluna na base de dados, na tabela players

- nova coluna attack_speed (default 2000)


## Redução discreta baseada na skill

- da mesma maneira que critical hit chance, mana leech chance e life leech chance, a skill attack_speed vai sofrer alteração com base na arma equipada e no skill corresponte a essa arma, vou precisar de ajuda para decidir como vai ser essa alteração, porem quero que seja discreta.


Os items com o atributo enhancedattackspeed são aditivos nessa skill, ou seja, o comportamento atual continua igual.


## Client side

- vamos precisar adicionar a nova skill embaixo da skill mana leech amoumt
- para entender o client leia "C:\Users\Pedro\Documents\tiablo\client\CLAUDE.md"

## Regras
- Me pergunte o que não foi entendido, não assuma nada
- O plano precisa ter confiança de 95%

## Output 
- server com nova skill funcionando
- client exibindo nova skill